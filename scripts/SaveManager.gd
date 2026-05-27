## SaveManager.gd
## Autoload singleton – obsługuje zapis i odczyt stanu gry do/z pliku JSON.
## Ścieżki: user://savegame.json  +  res://last_saves/save_TIMESTAMP.json
extends Node

const SAVE_PATH      := "user://savegame.json"
const LAST_SAVES_DIR := "res://last_saves"

signal save_completed
signal load_completed(success: bool)

# ─────────────────────────────────────────────────────────────────────────────
#  SAVE
# ─────────────────────────────────────────────────────────────────────────────

func save_game() -> bool:
	var data := {}

	# ── 1. GameManager ───────────────────────────────────────────────────────
	data["money"]                   = GameManager.money
	data["prestige"]                = GameManager.prestige
	data["event_prestige_modifier"] = GameManager.event_prestige_modifier
	data["customers"]               = GameManager.customers
	data["play_time"]               = GameManager.play_time
	data["time_multiplier"]         = GameManager.time_multiplier
	data["tables_bought"]           = GameManager.tables_bought
	data["has_won"]                 = GameManager.has_won
	data["time_since_last_event"]   = GameManager.time_since_last_event
	data["next_event_time"]         = GameManager.next_event_time
	data["player_nickname"]         = GameManager.player_nickname

	# ── 2. Stoliki ───────────────────────────────────────────────────────────
	var tables_list: Array = _get_tree().get_nodes_in_group("tables")
	var table_to_idx := {}          # Node -> int  (do linkowania NPC)
	var tables_data: Array = []

	for i in range(tables_list.size()):
		var table = tables_list[i]
		table_to_idx[table] = i
		var t := {
			"table_type":      table.get("table_type")      if "table_type"      in table else "roulette",
			"position_x":      table.global_position.x,
			"position_y":      table.global_position.y,
			"win_probability": table.get("win_probability") if "win_probability" in table else 0.5,
			"bet":             table.get("bet")             if "bet"             in table else 10,
			"play_time":       table.get("play_time")       if "play_time"       in table else 10.0,
			"vip_chance_bonus":table.get("vip_chance_bonus")if "vip_chance_bonus"in table else 0.0,
			"prestige_bonus":  table.get("prestige_bonus")  if "prestige_bonus"  in table else 0,
			"has_felt":        table.get("has_felt")        if "has_felt"        in table else false,
			"has_led":         table.get("has_led")         if "has_led"         in table else false,
			"has_chip_rack":   table.get("has_chip_rack")   if "has_chip_rack"   in table else false,
			"has_vip_seats":   table.get("has_vip_seats")   if "has_vip_seats"   in table else false,
			"has_spinner":     table.get("has_spinner")     if "has_spinner"     in table else false,
			"has_drinks":      table.get("has_drinks")      if "has_drinks"      in table else false,
		}
		tables_data.append(t)
	data["tables"] = tables_data

	# ── 3. Bar ───────────────────────────────────────────────────────────────
	var bar_data := {}
	var bars = _get_tree().get_nodes_in_group("bars")
	if bars.size() > 0:
		var bar = bars[0]
		bar_data = {
			"purchased":          bar.visible,
			"passive_income":     bar.get("passive_income")     if bar.get("passive_income")     != null else 0,
			"prestige":           bar.get("prestige")           if bar.get("prestige")           != null else 0,
			"vip_percentage":     bar.get("vip_percentage")     if bar.get("vip_percentage")     != null else 0.0,
			"cashier_upgraded":   bar.get("cashier_upgraded")   if bar.get("cashier_upgraded")   != null else false,
			"drinks_upgraded":    bar.get("drinks_upgraded")    if bar.get("drinks_upgraded")    != null else false,
			"live_band_upgraded": bar.get("live_band_upgraded") if bar.get("live_band_upgraded") != null else false,
			"position_x":         bar.global_position.x,
			"position_y":         bar.global_position.y,
		}
	else:
		bar_data["purchased"] = false
	data["bar"] = bar_data

	# ── 4. NPC – pozycja, stan, powiązanie ze stolikiem / miejscem ───────────
	var npcs_data: Array = []
	for npc in _get_tree().get_nodes_in_group("customers"):
		var n := {
			"position_x":           npc.global_position.x,
			"position_y":           npc.global_position.y,
			"status":               npc.get("status")               if npc.get("status")               != null else "normal",
			"money":                npc.get("money")                if npc.get("money")                != null else 100.0,
			"anger":                npc.get("anger")                if npc.get("anger")                != null else 0.0,
			"on_sidewalk":          npc.get("on_sidewalk")          if npc.get("on_sidewalk")          != null else true,
			"walking_direction":    npc.get("walking_direction")    if npc.get("walking_direction")    != null else 1,
			"is_seated":            npc.get("is_seated")            if npc.get("is_seated")            != null else false,
			"is_leaving_casino":    npc.get("is_leaving_casino")    if npc.get("is_leaving_casino")    != null else false,
			"is_going_to_bar":      npc.get("is_going_to_bar")      if npc.get("is_going_to_bar")      != null else false,
			"is_in_cashier_queue":  npc.get("is_in_cashier_queue")  if npc.get("is_in_cashier_queue")  != null else false,
			"has_visited_cashier":  npc.get("has_visited_cashier")  if npc.get("has_visited_cashier")  != null else false,
			"table_index":          -1,
			"seat_index":           -1,
		}

		# Zapamiętaj przy którym stoliku i miejscu siedzi NPC
		var target_table = npc.get("target_table")
		if target_table != null and target_table in table_to_idx:
			n["table_index"] = table_to_idx[target_table]
			var target_seat = npc.get("target_seat")
			if target_seat != null and "seats" in target_table:
				n["seat_index"] = target_table.seats.find(target_seat)

		npcs_data.append(n)
	data["npcs"] = npcs_data

	# ── Timestamp ────────────────────────────────────────────────────────────
	data["saved_at"] = Time.get_datetime_string_from_system()

	# ── Zapis ────────────────────────────────────────────────────────────────
	var json_str := JSON.stringify(data, "\t")

	if not _write_file(SAVE_PATH, json_str):
		return false

	_write_last_save(json_str)   # kopia do res://last_saves/
	emit_signal("save_completed")
	print("SaveManager: gra zapisana → ", SAVE_PATH)
	return true


