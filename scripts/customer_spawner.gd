extends Node2D

@export var customer_scene: PackedScene
@export var spawn_x_min: int = 50
@export var spawn_x_max: int = 150   # szerokość chodnika

@export var screen_height: int = 1080

func _ready():
	spawn_loop()

func spawn_loop():
	while true:
		await get_tree().create_timer(randf_range(1.0, 2.5)).timeout
		spawn_customer()

func spawn_customer():
	var customer = customer_scene.instantiate()
	
	# 🔥 losuj czy z góry czy z dołu
	var spawn_top = randi() % 2 == 0
	
	var x = randf_range(spawn_x_min, spawn_x_max)
	var y = 0 if spawn_top else screen_height
	
	customer.global_position = Vector2(x, y)
	
	# 🔥 ustaw kierunek ruchu
	if spawn_top:
		customer.walking_direction = 1   # w dół
	else:
		customer.walking_direction = -1  # w górę
	
	get_parent().get_node("Customers").add_child(customer)
