## TableShopUI.gd
## Attach to a CanvasLayer node (tworzony dynamicznie przez CasinoFloor).
## Emituje sygnał `table_selected(table_type)` gdy gracz wybierze stół.
extends CanvasLayer

signal table_selected(table_type: String)

# ── definicje stołów ─────────────────────────────────────────────────────────
const TABLE_DEFS: Array[Dictionary] = [
	{ "type": "roulette",  "label": "Ruletka",   "price": 1000,
	  "scene": "res://scenes/tables/roulette_table.tscn",
	  "color": Color(0.13, 0.55, 0.13) },
	{ "type": "blackjack", "label": "Blackjack",  "price": 1500,
	  "scene": "res://scenes/tables/blackjack_table.tscn",
	  "color": Color(0.10, 0.35, 0.65) },
]

# ── internal ─────────────────────────────────────────────────────────────────
var _pending_slot: Area2D = null

# ── UI refs ───────────────────────────────────────────────────────────────────
var _root_control:  Control
var _money_label:   Label
var _buttons_box:   VBoxContainer


func _ready() -> void:
	layer = 10
	# !! KLUCZOWE: CanvasLayer i cały UI musi działać gdy gra jest spauzowana
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()


# ============================================================
#  PUBLIC API
# ============================================================

func open(slot: Area2D) -> void:
	_pending_slot = slot
	_refresh_money()
	_refresh_buttons()
	show()
	get_tree().paused = true


func close() -> void:
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
	_money_label.text = "Twoje pieniądze: $%.0f" % GameManager.money

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
#  UI BUILDER
# ============================================================

func _build_ui() -> void:
	# --- pełnoekranowy overlay (przyciemnienie) ---
	_root_control = Control.new()
	_root_control.name = "ShopUIRoot"
	_root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	# proces zawsze aktywny – inaczej kliknięcia nie działają przy pauzie
	_root_control.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_root_control)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_root_control.add_child(overlay)

	# --- panel centralny ---
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.custom_minimum_size = Vector2(360, 0)

	# wyśrodkowanie: anchor = center, offset przesuwa do góry od środka
	panel.set_anchors_preset(Control.PRESET_CENTER)
	# anchor_left/right/top/bottom = 0.5 → w środku ekranu
	# grow_horizontal/vertical = GROW_DIRECTION_BOTH → rozszerza się od środka
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH

	_root_control.add_child(panel)

	# --- margines wewnętrzny ---
	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# --- tytuł ---
	var title = Label.new()
	title.text = "Kup stół"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	# --- pieniądze ---
	_money_label = Label.new()
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_money_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	vbox.add_child(_money_label)

	vbox.add_child(HSeparator.new())

	# --- przyciski stołów ---
	_buttons_box = VBoxContainer.new()
	_buttons_box.add_theme_constant_override("separation", 10)
	vbox.add_child(_buttons_box)

	for def in TABLE_DEFS:
		var btn = Button.new()
		btn.name = "Btn_" + def["type"]
		btn.text = "%s  –  $%d" % [def["label"], def["price"]]
		btn.custom_minimum_size = Vector2(0, 52)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS  # działa przy pauzie
		btn.set_meta("table_type", def["type"])

		var sb = StyleBoxFlat.new()
		sb.bg_color = def["color"]
		for corner in ["corner_radius_top_left", "corner_radius_top_right",
					   "corner_radius_bottom_left", "corner_radius_bottom_right"]:
			sb.set(corner, 8)
		btn.add_theme_stylebox_override("normal", sb)

		var hover_sb = sb.duplicate()
		hover_sb.bg_color = def["color"].lightened(0.15)
		btn.add_theme_stylebox_override("hover", hover_sb)

		var type_copy = def["type"]
		btn.pressed.connect(func(): _on_table_btn_pressed(type_copy))
		_buttons_box.add_child(btn)

	vbox.add_child(HSeparator.new())

	# --- anuluj ---
	var cancel = Button.new()
	cancel.name = "CancelBtn"
	cancel.text = "Anuluj"
	cancel.custom_minimum_size = Vector2(0, 44)
	cancel.process_mode = Node.PROCESS_MODE_ALWAYS
	cancel.pressed.connect(_on_cancel_pressed)
	vbox.add_child(cancel)
