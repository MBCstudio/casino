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
	
	# Zaktualizuj tytuł na podstawie typu stołu
	var title_lbl = $CenterContainer/Panel/VBoxContainer/Header/TitleBox/TitleLabel
	if title_lbl:
		if table.table_type == "blackjack":
			title_lbl.text = "Blackjack Table"
		else:
			title_lbl.text = "Roulette Table"

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
	
	_update_upgrade_titles()
	_update_upgrade_buttons()

func _update_upgrade_titles() -> void:
	"""Aktualizuj Label'e z nazwami ulepszeń"""
	if current_table == null:
		return
	
	# Dealer Upgrades
	var title = get_node_or_null("CenterContainer/Panel/VBoxContainer/TabContainer/Dealer Upgrade/VBoxContainer/SpeedTrainingPanel/MarginContainer/HBoxContainer/VBoxContainer/Title")
	if title:
		var info = _get_upgrade_info("speed")
		title.text = info["name"]
	
	title = get_node_or_null("CenterContainer/Panel/VBoxContainer/TabContainer/Dealer Upgrade/VBoxContainer/CharismaCoursePanel/MarginContainer/HBoxContainer/VBoxContainer/Title")
	if title:
		var info = _get_upgrade_info("charisma")
		title.text = info["name"]
	
	title = get_node_or_null("CenterContainer/Panel/VBoxContainer/TabContainer/Dealer Upgrade/VBoxContainer/MasterClassPanel/MarginContainer/HBoxContainer/VBoxContainer/Title")
	if title:
		var info = _get_upgrade_info("master")
		title.text = info["name"]
	
	# Table Upgrades
	title = get_node_or_null("CenterContainer/Panel/VBoxContainer/TabContainer/Table Upgrade/ScrollContainer/VBoxContainer/VelvetFeltPanel/MarginContainer/HBoxContainer/VBoxContainer/Title")
	if title:
		var info = _get_upgrade_info("felt")
		title.text = info["name"]
	
	title = get_node_or_null("CenterContainer/Panel/VBoxContainer/TabContainer/Table Upgrade/ScrollContainer/VBoxContainer/LEDLightingPanel/MarginContainer/HBoxContainer/VBoxContainer/Title")
	if title:
		var info = _get_upgrade_info("led")
		title.text = info["name"]
	
	title = get_node_or_null("CenterContainer/Panel/VBoxContainer/TabContainer/Table Upgrade/ScrollContainer/VBoxContainer/GoldChipRackPanel/MarginContainer/HBoxContainer/VBoxContainer/Title")
	if title:
		var info = _get_upgrade_info("chip_rack")
		title.text = info["name"]
	
	title = get_node_or_null("CenterContainer/Panel/VBoxContainer/TabContainer/Table Upgrade/ScrollContainer/VBoxContainer/VIPSeatingPanel/MarginContainer/HBoxContainer/VBoxContainer/Title")
	if title:
		var info = _get_upgrade_info("vip")
		title.text = info["name"]
	
	title = get_node_or_null("CenterContainer/Panel/VBoxContainer/TabContainer/Table Upgrade/ScrollContainer/VBoxContainer/ExtraTestPanel1/MarginContainer/HBoxContainer/VBoxContainer/Title")
	if title:
		var info = _get_upgrade_info("test1")
		title.text = info["name"]
	
	title = get_node_or_null("CenterContainer/Panel/VBoxContainer/TabContainer/Table Upgrade/ScrollContainer/VBoxContainer/ExtraTestPanel2/MarginContainer/HBoxContainer/VBoxContainer/Title")
	if title:
		var info = _get_upgrade_info("test2")
		title.text = info["name"]

func _get_upgrade_info(upgrade_id: String) -> Dictionary:
	if current_table == null:
		return {"name": "Unknown", "price": 999999}
	var is_bj = (current_table.table_type == "blackjack")
	match upgrade_id:
		"speed": return {"name": "Fast Dealing" if is_bj else "Fast Spinning", "price": 4000 if is_bj else 6000}
		"charisma": return {"name": "Professional" if is_bj else "Elegant Croupier", "price": 6000 if is_bj else 9000}
		"master": return {"name": "Senior Dealer" if is_bj else "Master Croupier", "price": 10000 if is_bj else 15000}
		"felt": return {"name": "Premium Felt" if is_bj else "Luxury Felt", "price": 8000 if is_bj else 12000}
		"led": return {"name": "Brass Finish" if is_bj else "Gold Finish", "price": 12000 if is_bj else 18000}
		"chip_rack": return {"name": "Wooden Rack" if is_bj else "Classic Rack", "price": 16000 if is_bj else 24000}
		"vip": return {"name": "Leather Seats" if is_bj else "Velvet Seats", "price": 25000 if is_bj else 35000}
		"test1": return {"name": "Vintage Cards" if is_bj else "Mahogany Wheel", "price": 40000 if is_bj else 60000}
		"test2": return {"name": "Free Snacks" if is_bj else "Gourmet Snacks", "price": 80000 if is_bj else 120000}
	return {"name": "Unknown", "price": 999999}

