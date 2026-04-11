extends CharacterBody2D

@export var speed = 100
@export var enter_chance = 0.75

@export var wait_time_cashier: float = 5.0
@export var wait_time_table: float = 15.0

@export var money: float = 100.0
@export var base_bet: float = 10.0
@export var status: String = "normal"

@onready var nav_agent = $NavigationAgent2D

var target_position: Vector2
var target_table = null
var target_seat = null
var is_seated = false

var has_visited_cashier = false
var is_in_cashier_queue = false
var is_waiting = false
var on_sidewalk = true
var walking_direction = 1
var is_moving = false

var is_going_to_cashier = false
var is_waiting_at_cashier = false
var is_going_to_seat = false
var is_going_to_bar = false
var is_leaving_casino = false

# ====== ANTI-STUCK ======
var last_stuck_pos: Vector2
var stuck_check_timer: float = 0.0
var is_recovering: bool = false
var recovery_timer: float = 0.0
var recovery_dir: Vector2

# ====== STATS ======
var risk: float
var addiction: float
var luck: float
var experience: float
var anger: float = 0.0

# ====== INIT ======
func _ready():
	randomize()
	add_to_group("customers")
	
	risk = randf_range(0.0, 0.25)
	addiction = randf_range(0.0, 10.0)
	luck = randf_range(-0.05, 0.05)
	experience = randf_range(0.0, 0.03)

	# Podłączenie sygnału omijania z NavigationAgent2D
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	nav_agent.max_speed = speed * 1.0
	
	# Większa tolerancja na zaliczanie punktów ścieżki (zapobiega blokowaniu na rogach)
	nav_agent.path_desired_distance = 25.0
	nav_agent.target_desired_distance = 15.0

# ====== NAVIGATION ======
func set_target(pos: Vector2):
	target_position = pos
	nav_agent.target_position = pos

# ====== DEBUG ======
func _draw():
	if target_position != Vector2.ZERO:
		# Grubsza, bardziej widoczna czerwona kropka wskazująca cel
		draw_circle(to_local(target_position), 5, Color.RED)
	draw_circle(Vector2.ZERO, 5, Color.GREEN)

# ====== MAIN LOOP ======
func _physics_process(delta):
	queue_redraw()
	
	# === ANTI-STUCK SYSTEM ===
	if is_moving and not is_waiting and not is_seated and not on_sidewalk and not is_in_cashier_queue:
		if is_recovering:
			recovery_timer -= delta
			if recovery_timer <= 0:
				is_recovering = false
		else:
			stuck_check_timer += delta
			if stuck_check_timer >= 2.5: # Sprawdzaj co 2.5 sekundy
				if global_position.distance_to(last_stuck_pos) < 20.0:
					is_recovering = true
					recovery_timer = 1.2 # Obejście przeszkody potrwa około 1 sekundę
					var to_target = (target_position - global_position).normalized()
					# Wektor obrócony o 90 do 270 stopni (idzie ostro w bok lub się cofa)
					var angle = randf_range(90, 270)
					recovery_dir = to_target.rotated(deg_to_rad(angle))
				last_stuck_pos = global_position
				stuck_check_timer = 0.0
	
	move_to_target()
	update_animation()

# ====== SIDEWALK ======
func go_to_casino():
	on_sidewalk = false
	is_in_cashier_queue = true
	find_cashier()

# ====== CASHIER ======
func find_cashier():
	var cashiers = get_tree().get_nodes_in_group("cashier")
	
	if cashiers.size() > 0:
		set_target(cashiers[0].global_position)
	else:
		has_visited_cashier = true
		# dodanie klienta do UI
		GameManager.add_customer()
		find_table()

func wait_at_cashier():
	has_visited_cashier = true
	is_waiting = true
	
	await get_tree().create_timer(wait_time_cashier).timeout
	

	# Czekamy przy kasie aż zwolni się jakieś miejsce przy stolikach (jeśli kasyno jest pełne)
	while _get_free_play_spots() <= 0:
		await get_tree().create_timer(1.0).timeout
	
	is_waiting = false
	is_in_cashier_queue = false
	
	find_table()
	
	# Zablokowanie ruchu kolejki na 1 sekundę by gracz na spokojnie uciekł
	var cashiers = get_tree().get_nodes_in_group("cashier")
	if cashiers.size() > 0:
		cashiers[0].set_meta("queue_cooldown", Time.get_ticks_msec() + 1000)

func _get_free_play_spots() -> int:
	var total_seats = 0
	for t in get_tree().get_nodes_in_group("tables"):
		total_seats += t.max_players
	
	var in_casino_playing = 0
	for c in get_tree().get_nodes_in_group("customers"):
		if not c.on_sidewalk and not c.is_in_cashier_queue:
			in_casino_playing += 1
			
	return total_seats - in_casino_playing

