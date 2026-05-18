## TableShopUI.gd
## Attach to a CanvasLayer node (tworzony dynamicznie przez CasinoFloor).
## Emituje sygnał `table_selected(table_type)` gdy gracz wybierze stół.
extends CanvasLayer

signal table_selected(table_type: String)

# ── definicje stołów ─────────────────────────────────────────────────────────
const TABLE_DEFS: Array[Dictionary] = [
	{ "type": "roulette",  "label": "Roulette",   "price": 1000,
	  "scene": "res://scenes/tables/roulette_table.tscn",
	  "color": Color(0.13, 0.55, 0.13) },
	{ "type": "blackjack", "label": "Blackjack",  "price": 1500,
	  "scene": "res://scenes/tables/blackjack_table.tscn",
	  "color": Color(0.10, 0.35, 0.65) },
]

# ── internal ─────────────────────────────────────────────────────────────────
var _pending_slot: Area2D = null

# ── UI refs ───────────────────────────────────────────────────────────────────
var _money_label:    Label
var _buttons_box:    VBoxContainer
var _close_button:   Button
var _cancel_btn:     Button


func _ready() -> void:
	# !! KLUCZOWE: CanvasLayer i cały UI musi działać gdy gra jest spauzowana
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_ui_refs()
	_build_table_buttons()
	hide()


# ============================================================
#  PUBLIC API
# ============================================================

func open(slot: Area2D) -> void:
	_pending_slot = slot
	GameManager.play_ui_open_sound()
	_refresh_money()
	_refresh_buttons()
	show()
	get_tree().paused = true


func close() -> void:
	GameManager.play_ui_open_sound()
	_pending_slot = null
	hide()
	get_tree().paused = false


func get_pending_slot() -> Area2D:
	return _pending_slot

func get_table_scene(table_type: String) -> String:
	for d in TABLE_DEFS:
		if d["type"] == table_type:
			return d["scene"]
	return ""

func get_table_price(table_type: String) -> int:
	for d in TABLE_DEFS:
		if d["type"] == table_type:
			return d["price"]
	return 0


# ============================================================
#  CALLBACKS
# ============================================================

func _on_table_btn_pressed(table_type: String) -> void:
	emit_signal("table_selected", table_type)
	close()

func _on_cancel_pressed() -> void:
	close()


# ============================================================
#  REFRESH
# ============================================================

func _refresh_money() -> void:
	_money_label.text = "Your money: $%.0f" % GameManager.money

func _refresh_buttons() -> void:
	for btn in _buttons_box.get_children():
		var def_type: String = btn.get_meta("table_type", "")
		if def_type.is_empty():
			continue
		var price = get_table_price(def_type)
		var can_buy = GameManager.money >= price
		btn.disabled = not can_buy
		btn.modulate.a = 1.0 if can_buy else 0.45


# ============================================================
#  UI INITIALIZATION
# ============================================================

func _init_ui_refs() -> void:
	"""Załaduj referencje do węzłów ze sceny"""
	_money_label = $CenterContainer/Panel/VBoxContainer/Margin/ContentVBox/MoneyLabel
	_buttons_box = $CenterContainer/Panel/VBoxContainer/Margin/ContentVBox/ButtonsVBox
	_close_button = $CenterContainer/Panel/VBoxContainer/Header/CloseButton
	_cancel_btn = $CenterContainer/Panel/VBoxContainer/Margin/ContentVBox/CancelBtn
	
	# podłącz przyciski zamknięcia
	_close_button.pressed.connect(_on_cancel_pressed)
	_cancel_btn.pressed.connect(_on_cancel_pressed)


func _build_table_buttons() -> void:
	"""Utwórz przyciski dla każdego typu stołu"""
	for def in TABLE_DEFS:
		var btn = Button.new()
		btn.name = "Btn_" + def["type"]
		btn.text = "%s  –  $%d" % [def["label"], def["price"]]
		btn.custom_minimum_size = Vector2(0, 52)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.set_meta("table_type", def["type"])

		# normalna stylizacja
		var sb = StyleBoxFlat.new()
		sb.bg_color = def["color"]
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.9882353, 0.8352941, 0.24705882, 1)
		for corner in ["corner_radius_top_left", "corner_radius_top_right",
					   "corner_radius_bottom_left", "corner_radius_bottom_right"]:
			sb.set(corner, 10)
		sb.shadow_color = Color(0, 0, 0, 0.3)
		sb.shadow_size = 5
		btn.add_theme_stylebox_override("normal", sb)

		# hover stylizacja
		var hover_sb = sb.duplicate()
		hover_sb.bg_color = def["color"].lightened(0.15)
		hover_sb.border_color = Color(1, 0.95, 0.4, 1)
		btn.add_theme_stylebox_override("hover", hover_sb)

		# disabled stylizacja
		var disabled_sb = sb.duplicate()
		disabled_sb.bg_color = def["color"].darkened(0.3)
		disabled_sb.border_color = Color(0.5, 0.5, 0.5, 1)
		btn.add_theme_stylebox_override("disabled", disabled_sb)

		# font stylizacja
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_font_size_override("font_size", 16)

		# podłącz sygnał
		var type_copy = def["type"]
		btn.pressed.connect(func(): _on_table_btn_pressed(type_copy))
		_buttons_box.add_child(btn)
