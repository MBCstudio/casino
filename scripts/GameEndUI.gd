extends CanvasLayer

@onready var play_time_label = %PlayTimeLabel
@onready var tables_label = %TablesLabel
@onready var customers_label = %CustomersLabel
@onready var money_label = %MoneyLabel
@onready var prestige_label = %PrestigeLabel
@onready var play_again_button = %PlayAgainButton
@onready var quit_button = %QuitButton

func _ready():
	visible = false
	add_to_group("game_end_ui")
	
	# Pozwól na działanie gdy gra jest paused
	process_mode = PROCESS_MODE_WHEN_PAUSED
	
	print("GameEndUI: Connecting to GameManager.game_won signal")
	GameManager.game_won.connect(_on_game_won)
	print("GameEndUI: Signal connected successfully")
	
	print("GameEndUI: play_again_button: ", play_again_button)
	print("GameEndUI: quit_button: ", quit_button)
	
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again)
		print("GameEndUI: PlayAgain button connected")
	else:
		print("GameEndUI: ERROR - play_again_button not found!")
		
	if quit_button:
		quit_button.pressed.connect(_on_quit)
		print("GameEndUI: Quit button connected")
	else:
		print("GameEndUI: ERROR - quit_button not found!")

func _on_game_won():
	print("GameEndUI: game_won signal received!")
	show_end_screen()

func show_end_screen():
	visible = true
	
	# Formatuj czas gry
	var minutes = int(GameManager.play_time) / 60
	var seconds = int(GameManager.play_time) % 60
	var time_text = "%02d:%02d" % [minutes, seconds]
	
	if play_time_label:
		play_time_label.text = time_text
	
	if tables_label:
		tables_label.text = str(GameManager.count_tables())
	
	if customers_label:
		customers_label.text = str(GameManager.customers)
	
	if money_label:
		money_label.text = "$" + str(int(GameManager.money))
	
	if prestige_label:
		prestige_label.text = str(GameManager.get_total_prestige())

func _on_play_again():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit():
	get_tree().paused = false
	get_tree().quit()