func wait_at_random_place():
	is_waiting = true
	try_face_target(target_position)
	
	var wait_t = randf_range(10.0, 15.0)
	await get_tree().create_timer(wait_t).timeout
	
	is_waiting = false
	
	find_table()

# ====== MOVEMENT ======
func move_to_target():
	is_moving = false
	
	if is_seated or is_waiting:
		nav_agent.avoidance_priority = 1.0 # Jesteśmy stojącą ("ciężką") przeszkodą
		nav_agent.radius = 10.0 # "Kurczymy się" w oczach RVO, by nie odpychać innych w ciasnocie
		nav_agent.set_velocity(Vector2.ZERO)
		return
	
	# SIDEWALK (unchanged)
	if on_sidewalk:
		is_moving = true
		velocity = Vector2(0, walking_direction * speed)
		move_and_slide()
		
		if global_position.y < -50 or global_position.y > 1200:
			queue_free()
		return
	
	# CASINO NAVIGATION
	
	if is_in_cashier_queue:
		var cashiers = get_tree().get_nodes_in_group("cashier")
		if cashiers.size() > 0:
			var cashier_node = cashiers[0]
			var c_pos = cashier_node.get_node("CashierDeskPoint").global_position

			
			# Oblicz ile osób stoi w kolejce przed tą osobą
			var my_dist = global_position.distance_squared_to(c_pos)
			var people_ahead = 0
			for c in get_tree().get_nodes_in_group("customers"):
				if c != self and "is_in_cashier_queue" in c and c.is_in_cashier_queue:
					if c.global_position.distance_squared_to(c_pos) < my_dist:
						people_ahead += 1
						
			# Czekamy 1s zanim przeskoczymy na miejsce osoby która właśnie opuściła kasę
			var cooldown = cashier_node.get_meta("queue_cooldown", 0)
			if Time.get_ticks_msec() < cooldown:
				people_ahead += 1
			
			# Ustaw się w szyku (oddalając się od kasy w osi X w lewo)
			# Zwiększony odstęp z 60.0 na 80.0 px
			var queue_spacing = 50.0
			var target_spot = c_pos + Vector2(-people_ahead * queue_spacing, 0)
			set_target(target_spot)
			
			# Jeśli postać dotarła na swoje miejsce w kolejce
			if global_position.distance_to(target_spot) < 15.0:
				nav_agent.avoidance_priority = 1.0
				nav_agent.radius = 10.0 # Mniejsza strefa RVO w kolejce
				nav_agent.set_velocity(Vector2.ZERO)
				$AnimatedSprite2D.stop() # Przerywa animację ("w miejscu")				try_face_target(c_pos) # Obróć postać przodem do kasy				
				# Ktoś staje się pierwszym w kolejce i dochodzi do samej kasy
				if people_ahead == 0 and global_position.distance_to(c_pos) < 30.0:
					if not has_visited_cashier and not is_waiting:
						wait_at_cashier()
				
				return # Zatrzymaj dalsze przesunięcia
				
	# AUTOMATIC CASINO NAVIGATION (Z użyciem NavigationObstacle2D)
	if nav_agent.is_navigation_finished():
		nav_agent.avoidance_priority = 1.0
		nav_agent.radius = 15.0 # Mniejsza strefa po dotarciu do celu
		nav_agent.set_velocity(Vector2.ZERO)
		if not is_waiting:
			if is_leaving_casino:
				queue_free()
			elif is_going_to_bar:
				wait_at_bar()
			elif target_table != null and not is_seated:
				is_seated = true
				face_table()
				try_play()
			elif target_table == null:
				wait_at_random_place()
		return
	
	is_moving = true
	nav_agent.avoidance_priority = 0.5 # Idące postacie mają mniejszy priorytet – muszą ustępować stojącym
	nav_agent.radius = 30.0 # Wracamy do pełnej strefy omijania na czas wędrówki
	
	var next_point = nav_agent.get_next_path_position()
	var direction = (next_point - global_position).normalized()
	
	# Zamiast od razu stosować prędkość, wysyłamy ją do agenta, by obliczył omijanie
	var intended_velocity = direction * speed
	
	# Odblokowywanie jeśli mechanizm w _physics_process to wymusił
	if is_recovering:
		# Ignorujemy główny kierunek i odpychamy postać wektorem odzyskiwania
		intended_velocity = recovery_dir * speed
	
	nav_agent.set_velocity(intended_velocity)

func pick_random_target():
	set_target(Vector2(
		randf_range(0, 800),
		randf_range(0, 600)
	))

