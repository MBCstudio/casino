extends CharacterBody2D

@export var speed = 100

@export var money: float = 100.0
@export var base_bet: float = 10.0
@export var status: String = "normal"

var target_position: Vector2
var target_table = null
var target_seat = null
var is_seated = false

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
	# Gracz gra przy stole dopóki ma pieniądze, nie rozzłości się wystarczająco i nie zechce zmienić stołu
	while target_table != null:
		if target_table.table_type == "roulette":
			await get_tree().create_timer(20.0).timeout
		else:
			await get_tree().create_timer(5.0).timeout # opóźnienie dla innych gier jeśli są
			
		# Sprawdzenie zabezpieczające, gdyby w międzyczasie stracił dostęp do stołu
		if not target_table:
			break
			
		var could_play = target_table.play_with_client(self)
		
		# Brak wystarczających środków na grę
		if not could_play:
			print("Gracz [%s] nie ma srodków na grę, szuka innej opcji." % status)
			break
			
		# Decyzje po rozegranej rundzie:
		if should_leave():
			print("Gracz [%s] jest wściekły (Złość: %.1f) i wychodzi z kasyna!" % [status, anger])
			target_table.remove_player(self)
			queue_free() # Gracz usuwany jest z gry (wychodzi)
			return
		elif should_change_table():
			print("Gracz [%s] zmienia stolik (Złość: %.1f)." % [status, anger])
			break
			
	# Zakończył partię gier na tym stole
	if target_table:
		target_table.remove_player(self)
		
	is_seated = false   # 🔥 reset
	
	target_table = null
	target_seat = null
	
	# Szuka następnego stołu
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
			
	sprite.stop() # Zatrzymuje animację, aby klient stał zamiast przebierać nogami

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
