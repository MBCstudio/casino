extends CanvasLayer

@onready var money_label = $HBoxContainer/Money
@onready var rep_label = $HBoxContainer/Reputation
@onready var cust_label = $HBoxContainer/Customers

func _ready():
	GameManager.stats_changed.connect(update_ui)
	update_ui()

func update_ui():
	money_label.text = "💰 $" + str(int(GameManager.money))
	rep_label.text = "⭐ " + str(int(GameManager.reputation))
	cust_label.text = "👥 " + str(GameManager.customers)
