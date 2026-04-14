extends Node

var money: float = 10000
var reputation: float = 10
var customers: int = 0

signal stats_changed

func add_money(amount):
	money += amount
	emit_signal("stats_changed")

func remove_money(amount):
	money -= amount
	emit_signal("stats_changed")

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
	return total

func update_global_prestige():
	reputation = get_total_prestige()
	emit_signal("stats_changed")

func change_reputation(amount):
	update_global_prestige()
