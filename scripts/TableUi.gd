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
@onready var base_bet_label = %Value
@onready var play_time_label = %Value2
@onready var vip_bonus_label = %Value3

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
func _update_details_label():
	if current_table and base_bet_label and play_time_label and vip_bonus_label:
		base_bet_label.text = "$%d" % current_table.bet
		play_time_label.text = "%.1fs" % current_table.play_time
		vip_bonus_label.text = "+%.0f%%" % (current_table.vip_chance_bonus * 100)

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
	
	_update_details_label()
	
	win_label.text = "Win Chance: %.2f%%" % (current_table.win_probability * 100)
	
	# Initial prestige text calc
	var change_percent = (current_table.win_probability - center_prob)
	var prestige_change = int(-change_percent * 100 * 4)
	var sign_str = "+" if prestige_change > 0 else ""
	var color_tag = "[color=#d4af37]" if prestige_change >= 0 else "[color=#cc4444]"
	prestige_delta_label.text = "[right]" + color_tag + sign_str + str(prestige_change) + " ⭐[/color][/right]"
	_updating_slider = false
	
	_update_upgrade_buttons()

func _update_upgrade_buttons():
	if current_table == null:
		return
		
	_update_details_label()
		
	# Speed Train
	if has_node("%BuySpeedBtn"):
		var btn = get_node("%BuySpeedBtn")
		if current_table.play_time <= 8.0:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 5000
			btn.text = "$5,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))
			
	# Charisma
	if has_node("%BuyCharismaBtn"):
		var btn = get_node("%BuyCharismaBtn")
		if current_table.vip_chance_bonus > 0.04:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 8000
			btn.text = "$8,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	# Master
	if has_node("%BuyMasterBtn"):
		var btn = get_node("%BuyMasterBtn")
		if current_table.bet >= 50:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 12000
			btn.text = "$12,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	# Table Upgrades
	if has_node("%BuyFeltBtn"):
		var btn = get_node("%BuyFeltBtn")
		if current_table.has_felt:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 10000
			btn.text = "$10,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%BuyLEDBtn"):
		var btn = get_node("%BuyLEDBtn")
		if current_table.has_led:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 15000
			btn.text = "$15,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%BuyChipRackBtn"):
		var btn = get_node("%BuyChipRackBtn")
		if current_table.has_chip_rack:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 20000
			btn.text = "$20,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%BuyVIPBtn"):
		var btn = get_node("%BuyVIPBtn")
		if current_table.has_vip_seats:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 35000
			btn.text = "$35,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%TestBtn1"):
		var btn = get_node("%TestBtn1")
		if current_table.has_spinner:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 50000
			btn.text = "$50,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%TestBtn2"):
		var btn = get_node("%TestBtn2")
		if current_table.has_drinks:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 100000
			btn.text = "$100,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

func _on_HSlider_value_changed(value):
	if _updating_slider or current_table == null:
		return
		
	current_table.win_probability = value
	win_label.text = "Win Chance: %.2f%%" % (value * 100)
	
	var center_prob = 0.50
	var change_percent = (value - center_prob)
	var prestige_change = int(-change_percent * 100 * 4) # Decrease prestige if win probability is higher (left = more, right = less)
	var sign_str = "+" if prestige_change > 0 else ""
	var color_tag = "[color=#d4af37]" if prestige_change >= 0 else "[color=#cc4444]" # Gold for positive, red for negative
	prestige_delta_label.text = "[right]" + color_tag + sign_str + str(prestige_change) + " ⭐[/color][/right]"
	
	if current_table.has_method("update_prestige"):
		current_table.update_prestige()
		update_header()

# ====== CLOSE ======
func _on_stats_changed():
	if visible and current_table:
		_update_upgrade_buttons()

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
	if current_table and GameManager.money >= 5000 and current_table.play_time > 8.0:
		GameManager.remove_money(5000)
		current_table.play_time = 8.0
		_update_upgrade_buttons()

