extends Control

## SettingsMenu – elegancki sidebar wysuwany z prawej strony
## Użycie: podłącz SettingsButton.pressed -> toggle_menu()
## Węzeł powinien być dzieckiem CanvasLayer (layer >= 10)

# ── Stałe animacji ──────────────────────────────────────────────────────────
const SLIDE_DURATION := 0.32
const EASE_IN  := Tween.EASE_IN_OUT
const TRANS    := Tween.TRANS_CUBIC

# ── Referencje do node'ów ────────────────────────────────────────────────────
@onready var _overlay:       ColorRect      = $Overlay
@onready var _panel:         PanelContainer = $SidebarPanel
@onready var _close_btn:     Button         = $SidebarPanel/MarginContainer/VBoxContainer/HeaderRow/CloseButton
@onready var _help_btn:      Button         = $SidebarPanel/MarginContainer/VBoxContainer/HeaderRow/HelpButton
@onready var _tutorial_btn:  Button         = $SidebarPanel/MarginContainer/VBoxContainer/TutorialButton
@onready var _pause_btn:     Button         = $SidebarPanel/MarginContainer/VBoxContainer/PauseButton
@onready var _speed_label:   Label          = $SidebarPanel/MarginContainer/VBoxContainer/SpeedSection/SpeedLabel
@onready var _btn_x1:        Button         = $SidebarPanel/MarginContainer/VBoxContainer/SpeedSection/SpeedRow/BtnX1
@onready var _btn_x2:        Button         = $SidebarPanel/MarginContainer/VBoxContainer/SpeedSection/SpeedRow/BtnX2
@onready var _btn_x4:        Button         = $SidebarPanel/MarginContainer/VBoxContainer/SpeedSection/SpeedRow/BtnX4
@onready var _save_btn:      Button         = $SidebarPanel/MarginContainer/VBoxContainer/SaveLoadSection/SaveButton
@onready var _load_btn:      Button         = $SidebarPanel/MarginContainer/VBoxContainer/SaveLoadSection/LoadButton
@onready var _toast_label:   Label          = $SidebarPanel/MarginContainer/VBoxContainer/SaveLoadSection/ToastLabel
@onready var _music_vibe_label: Label    = $SidebarPanel/MarginContainer/VBoxContainer/MusicSection/VibeRow/MusicVibeLabel
@onready var _music_prev_btn: Button     = $SidebarPanel/MarginContainer/VBoxContainer/MusicSection/VibeRow/MusicPrevButton
@onready var _music_next_btn: Button     = $SidebarPanel/MarginContainer/VBoxContainer/MusicSection/VibeRow/MusicNextButton
@onready var _music_label:   Label       = $SidebarPanel/MarginContainer/VBoxContainer/MusicSection/MusicLabel
@onready var _music_slider:  HSlider     = $SidebarPanel/MarginContainer/VBoxContainer/MusicSection/MusicSlider
@onready var _sfx_label:     Label       = $SidebarPanel/MarginContainer/VBoxContainer/SoundSection/SfxLabel
@onready var _sfx_slider:    HSlider     = $SidebarPanel/MarginContainer/VBoxContainer/SoundSection/SfxSlider

# ── Stan wewnętrzny ──────────────────────────────────────────────────────────
var _is_open:   bool = false
var _tween:     Tween
var _toast_tween: Tween
var _tutorial_layer: Control
var _tutorial_panel: PanelContainer
var _tutorial_close_btn: Button

