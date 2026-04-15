extends Control

@onready var main_menu = $CenterContainer/VBoxContainer
@onready var difficulty_menu = $CenterContainer/DifficultyMenu

func _ready():
	# Pause the game underneath
	get_tree().paused = true
	# Ensure the menu keeps processing even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	main_menu.show()
	difficulty_menu.hide()

func _on_start_button_pressed():
	# Hide the main button and show difficulty options
	main_menu.hide()
	difficulty_menu.show()

func _start_game_with_difficulty(starting_money: float):
	# Set the money in GameManager and update UI
	GameManager.money = starting_money
	GameManager.emit_signal("stats_changed")
	
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
	_start_game_with_difficulty(100000.0)

func _on_medium_button_pressed():
	_start_game_with_difficulty(20000.0)

func _on_hard_button_pressed():
	_start_game_with_difficulty(2000.0)
