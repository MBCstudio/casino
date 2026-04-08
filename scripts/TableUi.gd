extends CanvasLayer

var current_table = null

#@onready var stats_label = $Panel/VBoxContainer/TabContainer/Stats/StatsLabel
@onready var slider = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/SliderPanel/HSlider
@onready var win_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/SliderPanel/WinLabel

func open(table):
	if table == null:
		print("ERROR: table is null")
		return
		
	visible = true
	current_table = table
	
	#update_stats()
	update_controls()

func close():
	visible = false
	get_tree().paused = false

# ====== STATS ======
#func update_stats():
	#stats_label.text = "Typ: %s\nBet: %d\nMax Players: %d\nPrestige: %d" % [
		#current_table.table_type,
		#current_table.bet,
		#current_table.max_players,
		#current_table.get_prestige()
	#]

# ====== CONTROL ======
func update_controls():
	slider.min_value = current_table.base_win_probability - 0.05
	slider.max_value = current_table.base_win_probability + 0.05
	slider.value = current_table.win_probability
	
	win_label.text = "Win Chance: %.2f" % current_table.win_probability

func _on_HSlider_value_changed(value):
	current_table.win_probability = value
	win_label.text = "Win Chance: %.2f" % value
	
	current_table.update_prestige()

# ====== CLOSE ======
func _on_Close_pressed():
	close()
	
func _on_upgrade_table_pressed():
	if GameManager.money >= 100:
		GameManager.remove_money(100)
		current_table.bet += 5
		#update_stats()
		print("Upgrade Table")

func _on_upgrade_dealer_pressed():
	if GameManager.money >= 150:
		GameManager.remove_money(150)
		current_table.win_probability += 0.02
		update_controls()
		print("Upgrade Dealer")
		
func _ready():
	visible = false
	add_to_group("table_ui")
	print("SLIDER:", slider)
	print("LABEL:", win_label)
	
	slider.value_changed.connect(_on_HSlider_value_changed)
	
