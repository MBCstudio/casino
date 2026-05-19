extends Control

@onready var main_menu       = $CenterContainer/VBoxContainer
@onready var difficulty_menu = $CenterContainer/DifficultyMenu
@onready var file_dialog     = $LoadFileDialog

func _ready():
	# Pause the game underneath
	get_tree().paused = true
	# Ensure the menu keeps processing even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	main_menu.show()
	difficulty_menu.hide()

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
	var load_btn = $CenterContainer/VBoxContainer/LoadButton
	if load_btn:
		var has_saves = DirAccess.dir_exists_absolute(saves_dir)
		load_btn.modulate.a = 1.0 if has_saves else 0.4


func _on_start_button_pressed():
	# Hide the main button and show difficulty options
	main_menu.hide()
	difficulty_menu.show()


func _on_load_button_pressed():
	# Otwórz menedżer plików w folderze last_saves
	file_dialog.popup_centered_ratio(0.65)


func _on_save_file_selected(path: String) -> void:
	# Wczytaj wskazany plik jako aktywny save, a potem uruchom grę
	var ok := await SaveManager.load_from_path(path)
	if ok:
		# Uruchom grę bez wyboru trudności (pieniądze już załadowane z pliku)
		_launch_game()
	else:
		# Pokaż komunikat o błędzie (prosty fallback)
		var lbl = Label.new()
		lbl.text = "❌  Failed to load save file!"
		lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		$CenterContainer/VBoxContainer.add_child(lbl)
		await get_tree().create_timer(2.5).timeout
		lbl.queue_free()


func _start_game_with_difficulty(starting_money: float):
	# Set the money in GameManager and update UI
	GameManager.money = starting_money
	GameManager.emit_signal("stats_changed")
	_launch_game()


func _launch_game():
	# Unpause the game!
	get_tree().paused = false

	# Clean up the start menu from the scene
	var canvas_parent = get_parent()
	if canvas_parent is CanvasLayer:
		canvas_parent.queue_free()
	else:
		hide()
		queue_free()


func _on_easy_button_pressed():
	_start_game_with_difficulty(25000.0)

func _on_medium_button_pressed():
	_start_game_with_difficulty(15000.0)

func _on_hard_button_pressed():
	_start_game_with_difficulty(2000.0)
