extends StaticBody2D

@export var passive_income: int = 0
@export var passive_ready: bool = false
@export var prestige: int = 0
@export var vip_percentage: float = 0.0
@export var cashier_upgraded: bool = false
@export var drinks_upgraded: bool = false
@export var live_band_upgraded: bool = false

func _ready():
	add_to_group("bars")
	input_pickable = true

	# ensure we don't leave stray bubble timers between scenes
	if has_node("PassiveBubbleTimer"):
		var bt = get_node("PassiveBubbleTimer")
		bt.queue_free()
	if has_node("PassiveTimer"):
		var t = get_node("PassiveTimer")
		t.queue_free()

	# If this bar already has cashier upgraded, ensure passive timer runs
	# (no auto time-scaling) leave timer behavior as before; do not auto-start here

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
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
	# show bubble and notify UI if open for this bar
	_show_passive_bubble()
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
