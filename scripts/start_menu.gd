extends Control

@onready var main_menu: VBoxContainer = $CenterContainer/VBoxContainer
@onready var difficulty_menu: PanelContainer = $CenterContainer/DifficultyMenu
@onready var nickname_menu: PanelContainer = $CenterContainer/NicknameMenu
@onready var file_dialog: FileDialog = $LoadFileDialog

var leaderboard_panel: PanelContainer = null
var leaderboard_tabs: TabContainer = null
var leaderboard_button: Button = null

const DIFFICULTY_STARTING_MONEY: Dictionary = {
	"easy": 25000.0,
	"medium": 15000.0,
	"hard": 2000.0,
}

func _ready():
	# Pause the game underneath
	get_tree().paused = true
	# Ensure the menu keeps processing even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	main_menu.show()
	difficulty_menu.hide()
	nickname_menu.hide()
	_setup_leaderboard_button()
	_setup_leaderboard_panel()
	_refresh_leaderboard()

	# Skonfiguruj FileDialog
	file_dialog.file_mode   = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access      = FileDialog.ACCESS_FILESYSTEM
	file_dialog.title       = "Load Save File"
	file_dialog.filters     = PackedStringArray(["*.json ; Save Files"])
	file_dialog.ok_button_text = "Load"

	# Ustaw katalog startowy na res://last_saves (globalizuj ścieżkę do systemu plików)
	var saves_dir: String = ProjectSettings.globalize_path("res://last_saves")
	if DirAccess.dir_exists_absolute(saves_dir):
		file_dialog.current_dir = saves_dir
	else:
		file_dialog.current_dir = ProjectSettings.globalize_path("res://")

	file_dialog.file_selected.connect(_on_save_file_selected)

	# Wyszarz przycisk Load jeśli brak folderu z zapisami
	var load_btn: Button = $CenterContainer/VBoxContainer/LoadButton
	if load_btn:
		var has_saves: bool = DirAccess.dir_exists_absolute(saves_dir)
		load_btn.modulate.a = 1.0 if has_saves else 0.4


func _on_start_button_pressed():
	# Show nickname input before difficulty selection
	main_menu.hide()
	if leaderboard_panel:
		leaderboard_panel.hide()
	nickname_menu.show()
	var nick_field: LineEdit = $CenterContainer/NicknameMenu/MarginContainer/VBoxContainer/NicknameLineEdit
	nick_field.text = ""
	nick_field.grab_focus()


func _on_nickname_confirmed():
	var nick_field: LineEdit = $CenterContainer/NicknameMenu/MarginContainer/VBoxContainer/NicknameLineEdit
	GameManager.player_nickname = nick_field.text.strip_edges()
	nickname_menu.hide()
	difficulty_menu.show()


func _on_load_button_pressed():
	# Otwórz menedżer plików w folderze last_saves
	file_dialog.popup_centered_ratio(0.65)

func _on_leaderboard_button_pressed() -> void:
	if leaderboard_panel == null:
		return

	_refresh_leaderboard()
	leaderboard_panel.visible = not leaderboard_panel.visible

func _on_leaderboard_close_pressed() -> void:
	if leaderboard_panel:
		leaderboard_panel.hide()


func _on_save_file_selected(path: String) -> void:
	# Wczytaj wskazany plik jako aktywny save, a potem uruchom grę
	var ok: bool = await SaveManager.load_from_path(path)
	if ok:
		# Uruchom grę bez wyboru trudności (pieniądze już załadowane z pliku)
		_launch_game()
	else:
		# Pokaż komunikat o błędzie (prosty fallback)
		var lbl: Label = Label.new()
		lbl.text = "❌  Failed to load save file!"
		lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		$CenterContainer/VBoxContainer.add_child(lbl)
		await get_tree().create_timer(2.5).timeout
		lbl.queue_free()


func _start_game_with_difficulty(difficulty: String):
	# Set the money in GameManager and update UI
	GameManager.money = float(DIFFICULTY_STARTING_MONEY[difficulty])
	GameManager.current_difficulty = difficulty
	GameManager.prestige = 10
	GameManager.event_prestige_modifier = 0
	GameManager.play_time = 0.0
	GameManager.customers = 0
	GameManager.tables_bought = 0
	GameManager.has_won = false
	GameManager.has_lost = false
	GameManager.time_since_last_event = 0.0
	GameManager.next_event_time = randf_range(120.0, 180.0)
	GameManager.reset_run_stats()
	GameManager.emit_signal("stats_changed")
	_launch_game()


func _launch_game():
	# Unpause the game!
	get_tree().paused = false

	# Clean up the start menu from the scene
	var canvas_parent: Node = get_parent()
	if canvas_parent is CanvasLayer:
		canvas_parent.queue_free()
	else:
		hide()
		queue_free()


func _on_easy_button_pressed():
	_start_game_with_difficulty("easy")

func _on_medium_button_pressed():
<<<<<<< Updated upstream
	_start_game_with_difficulty(12000.0)

func _on_hard_button_pressed():
	_start_game_with_difficulty(5000.0)
=======
	_start_game_with_difficulty("medium")

func _on_hard_button_pressed():
	_start_game_with_difficulty("hard")

