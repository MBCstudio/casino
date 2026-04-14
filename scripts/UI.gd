extends CanvasLayer

@onready var money_label = $HBoxContainer/Money
@onready var rep_label = $HBoxContainer/Reputation
@onready var cust_label = $HBoxContainer/Customers

func _ready():
	GameManager.stats_changed.connect(update_ui)
	update_ui()

func update_ui():
	money_label.text = "💰 $" + str(int(GameManager.money))
	
	var total_prestige = int(GameManager.get_total_prestige())
	rep_label.text = "⭐ " + str(total_prestige)
	if total_prestige < 0:
		rep_label.add_theme_color_override("font_color", Color(0.8, 0.26, 0.26))
	else:
		rep_label.remove_theme_color_override("font_color")
		
	cust_label.text = "👥 " + str(GameManager.customers)
