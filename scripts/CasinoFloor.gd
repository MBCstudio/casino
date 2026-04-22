extends Node2D

# ── scene paths ──────────────────────────────────────────────────────────────
const TABLE_SHOP_UI_SCRIPT := preload("res://scripts/TableShopUI.gd")

# ── internal ─────────────────────────────────────────────────────────────────
var _shop_ui: CanvasLayer = null


# ============================================================
#  LIFECYCLE
# ============================================================

func _ready() -> void:
	_setup_shop_ui()
	_connect_slots()


# ============================================================
#  SETUP
# ============================================================

func _setup_shop_ui() -> void:
	_shop_ui = CanvasLayer.new()
	_shop_ui.set_script(TABLE_SHOP_UI_SCRIPT)
	add_child(_shop_ui)
	_shop_ui.table_selected.connect(_on_table_selected)


## Podłącza sygnał slot_clicked do każdego TableSlot na scenie.
## Działa dla slotów już obecnych w chwili _ready, jak i tych dodanych przez
## EditorScene (dzieci CasinoFloor lub cała scena).
func _connect_slots() -> void:
	# Sloty mogą być dowolnie zagnieżdżone – szukamy po grupie.
	# Każdy TableSlot.gd dodaje się do grupy "table_slots" samodzielnie
	# (patrz niżej) albo łączymy tu przez get_children rekursywnie.
	for slot in get_tree().get_nodes_in_group("table_slots"):
		_connect_single_slot(slot)

	# Fallback: jeśli sloty nie są jeszcze w grupie (nie miały _ready),
	# podłączymy przez sygnał drzewa.
	get_tree().node_added.connect(_on_node_added)


func _connect_single_slot(slot: Node) -> void:
	if slot.has_signal("slot_clicked") and not slot.slot_clicked.is_connected(_on_slot_clicked):
		slot.slot_clicked.connect(_on_slot_clicked)


# ============================================================
#  SIGNAL HANDLERS
# ============================================================

## Wywoływane gdy nowy węzeł wejdzie do drzewa sceny.
## Pozwala podłączyć dynamicznie instancjonowane sloty.
func _on_node_added(node: Node) -> void:
	if node.is_in_group("table_slots"):
		_connect_single_slot(node)


## Gracz kliknął slot → otwieramy menu sklepu.
func _on_slot_clicked(slot: Area2D) -> void:
	_shop_ui.open(slot)


## Gracz wybrał typ stołu z menu.
func _on_table_selected(table_type: String) -> void:
	var slot: Area2D = _shop_ui.get_pending_slot()
	if slot == null:
		push_warning("CasinoFloor: table_selected ale pending_slot == null")
		return

	var price: int = _shop_ui.get_table_price(table_type)

	# Sprawdzenie środków
	if GameManager.money < price:
		print("CasinoFloor: za mało pieniędzy (masz %d, potrzebujesz %d)" \
				% [GameManager.money, price])
		return

	# Pobierz środki
	GameManager.remove_money(price)

	# Zapamiętaj pozycję przed usunięciem slotu
	var spawn_pos: Vector2 = slot.global_position

	# Usuń slot
	slot.queue_free()

	# Stwórz stół
	_spawn_table(table_type, spawn_pos)


# ============================================================
#  TABLE SPAWNING
# ============================================================

func _spawn_table(table_type: String, pos: Vector2) -> void:
	var scene_path: String = _shop_ui.get_table_scene(table_type)
	if scene_path.is_empty():
		push_error("CasinoFloor: brak ścieżki sceny dla '%s'" % table_type)
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("CasinoFloor: nie można wczytać sceny '%s'" % scene_path)
		return

	var table: Node2D = packed.instantiate()
	add_child(table)
	table.global_position = pos

	print("CasinoFloor: postawiono '%s' na pozycji %s" % [table_type, pos])