func _setup_leaderboard_button() -> void:
	if leaderboard_button:
		return

	leaderboard_button = Button.new()
	leaderboard_button.name = "LeaderboardButton"
	leaderboard_button.custom_minimum_size = Vector2(400.0, 64.0)
	leaderboard_button.text = "LEADERBOARD"
	leaderboard_button.add_theme_font_size_override("font_size", 28)
	leaderboard_button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72, 1.0))
	leaderboard_button.add_theme_color_override("font_hover_color", Color.WHITE)
	leaderboard_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.34, 0.2, 0.08, 1.0), Color(0.98, 0.83, 0.24, 0.68)))
	leaderboard_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.48, 0.28, 0.1, 1.0), Color(1.0, 0.9, 0.34, 0.92)))
	leaderboard_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.2, 0.12, 0.05, 1.0), Color(0.86, 0.62, 0.18, 0.7)))
	leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	main_menu.add_child(leaderboard_button)

func _setup_leaderboard_panel() -> void:
	leaderboard_panel = PanelContainer.new()
	leaderboard_panel.name = "LeaderboardPanel"
	leaderboard_panel.visible = false
	leaderboard_panel.custom_minimum_size = Vector2(520.0, 440.0)
	leaderboard_panel.set_anchors_preset(Control.PRESET_CENTER)
	leaderboard_panel.offset_left = -260.0
	leaderboard_panel.offset_top = -220.0
	leaderboard_panel.offset_right = 260.0
	leaderboard_panel.offset_bottom = 220.0
	leaderboard_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	leaderboard_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(leaderboard_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	leaderboard_panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	box.add_child(header_row)

	var title: Label = Label.new()
	title.text = "LEADERBOARD"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24, 1.0))
	header_row.add_child(title)

	var close_button: Button = Button.new()
	close_button.custom_minimum_size = Vector2(38.0, 34.0)
	close_button.text = "X"
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
	close_button.add_theme_color_override("font_hover_color", Color(1.0, 0.35, 0.35, 1.0))
	close_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.0, 0.0, 0.0, 0.0), Color(1.0, 1.0, 1.0, 0.14)))
	close_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.55, 0.08, 0.08, 0.3), Color(1.0, 0.36, 0.36, 0.7)))
	close_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.26, 0.02, 0.02, 0.55), Color(1.0, 0.36, 0.36, 0.55)))
	close_button.pressed.connect(_on_leaderboard_close_pressed)
	header_row.add_child(close_button)

	var subtitle: Label = Label.new()
	subtitle.text = "Fastest wins by difficulty"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.82, 0.82, 0.88, 1.0))
	box.add_child(subtitle)

	leaderboard_tabs = TabContainer.new()
	leaderboard_tabs.custom_minimum_size = Vector2(0.0, 290.0)
	leaderboard_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaderboard_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaderboard_tabs.add_theme_font_size_override("font_size", 15)
	leaderboard_tabs.add_theme_color_override("font_selected_color", Color.WHITE)
	leaderboard_tabs.add_theme_color_override("font_unselected_color", Color(1.0, 1.0, 1.0, 0.68))
	box.add_child(leaderboard_tabs)

	for difficulty in LeaderboardManager.DIFFICULTIES:
		var tab: VBoxContainer = VBoxContainer.new()
		tab.name = difficulty.capitalize()
		tab.add_theme_constant_override("separation", 8)
		leaderboard_tabs.add_child(tab)

func _refresh_leaderboard() -> void:
	if leaderboard_tabs == null:
		return

	for difficulty in LeaderboardManager.DIFFICULTIES:
		var tab: VBoxContainer = leaderboard_tabs.get_node_or_null(difficulty.capitalize()) as VBoxContainer
		if tab == null:
			continue

		for child in tab.get_children():
			child.queue_free()

		var target_label: Label = Label.new()
		target_label.text = "Beat this for #1: " + LeaderboardManager.get_best_time_text(difficulty)
		target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		target_label.add_theme_font_size_override("font_size", 15)
		target_label.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24, 1.0))
		tab.add_child(target_label)

		_add_leaderboard_row(tab, "Rank", "Player", "Time", Color(0.62, 0.62, 0.72, 1.0), 13)

		var entries: Array = LeaderboardManager.get_entries(difficulty, 8)
		if entries.is_empty():
			var empty_label: Label = Label.new()
			empty_label.text = "No wins yet"
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78, 1.0))
			tab.add_child(empty_label)
			continue

		for i in range(entries.size()):
			var entry: Dictionary = entries[i]
			var rank: String = "#%d" % (i + 1)
			var name: String = str(entry.get("name", "Player")).left(16)
			var time_text: String = LeaderboardManager.format_time(float(entry.get("time", 0.0)))
			_add_leaderboard_row(tab, rank, name, time_text, Color(0.92, 0.92, 0.96, 1.0), 15)

func _add_leaderboard_row(parent: VBoxContainer, rank: String, player_name: String, time_text: String, color: Color, font_size: int) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var rank_label: Label = _make_leaderboard_cell(rank, color, font_size, HORIZONTAL_ALIGNMENT_LEFT)
	rank_label.custom_minimum_size = Vector2(54.0, 0.0)
	row.add_child(rank_label)

	var name_label: Label = _make_leaderboard_cell(player_name, color, font_size, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var time_label: Label = _make_leaderboard_cell(time_text, color, font_size, HORIZONTAL_ALIGNMENT_RIGHT)
	time_label.custom_minimum_size = Vector2(72.0, 0.0)
	row.add_child(time_label)

func _make_leaderboard_cell(text: String, color: Color, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 14.0
	style.content_margin_top = 8.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 8.0
	return style

func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.05, 0.92)
	style.border_color = Color(0.98, 0.83, 0.24, 0.58)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 18
	return style
>>>>>>> Stashed changes
