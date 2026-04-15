extends Node2D

@export var table_type: String = "roulette"
@export var win_probability: float = 0.5#im to mniejsze to kasyno więcej zarabia
@export var base_win_probability: float = 0.50#na samym poczatku przy inicjalizacji
@export var bet: int = 10
@export var max_players: int = 5
@export var play_time: float = 10.0
@export var vip_chance_bonus: float = 0.0

var prestige: int = 5
var has_felt: bool = false
var has_led: bool = false
var has_chip_rack: bool = false
var has_vip_seats: bool = false
var has_spinner: bool = false
var has_drinks: bool = false

var current_players: Array = []
var seats: Array = []
var occupied_seats: Dictionary = {} # client -> seat

func _ready():
	randomize()
	add_to_group("tables")
	
	if "input_pickable" in self:
		set("input_pickable", true)
	
	seats = $Seats.get_children()
	
	# Inicjalizujemy bazowe prestige od razu
	update_prestige()

# ====== GAME LOGIC ======

func play_game() -> int:
	match table_type:
		"roulette":
			return play_roulette()
		"blackjack":
			return play_blackjack()
		_:
			return 0

func play_roulette() -> int:
	var roll = randf()
	return bet * 2 if roll < win_probability else -bet

func play_blackjack() -> int:
	var roll = randf()
	return bet if roll < win_probability else -bet
	

# ====== CLIENT SYSTEM ======

func try_add_player(client) -> bool:
	if current_players.size() >= max_players:
		return false
	
	var free_seat = get_free_seat()
	if free_seat == null:
		return false
	
	current_players.append(client)
	occupied_seats[client] = free_seat
	
	client.set_target_seat(free_seat, self)
	return true

func get_free_seat():
	for seat in seats:
		if seat not in occupied_seats.values():
			return seat
	return null

func remove_player(client):
	current_players.erase(client)
	occupied_seats.erase(client)

func has_space() -> bool:
	return current_players.size() < max_players

func play_with_client(client) -> bool:
	var current_bet = client.approach_table()
	
	if client.money < current_bet:
		return false
	
	var is_win = client.play_round(win_probability)
	
	if is_win:
		client.on_win(current_bet)
		
		# 🔥 kasyno przegrywa
		GameManager.remove_money(current_bet)
		
		if client.has_method("happy"):
			client.happy()
			
	else:
		client.on_loss(current_bet)
		
		# 🔥 kasyno zarabia
		GameManager.add_money(current_bet)
		
		if client.has_method("angry"):
			client.angry()
	
	return true

# ====== CLICK / UI ======

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		open_table_menu()

func open_table_menu():
	get_tree().paused = true
	
	var ui = get_tree().get_first_node_in_group("table_ui")
	
	if ui:
		ui.open(self)
	else:
		print("TableUI not found!")
	
# ====== Prestige ========
func get_prestige():
	return prestige

var prestige_bonus: int = 0

func add_prestige_bonus(amount: int):
	prestige_bonus += amount
	update_prestige()

func update_prestige():
	# win_probability typically ranges from 0.45 to 0.55
	# Middle point is 0.50 -> 0 prestige change.
	# 0.45 -> +20 prestige
	# 0.55 -> -20 prestige
	var diff = win_probability - 0.50
	var base_prestige = 5
	var calculated_prestige = base_prestige + int(diff * 100 * 4) + prestige_bonus
	prestige = calculated_prestige
	
	if GameManager.has_method("update_global_prestige"):
		GameManager.update_global_prestige()