# ─────────────────────────────────────────────────────────────────────────────
#  LOAD
# ─────────────────────────────────────────────────────────────────────────────

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("SaveManager: brak pliku zapisu: " + SAVE_PATH)
		emit_signal("load_completed", false)
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: nie można otworzyć pliku do odczytu: " + SAVE_PATH)
		emit_signal("load_completed", false)
		return false

	var json_str := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if parsed == null or not parsed is Dictionary:
		push_error("SaveManager: błąd parsowania JSON")
		emit_signal("load_completed", false)
		return false

	var data: Dictionary = parsed

	# ── 1. GameManager ───────────────────────────────────────────────────────
	if "money"                   in data: GameManager.money                   = float(data["money"])
	if "prestige"                in data: GameManager.prestige                = int(data["prestige"])
	if "event_prestige_modifier" in data: GameManager.event_prestige_modifier = int(data["event_prestige_modifier"])
	if "customers"               in data: GameManager.customers               = int(data["customers"])
	if "play_time"               in data: GameManager.play_time               = float(data["play_time"])
	if "time_multiplier"         in data: GameManager.time_multiplier         = float(data["time_multiplier"])
	if "tables_bought"           in data: GameManager.tables_bought           = int(data["tables_bought"])
	if "has_won"                 in data: GameManager.has_won                 = bool(data["has_won"])
	if "time_since_last_event"   in data: GameManager.time_since_last_event   = float(data["time_since_last_event"])
	if "next_event_time"         in data: GameManager.next_event_time         = float(data["next_event_time"])
	if "player_nickname"         in data: GameManager.player_nickname         = str(data["player_nickname"])

	# ── 2. Stoliki ───────────────────────────────────────────────────────────
	var restored_tables: Array = []
	if "tables" in data:
		restored_tables = await _restore_tables(data["tables"])

	# ── 3. Bar ───────────────────────────────────────────────────────────────
	if "bar" in data:
		_restore_bar(data["bar"])

	# ── 4. NPC ───────────────────────────────────────────────────────────────
	if "npcs" in data:
		await _restore_npcs(data["npcs"], restored_tables)

	# ── Przelicz klientów w kasynie po przywróceniu NPC ───────────────────────
	# Liczymy NPC, którzy fizycznie są w kasynie (nie na chodniku, po kasie)
	var casino_count := 0
	for npc in _get_tree().get_nodes_in_group("customers"):
		var on_sw   = npc.get("on_sidewalk")
		var visited = npc.get("has_visited_cashier")
		if on_sw != null and not bool(on_sw) \
				and visited != null and bool(visited):
			casino_count += 1
	GameManager.customers = casino_count

	GameManager.update_global_prestige()
	GameManager.emit_signal("stats_changed")

	emit_signal("load_completed", true)
	print("SaveManager: gra wczytana ← ", SAVE_PATH)
	return true


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Wczytuje grę z dowolnego wskazanego pliku (np. wybranego przez FileDialog).
## Po wczytaniu automatycznie kopiuje plik do user://savegame.json
## tak żeby przyciski Save/Load w grze dalej działały poprawnie.
func load_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("SaveManager: plik nie istnieje: " + path)
		emit_signal("load_completed", false)
		return false

	# Skopiuj wybrany plik do user://savegame.json
	var src := FileAccess.open(path, FileAccess.READ)
	if src == null:
		push_error("SaveManager: nie można odczytać: " + path)
		emit_signal("load_completed", false)
		return false
	var content := src.get_as_text()
	src.close()

	var dst := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if dst == null:
		push_error("SaveManager: nie można zapisać do: " + SAVE_PATH)
		emit_signal("load_completed", false)
		return false
	dst.store_string(content)
	dst.close()

	# Teraz wczytaj ze standardowej ścieżki
	return await load_game()


