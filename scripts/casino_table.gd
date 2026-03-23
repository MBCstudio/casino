extends Node2D

@export var table_type: String = "roulette"
@export var win_probability: float = 0.45
@export var bet: int = 10
@export var max_players: int = 5

var current_players: Array = []
var seats: Array = []
var occupied_seats: Dictionary = {} # client -> seat

func _ready():
	randomize()
	add_to_group("tables")
	
	seats = $Seats.get_children()

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

func play_with_client(client):
	if client.money < bet:
		remove_player(client)
		return
	
	var result = play_game()
	client.money += result
	
	if result > 0:
		if client.has_method("happy"):
			client.happy()
	else:
		if client.has_method("angry"):
			client.angry()
	
	remove_player(client)

# ====== CLICK / UI ======

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		open_table_menu()

func open_table_menu():
	print("Kliknięto stolik:", table_type)