func _update_upgrade_buttons():
	if current_table == null:
		return
		
	_update_details_label()
		
	# Speed
	if has_node("%BuySpeedBtn"):
		var btn = get_node("%BuySpeedBtn")
		var info = _get_upgrade_info("speed")
		if current_table.play_time <= 8.0:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < info.price
			btn.text = "$%d" % info.price
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))
			
	# Charisma
	if has_node("%BuyCharismaBtn"):
		var btn = get_node("%BuyCharismaBtn")
		var info = _get_upgrade_info("charisma")
		if current_table.vip_chance_bonus > 0.04:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < info.price
			btn.text = "$%d" % info.price
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	# Master
	if has_node("%BuyMasterBtn"):
		var btn = get_node("%BuyMasterBtn")
		var info = _get_upgrade_info("master")
		if current_table.bet >= 50: # upraszczam: bet limit zostaje jak był z wliczonym masterem (albo uzyto innej flagi)
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < info.price
			btn.text = "$%d" % info.price
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	# Table Upgrades
	if has_node("%BuyFeltBtn"):
		var btn = get_node("%BuyFeltBtn")
		var info = _get_upgrade_info("felt")
		if current_table.has_felt:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < info.price
			btn.text = "$%d" % info.price
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%BuyLEDBtn"):
		var btn = get_node("%BuyLEDBtn")
		var info = _get_upgrade_info("led")
		if current_table.has_led:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < info.price
			btn.text = "$%d" % info.price
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%BuyChipRackBtn"):
		var btn = get_node("%BuyChipRackBtn")
		var info = _get_upgrade_info("chip_rack")
		if current_table.has_chip_rack:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < info.price
			btn.text = "$%d" % info.price
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%BuyVIPBtn"):
		var btn = get_node("%BuyVIPBtn")
		var info = _get_upgrade_info("vip")
		if current_table.has_vip_seats:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < info.price
			btn.text = "$%d" % info.price
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%TestBtn1"):
		var btn = get_node("%TestBtn1")
		var info = _get_upgrade_info("test1")
		if current_table.has_spinner:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < info.price
			btn.text = "$%d" % info.price
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%TestBtn2"):
		var btn = get_node("%TestBtn2")
		var info = _get_upgrade_info("test2")
		if current_table.has_drinks:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < info.price
			btn.text = "$%d" % info.price
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

func _on_HSlider_value_changed(value):
	if _updating_slider or current_table == null:
		return
		
	current_table.win_probability = value
	win_label.text = "Win Chance: %.2f%%" % (value * 100)
	
	var center_prob = 0.50
	var change_percent = (value - center_prob)
	var prestige_change = int(change_percent * 100 * 4) # Decrease prestige if win probability is higher (left = less, right = more)
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
	var info = _get_upgrade_info("speed")
	if current_table and GameManager.money >= info.price and current_table.play_time > 8.0:
		GameManager.remove_money(info.price)
		current_table.play_time = 8.0
		_update_upgrade_buttons()

func _on_buy_charisma():
	var info = _get_upgrade_info("charisma")
	if current_table and GameManager.money >= info.price and current_table.vip_chance_bonus <= 0.04:
		GameManager.remove_money(info.price)
		current_table.vip_chance_bonus += 0.05
		_update_upgrade_buttons()

func _on_buy_master():
	var info = _get_upgrade_info("master")
	if current_table and GameManager.money >= info.price and current_table.bet < 50:
		GameManager.remove_money(info.price)
		current_table.bet += 40
		_update_upgrade_buttons()

func _on_buy_felt():
	var info = _get_upgrade_info("felt")
	if current_table and GameManager.money >= info.price and not current_table.has_felt:
		GameManager.remove_money(info.price)
		current_table.has_felt = true
		current_table.add_prestige_bonus(60)
		_update_upgrade_buttons()
		update_header()

func _on_buy_led():
	var info = _get_upgrade_info("led")
	if current_table and GameManager.money >= info.price and not current_table.has_led:
		GameManager.remove_money(info.price)
		current_table.has_led = true
		current_table.add_prestige_bonus(80)
		_update_upgrade_buttons()
		update_header()

func _on_buy_chip_rack():
	var info = _get_upgrade_info("chip_rack")
	if current_table and GameManager.money >= info.price and not current_table.has_chip_rack:
		GameManager.remove_money(info.price)
		current_table.has_chip_rack = true
		current_table.add_prestige_bonus(100)
		_update_upgrade_buttons()
		update_header()

func _on_buy_vip():
	var info = _get_upgrade_info("vip")
	if current_table and GameManager.money >= info.price and not current_table.has_vip_seats:
		GameManager.remove_money(info.price)
		current_table.has_vip_seats = true
		current_table.add_prestige_bonus(120)
		_update_upgrade_buttons()
		update_header()

func _on_buy_spinner():
	var info = _get_upgrade_info("test1")
	if current_table and GameManager.money >= info.price and not current_table.has_spinner:
		GameManager.remove_money(info.price)
		current_table.has_spinner = true
		current_table.add_prestige_bonus(150)
		_update_upgrade_buttons()
		update_header()

func _on_buy_drinks():
	var info = _get_upgrade_info("test2")
	if current_table and GameManager.money >= info.price and not current_table.has_drinks:
		GameManager.remove_money(info.price)
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
	
