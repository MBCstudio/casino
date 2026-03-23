extends CharacterBody2D

@export var speed = 100

var target_position: Vector2
var target_table = null
var target_seat = null
var money = 100
var is_seated = false

func _ready():
	randomize()
	
	# 🔥 disable collisions with other customers
	collision_mask = 0
	
	find_table()

# ====== DEBUG ======
func _draw():
	draw_circle(to_local(target_position), 5, Color.RED)
	draw_circle(Vector2.ZERO, 5, Color.GREEN)

func _physics_process(delta):
	queue_redraw()
	move_to_target()
	update_animation()

# ====== MOVEMENT ======

func move_to_target():
	if is_seated:
		return
	
	if target_seat:
		target_position = target_seat.global_position
	
	var direction = target_position - global_position
	
	if direction.length() > 2:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO
		global_position = target_position
		
		if target_table:
			is_seated = true   # 🔥 IMPORTANT
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
	
	# no table available
	target_table = null
	target_seat = null
	pick_random_target()

func try_play():
	if target_table:
		target_table.play_with_client(self)
		
		is_seated = false   # 🔥 reset
		
		target_table = null
		target_seat = null
		find_table()

# ====== FACING SYSTEM ======

func face_table():
	var sprite = $AnimatedSprite2D
	
	var dir = (target_table.global_position - global_position).normalized()
	
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			sprite.play("walk_right")
		else:
			sprite.play("walk_left")
	else:
		if dir.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")

# ====== ANIMATION ======

func update_animation():
	var sprite = $AnimatedSprite2D
	
	# if seated → DO NOTHING (keep last frame)
	if is_seated:
		return
	
	if velocity.length() < 5:
		sprite.stop()
		return
	
	if abs(velocity.x) > abs(velocity.y):
		if velocity.x > 0:
			sprite.play("walk_right")
		else:
			sprite.play("walk_left")
	else:
		if velocity.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")

# ====== EMOTIONS ======

func happy():
	print("😊 klient wygrywa")

func angry():
	print("😡 klient przegrywa")
