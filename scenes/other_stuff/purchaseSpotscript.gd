extends Area2D

@export var building_name : String = "BAR"
@export var price : int = 10000

func _ready():
	add_to_group("bar_purchase_spots")
	$Label.text = "%s\n$%d" % [building_name, price]
