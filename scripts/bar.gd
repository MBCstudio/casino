extends StaticBody2D

@export var passive_income: int = 0
@export var passive_ready: bool = false
@export var prestige: int = 0
@export var vip_percentage: float = 0.0
@export var cashier_upgraded: bool = false
@export var drinks_upgraded: bool = false
@export var live_band_upgraded: bool = false

@onready var collect_indicator = $CollectIndicator
@onready var indicator_icon = $CollectIndicator/Icon
@onready var indicator_animation = $CollectIndicator/AnimationPlayer

var _collect_tween: Tween = null

func _ready():
	add_to_group("bars")
	add_to_group("collect_indicators")
	input_pickable = true

	# ensure we don't leave stray bubble timers between scenes
	if has_node("PassiveBubbleTimer"):
		var bt = get_node("PassiveBubbleTimer")
		bt.queue_free()
	if has_node("PassiveTimer"):
		var t = get_node("PassiveTimer")
		t.queue_free()

	# Setup collect indicator
	_setup_collect_indicator()

	# If this bar already has cashier upgraded, ensure passive timer runs
	# (no auto time-scaling) leave timer behavior as before; do not auto-start here

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Check if clicking on collect indicator
		if collect_indicator and collect_indicator.visible and passive_ready:
			_collect_passive_income()
		else:
			open_bar_ui()

func open_bar_ui():
	var ui = get_tree().get_first_node_in_group("bar_ui")
	if ui:
		ui.open(self)
	else:
		print("BarUi not found in group bar_ui")

func start_passive_timer():
	# starts (or restarts) a one-shot timer that will mark passive income as ready
	var base_wait = 60.0
	var mult = 1.0
	if typeof(GameManager) != TYPE_NIL:
		if "time_multiplier" in GameManager:
			mult = GameManager.time_multiplier
		elif GameManager.has_method("get") and GameManager.get("time_multiplier") != null:
			mult = GameManager.get("time_multiplier")

	var wait = base_wait / max(mult, 0.0001)

	if has_node("PassiveTimer"):
		var t = get_node("PassiveTimer")
		t.stop()
		t.wait_time = wait
	else:
		var t = Timer.new()
		t.name = "PassiveTimer"
		t.one_shot = true
		add_child(t)
		t.timeout.connect(_on_passive_timer_timeout)
	get_node("PassiveTimer").start()

func _on_passive_timer_timeout():
	passive_ready = true
	# Show the collect indicator
	_show_collect_indicator()
	# notify UI if open for this bar
	var ui = get_tree().get_first_node_in_group("bar_ui")
	if ui and ui.has_method("on_bar_passive_ready"):
		ui.on_bar_passive_ready(self)

func _show_passive_bubble():
	# delegate showing the bubble to the Bar UI (avoids engine-specific 2D label class)
	var ui = get_tree().get_first_node_in_group("bar_ui")
	if ui and ui.has_method("_show_passive_bubble_world"):
		ui._show_passive_bubble_world(self)
		return

	# fallback: print a message if no UI available
	print("Passive income ready!")

func _on_passive_bubble_timeout():
	if has_node("PassiveBubble"):
		get_node("PassiveBubble").queue_free()
	if has_node("PassiveBubbleTimer"):
		get_node("PassiveBubbleTimer").queue_free()


# ═══════════════════════════════════════════════════════════════════════════════
# COLLECT INDICATOR - Passive Income Collection UI
# ═══════════════════════════════════════════════════════════════════════════════

func _setup_collect_indicator():
	"""Initialize the collect indicator (money animation)"""
	if not collect_indicator:
		return
	
	# Initially hidden
	collect_indicator.visible = false
	
	# Load money icon texture if Icon doesn't have one yet
	if indicator_icon and not indicator_icon.texture:
		# Try to find a money/coin texture
		var money_texture_path = "res://assets/sprites/plus_sign.png"
		if ResourceLoader.exists(money_texture_path):
			indicator_icon.texture = load(money_texture_path)

func _create_bob_animation():
	"""Create the up-down bobbing animation using Tween"""
	# Kill previous tween if running
	if _collect_tween:
		_collect_tween.kill()
	
	# Create looping tween animation
	_collect_tween = create_tween()
	_collect_tween.set_loops()  # Loop forever
	_collect_tween.set_trans(Tween.TRANS_SINE)
	_collect_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Animate position Y up and down
	_collect_tween.tween_property(collect_indicator, "position:y", -10.0, 0.5)
	_collect_tween.tween_property(collect_indicator, "position:y", 0.0, 0.5)
	
	# Animate alpha (pulse)
	var alpha_tween = create_tween()
	alpha_tween.set_loops()
	alpha_tween.set_trans(Tween.TRANS_SINE)
	alpha_tween.set_ease(Tween.EASE_IN_OUT)
	alpha_tween.tween_property(indicator_icon, "modulate:a", 1.0, 0.5)
	alpha_tween.tween_property(indicator_icon, "modulate:a", 0.8, 0.5)

func _show_collect_indicator():
	"""Show the collect indicator and start bobbing animation"""
	if not collect_indicator:
		return
	
	collect_indicator.visible = true
	
	# Create and play bobbing animation
	_create_bob_animation()

func _hide_collect_indicator():
	"""Hide the collect indicator"""
	if not collect_indicator:
		return
	
	collect_indicator.visible = false
	
	# Kill tween animation
	if _collect_tween:
		_collect_tween.kill()
		_collect_tween = null

func _collect_passive_income():
	"""Collect passive income when player clicks on indicator"""
	if not passive_ready:
		return
	
	# Add money
	var amount = passive_income
	if amount > 0:
		if GameManager.has_method("add_money"):
			GameManager.add_money(amount)
		elif "money" in GameManager:
			GameManager.money += amount
	
	# Reset state
	passive_ready = false
	_hide_collect_indicator()
	
	# Restart timer for next cycle
	start_passive_timer()
	
	# Update UI if open
	var ui = get_tree().get_first_node_in_group("bar_ui")
	if ui and ui.has_method("update_controls"):
		ui.update_controls()
