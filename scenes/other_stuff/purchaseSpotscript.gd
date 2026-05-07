extends Area2D

@export var building_name : String = "BAR"
@export var price : int = 10000

func _ready():
	$Label.text = "%s\n$%d" % [building_name, price]
