extends CharacterBody2D

@export var speed = 100
@export var enter_chance = 0.3

@export var money: float = 100.0
@export var base_bet: float = 10.0
@export var status: String = "normal"

@onready var nav_agent = $NavigationAgent2D

var target_position: Vector2
var target_table = null
var target_seat = null
var is_seated = false

# 🔥 NOWE
var on_sidewalk = true
var walking_direction = 1
var risk: float
var addiction: float
var luck: float
var experience: float
var anger: float = 0.0

func _ready():
	randomize()
	
	risk = randf_range(0.0, 0.25)
	addiction = randf_range(0.0, 10.0)
	luck = randf_range(-0.05, 0.05)
	experience = randf_range(0.0, 0.03)
	
	print("Nowy gracz [%s]: 🪙 $%.2f | 🎲 Zakład: $%.2f | ⚠️ Ryzyko: %.2f | 🍷 Uzależnienie: %.2f | 🍀 Szczęście: %.2f | 🧠 Exp: %.2f" % [status, money, base_bet, risk, addiction, luck, experience])

# ====== NAVIGATION HELPER ======
func set_target(pos: Vector2):
	target_position = pos
	nav_agent.target_position = pos

# ====== DEBUG ======
func _draw():
	draw_circle(to_local(target_position), 5, Color.RED)
	draw_circle(Vector2.ZERO, 5, Color.GREEN)

func _physics_process(delta):
	queue_redraw()
	
	# If reached entrance and no table yet → find table
	if not on_sidewalk and nav_agent.is_navigation_finished() and target_table == null:
		find_table()
	
	move_to_target()
	update_animation()

# ====== SIDEWALK ======

func start_sidewalk_walk():
	walking_direction = [1, -1].pick_random()
	on_sidewalk = true

func go_to_casino():
	on_sidewalk = false
	
	# 🔥 IMPORTANT: adjust path to your scene!
	var entrance = get_node("/root/CasinoFloor/CasinoEntrance/EntrancePoint")
	set_target(entrance.global_position)

# ====== MOVEMENT ======

func move_to_target():
	if is_seated:
		return
	
	# 🔥 SIDEWALK (unchanged)
	if on_sidewalk:
		velocity = Vector2(0, walking_direction * speed)
		move_and_slide()
		
		if global_position.y < -50 or global_position.y > 1200:
			queue_free()
		
		return
	
	# 🔥 CASINO NAVIGATION
	
	if target_seat:
		set_target(target_seat.global_position)
	
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		
		if target_table and not is_seated:
			is_seated = true
			face_table()
			try_play()
		
		return
	
	var next_point = nav_agent.get_next_path_position()
	var direction = (next_point - global_position).normalized()
	
	velocity = direction * speed
	move_and_slide()

func pick_random_target():
	set_target(Vector2(
		randf_range(0, 800),
		randf_range(0, 600)
	))

# ====== TABLE SYSTEM ======

func set_target_seat(seat, table):
	target_seat = seat
	target_table = table
	set_target(seat.global_position)

func find_table():
	var tables = get_tree().get_nodes_in_group("tables")
	
	for table in tables:
		if table.try_add_player(self):
			return
	
	target_table = null
	target_seat = null
	pick_random_target()

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
			print("Gracz [%s] nie ma srodków na grę, szuka innej opcji." % status)
			break
			
		if should_leave():
			print("Gracz [%s] jest wściekły (Złość: %.1f) i wychodzi z kasyna!" % [status, anger])
			target_table.remove_player(self)
			queue_free()
			return
		elif should_change_table():
			print("Gracz [%s] zmienia stolik (Złość: %.1f)." % [status, anger])
			break
			
	if target_table:
		target_table.remove_player(self)
		
	is_seated = false
	
	target_table = null
	target_seat = null
	
	find_table()

# ====== ENTRY DECISION ======

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
			
	sprite.stop()

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

# ====== GAMBLING LOGIC ======

func approach_table() -> float:
	var drawn = randf_range(0.0, 1.0)
	var current_bet = base_bet
	if drawn < risk:
		current_bet *= 2.0
	return current_bet

func play_round(win_probability: float) -> bool:
	var final_win_chance = win_probability + luck + experience
	var drawn = randf_range(0.0, 1.0)
	return drawn < final_win_chance

func on_win(bet: float) -> void:
	money += bet
	anger = clamp(anger - 20.0, 0.0, 100.0)

func on_loss(bet: float) -> void:
	money -= bet
	anger = clamp(anger + 20.0 - addiction, 0.0, 100.0)

func should_leave() -> bool:
	return anger > 75.0

func should_change_table() -> bool:
	return anger >= 50.0 and anger <= 75.0
