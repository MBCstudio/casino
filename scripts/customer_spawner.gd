extends Node2D

var normal_customer_scene = preload("res://scenes/actors/customers/normal_customer.tscn")
var poor_customer_scene = preload("res://scenes/actors/customers/poor_customer.tscn")
var rich_customer_scene = preload("res://scenes/actors/customers/rich_customer.tscn")
var vip_customer_scene = preload("res://scenes/actors/customers/vip_customer.tscn")

@export var spawn_x_min: int = 50
@export var spawn_x_max: int = 150   # szerokość chodnika

@export var screen_height: int = 1080
@export var max_active_customers: int = 120
@export var max_total_spawned: int = 10000

var _total_spawned: int = 0

func _ready():
	spawn_loop()

func spawn_loop():
	while _total_spawned < max_total_spawned:
		await get_tree().create_timer(randf_range(5.0, 8.5), false).timeout
		if _get_active_customer_count() < max_active_customers:
			spawn_customer()

func _get_active_customer_count() -> int:
	var customers_parent := get_parent().get_node_or_null("Customers")
	if customers_parent == null:
		return get_tree().get_nodes_in_group("customers").size()
	return customers_parent.get_child_count()

func get_random_customer_scene() -> PackedScene:
	var roll = randf()
	# 40% poor, 35% normal, 20% rich, 5% vip
	if roll < 0.40:
		return poor_customer_scene
	elif roll < 0.75:
		return normal_customer_scene
	elif roll < 0.95:
		return rich_customer_scene
	else:
		return vip_customer_scene

func spawn_customer():
	var scene_to_spawn = get_random_customer_scene()
	if not scene_to_spawn:
		return
		
	var customer = scene_to_spawn.instantiate()
	
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
	
	var customers_parent := get_parent().get_node_or_null("Customers")
	if customers_parent == null:
		customer.queue_free()
		return

	customers_parent.add_child(customer)
	_total_spawned += 1
