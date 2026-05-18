extends CanvasLayer

var current_bar = null

@onready var passive_income_label = %Value
@onready var prestige_label = %Value2
@onready var vip_bonus_label = %Value3
@onready var collect_btn = %CollectPassiveBtn

func _ready():
	add_to_group("bar_ui")
	var speed_btn = get_node_or_null("%BuySpeedBtn")
	if speed_btn:
		speed_btn.pressed.connect(_on_buy_cashier)
		
	var drinks_btn = get_node_or_null("%BuyDrinksBtn")
	if drinks_btn:
		drinks_btn.pressed.connect(_on_buy_drinks)
		
	var band_btn = get_node_or_null("%BuyBandBtn")
	if band_btn:
		band_btn.pressed.connect(_on_buy_band)

	var cbtn = get_node_or_null("%CollectPassiveBtn")
	if cbtn:
		cbtn.pressed.connect(_on_collect_passive)

	var close_btn = find_child("CloseButton", true, false)
	var top_prestige = %PrestigeLabel if has_node("%PrestigeLabel") else get_node_or_null("%PrestigeLabel")
	if close_btn:
		close_btn.pressed.connect(close)

func open(bar):
	if bar == null:
		print("ERROR: bar is null")
		return
		
	visible = true
	current_bar = bar
	
	update_controls()

func close():
	visible = false
	get_tree().paused = false

func _update_details_label():
	if current_bar and passive_income_label and prestige_label and vip_bonus_label:
		var p_inc = 0
		if "passive_income" in current_bar:
			p_inc = current_bar.passive_income
		passive_income_label.text = "$%d/min" % p_inc
		
		var pres = 0
		if current_bar.has_method("get_prestige"):
			pres = current_bar.get_prestige()
		elif "prestige" in current_bar:
			pres = current_bar.prestige
			
		prestige_label.text = "%d" % pres
		
		var top_prestige = get_node_or_null("%PrestigeLabel")
		if top_prestige:
			top_prestige.text = "⭐ %d" % pres
		
		var vip = 0.0
		if "vip_percentage" in current_bar:
			vip = current_bar.vip_percentage
			
		vip_bonus_label.text = "+%.0f%%" % (vip * 100)

func update_controls():
	_update_details_label()
	_update_upgrade_buttons()
	# show collect button when passive income is ready
	var cbtn = get_node_or_null("%CollectPassiveBtn")
	if cbtn:
		var ready = false
		if current_bar and current_bar.get("passive_ready") != null:
			ready = current_bar.get("passive_ready")
		cbtn.visible = ready
		cbtn.disabled = not ready

func _update_upgrade_buttons():
	if current_bar == null:
		return
		
	_update_details_label()
		
	var btn = get_node_or_null("%BuySpeedBtn")
	if btn:
		var is_upgraded = current_bar.get("cashier_upgraded") if current_bar.get("cashier_upgraded") != null else false
		var cost = 5000
		var player_money = GameManager.get("money") if GameManager and GameManager.get("money") != null else 0
		if is_upgraded:
			btn.disabled = true
			btn.text = "Bought"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.disabled = player_money < cost
			btn.text = "$5,000"
			btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not btn.disabled else Color(0.4, 0.4, 0.4))

	var drinks_btn = get_node_or_null("%BuyDrinksBtn")
	if drinks_btn:
		var is_upgraded = current_bar.get("drinks_upgraded") if current_bar.get("drinks_upgraded") != null else false
		var cost = 8000
		var player_money = GameManager.get("money") if GameManager and GameManager.get("money") != null else 0
		if is_upgraded:
			drinks_btn.disabled = true
			drinks_btn.text = "Bought"
			drinks_btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			drinks_btn.disabled = player_money < cost
			drinks_btn.text = "$8,000"
			drinks_btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not drinks_btn.disabled else Color(0.4, 0.4, 0.4))

	var band_btn = get_node_or_null("%BuyBandBtn")
	if band_btn:
		var is_upgraded = current_bar.get("live_band_upgraded") if current_bar.get("live_band_upgraded") != null else false
		var cost = 12000
		var player_money = GameManager.get("money") if GameManager and GameManager.get("money") != null else 0
		if is_upgraded:
			band_btn.disabled = true
			band_btn.text = "Bought"
			band_btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			band_btn.disabled = player_money < cost
			band_btn.text = "$12,000"
			band_btn.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24) if not band_btn.disabled else Color(0.4, 0.4, 0.4))