# ─────────────────────────────────────────────────────────────────────────────
#  PRIVATE HELPERS
# ─────────────────────────────────────────────────────────────────────────────

func _get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _write_file(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: nie można zapisać do: " + path)
		return false
	file.store_string(content)
	file.close()
	return true


func _write_last_save(json_str: String) -> void:
	# Stwórz katalog jeśli nie istnieje
	var dir := DirAccess.open("res://")
	if dir == null:
		push_warning("SaveManager: brak dostępu do res://")
		return
	if not dir.dir_exists("last_saves"):
		dir.make_dir("last_saves")

	# Timestampowana nazwa pliku (zastąp ":" i spację by uniknąć problemów z FS)
	var ts: String = Time.get_datetime_string_from_system()\
		.replace(":", "-").replace(" ", "_")

	# Prefiks: nickname gracza lub fallback "save"
	var prefix: String = GameManager.player_nickname.strip_edges()
	if prefix.is_empty():
		prefix = "save"
	else:
		# Usuń znaki niedozwolone w nazwach plików
		prefix = prefix.replace("/", "").replace("\\", "").replace(":", "").replace("*", "") \
				.replace("?", "").replace("\"", "").replace("<", "").replace(">", "").replace("|", "")
	var path := LAST_SAVES_DIR + "/%s_%s.json" % [prefix, ts]

	if _write_file(path, json_str):
		print("SaveManager: kopia → ", path)


func _restore_tables(tables_data: Array) -> Array:
	# Usuń stare stoliki
	for table in _get_tree().get_nodes_in_group("tables"):
		table.queue_free()
	await _get_tree().process_frame

	var casino_floor = _get_tree().get_first_node_in_group("casino_floor")
	if casino_floor == null:
		casino_floor = _get_tree().current_scene

	var spawned: Array = []
	for t_data in tables_data:
		var ttype: String   = t_data.get("table_type", "roulette")
		var spath: String   = _get_table_scene_path(ttype)
		if spath.is_empty():
			push_warning("SaveManager: nieznany typ stołu '%s'" % ttype)
			spawned.append(null)
			continue

		var packed: PackedScene = load(spath)
		if packed == null:
			push_error("SaveManager: brak sceny '%s'" % spath)
			spawned.append(null)
			continue

		var table: Node2D = packed.instantiate()
		casino_floor.add_child(table)
		table.global_position = Vector2(float(t_data.get("position_x", 0.0)),
		                                float(t_data.get("position_y", 0.0)))

		if "win_probability"  in t_data: table.win_probability  = float(t_data["win_probability"])
		if "bet"              in t_data: table.bet              = int(t_data["bet"])
		if "play_time"        in t_data: table.play_time        = float(t_data["play_time"])
		if "vip_chance_bonus" in t_data: table.vip_chance_bonus = float(t_data["vip_chance_bonus"])
		if "prestige_bonus"   in t_data: table.prestige_bonus   = int(t_data["prestige_bonus"])
		if "has_felt"         in t_data: table.has_felt         = bool(t_data["has_felt"])
		if "has_led"          in t_data: table.has_led          = bool(t_data["has_led"])
		if "has_chip_rack"    in t_data: table.has_chip_rack    = bool(t_data["has_chip_rack"])
		if "has_vip_seats"    in t_data: table.has_vip_seats    = bool(t_data["has_vip_seats"])
		if "has_spinner"      in t_data: table.has_spinner      = bool(t_data["has_spinner"])
		if "has_drinks"       in t_data: table.has_drinks       = bool(t_data["has_drinks"])
		if table.has_method("update_prestige"):
			table.update_prestige()

		spawned.append(table)

	# Dodatkowa klatka – pozwala _ready() stołów wypełnić tablicę seats
	await _get_tree().process_frame

	# ── Usuń TableSloty w miejscach kupionych stołów ──────────────────────────
	# Normalnie slot jest usuwany przy zakupie (slot.queue_free()). Po loadzie
	# slot jest wciąż w scenie i zasłania/nakłada się na przywrócony stolik.
	var slots = _get_tree().get_nodes_in_group("table_slots")
	for table in spawned:
		if table == null:
			continue
		for slot in slots:
			if is_instance_valid(slot) \
					and slot.global_position.distance_to(table.global_position) < 80.0:
				slot.queue_free()
				break

	return spawned


func _restore_bar(bar_data: Dictionary) -> void:
	var bars = _get_tree().get_nodes_in_group("bars")
	if bars.size() == 0:
		return

	var bar       = bars[0]
	var purchased := bool(bar_data.get("purchased", false))
	bar.visible   = purchased

	if not purchased:
		return

	# Ukryj PurchaseSpotOfBar – szukaj przez węzeł CasinoFloor (nie current_scene!)
	var casino_floor = _get_tree().get_first_node_in_group("casino_floor")
	var spot: Node = null

	if casino_floor:
		spot = casino_floor.get_node_or_null("PurchaseSpotOfBar")

	# Fallback: przeszukaj całe drzewo po nazwie
	if spot == null:
		var all = _get_tree().get_nodes_in_group("bar_purchase_spots")
		if all.size() > 0:
			spot = all[0]

	if spot:
		spot.visible = false
		if spot.has_method("set"):
			spot.set("input_pickable", false)

	if "passive_income"     in bar_data: bar.set("passive_income",     int(bar_data["passive_income"]))
	if "prestige"           in bar_data: bar.set("prestige",           int(bar_data["prestige"]))
	if "vip_percentage"     in bar_data: bar.set("vip_percentage",     float(bar_data["vip_percentage"]))
	if "cashier_upgraded"   in bar_data: bar.set("cashier_upgraded",   bool(bar_data["cashier_upgraded"]))
	if "drinks_upgraded"    in bar_data: bar.set("drinks_upgraded",    bool(bar_data["drinks_upgraded"]))
	if "live_band_upgraded" in bar_data: bar.set("live_band_upgraded", bool(bar_data["live_band_upgraded"]))

	if bar.get("cashier_upgraded") and bar.has_method("start_passive_timer"):
		bar.start_passive_timer()


func _restore_npcs(npcs_data: Array, restored_tables: Array) -> void:
	# Usuń starych klientów
	for npc in _get_tree().get_nodes_in_group("customers"):
		npc.queue_free()
	await _get_tree().process_frame

	var customer_scenes := {
		"normal": "res://scenes/actors/customers/normal_customer.tscn",
		"poor":   "res://scenes/actors/customers/poor_customer.tscn",
		"rich":   "res://scenes/actors/customers/rich_customer.tscn",
		"vip":    "res://scenes/actors/customers/vip_customer.tscn",
	}

	var customers_node = _get_tree().current_scene.get_node_or_null("Customers")

	for n_data in npcs_data:
		var status:     String = str(n_data.get("status", "normal"))
		var on_sidewalk: bool  = bool(n_data.get("on_sidewalk", true))

		var packed: PackedScene = load(customer_scenes.get(status, customer_scenes["normal"]))
		if packed == null:
			continue

		var npc: Node2D = packed.instantiate()
		if customers_node:
			customers_node.add_child(npc)
		else:
			_get_tree().current_scene.add_child(npc)

		npc.global_position = Vector2(float(n_data.get("position_x", 100.0)),
		                              float(n_data.get("position_y", 100.0)))

		if "money"             in n_data: npc.set("money",             float(n_data["money"]))
		if "anger"             in n_data: npc.set("anger",             float(n_data["anger"]))
		if "walking_direction" in n_data: npc.set("walking_direction", int(n_data["walking_direction"]))
		if "has_visited_cashier" in n_data: npc.set("has_visited_cashier", bool(n_data["has_visited_cashier"]))
		npc.set("on_sidewalk", on_sidewalk)

		# ── Przywróć powiązanie NPC → stolik → siedzenie ─────────────────────
		var table_idx: int  = int(n_data.get("table_index",       -1))
		var seat_idx:  int  = int(n_data.get("seat_index",        -1))
		var is_seated: bool = bool(n_data.get("is_seated",        false))
		var in_queue:  bool = bool(n_data.get("is_in_cashier_queue", false))

		if is_seated and table_idx >= 0 and table_idx < restored_tables.size():
			var table = restored_tables[table_idx]
			if table != null and "seats" in table and seat_idx >= 0 and seat_idx < table.seats.size():
				var seat = table.seats[seat_idx]

				# Pozycja dokładnie na siedzeniu
				npc.global_position = seat.global_position

				# Zarejestruj w tablicach stołu
				if "current_players" in table:
					table.current_players.append(npc)
				if "occupied_seats" in table:
					table.occupied_seats[npc] = seat

				# Pełny stan siedzenia
				npc.set("target_table",        table)
				npc.set("target_seat",         seat)
				npc.set("is_seated",           true)
				npc.set("has_visited_cashier", true)
				npc.set("is_in_cashier_queue", false)
				npc.set("coming_from_queue",   false)

				# Wyłącz kolizję
				var col := npc.get_node_or_null("CollisionShape2D")
				if col:
					col.disabled = true

				# ── Twarz do stolika ─────────────────────────────────────────
				if npc.has_method("face_table"):
					npc.face_table()

				# ── Wznów pętlę gry (fire-and-forget coroutine) ──────────────
				if npc.has_method("try_play"):
					npc.try_play()

		elif in_queue and not on_sidewalk:
			# NPC był w kolejce do kasy – przywróć stan kolejki
			npc.set("is_in_cashier_queue",  true)
			npc.set("is_going_to_cashier",  true)

			# Twarz do kasy
			var cashiers = _get_tree().get_nodes_in_group("cashier")
			if cashiers.size() > 0 and npc.has_method("try_face_target"):
				var desk = cashiers[0].get_node_or_null("CashierDeskPoint")
				var target_pos = desk.global_position if desk else cashiers[0].global_position
				npc.try_face_target(target_pos)


func _get_table_scene_path(table_type: String) -> String:
	match table_type:
		"roulette":  return "res://scenes/tables/roulette_table.tscn"
		"blackjack": return "res://scenes/tables/blackjack_table.tscn"
	return ""
