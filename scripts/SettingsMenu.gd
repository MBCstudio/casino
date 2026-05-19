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

# ── Stan wewnętrzny ──────────────────────────────────────────────────────────
var _is_open:   bool = false
var _tween:     Tween
var _toast_tween: Tween

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
	_panel.offset_top    = 200.0

	_overlay.visible = false
	_overlay.modulate.a = 0.0

	# Połącz sygnały przycisków
	_close_btn.pressed.connect(close_menu)
	_pause_btn.pressed.connect(_on_pause_pressed)
	_btn_x1.pressed.connect(func(): _set_speed(1.0))
	_btn_x2.pressed.connect(func(): _set_speed(2.0))
	_btn_x4.pressed.connect(func(): _set_speed(4.0))
	_music_prev_btn.pressed.connect(func(): _change_music_vibe(-1))
	_music_next_btn.pressed.connect(func(): _change_music_vibe(1))
	_music_slider.value_changed.connect(_on_music_slider_changed)
	_overlay.gui_input.connect(_on_overlay_input)

	_save_btn.pressed.connect(_on_save_pressed)
	_load_btn.pressed.connect(_on_load_pressed)

	_toast_label.visible = false
	_update_load_button()

	_music_slider.value = GameManager.get_music_volume()
	_update_music_label(_music_slider.value)
	_update_music_vibe_label()
	_update_pause_button()
	_highlight_active_speed()

# ── Obsługa klawiatury (Escape zamyka menu) ──────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _is_open:
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

func close_menu() -> void:
	if not _is_open:
		return
	_is_open = false
	GameManager.play_ui_open_sound()
	_animate(false)
	# Ukryj panel na koniec animacji (w _animate callback)


# ── Animacja Tween ────────────────────────────────────────────────────────────
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