# ── Rozmiar panelu (szerokość sidebar'a) ─────────────────────────────────────
const PANEL_WIDTH := 300.0

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	

	# Panel startuje poza ekranem po prawej stronie
	_panel.anchor_left   = 1.0
	_panel.anchor_right  = 1.0
	_panel.anchor_top    = 0.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left   = PANEL_WIDTH
	_panel.offset_right  = 0.0
	_panel.offset_top    = 580.0

	_overlay.visible = false
	_overlay.modulate.a = 0.0

	# Połącz sygnały przycisków
	_close_btn.pressed.connect(close_menu)
	_help_btn.pressed.connect(_open_tutorial)
	_tutorial_btn.pressed.connect(_open_tutorial)
	_pause_btn.pressed.connect(_on_pause_pressed)
	_btn_x1.pressed.connect(func(): _set_speed(1.0))
	_btn_x2.pressed.connect(func(): _set_speed(2.0))
	_btn_x4.pressed.connect(func(): _set_speed(4.0))
	_music_prev_btn.pressed.connect(func(): _change_music_vibe(-1))
	_music_next_btn.pressed.connect(func(): _change_music_vibe(1))
	_music_slider.value_changed.connect(_on_music_slider_changed)
	_sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	_overlay.gui_input.connect(_on_overlay_input)

	_save_btn.pressed.connect(_on_save_pressed)
	_load_btn.pressed.connect(_on_load_pressed)

	_toast_label.visible = false
	_build_tutorial_popup()
	_update_load_button()

	_music_slider.value = GameManager.get_music_volume()
	_update_music_label(_music_slider.value)
	_update_music_vibe_label()
	_sfx_slider.value = GameManager.get_sfx_volume()
	_update_sfx_label(_sfx_slider.value)
	_update_pause_button()
	_highlight_active_speed()

# ── Obsługa klawiatury (Escape zamyka menu) ──────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _tutorial_layer != null and _tutorial_layer.visible:
		_close_tutorial()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and _is_open:
		close_menu()
		get_viewport().set_input_as_handled()

# ── Publiczne API ─────────────────────────────────────────────────────────────
func toggle_menu() -> void:
	if _is_open:
		close_menu()
	else:
		open_menu()

func open_menu() -> void:
	if _is_open:
		return
	_is_open = true
	GameManager.play_ui_open_sound()
	_overlay.visible = true
	_panel.visible = true
	_animate(true)
	_update_pause_button()
	_highlight_active_speed()
	_update_load_button()
	_music_slider.value = GameManager.get_music_volume()
	_update_music_label(_music_slider.value)
	_update_music_vibe_label()
	_sfx_slider.value = GameManager.get_sfx_volume()
	_update_sfx_label(_sfx_slider.value)

func close_menu() -> void:
	if not _is_open:
		return
	_close_tutorial()
	_is_open = false
	GameManager.play_ui_open_sound()
	_animate(false)
	# Ukryj panel na koniec animacji (w _animate callback)


# ── Animacja Tween ────────────────────────────────────────────────────────────
func _build_tutorial_popup() -> void:
	_tutorial_layer = Control.new()
	_tutorial_layer.name = "TutorialPopup"
	_tutorial_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_tutorial_layer.visible = false
	_tutorial_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_layer.top_level = true
	_tutorial_layer.z_index = 100
	_tutorial_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_layer.offset_left = 0
	_tutorial_layer.offset_top = 0
	_tutorial_layer.offset_right = 0
	_tutorial_layer.offset_bottom = 0
	add_child(_tutorial_layer)

	var dim := ColorRect.new()
	dim.name = "TutorialDim"
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_layer.add_child(dim)

	var center := CenterContainer.new()
	center.name = "TutorialCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_layer.add_child(center)

	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.name = "TutorialPanel"
	_tutorial_panel.custom_minimum_size = Vector2(640, 520)
	_tutorial_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_panel.add_theme_stylebox_override("panel", _tutorial_panel_stylebox())
	center.add_child(_tutorial_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	_tutorial_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	content.add_child(header)

	var title := Label.new()
	title.text = "Casino Guide"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.2))
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)

	_tutorial_close_btn = Button.new()
	_tutorial_close_btn.text = "X"
	_tutorial_close_btn.custom_minimum_size = Vector2(38, 34)
	_tutorial_close_btn.add_theme_font_size_override("font_size", 18)
	_tutorial_close_btn.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	_tutorial_close_btn.add_theme_color_override("font_hover_color", Color(1, 0.35, 0.35))
	_tutorial_close_btn.add_theme_stylebox_override("normal", _flat_button_stylebox(Color(0, 0, 0, 0), Color(0.95, 0.78, 0.2, 0.25)))
	_tutorial_close_btn.add_theme_stylebox_override("hover", _flat_button_stylebox(Color(0.8, 0.2, 0.2, 0.25), Color(1, 0.35, 0.35, 0.55)))
	_tutorial_close_btn.add_theme_stylebox_override("pressed", _flat_button_stylebox(Color(0.8, 0.2, 0.2, 0.35), Color(1, 0.35, 0.35, 0.75)))
	header.add_child(_tutorial_close_btn)
	_tutorial_close_btn.pressed.connect(_close_tutorial)

	var separator := HSeparator.new()
	separator.add_theme_stylebox_override("separator", _separator_stylebox())
	content.add_child(separator)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(570, 390)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	var tutorial_content := VBoxContainer.new()
	tutorial_content.custom_minimum_size = Vector2(540, 0)
	tutorial_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_content.add_theme_constant_override("separation", 12)
	scroll.add_child(tutorial_content)

	_populate_tutorial_content(tutorial_content)


