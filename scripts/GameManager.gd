extends Node

var money: float = 9950
var reputation: float = 10
var customers: int = 0
var play_time: float = 0.0
var tables_bought: int = 0
var has_won: bool = false

const WIN_CONDITION = 100010#specjalnie żeby gra się za szybko nie kończyła

signal stats_changed
signal game_won

func _ready():
	add_to_group("game_manager")
	print("GameManager: Initialized with $", money, " (target: $", WIN_CONDITION, ")")

func add_money(amount):
	money += amount
	print("GameManager: Added $", amount, ", total: $", money)
	emit_signal("stats_changed")
	_check_win_condition()

func remove_money(amount):
	money -= amount
	emit_signal("stats_changed")

func _check_win_condition():
	if money >= WIN_CONDITION and not has_won:
		print("GameManager: WIN CONDITION REACHED! Money: ", money, " Target: ", WIN_CONDITION)
		has_won = true
		get_tree().paused = true
		await get_tree().process_frame  # Wait one frame to ensure GameEndUI is ready
		emit_signal("game_won")

func add_customer():
	customers += 1
	emit_signal("stats_changed")

func remove_customer():
	customers -= 1
	emit_signal("stats_changed")

func get_total_prestige() -> int:
	var total = 0
	for table in get_tree().get_nodes_in_group("tables"):
		if table.has_method("get_prestige"):
			total += table.get_prestige()
	for cashier in get_tree().get_nodes_in_group("cashier"):
		if "prestige" in cashier:
			total += cashier.prestige
	return total

func count_tables() -> int:
	return get_tree().get_nodes_in_group("tables").size()

func update_global_prestige():
	reputation = get_total_prestige()
	emit_signal("stats_changed")

func change_reputation(amount):
	update_global_prestige()

func _process(delta):
	if not get_tree().paused:
		play_time += delta
