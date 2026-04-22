extends CanvasLayer

var current_cashier = null
var _updating_slider = false

#@onready var stats_label = $Panel/VBoxContainer/TabContainer/Stats/StatsLabel
@onready var slider = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/HSlider
@onready var win_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/LabelsRow/WinLabel
@onready var prestige_delta_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/LabelsRow/PrestigeDeltaLabel
@onready var min_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/BottomLabels/MinLabel
@onready var max_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/BottomLabels/MaxLabel
@onready var mid_label = $CenterContainer/Panel/VBoxContainer/TabContainer/Stats/WinProbPanel/MarginContainer/SliderPanel/BottomLabels/MidLabel
@onready var wait_time_label = %Value
@onready var prestige_label = %Value2
@onready var vip_bonus_label = %Value3

func open(cashier):
	if cashier == null:
		print("ERROR: cashier is null")
		return
		
	visible = true
	current_cashier = cashier
	
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
	if current_cashier and wait_time_label and prestige_label and vip_bonus_label:
		wait_time_label.text = "%.1fs" % current_cashier.wait_time if current_cashier.get("wait_time") != null else "5.0s"
		prestige_label.text = str(current_cashier.prestige) if current_cashier.get("prestige") != null else "0"
		vip_bonus_label.text = "+%.0f%%" % (current_cashier.vip_chance * 100) if current_cashier.get("vip_chance") != null else "+0%"

func update_controls():
	_updating_slider = true
	
	slider.step = 0.01
	var center_prob = 0.50 # Force middle point to 50%
	var spread = 0.05 # allowing a +/- 5% change
	slider.min_value = center_prob - spread
	slider.max_value = center_prob + spread
	
	if current_cashier.get("win_probability") == null:
		current_cashier.win_probability = 0.50

	# If the table's probability is out of our new strict 45-55% bounds, default it exactly to 50%
	if current_cashier.win_probability < slider.min_value or current_cashier.win_probability > slider.max_value:
		current_cashier.win_probability = center_prob
		
	slider.value = current_cashier.win_probability
	
	min_label.text = "%.0f%%" % ((center_prob - spread) * 100)
	max_label.text = "%.0f%%" % ((center_prob + spread) * 100)
	mid_label.text = "%.0f%%" % (center_prob * 100)
	
	_update_details_label()
	
	win_label.text = "Win Chance: %.2f%%" % (current_cashier.win_probability * 100)
	
	# Initial prestige text calc
	var change_percent = (current_cashier.win_probability - center_prob)
	var prestige_change = int(-change_percent * 100 * 4)
	var sign_str = "+" if prestige_change > 0 else ""
	var color_tag = "[color=#d4af37]" if prestige_change >= 0 else "[color=#cc4444]"
	prestige_delta_label.text = "[right]" + color_tag + sign_str + str(prestige_change) + " ⭐[/color][/right]"
	_updating_slider = false
	
	_update_upgrade_buttons()

func _update_upgrade_buttons():
	if current_cashier == null:
		return
		
	_update_details_label()
		
	# Cashier Update
	if has_node("%BuyCashierUpdateBtn"):
		var btn = get_node("%BuyCashierUpdateBtn")
		var w_time = current_cashier.wait_time if current_cashier.get("wait_time") != null else 5.0
		if w_time <= 2.0:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 5000
			btn.text = "$5,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%BuyPrestigeBtn"):
		var btn = get_node("%BuyPrestigeBtn")
		var maxed = current_cashier.get("prestige") != null and current_cashier.prestige >= 10
		if maxed:
			btn.disabled = true
			btn.text = "Maxed"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 10000
			btn.text = "$10,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	if has_node("%BuyVipBtn"):
		var btn = get_node("%BuyVipBtn")
		var maxed = current_cashier.get("vip_chance") != null and current_cashier.vip_chance >= 0.10
		if maxed:
			btn.disabled = true
			btn.text = "Maxed"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = GameManager.money < 20000
			btn.text = "$20,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

func _on_HSlider_value_changed(value):
	if _updating_slider or current_cashier == null:
		return
		
	current_cashier.win_probability = value
	win_label.text = "Win Chance: %.2f%%" % (value * 100)
	
	var center_prob = 0.50
	var change_percent = (value - center_prob)
	var prestige_change = int(-change_percent * 100 * 4) # Decrease prestige if win probability is higher (left = more, right = less)
	var sign_str = "+" if prestige_change > 0 else ""
	var color_tag = "[color=#d4af37]" if prestige_change >= 0 else "[color=#cc4444]" # Gold for positive, red for negative
	prestige_delta_label.text = "[right]" + color_tag + sign_str + str(prestige_change) + " ⭐[/color][/right]"
	
	if current_cashier.has_method("update_prestige"):
		current_cashier.update_prestige()
		update_header()

# ====== CLOSE ======
func _on_stats_changed():
	if visible and current_cashier:
		_update_upgrade_buttons()

func _on_Close_pressed():
	close()
	
func _on_buy_cashier_update():
	if current_cashier and GameManager.money >= 5000:
		var w_time = current_cashier.wait_time if current_cashier.get("wait_time") != null else 5.0
		if w_time > 2.0:
			GameManager.remove_money(5000)
			current_cashier.wait_time = w_time - 1.0
			_update_upgrade_buttons()

func _on_buy_prestige_update():
	if current_cashier and GameManager.money >= 10000:
		if current_cashier.prestige < 10:
			GameManager.remove_money(10000)
			current_cashier.prestige += 1
			if current_cashier.has_method("update_prestige"):
				current_cashier.update_prestige()
			else:
				GameManager.update_global_prestige()
			_update_upgrade_buttons()
			update_header()

func _on_buy_vip_update():
	if current_cashier and GameManager.money >= 20000:
		if current_cashier.vip_chance < 0.10:
			GameManager.remove_money(20000)
			current_cashier.vip_chance += 0.01
			_update_upgrade_buttons()

func update_header():
	if current_cashier:
		var header_prestige_label = $CenterContainer/Panel/VBoxContainer/Header/PrestigePanel/PrestigeMargin/PrestigeLabel
		if header_prestige_label:
			var p = current_cashier.prestige if current_cashier.get("prestige") != null else 0
			header_prestige_label.text = "⭐ " + str(p)
			if p < 0:
				header_prestige_label.add_theme_color_override("font_color", Color(0.8, 0.26, 0.26))
			else:
				header_prestige_label.remove_theme_color_override("font_color")

func _ready():
	visible = false
	add_to_group("cashier_ui")
	
	slider.value_changed.connect(_on_HSlider_value_changed)
	if has_node("CenterContainer/Panel/VBoxContainer/Header/CloseButton"):
		$CenterContainer/Panel/VBoxContainer/Header/CloseButton.pressed.connect(_on_Close_pressed)
		
	GameManager.stats_changed.connect(_on_stats_changed)
		
	if has_node("%BuyCashierUpdateBtn"):
		%BuyCashierUpdateBtn.pressed.connect(_on_buy_cashier_update)
	if has_node("%BuyPrestigeBtn"):
		%BuyPrestigeBtn.pressed.connect(_on_buy_prestige_update)
	if has_node("%BuyVipBtn"):
		%BuyVipBtn.pressed.connect(_on_buy_vip_update)
	