func _open_tutorial() -> void:
	if _tutorial_layer == null:
		_build_tutorial_popup()
	GameManager.play_ui_open_sound()
	_tutorial_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_layer.offset_left = 0
	_tutorial_layer.offset_top = 0
	_tutorial_layer.offset_right = 0
	_tutorial_layer.offset_bottom = 0
	_tutorial_layer.size = get_viewport_rect().size
	_tutorial_layer.show()
	_tutorial_layer.move_to_front()


func _close_tutorial() -> void:
	if _tutorial_layer == null or not _tutorial_layer.visible:
		return
	GameManager.play_ui_open_sound()
	_tutorial_layer.visible = false


func _tutorial_panel_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.09, 0.13, 0.98)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.95, 0.78, 0.2, 0.75)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.shadow_color = Color(0, 0, 0, 0.62)
	sb.shadow_size = 24
	return sb


func _flat_button_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = border
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 8
	sb.content_margin_top = 4
	sb.content_margin_right = 8
	sb.content_margin_bottom = 4
	return sb


func _separator_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.95, 0.78, 0.2, 0.22)
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	return sb


func _populate_tutorial_content(parent: VBoxContainer) -> void:
	_add_tutorial_text(parent, "[color=#f2c733][b]Goal[/b][/color]\nBuild a profitable casino and reach [b]$110000[/b]. Money, prestige, customers, upgrades and special events all pull on each other, so every choice changes the run.")

	_add_tutorial_header(parent, "Customers")
	_add_tutorial_card(parent, "Poor Customer", _atlas_texture("res://assets/sprites/customer_poor.png", Rect2(0, 0, 64, 128)), "Money: $1000\nBase bet: $50\n⭐ Prestige: Low\nRole: Enters most often when prestige is low. Small bets are safer, but they will not grow the casino quickly.")
	_add_tutorial_card(parent, "Normal Customer", _atlas_texture("res://assets/sprites/customer.png", Rect2(0, 0, 64, 128)), "Money: $7500\nBase bet: $150\n⭐ Prestige: Low to Medium\nRole: Your steady early-game visitor. Better prestige makes them more willing to enter, but very high prestige shifts attention toward richer guests.")
	_add_tutorial_card(parent, "Rich Customer", _atlas_texture("res://assets/sprites/customer_rich.png", Rect2(0, 0, 64, 128)), "Money: $25000\nBase bet: $500\n⭐ Prestige: Medium to High\nRole: Strong profit source. They need enough prestige to care about the casino and enough table space to sit down.")
	_add_tutorial_card(parent, "VIP Customer", _atlas_texture("res://assets/sprites/customer_vip.png", Rect2(0, 0, 64, 128)), "Money: $100000\nBase bet: $2500\n⭐ Prestige: High\nRole: High risk, high reward. VIPs start appearing reliably only after the casino earns serious prestige and VIP bonuses.")

	_add_tutorial_header(parent, "Objects And Upgrades")
	_add_tutorial_card(parent, "Roulette Table", _atlas_texture("res://assets/sprites/2D_TopDown_Tileset_Casino_1024x512.png", Rect2(911.86273, 195.77155, 112.70575, 61.092865)), "Cost: $1000\nBase round: about 10s\nRole: Customers sit, place bets and either pay the casino or win money from it. Lower customer win chance gives more house edge, but can hurt ⭐ prestige.")
	_add_tutorial_card(parent, "Blackjack Table", _atlas_texture("res://assets/sprites/2D_TopDown_Tileset_Casino_1024x512.png", Rect2(927.4036, 367.9104, 96.45599, 52.153503)), "Cost: $1500\nRole: Similar economy loop to roulette, with its own cheaper upgrade prices. Dealer upgrades can speed rounds, improve VIP attraction or raise bets.")
	_add_tutorial_card(parent, "Cashier", "res://assets/sprites/prop_cashier_desk_side_144x256.png", "Upgrade: $5000 per speed step\n⭐ Prestige: many upgrades.\nRole: Customers queue here before playing. Faster service gets guests to tables sooner and keeps the casino flowing.")
	_add_tutorial_card(parent, "Bar", "res://assets/sprites/bar_asset.png", "Cost: $10000\nPassive income upgrade: +$50/min\n⭐ Prestige many upgrades.\nRole: Angry customers can go here instead of leaving. After a drink, their anger drops and they return to play.")

	_add_tutorial_header(parent, "Core Systems")
	_add_tutorial_card(parent, "Money", "res://assets/sprites/welcome_graphics/coin_64.png", "You gain money when customers lose at tables and when bar passive income is collected. You lose money when customers win, when buying objects/upgrades, and when events have a cost.")
	_add_tutorial_card(parent, "⭐ Prestige", "res://assets/sprites/level-up (1).png", "⭐ Prestige comes from tables, cashier upgrades, bar upgrades and event outcomes. It controls which customer classes want to enter: poor visitors like low prestige, rich and VIP visitors need much more.")
	_add_tutorial_card(parent, "Special Events", "res://assets/sprites/casino-dealer (1).png", "Events happen every 2-3 minutes. They can add or remove money, change prestige, or lead into follow-up events. Your decisions are not cosmetic; they change the run.")