# ====== TABLE SYSTEM ======
func set_target_seat(seat, table):
	target_seat = seat
	target_table = table
	
	# Teraz nie ręcznie ustalamy trasy - NavigationAgent sam omija kasy i meble!
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
		await get_tree().create_timer(wait_time_table).timeout
			
		if not target_table:
			break
		
		var could_play = target_table.play_with_client(self)
		
		if not could_play:
			# Brak pieniędzy lub inny powód braku możliwości gry też może złościć / zmuszać do wyjścia
			if should_leave():
				target_table.remove_player(self)
				go_to_exit()
				return
			elif should_go_to_bar():
				target_table.remove_player(self)
				go_to_bar()
				return
			break
		
		if should_leave():
			target_table.remove_player(self)
			go_to_exit()
			return
		
		elif should_go_to_bar():
			target_table.remove_player(self)
			go_to_bar()
			return
	
	if target_table:
		target_table.remove_player(self)
		
	is_seated = false
	target_table = null
	target_seat = null
	
	if should_leave():
		go_to_exit()
	elif should_go_to_bar():
		go_to_bar()
	else:
		find_table()

# ====== ENTRY ======
func decide_enter_casino():
	if randf() < enter_chance:
		# Ile osób max przy stołach
		var total_seats = 0
		for t in get_tree().get_nodes_in_group("tables"):
			total_seats += t.max_players
			
		# Obliczamy ile osób już gra LUB szuka stolika
		var in_casino_playing = 0
		var queue_count = 0
		
		for c in get_tree().get_nodes_in_group("customers"):
			if not c.on_sidewalk:
				if "is_in_cashier_queue" in c and c.is_in_cashier_queue:
					queue_count += 1
				else:
					in_casino_playing += 1
					
		# Wpuszczamy z chodnika jeżeli kolejka przy kasie ma miejsce (max 5)
		# Tzn. chlejąc że nie wpuścimy jeśli total capacity + te 5 miejsc do kasy by się przebiło
		if queue_count < 5:
			go_to_casino()
		else:
			print("Kolejka pełna (5). Gracz [%s] odpuszcza wejście (Gra: %d/%d)." % [status, in_casino_playing, total_seats])

# ====== FACING ======

func try_face_target(target_pos: Vector2):
	var sprite = $AnimatedSprite2D
	var dir = (target_pos - global_position).normalized()
	
	# Zabezpieczenie przed dziwnymi kątami - faworyzujemy pion/poziom
	if abs(dir.x) > abs(dir.y):
		sprite.play("walk_right" if dir.x > 0 else "walk_left")
	else:
		sprite.play("walk_down" if dir.y > 0 else "walk_up")
			
	sprite.stop()

func face_table():
	if target_table:
		try_face_target(target_table.global_position)

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

# ====== LOGIC ======
func go_to_exit():
	is_seated = false
	target_table = null
	target_seat = null
	is_leaving_casino = true
	
	var exits = get_tree().get_nodes_in_group("exits")
	if exits.size() > 0:
		# Pobieramy pozycję ze Sprite2D, ponieważ główny węzeł Exit (Area2D) ma pozycję (0,0) na wejściu
		var exit_pos = exits[0].get_node("Sprite2D").global_position if exits[0].has_node("Sprite2D") else exits[0].global_position
		set_target(exit_pos)
	

func go_to_bar():
	is_seated = false
	target_table = null
	target_seat = null
	
	var bars = get_tree().get_nodes_in_group("bars")
	if bars.size() > 0:
		var customers_at_bar = 0
		for c in get_tree().get_nodes_in_group("customers"):
			if c.get("is_going_to_bar"):
				customers_at_bar += 1
				
		if customers_at_bar > 4:
			go_to_exit()
		else:
			is_going_to_bar = true
			set_target(bars[0].global_position + Vector2(randf_range(-40, 40), randf_range(20, 60)))
	else:
		go_to_exit()

func wait_at_bar():
	is_waiting = true
	# Możesz dodać animację stania obróconego do baru
	var wait_t = randf_range(10.0, 15.0)
	await get_tree().create_timer(wait_t).timeout
	
	anger = 0.0 # reset anger po wypiciu drinka
	is_waiting = false
	is_going_to_bar = false
	
	find_table()

func should_leave() -> bool:
	return anger > 75.0

func should_go_to_bar() -> bool:
	return anger >= 50.0 and anger <= 75.0

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

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if not is_moving:
		# Zabezpieczenie przed "własnym drżeniem" w symulacji fizyki.
		# Skoro my chcemy stać na sztywno, ignorujemy sygnały mikro-odepchnięcia.
		safe_velocity = Vector2.ZERO
		
	velocity = safe_velocity
	move_and_slide()
