extends CharacterBody2D

@export var speed = 100
@export var enter_chance = 1.0

@export var wait_time_cashier: float = 5.0
@export var wait_time_table: float = 10.0

@export var money: float = 100.0
@export var base_bet: float = 10.0
@export var status: String = "normal"

@onready var nav_agent = $NavigationAgent2D

var target_position: Vector2
var target_table = null
var target_seat = null
var is_seated = false

# Tablica trasy punkt po punkcie (waypointy) zastępująca skomplikowane flagi
var waypoints: Array[Vector2] = []

var counted_as_customer = false
var has_visited_cashier = false
var is_in_cashier_queue = false
var is_waiting = false
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
	add_to_group("customers")
	
	risk = randf_range(0.0, 0.25)
	addiction = randf_range(0.0, 10.0)
	luck = randf_range(-0.05, 0.05)
	experience = randf_range(0.0, 0.03)

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
	
	move_to_target()
	update_animation()

func _exit_tree():
	if counted_as_customer and is_instance_valid(GameManager):
		GameManager.remove_customer()

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
		counted_as_customer = true
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
	
	counted_as_customer = true
	GameManager.add_customer()
	
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
	if is_seated or is_waiting:
		return
	
	# SIDEWALK (unchanged)
	if on_sidewalk:
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
			var c_pos = cashier_node.global_position
			
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
				velocity = Vector2.ZERO
				$AnimatedSprite2D.stop() # Przerywa animację ("w miejscu")
				
				# Ktoś staje się pierwszym w kolejce i dochodzi do samej kasy
				if people_ahead == 0 and global_position.distance_to(c_pos) < 30.0:
					if not has_visited_cashier and not is_waiting:
						wait_at_cashier()
				
				return # Zatrzymaj dalsze przesunięcia
				
	# WAYPOINTS DRIVEN CASINO NAVIGATION
	
	if waypoints.size() > 0:
		var current_wp = waypoints[0]
		
		# Sprawdzanie czy osiągnął obecny waypoint (bardzo mały zasięg, żeby nie ścinał kątów)
		if global_position.distance_to(current_wp) < 5.0:
			waypoints.pop_front()
			
			if waypoints.size() == 0:
				# Koniec trasy do stołu: siadamy!
				velocity = Vector2.ZERO
				if target_table and not is_seated:
					is_seated = true
					face_table()
					try_play()
				elif target_table == null and not is_waiting:
					wait_at_random_place()
			return
			
		# Poruszamy się dokładnie i wyłącznie pod kątem prostym do waypointów
		var direction = (current_wp - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		return
			
	elif target_table == null and nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		if not is_waiting:
			wait_at_random_place()
		return
	
	var next_point = nav_agent.get_next_path_position()
	var direction = (next_point - global_position).normalized()
	
	velocity = direction * speed
	move_and_slide()

func pick_random_target():
	waypoints.clear()
	set_target(Vector2(
		randf_range(0, 800),
		randf_range(0, 600)
	))

# ====== TABLE SYSTEM ======
func set_target_seat(seat, table):
	target_seat = seat
	target_table = table
	waypoints.clear()
	
	# Obliczenie osi
	var dir = (seat.global_position - table.global_position).normalized()
	var axis_dir = Vector2.ZERO
	if abs(dir.x) > abs(dir.y):
		axis_dir.x = sign(dir.x)
	else:
		axis_dir.y = sign(dir.y)

	var approach_spot = seat.global_position + axis_dir * 150.0
	
	# --- NOWY SYSTEM (OD KASY: Omijamy od góry/środka/dołu i wjeżdżamy na długi DYWAN) ---
	# Stałe współrzędne świata dla autostrad i omijania kasy (Dostosowane do 1920x1080)
	var CASHIER_LEFT_X = 304.0
	var CASHIER_RIGHT_X = 432.0
	var HIGHWAY_TOP_Y = 128.0
	var HIGHWAY_BOTTOM_Y = 944.0
	var MAP_CENTER_Y = 544.0
	
	# Jeżeli jesteśmy blisko kasy (np X < 600, powiększone dla rozdzielczości 1920)
	if has_visited_cashier and global_position.x < 600:
		# Domyslna autostrada w zależności gdzie stoi stół (góra czy dół planszy)
		var y_highway = HIGHWAY_BOTTOM_Y
		if table.global_position.y < MAP_CENTER_Y:
			y_highway = HIGHWAY_TOP_Y
			
		# WYMUSZENIE ŚRODKOWEGO DYWANU DLA OKREŚLONYCH MIEJSC:
		var s_name = str(seat.name)
		var is_seat_1_or_2 = ("1" in s_name) or ("2" in s_name) or (seat.get_index() in [0, 1])
		var is_seat_4_or_5 = ("4" in s_name) or ("5" in s_name) or (seat.get_index() in [3, 4])
		
		# Jeśli krzesło 1/2 u góry albo krzesło 4/5 na dole - nadpisz dywan docelowy na środek
		if table.global_position.y < MAP_CENTER_Y and is_seat_1_or_2:
			y_highway = MAP_CENTER_Y
		elif table.global_position.y > MAP_CENTER_Y and is_seat_4_or_5:
			y_highway = MAP_CENTER_Y

		# y_bypass: żeby wyminąć kasę bez schodzenia na sam skraj ekranu (HIGHWAY_TOP/BOTTOM),
		# wychylamy się od kasy po prostu lekko w osi Y (tak jak w oryginalnym skrypcie).
		var y_bypass = HIGHWAY_BOTTOM_Y
		if y_highway == MAP_CENTER_Y:
			# Jeżeli docelowo idziemy na środek, wyminięcie kasy to lekki dół lub góra względem jej pozycji
			var offset_y = 170.0
			if table.global_position.y < MAP_CENTER_Y:
				offset_y = -170.0
			y_bypass = global_position.y + offset_y
		else:
			# Jeżeli idziemy na boczny dywan, omijamy kasę prosto idąc na tę autostradę!
			y_bypass = y_highway
		
		# 1 KROK: Przejście do korytarza na lewo od kasy
		waypoints.append(Vector2(CASHIER_LEFT_X, global_position.y))
		
		# 2 KROK: Marsz w górę/dół rzędu kasy do objazdu bocznego (na y_bypass)
		waypoints.append(Vector2(CASHIER_LEFT_X, y_bypass))
		
		# 3 KROK: Przeprawa przez ominięcie lady o prawy bok (CASHIER_RIGHT)
		waypoints.append(Vector2(CASHIER_RIGHT_X, y_bypass))
		
		# 4 KROK: Tuż za kasą schodzimy docelowo na MAP_CENTER_Y (lub po prostu na swój dywan autostrady)
		if y_highway != y_bypass:
			waypoints.append(Vector2(CASHIER_RIGHT_X, y_highway))
		
		# 5 KROK: Podążamy długim, właściwym dywanem w pobliże x krzeseł
		waypoints.append(Vector2(approach_spot.x, y_highway))

	
	else:
		# Przechodzenie Pomiędzy Stołami -> schodzimy z krzesła na jego ścieżkę 
		var y_highway = approach_spot.y
		if axis_dir.x != 0: # Jeżeli stół ma krzesła na prawo/lewo, bierzemy Y samego krzesła
			y_highway = seat.global_position.y
		
		# Robimy krok do tyłu, idziemy do autostrady Y
		waypoints.append(global_position + Vector2(0, 100))
		waypoints.append(Vector2(global_position.x, y_highway))
		waypoints.append(Vector2(approach_spot.x, y_highway))

	# Zakończenie
	waypoints.append(approach_spot)
	waypoints.append(seat.global_position)
	
	if waypoints.size() > 0:
		set_target(waypoints[0])
		
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
func should_leave() -> bool:
	return anger > 75.0

func should_change_table() -> bool:
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