func _add_tutorial_header(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.2))
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)


func _add_tutorial_text(parent: VBoxContainer, text: String) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(540, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("default_color", Color(0.82, 0.82, 0.9))
	label.add_theme_font_size_override("normal_font_size", 15)
	label.add_theme_font_size_override("bold_font_size", 15)
	label.text = text
	parent.add_child(label)


func _add_tutorial_card(parent: VBoxContainer, title: String, texture_source: Variant, description: String) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _tutorial_card_stylebox())
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(96, 96)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if texture_source is Texture2D:
		icon.texture = texture_source
	elif texture_source is String and ResourceLoader.exists(texture_source):
		icon.texture = load(texture_source)
	row.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.2))
	title_label.add_theme_font_size_override("font_size", 16)
	text_box.add_child(title_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(390, 0)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.9))
	desc_label.add_theme_font_size_override("font_size", 14)
	text_box.add_child(desc_label)


func _tutorial_card_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.18, 0.88)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.95, 0.78, 0.2, 0.28)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	return sb


func _atlas_texture(texture_path: String, region: Rect2) -> Texture2D:
	if not ResourceLoader.exists(texture_path):
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = load(texture_path)
	atlas.region = region
	return atlas


func _animate(opening: bool) -> void:
	if _tween and _tween.is_running():
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)

	if opening:
		# Przesuń panel do widocznej pozycji (offset_left = -PANEL_WIDTH)
		_tween.tween_property(_panel, "offset_left", -PANEL_WIDTH, SLIDE_DURATION)\
			.set_ease(EASE_IN).set_trans(TRANS)
		_tween.tween_property(_overlay, "modulate:a", 0.45, SLIDE_DURATION)\
			.set_ease(EASE_IN).set_trans(TRANS)
	else:
		# Wysuń panel z powrotem za prawą krawędź
		_tween.tween_property(_panel, "offset_left", 0.0, SLIDE_DURATION)\
			.set_ease(EASE_IN).set_trans(TRANS)
		_tween.tween_property(_overlay, "modulate:a", 0.0, SLIDE_DURATION)\
			.set_ease(EASE_IN).set_trans(TRANS)
		# Po zakończeniu ukryj overlay i panel
		_tween.chain().tween_callback(func():
			_overlay.visible = false
			_panel.visible = false
		)

# ── Logika gry ────────────────────────────────────────────────────────────────
func _on_pause_pressed() -> void:
	get_tree().paused = not get_tree().paused
	_update_pause_button()

func _update_pause_button() -> void:
	if get_tree().paused:
		_pause_btn.text = "▶  Resume"
	else:
		_pause_btn.text = "⏸  Pause"

func _set_speed(value: float) -> void:
	Engine.time_scale = value
	_speed_label.text = "Current: %.1fx" % value
	_highlight_active_speed()

