extends CharacterBody2D

@export var speed = 100
@export var enter_chance = 0.3

var target_position: Vector2
var target_table = null
var target_seat = null
var money = 100
var is_seated = false

# 🔥 NOWE
var on_sidewalk = true
var walking_direction = 1

func _ready():
	randomize()
	
	collision_mask = 0
	

# ====== DEBUG ======
func _draw():
	draw_circle(to_local(target_position), 5, Color.RED)
	draw_circle(Vector2.ZERO, 5, Color.GREEN)

func _physics_process(delta):
	queue_redraw()
	move_to_target()
	update_animation()

# ====== SIDEWALK ======

func start_sidewalk_walk():
	walking_direction = [1, -1].pick_random()
	on_sidewalk = true

func go_to_casino():
	on_sidewalk = false
	find_table()

# ====== MOVEMENT ======

func move_to_target():
	if is_seated:
		return
	
	# 🔥 CHODNIK
	if on_sidewalk:
		velocity = Vector2(0, walking_direction * speed)
		move_and_slide()
		
		# znikanie poza mapą
		if global_position.y < -50 or global_position.y > 1200:
			queue_free()
		
		return
	
	# 🔥 KASYNO
	if target_seat:
		target_position = target_seat.global_position
	
	var direction = target_position - global_position
	
	if direction.length() > 5:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO
		global_position = target_position
		
		if target_table:
			is_seated = true
			face_table()
			try_play()
	
	move_and_slide()

func pick_random_target():
	target_position = Vector2(
		randf_range(0, 800),
		randf_range(0, 600)
	)

# ====== TABLE SYSTEM ======

func set_target_seat(seat, table):
	target_seat = seat
	target_table = table

func find_table():
	var tables = get_tree().get_nodes_in_group("tables")
	
	for table in tables:
		if table.try_add_player(self):
			return
	
	target_table = null
	target_seat = null
	pick_random_target()

func try_play():
	if target_table:
		target_table.play_with_client(self)
		
		is_seated = false
		
		target_table = null
		target_seat = null
		find_table()

# ====== WEJŚCIE DO KASYNA ======

func decide_enter_casino():
	if randf() < enter_chance:
		go_to_casino()

# ====== FACING ======

func face_table():
	var sprite = $AnimatedSprite2D
	
	var dir = (target_table.global_position - global_position).normalized()
	
	if abs(dir.x) > abs(dir.y):
		sprite.play("walk_right" if dir.x > 0 else "walk_left")
	else:
		sprite.play("walk_down" if dir.y > 0 else "walk_up")

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

# ====== EMOTIONS ======

func happy():
	print("😊 klient wygrywa")

func angry():
	print("😡 klient przegrywa")
