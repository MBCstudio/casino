extends Node

var money: float = 1000
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

func change_reputation(amount):
	reputation += amount
	reputation = clamp(reputation, 0, 100)
	emit_signal("stats_changed")