func _highlight_active_speed() -> void:
	var current := Engine.time_scale
	_set_speed_active(_btn_x1, is_equal_approx(current, 1.0))
	_set_speed_active(_btn_x2, is_equal_approx(current, 2.0))
	_set_speed_active(_btn_x4, is_equal_approx(current, 4.0))

func _on_music_slider_changed(value: float) -> void:
	GameManager.set_music_volume(value)
	_update_music_label(value)

func _update_music_label(value: float) -> void:
	if value <= 0.0:
		_music_label.text = "Music: Off"
	else:
		_music_label.text = "Music Volume: %d%%" % int(round(value))

func _on_sfx_slider_changed(value: float) -> void:
	GameManager.set_sfx_volume(value)
	_update_sfx_label(value)

func _update_sfx_label(value: float) -> void:
	if value <= 0.0:
		_sfx_label.text = "SFX: Off"
	else:
		_sfx_label.text = "SFX Volume: %d%%" % int(round(value))

func _change_music_vibe(direction: int) -> void:
	GameManager.change_music_vibe(direction)
	_update_music_vibe_label()

func _update_music_vibe_label() -> void:
	_music_vibe_label.text = "%d/%d" % [
		GameManager.get_music_vibe_index() + 1,
		GameManager.get_music_vibe_count()
	]

func _set_speed_active(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_color_override("font_color",            Color(0.05, 0.05, 0.05))
		btn.add_theme_color_override("font_hover_color",      Color(0.05, 0.05, 0.05))
		btn.add_theme_color_override("font_pressed_color",    Color(0.05, 0.05, 0.05))
		btn.add_theme_stylebox_override("normal",  _active_stylebox())
		btn.add_theme_stylebox_override("hover",   _active_stylebox())
		btn.add_theme_stylebox_override("pressed", _active_stylebox())
	else:
		btn.remove_theme_color_override("font_color")
		btn.remove_theme_color_override("font_hover_color")
		btn.remove_theme_color_override("font_pressed_color")
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("hover")
		btn.remove_theme_stylebox_override("pressed")

func _active_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color        = Color(0.95, 0.78, 0.20)   # złoto
	sb.corner_radius_top_left     = 8
	sb.corner_radius_top_right    = 8
	sb.corner_radius_bottom_left  = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left   = 10
	sb.content_margin_right  = 10
	sb.content_margin_top    = 6
	sb.content_margin_bottom = 6
	return sb

# ── Save / Load ──────────────────────────────────────────────────────────────
func _on_save_pressed() -> void:
	_save_btn.disabled = true
	var ok := SaveManager.save_game()
	_save_btn.disabled = false
	_update_load_button()
	if ok:
		_show_toast("✅  Game Saved!", Color(0.2, 0.75, 0.35))
	else:
		_show_toast("❌  Save Failed!", Color(0.85, 0.25, 0.25))


func _on_load_pressed() -> void:
	if not SaveManager.save_exists():
		_show_toast("⚠  No save file found.", Color(0.85, 0.65, 0.10))
		return

	_load_btn.disabled = true
	close_menu()

	# Krótka przerwa by animacja zamknięcia zdążyła się skończyć
	await get_tree().create_timer(SLIDE_DURATION + 0.05).timeout

	var ok := await SaveManager.load_game()
	_load_btn.disabled = false

	if ok:
		_show_toast("✅  Game Loaded!", Color(0.2, 0.75, 0.35))
	else:
		_show_toast("❌  Load Failed!", Color(0.85, 0.25, 0.25))


func _update_load_button() -> void:
	if _load_btn:
		_load_btn.disabled = not SaveManager.save_exists()
		_load_btn.modulate.a = 1.0 if SaveManager.save_exists() else 0.5


func _show_toast(message: String, color: Color) -> void:
	_toast_label.text = message
	_toast_label.add_theme_color_override("font_color", color)
	_toast_label.visible = true
	_toast_label.modulate.a = 1.0

	if _toast_tween and _toast_tween.is_running():
		_toast_tween.kill()

	_toast_tween = create_tween()
	# Utrzymaj przez 1.8s, potem zanikaj przez 0.6s
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.6)
	_toast_tween.tween_callback(func(): _toast_label.visible = false)

# ── Overlay – kliknięcie poza panelem zamknij menu ────────────────────────────
func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		close_menu()
