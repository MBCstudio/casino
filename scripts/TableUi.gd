extends CanvasLayer

var current_table = null
var _updating_slider = false

#@onready var stats_label = $Panel/VBoxContainer/TabContainer/Stats/StatsLabel
@onready var slider = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/HSlider
@onready var win_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/LabelsRow/WinLabel
@onready var prestige_delta_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/LabelsRow/PrestigeDeltaLabel
@onready var min_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/BottomLabels/MinLabel
@onready var max_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/BottomLabels/MaxLabel
@onready var mid_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/BottomLabels/MidLabel

func open(table):
	if table == null:
		print("ERROR: table is null")
		return
		
	visible = true
	current_table = table
	
	update_controls()
	update_header()

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
	_updating_slider = true
	
	slider.step = 0.01
	var center_prob = 0.50 # Force middle point to 50%
	var spread = 0.05 # allowing a +/- 5% change
	slider.min_value = center_prob - spread
	slider.max_value = center_prob + spread
	
	# If the table's probability is out of our new strict 45-55% bounds, default it exactly to 50%
	if current_table.win_probability < slider.min_value or current_table.win_probability > slider.max_value:
		current_table.win_probability = center_prob
		
	slider.value = current_table.win_probability
	
	min_label.text = "%.0f%%" % ((center_prob - spread) * 100)
	max_label.text = "%.0f%%" % ((center_prob + spread) * 100)
	mid_label.text = "%.0f%%" % (center_prob * 100)
	
	win_label.text = "Win Chance: %.2f%%" % (current_table.win_probability * 100)
	
	# Initial prestige text calc
	var change_percent = (current_table.win_probability - center_prob) * 100.0
	var prestige_change = int(-change_percent * 5)
	var sign_str = "+" if prestige_change > 0 else ""
	var color_tag = "[color=#d4af37]" if prestige_change >= 0 else "[color=#cc4444]"
	prestige_delta_label.text = "[right]" + color_tag + sign_str + str(prestige_change) + " ⭐[/color][/right]"
	_updating_slider = false

func _on_HSlider_value_changed(value):
	if _updating_slider or current_table == null:
		return
		
	current_table.win_probability = value
	win_label.text = "Win Chance: %.2f%%" % (value * 100)
	
	var center_prob = 0.50
	var change_percent = (value - center_prob) * 100.0
	var prestige_change = int(-change_percent * 5) # Decrease prestige if win probability is higher (left = more, right = less)
	var sign_str = "+" if prestige_change > 0 else ""
	var color_tag = "[color=#d4af37]" if prestige_change >= 0 else "[color=#cc4444]" # Gold for positive, red for negative
	prestige_delta_label.text = "[right]" + color_tag + sign_str + str(prestige_change) + " ⭐[/color][/right]"
	
	if current_table.has_method("update_prestige"):
		current_table.update_prestige()
		update_header()

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
	pass

func _on_buy_speed():
	if current_table and GameManager.money >= 5000:
		GameManager.remove_money(5000)
		current_table.add_prestige_bonus(5)
		%BuySpeedBtn.disabled = true
		%BuySpeedBtn.text = "Bought"
		update_header()

func _on_buy_charisma():
	if current_table and GameManager.money >= 8000:
		GameManager.remove_money(8000)
		current_table.add_prestige_bonus(8)
		%BuyCharismaBtn.disabled = true
		%BuyCharismaBtn.text = "Bought"
		update_header()

func _on_buy_master():
	if current_table and GameManager.money >= 12000:
		GameManager.remove_money(12000)
		current_table.add_prestige_bonus(15)
		%BuyMasterBtn.disabled = true
		%BuyMasterBtn.text = "Bought"
		update_header()

func update_header():
	if current_table:
		var header_prestige_label = $CenterContainer/Panel/VBoxContainer/Header/PrestigePanel/PrestigeMargin/PrestigeLabel
		if header_prestige_label:
			header_prestige_label.text = "⭐ " + str(current_table.get_prestige())

func _ready():
	visible = false
	add_to_group("table_ui")
	
	slider.value_changed.connect(_on_HSlider_value_changed)
	if has_node("CenterContainer/Panel/VBoxContainer/Header/CloseButton"):
		$CenterContainer/Panel/VBoxContainer/Header/CloseButton.pressed.connect(_on_Close_pressed)
		
	if has_node("%BuySpeedBtn"):
		%BuySpeedBtn.pressed.connect(_on_buy_speed)
	if has_node("%BuyCharismaBtn"):
		%BuyCharismaBtn.pressed.connect(_on_buy_charisma)
	if has_node("%BuyMasterBtn"):
		%BuyMasterBtn.pressed.connect(_on_buy_master)
	
