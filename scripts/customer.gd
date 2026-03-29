extends CharacterBody2D

@export var speed = 100
@export var enter_chance = 0.3

@export var money: float = 100.0
@export var base_bet: float = 10.0
@export var status: String = "normal"

@onready var nav_agent = $NavigationAgent2D

var target_table = null
var target_seat = null
var is_seated = false

# ====== FLOW FLAGS ======
var on_sidewalk = true
var walking_direction = 1

var is_going_to_cashier = false
var is_waiting_at_cashier = false
var is_going_to_seat = false

# ====== STATS ======
var risk: float
var addiction: float
var luck: float
var experience: float
var anger: float = 0.0

# ====== INIT ======
func _ready():
	randomize()
	
	risk = randf_range(0.0, 0.25)
	addiction = randf_range(0.0, 10.0)
	luck = randf_range(-0.05, 0.05)
	experience = randf_range(0.0, 0.03)

# ====== NAVIGATION ======
func set_target(pos: Vector2):
	nav_agent.set_target_position(pos)

# ====== MAIN LOOP ======
func _physics_process(delta):
	move_to_target()
	update_animation()

# ====== SIDEWALK ======
func go_to_casino():
	on_sidewalk = false
	
	var entrance = get_node("/root/CasinoFloor/CasinoEntrance/EntrancePoint")
	set_target(entrance.global_position)
	is_going_to_cashier = true

# ====== CASHIER ======
func find_cashier():
	var cashiers = get_tree().get_nodes_in_group("cashier")
	
	if cashiers.size() > 0:
		set_target(cashiers[0].global_position)
	else:
		find_table()

func wait_at_cashier():
	is_waiting_at_cashier = true
	
	await get_tree().create_timer(5.0).timeout
	
	is_waiting_at_cashier = false
	find_table()

# ====== MOVEMENT ======
func move_to_target():
	if is_seated or is_waiting_at_cashier:
		return
	
	# ===== SIDEWALK =====
	if on_sidewalk:
		velocity = Vector2(0, walking_direction * speed)
		move_and_slide()
		
		if global_position.y < -50 or global_position.y > 1200:
			queue_free()
		return
	
	# ===== NAVIGATION =====
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		
		# 🔥 po wejściu → idź do kasjera
		if is_going_to_cashier:
			is_going_to_cashier = false
			find_cashier()
			return
		
		# 🔥 doszedł do kasjera
		if target_table == null and not is_going_to_seat:
			wait_at_cashier()
			return
		
		# 🔥 doszedł do stołu
		if is_going_to_seat:
			is_going_to_seat = false
			
			# 🔥 SNAP DO MIEJSCA (FIX!)
			global_position = target_seat.global_position
			
			is_seated = true
			face_table()
			try_play()
			return
	
	var next_point = nav_agent.get_next_path_position()
	var direction = (next_point - global_position).normalized()
	
	velocity = direction * speed
	move_and_slide()

# ====== TABLE SYSTEM ======
func set_target_seat(seat, table):
	target_seat = seat
	target_table = table
	
	is_going_to_seat = true
	set_target(seat.global_position)

func find_table():
	var tables = get_tree().get_nodes_in_group("tables")
	
	for table in tables:
		if table.try_add_player(self):
			return
	
	pick_random_target()

# ====== GAMEPLAY ======
func try_play():
	while target_table != null:
		
		if target_table.table_type == "roulette":
			await get_tree().create_timer(20.0).timeout
		else:
			await get_tree().create_timer(5.0).timeout
		
		if not target_table:
			break
		
		var could_play = target_table.play_with_client(self)
		
		if not could_play:
			break
		
		if should_leave():
			target_table.remove_player(self)
			queue_free()
			return
		
		elif should_change_table():
			break
	
	if target_table:
		target_table.remove_player(self)
	
	is_seated = false
	target_table = null
	target_seat = null
	
	find_table()

# ====== RANDOM ======
func pick_random_target():
	set_target(Vector2(
		randf_range(200, 800),
		randf_range(200, 900)
	))

# ====== ENTRY ======
func decide_enter_casino():
	if randf() < enter_chance:
		go_to_casino()

# ====== ANIMATION ======
func update_animation():
	var sprite = $AnimatedSprite2D
	
	if is_seated:
		return
	
	if velocity.length() < 5:
		sprite.stop()
		return
	
	if abs(velocity.x) > abs(velocity.y):
		sprite.play("walk_right" if velocity.x > 0 else "walk_left")
	else:
		sprite.play("walk_down" if velocity.y > 0 else "walk_up")

# ====== FACING ======
func face_table():
	var sprite = $AnimatedSprite2D
	
	var dir = (target_table.global_position - global_position).normalized()
	
	if abs(dir.x) > abs(dir.y):
		sprite.play("walk_right" if dir.x > 0 else "walk_left")
	else:
		sprite.play("walk_down" if dir.y > 0 else "walk_up")
	
	sprite.stop()

# ====== LOGIC ======
func should_leave() -> bool:
	return anger > 75.0

func should_change_table() -> bool:
	return anger >= 50.0 and anger <= 75.0