func _on_buy_cashier():
	var cost = 5000
	var player_money = GameManager.get("money") if GameManager and GameManager.get("money") != null else 0
		
	if player_money >= cost:
		if GameManager.has_method("remove_money"):
			GameManager.remove_money(cost)
		elif "money" in GameManager:
			GameManager.money -= cost
			
		current_bar.set("cashier_upgraded", true)
		if current_bar.get("passive_income") != null:
			current_bar.set("passive_income", current_bar.get("passive_income") + 50)
		# cashier purchased — start passive cycle
		# start passive income cycle after buying cashier upgrade
		if current_bar.has_method("start_passive_timer"):
			current_bar.start_passive_timer()
			
		update_controls()

func _on_buy_drinks():
	var cost = 8000
	var player_money = GameManager.get("money") if GameManager and GameManager.get("money") != null else 0
	if player_money >= cost:
		if GameManager.has_method("remove_money"):
			GameManager.remove_money(cost)
		elif "money" in GameManager:
			GameManager.money -= cost
		current_bar.set("drinks_upgraded", true)
		if current_bar.get("prestige") != null:
			current_bar.set("prestige", current_bar.get("prestige") + 150)
		update_controls()

func _on_buy_band():
	var cost = 12000
	var player_money = GameManager.get("money") if GameManager and GameManager.get("money") != null else 0
	if player_money >= cost:
		if GameManager.has_method("remove_money"):
			GameManager.remove_money(cost)
		elif "money" in GameManager:
			GameManager.money -= cost
		current_bar.set("live_band_upgraded", true)
		if current_bar.get("vip_percentage") != null:
			current_bar.set("vip_percentage", current_bar.get("vip_percentage") + 0.05)
		update_controls()

func _on_collect_passive():
	if current_bar == null:
		return
	var ready = current_bar.get("passive_ready") if current_bar.get("passive_ready") != null else false
	if not ready:
		return

	# Use the bar's collect method if available (for consistency)
	if current_bar.has_method("_collect_passive_income"):
		current_bar._collect_passive_income()
	else:
		# Fallback to old logic
		var amount = 0
		if current_bar.get("passive_income") != null:
			amount = current_bar.passive_income

		if amount > 0:
			if GameManager.has_method("add_money"):
				GameManager.add_money(amount)
			elif "money" in GameManager:
				GameManager.money += amount

		current_bar.set("passive_ready", false)
		# restart the passive timer for the next cycle
		if current_bar.has_method("start_passive_timer"):
			current_bar.start_passive_timer()

	update_controls()

func _show_passive_bubble_world(bar):
	# show a short top-center bubble in the Bar UI for 1s
	# remove existing bubble
	if has_node("PassiveWorldBubble"):
		get_node("PassiveWorldBubble").queue_free()

	var lbl = Label.new()
	lbl.name = "PassiveWorldBubble"
	lbl.text = "Passive income ready!"
	lbl.add_theme_color_override("font_color", Color(0.98, 0.83, 0.24))
	lbl.custom_minimum_size = Vector2(260, 36)
	lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	# add into header container so layout positions it safely at top-center
	var header = get_node_or_null("CenterContainer/Panel/VBoxContainer/Header")
	if header:
		header.add_child(lbl)
	else:
		add_child(lbl)

	var t = Timer.new()
	t.one_shot = true
	t.wait_time = 1.0
	add_child(t)
	t.timeout.connect(func():
		if lbl and lbl.is_inside_tree():
			lbl.queue_free()
		if t and t.is_inside_tree():
			t.queue_free()
	)
	t.start()

func on_bar_passive_ready(bar):
	# called by a Bar when its passive_income becomes ready
	if visible and current_bar == bar:
		# show bubble and update controls immediately
		_show_passive_bubble_world(bar)
		update_controls()