func _on_buy_charisma():
	if current_table and GameManager.money >= 8000 and current_table.vip_chance_bonus <= 0.04:
		GameManager.remove_money(8000)
		current_table.vip_chance_bonus += 0.05
		_update_upgrade_buttons()

func _on_buy_master():
	if current_table and GameManager.money >= 12000 and current_table.bet < 50:
		GameManager.remove_money(12000)
		current_table.bet += 40
		_update_upgrade_buttons()

func _on_buy_felt():
	if current_table and GameManager.money >= 10000 and not current_table.has_felt:
		GameManager.remove_money(10000)
		current_table.has_felt = true
		current_table.add_prestige_bonus(60)
		_update_upgrade_buttons()
		update_header()

func _on_buy_led():
	if current_table and GameManager.money >= 15000 and not current_table.has_led:
		GameManager.remove_money(15000)
		current_table.has_led = true
		current_table.add_prestige_bonus(80)
		_update_upgrade_buttons()
		update_header()

func _on_buy_chip_rack():
	if current_table and GameManager.money >= 20000 and not current_table.has_chip_rack:
		GameManager.remove_money(20000)
		current_table.has_chip_rack = true
		current_table.add_prestige_bonus(100)
		_update_upgrade_buttons()
		update_header()

func _on_buy_vip():
	if current_table and GameManager.money >= 35000 and not current_table.has_vip_seats:
		GameManager.remove_money(35000)
		current_table.has_vip_seats = true
		current_table.add_prestige_bonus(120)
		_update_upgrade_buttons()
		update_header()

func _on_buy_spinner():
	if current_table and GameManager.money >= 50000 and not current_table.has_spinner:
		GameManager.remove_money(50000)
		current_table.has_spinner = true
		current_table.add_prestige_bonus(150)
		_update_upgrade_buttons()
		update_header()

func _on_buy_drinks():
	if current_table and GameManager.money >= 100000 and not current_table.has_drinks:
		GameManager.remove_money(100000)
		current_table.has_drinks = true
		current_table.add_prestige_bonus(200)
		_update_upgrade_buttons()
		update_header()

func update_header():
	if current_table:
		var header_prestige_label = $CenterContainer/Panel/VBoxContainer/Header/PrestigePanel/PrestigeMargin/PrestigeLabel
		if header_prestige_label:
			var p = current_table.get_prestige()
			header_prestige_label.text = "⭐ " + str(p)
			if p < 0:
				header_prestige_label.add_theme_color_override("font_color", Color(0.8, 0.26, 0.26))
			else:
				header_prestige_label.remove_theme_color_override("font_color")

func _ready():
	visible = false
	add_to_group("table_ui")
	
	slider.value_changed.connect(_on_HSlider_value_changed)
	if has_node("CenterContainer/Panel/VBoxContainer/Header/CloseButton"):
		$CenterContainer/Panel/VBoxContainer/Header/CloseButton.pressed.connect(_on_Close_pressed)
		
	GameManager.stats_changed.connect(_on_stats_changed)
		
	if has_node("%BuySpeedBtn"):
		%BuySpeedBtn.pressed.connect(_on_buy_speed)
	if has_node("%BuyCharismaBtn"):
		%BuyCharismaBtn.pressed.connect(_on_buy_charisma)
	if has_node("%BuyMasterBtn"):
		%BuyMasterBtn.pressed.connect(_on_buy_master)
		
	if has_node("%BuyFeltBtn"):
		%BuyFeltBtn.pressed.connect(_on_buy_felt)
	if has_node("%BuyLEDBtn"):
		%BuyLEDBtn.pressed.connect(_on_buy_led)
	if has_node("%BuyChipRackBtn"):
		%BuyChipRackBtn.pressed.connect(_on_buy_chip_rack)
	if has_node("%BuyVIPBtn"):
		%BuyVIPBtn.pressed.connect(_on_buy_vip)
	if has_node("%TestBtn1"):
		%TestBtn1.pressed.connect(_on_buy_spinner)
	if has_node("%TestBtn2"):
		%TestBtn2.pressed.connect(_on_buy_drinks)
	
