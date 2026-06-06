extends Node

var money: float = 9950
var prestige: int = 10
var event_prestige_modifier: int = 0
var customers: int = 0
<<<<<<< Updated upstream
var total_customers: int = 0
=======
var total_customers_visited: int = 0
>>>>>>> Stashed changes
var play_time: float = 0.0
var time_multiplier: float = 1.0
var tables_bought: int = 0
var has_won: bool = false
var has_lost: bool = false
var time_since_last_event: float = 0.0
var next_event_time: float = randf_range(120.0, 180.0) # between 2 and 3 minutes
var player_nickname: String = ""
var current_difficulty: String = ""
var event_ui_instance = null
const MUSIC_PLAYLIST := [
	"res://assets/music/Best Relaxing Jazz Classics _ Franks Sinatra , Louis Armstrong, Nat King Cole, Ella Fitzgerald [0_tGe7KNJhU].mp3",
	"res://assets/music/Las Vegas Casino Music Video_ For Night Game of Poker, Blackjack, Roulette Wheel & Slots.mp3",
	"res://assets/music/2010 Throwback DJ Set (Rihanna, Kesha, David Guetta, Taio Cruz, etc.) - DJ MADEINRIKA Debut [u-jcRpOA514].mp3",
]
const UI_OPEN_SOUND_PATH := "res://assets/sounds_effects/litupsubway-ui-close-sfx-513359.mp3"
<<<<<<< Updated upstream
const DEFAULT_MUSIC_VOLUME := 2.0
const DEFAULT_SFX_VOLUME    := 40.0
const UI_OPEN_SOUND_VOLUME_DB := 2.0
=======
const DEFAULT_MUSIC_VOLUME := 5.0
const UI_OPEN_SOUND_VOLUME_DB := 6.0
const STATS_SAMPLE_INTERVAL := 60.0
>>>>>>> Stashed changes

const WIN_CONDITION = 110000#specjalnie żeby gra się za szybko nie kończyła

signal stats_changed
signal game_won
signal game_lost

var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float   = DEFAULT_SFX_VOLUME
var music_vibe_index: int = 0
var _music_player: AudioStreamPlayer
var _ui_open_sound_player: AudioStreamPlayer
var stats_history: Array[Dictionary] = []
var _next_stats_sample_time: float = STATS_SAMPLE_INTERVAL

var possible_events = [
	{
		"title": "Unwanted Protection",
		"rarity": 3,
		"description": "A local mafia boss visits your casino. He offers 'protection' for your business.",
		"choices": [
			{
				"text": "Accept Deal (-$1500)", 
				"outcome": {"money": -1500, "prestige": 0}
			},
			{
				"text": "Decline", 
				"next_event": {
					"title": "Mafia Retaliation!",
					"description": "The boss is insulted. He threatens to send his men to wreck your tables and harass customers. How do you handle it!?",
					"choices": [
						{
							"text": "Pay Him Off (-$3000, -5⭐)",
							"outcome": {"money": -3000, "prestige": -5}
						},
						{
							"text": "Call Police(-40⭐)",
							"outcome": {"money": 0, "prestige": -40}  # Very bad for prestige!
						}
					]
				}
			}
		]
	},
	{
		"title": "A Wealthy VIP Arrives",
		"rarity": 2,
		"description": "A well-known millionaire has entered the casino. They demand special treatment. Do you comp their drinks for $500 to keep them playing?",
		"choices": [
			{"text": "Comp Drinks (-$500, +10⭐)", "outcome": {"money": -500, "prestige": 10}},
			{"text": "Refuse (-2⭐)", "outcome": {"money": 0, "prestige": -2}}
		]
	},
	{
		"title": "Suspicious Activity",
		"rarity": 2,
		"description": "Security noticed a player counting cards at the Blackjack table. What should we do?",
		"choices": [
			{"text": "Kick them out! (-5⭐)", "outcome": {"money": 0, "prestige": -5}},
			{"text": "Let them play (-$1000)", "outcome": {"money": -1000, "prestige": 0}}
		]
	},
	{
		"title": "Maintenance Issue",
		"rarity": 1,
		"description": "A pipe burst near the slot machines. It needs immediate fixing.",
		"choices": [
			{"text": "Call Plumber (-$300)", "outcome": {"money": -300, "prestige": 0}},
			{"text": "Ignore it (-10⭐)", "outcome": {"money": 0, "prestige": -10}}
		]
	},
	{
		"title": "Charity Gala",
		"rarity": 2,
		"description": "You unexpectedly raised extra funds from hosting a local community charity event earlier in the week.",
		"choices": [
			{"text": "Awesome! (+10⭐)", "outcome": {"money": 0, "prestige": 10}}
		]
	},
	{
		"title": "Lucky Streamer (Positive)",
		"rarity": 3,
		"description": "A famous streamer is broadcasting from your casino and bringing in a lot of attention and new players!",
		"choices": [
			{"text": "Sponsor them (-$200, +20⭐)", "outcome": {"money": -200, "prestige": 20}},
			{"text": "Just enjoy it (+$500, +5⭐)", "outcome": {"money": 500, "prestige": 5}}
		]
	},
	{
		"title": "Tax Audit (Negative)",
		"rarity": 2,
		"description": "The tax authorities found a discrepancy in your recent filings. You must pay a penalty fee immediately.",
		"choices": [
			{"text": "Pay Fine (-$1500)", "outcome": {"money": -1500, "prestige": 0}}
		]
	},
	{
		"title": "Bad Press",
		"rarity": 1,
		"description": "A local paper published a nasty review about a rude dealer. Your prestige took a hit.",
		"choices": [
			{"text": "Apologize (-$300, -2⭐)", "outcome": {"money": -300, "prestige": -2}},
			{"text": "Deny it (-5⭐)", "outcome": {"money": 0, "prestige": -5}}
		]
	},
	{
	"title": "High Roller Losing Streak",
	"rarity": 2,
	"description": "A high roller is losing heavily at the blackjack table and getting visibly frustrated.",
	"choices": [
		{
			"text": "Offer Free Chips (-$800, +3⭐)",
			"outcome": {"money": -800, "prestige": 5}
		},
		{
			"text": "Let it play out",
			"next_event": {
				"title": "Public Outburst!",
				"description": "The player starts yelling and scaring other guests.",
				"choices": [
					{
						"text": "Call Security (-5⭐)",
						"outcome": {"money": 0, "prestige": -5}
					},
					{
						"text": "Calm Them Down (-$300)",
						"outcome": {"money": -300, "prestige": 0}
					}
				]
			}
		}
	]
},
{
	"title": "Roulette Table Rumor",
	"rarity": 3,
	"description": "Players are whispering that one roulette table is somehow 'rigged'.",
	"choices": [
		{
			"text": "Inspect Table (-$200, +5⭐)",
			"outcome": {"money": -200, "prestige": 8}
		},
		{
			"text": "Ignore Rumors (-7⭐)",
			"outcome": {"money": 0, "prestige": -7}
		}
	]
},
{
	"title": "Dealer Mistake",
	"rarity": 1,
	"description": "A dealer made a mistake at the blackjack table and a player noticed.",
	"choices": [
		{
			"text": "Refund Player (-$400, +3⭐)",
			"outcome": {"money": -400, "prestige": 3}
		},
		{
			"text": "Deny Responsibility (-8⭐)",
			"outcome": {"money": 0, "prestige": -8}
		}
	]
},
{
	"title": "Power Outage",
	"rarity": 3,
	"description": "Lights suddenly go out near the roulette section.",
	"choices": [
		{
			"text": "Fix Immediately (-$700, +3⭐)",
			"outcome": {"money": -700, "prestige":3}
		},
		{
			"text": "Wait It Out",
			"next_event": {
				"title": "Players Leave...",
				"description": "Guests get annoyed and leave the tables.",
				"choices": [
					{
						"text": "Offer Compensation (-$500, -3⭐)",
						"outcome": {"money": -500, "prestige": -3}
					},
					{
						"text": "Do Nothing (-10⭐)",
						"outcome": {"prestige": -10}
					}
				]
			}
		}
	]
},
{
	"title": "Inspector Visit",
	"rarity": 3,
	"description": "A government inspector walks in to check your blackjack tables.",
	"choices": [
		{
			"text": "Cooperate (-$300, +5⭐)",
			"outcome": {"money": -300, "prestige": 5}
		},
		{
			"text": "Try to Bribe (-$1000)",
			"next_event": {
				"title": "Bribe Backfires!",
				"description": "The inspector is offended and files a report.",
				"choices": [
					{
						"text": "Accept Fine (-$2000, -15⭐)",
						"outcome": {"money": -2000, "prestige": -15}
					}
				]
			}
		}
	]
},
{
	"title": "Employee Wants Raise",
	"rarity": 1,
	"description": "One of your dealers asks for a raise.",
	"choices": [
		{
			"text": "Give Raise (-$500, +2⭐)",
			"outcome": {"money": -500, "prestige": 2}
		},
		{
			"text": "Refuse",
			"next_event": {
				"title": "Dealer Quits",
				"description": "The dealer leaves and service quality drops.",
				"choices": [
					{
						"text": "Hire Replacement (-$1000, -2⭐)",
						"outcome": {"money": -1000, "prestige": -2}
					}
				]
			}
		}
	]
},
{
	"title": "All-In Maniac",
	"rarity": 2,
	"description": "A player at the roulette table keeps betting everything on red every round.",
	"choices": [
		{
			"text": "Let Him Continue",
			"next_event": {
				"title": "Huge Win!",
				"description": "He actually wins big and attracts a crowd!",
				"choices": [
					{
						"text": "Promote This (-$4000,+10⭐)",
						"outcome": {"money": -2000, "prestige": 10}
					},
					{
						"text": "Stay Quiet (+2⭐)",
						"outcome": {"money": 0, "prestige": 2}
					}
				]
			}
		},
		{
			"text": "Limit His Bets (-4⭐)",
			"outcome": {"money": 0, "prestige": -4}
		}
	]
},
{
	"title": "Conspiracy Guy",
	"rarity": 2,
	"description": "A player is loudly explaining that your roulette wheel is controlled by aliens.",
	"choices": [
		{
			"text": "Ignore Him",
			"next_event": {
				"title": "He Gains Followers...",
				"description": "Other players start believing him.",
				"choices": [
					{
						"text": "Kick Them Out (-$300, -4⭐)",
						"outcome": {"money": -300, "prestige": -4}
					},
					{
						"text": "Laugh It Off (+2⭐)",
						"outcome": {"money": 0, "prestige": 2}
					}
				]
			}
		},
		{
			"text": "Escort Him Out (-2⭐)",
			"outcome": {"money": 0, "prestige": -2}
		}
	]
},
{
	"title": "Table Ritual",
	"rarity": 2,
	"description": "A group of players is performing a strange ritual around a roulette table for 'luck'.",
	"choices": [
		{
			"text": "Allow It",
			"next_event": {
				"title": "It Actually Works?!",
				"description": "They start winning and attracting attention.",
				"choices": [
					{
						"text": "Market It (+$1000. -3⭐)",
						"outcome": {"money": 1000, "prestige": -3}
					},
					{
						"text": "Shut It Down",
						"outcome": {"money": 0, "prestige": 0}
					}
				]
			}
		},
		{
			"text": "Stop Them (-3⭐)",
			"outcome": {"money": 0, "prestige": -3}
		}
	]
},
{
	"title": "Drunk Whale at Blackjack",
	"rarity": 2,
	"description": "An extremely drunk high roller is playing blackjack and throwing chips everywhere.",
	"choices": [
		{
			"text": "Let Him Play",
			"next_event": {
				"title": "Chaos at the Table",
				"description": "He accidentally gives chips to other players and demands them back.",
				"choices": [
					{
						"text": "Side With Him (+$500, -5⭐)",
						"outcome": {"money": 500, "prestige": -5}
					},
					{
						"text": "Protect Other Players (-$300, +2⭐)",
						"outcome": {"money": -300, "prestige": 2}
					}
				]
			}
		},
		{
			"text": "Kick Him Out (-7⭐)",
			"outcome": {"money": 0, "prestige": -7}
		}
	]
},
{
	"title": "Suspiciously Lucky Grandma",
	"rarity": 3,
	"description": "An old lady is winning every single roulette spin. Staff is confused.",
	"choices": [
		{
			"text": "Investigate",
			"next_event": {
				"title": "Hidden Earpiece?!",
				"description": "You discover she might be receiving signals from someone.",
				"choices": [
					{
						"text": "Expose Her (+$800)",
						"outcome": {"money": 800, "prestige": 0}
					},
					{
						"text": "Let Her Play (-$1200, +3⭐)",
						"outcome": {"money": -1200, "prestige": 3}
					}
				]
			}
		},
		{
			"text": "Ignore It (-$600)",
			"outcome": {"money": -600, "prestige": 0}
		}
	]
},
]

func _ready():
	add_to_group("game_manager")
	print("GameManager: Initialized with $", money, " (target: $", WIN_CONDITION, ")")
	reset_run_stats()
	_setup_background_music()
	_setup_ui_open_sound()
	
	# Instantiate EventUI
	var event_ui_scene = load("res://scenes/UI/EventUI.tscn")
	if event_ui_scene:
		event_ui_instance = event_ui_scene.instantiate()
		add_child(event_ui_instance)
		event_ui_instance.event_resolved.connect(_on_event_resolved)

func _setup_background_music() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "BackgroundMusic"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)
	_load_current_music()
	set_music_volume(music_volume)

func _setup_ui_open_sound() -> void:
	var stream: AudioStream = load(UI_OPEN_SOUND_PATH)
	if stream == null:
		push_warning("GameManager: Could not load UI open sound: " + UI_OPEN_SOUND_PATH)
		return

	var mp3_stream := stream as AudioStreamMP3
	if mp3_stream:
		mp3_stream.loop = false

	_ui_open_sound_player = AudioStreamPlayer.new()
	_ui_open_sound_player.name = "UiOpenSound"
	_ui_open_sound_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_open_sound_player.stream = stream
	_apply_sfx_volume()
	add_child(_ui_open_sound_player)

func play_ui_open_sound() -> void:
	if _ui_open_sound_player == null:
		return

	_ui_open_sound_player.stop()
	_ui_open_sound_player.play()

func _load_current_music() -> void:
	if _music_player == null or MUSIC_PLAYLIST.is_empty():
		return

	music_vibe_index = wrapi(music_vibe_index, 0, MUSIC_PLAYLIST.size())
	var music_path: String = MUSIC_PLAYLIST[music_vibe_index]
	var stream: AudioStream = load(music_path)
	if stream == null:
		push_warning("GameManager: Could not load background music: " + music_path)
		return

	var mp3_stream := stream as AudioStreamMP3
	if mp3_stream:
		mp3_stream.loop = true

	_music_player.stream = stream
	if music_volume > 0.0:
		_music_player.play()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 100.0)
	if _music_player == null:
		return

	var volume_linear := music_volume / 100.0
	_music_player.volume_db = linear_to_db(maxf(volume_linear, 0.0001))
	_music_player.stream_paused = music_volume <= 0.0

	if music_volume > 0.0 and not _music_player.playing:
		_music_player.play()

func get_music_volume() -> float:
	return music_volume

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 100.0)
	_apply_sfx_volume()

func get_sfx_volume() -> float:
	return sfx_volume

func _apply_sfx_volume() -> void:
	if _ui_open_sound_player == null:
		return
	var linear := sfx_volume / 100.0
	_ui_open_sound_player.volume_db = linear_to_db(maxf(linear, 0.0001)) + UI_OPEN_SOUND_VOLUME_DB

func change_music_vibe(direction: int) -> void:
	set_music_vibe(music_vibe_index + direction)

func set_music_vibe(index: int) -> void:
	music_vibe_index = wrapi(index, 0, MUSIC_PLAYLIST.size())
	_load_current_music()
	set_music_volume(music_volume)

func get_music_vibe_index() -> int:
	return music_vibe_index

func get_music_vibe_count() -> int:
	return MUSIC_PLAYLIST.size()

func add_money(amount):
	money += amount
	print("GameManager: Added $", amount, ", total: $", money)
	emit_signal("stats_changed")
	_check_win_condition()
	_check_lose_condition()

func set_time_multiplier(m: float):
	time_multiplier = m
	print("GameManager: time_multiplier set to", time_multiplier)

func remove_money(amount):
	money -= amount
	emit_signal("stats_changed")
	_check_lose_condition()

func _check_win_condition():
	if money >= WIN_CONDITION and not has_won and not has_lost:
		print("GameManager: WIN CONDITION REACHED! Money: ", money, " Target: ", WIN_CONDITION)
		has_won = true
		record_final_stats_sample()
		LeaderboardManager.add_result(player_nickname, current_difficulty, play_time)
		get_tree().paused = true
		await get_tree().process_frame  # Wait one frame to ensure GameEndUI is ready
		emit_signal("game_won")

func _check_lose_condition():
	if money < 0 and not has_lost and not has_won:
		print("GameManager: LOSE CONDITION REACHED! Money: ", money)
		has_lost = true
		record_final_stats_sample()
		# Use call_deferred so the signal fires AFTER the current call stack
		# finishes (e.g. EventUI calling get_tree().paused = false on line 73
		# of EventUI.gd). show_end_screen() will then re-pause correctly.
		emit_signal.call_deferred("game_lost")

func add_customer():
	customers += 1
<<<<<<< Updated upstream
	total_customers += 1
=======
	total_customers_visited += 1
>>>>>>> Stashed changes
	emit_signal("stats_changed")

func remove_customer():
	customers -= 1
	emit_signal("stats_changed")

func get_total_prestige() -> int:
	var total = 0
	for table in get_tree().get_nodes_in_group("tables"):
		if table.has_method("get_prestige"):
			total += table.get_prestige()
	for cashier in get_tree().get_nodes_in_group("cashier"):
		if "prestige" in cashier:
			total += cashier.prestige
	return total + event_prestige_modifier

func count_tables() -> int:
	return get_tree().get_nodes_in_group("tables").size()

func update_global_prestige():
	prestige = get_total_prestige()
	emit_signal("stats_changed")

func change_reputation(amount):
	event_prestige_modifier += amount
	update_global_prestige()

func _process(delta):
	if not get_tree().paused and not has_won and not has_lost:
		if stats_history.is_empty():
			record_stats_sample()
		play_time += delta
		time_since_last_event += delta
		while play_time >= _next_stats_sample_time:
			record_stats_sample(_next_stats_sample_time)
			_next_stats_sample_time += STATS_SAMPLE_INTERVAL
		
		# Check if it's time for an event
		if time_since_last_event >= next_event_time:
			time_since_last_event = 0.0
			next_event_time = randf_range(120.0, 180.0) # Randomize next time (between 2 and 3 minutes)
			_trigger_random_event()

func _trigger_random_event():
	if possible_events.size() > 0 and event_ui_instance != null:
		var roll = randf() # Returns a value between 0.0 and 1.0
		var target_rarity = 1
		
		# 50% chance for rarity 1, 30% for rarity 2, 20% for rarity 3
		if roll < 0.20:
			target_rarity = 3
		elif roll < 0.50: # 0.20 + 0.30
			target_rarity = 2
		else:
			target_rarity = 1
			
		# Filter events by the selected rarity
		var filtered_events = []
		for e in possible_events:
			if e.has("rarity") and e["rarity"] == target_rarity:
				filtered_events.append(e)
				
		# Fallback mathematically just in case a tier has no events
		if filtered_events.size() == 0:
			filtered_events = possible_events
			
		# Pick a random event from the appropriate rarity pool
		var event = filtered_events[randi() % filtered_events.size()]
		event_ui_instance.show_event(event)

func _on_event_resolved(outcome: Dictionary):
	if outcome.has("money"):
		add_money(outcome["money"])
	if outcome.has("prestige"):
		change_reputation(outcome["prestige"])

func reset_run_stats() -> void:
	stats_history.clear()
	total_customers_visited = 0
	_next_stats_sample_time = STATS_SAMPLE_INTERVAL

func sync_next_stats_sample_time() -> void:
	var completed_intervals: float = floor(play_time / STATS_SAMPLE_INTERVAL)
	_next_stats_sample_time = (completed_intervals + 1.0) * STATS_SAMPLE_INTERVAL

func record_stats_sample(sample_time: float = -1.0) -> void:
	var time_value: float = play_time if sample_time < 0.0 else sample_time
	if not stats_history.is_empty():
		var last_sample: Dictionary = stats_history[stats_history.size() - 1]
		if abs(float(last_sample.get("time", -9999.0)) - time_value) < 0.01:
			last_sample["money"] = money
			last_sample["prestige"] = get_total_prestige()
			last_sample["total_customers"] = total_customers_visited
			stats_history[stats_history.size() - 1] = last_sample
			return

	stats_history.append({
		"time": time_value,
		"money": money,
		"prestige": get_total_prestige(),
		"total_customers": total_customers_visited,
	})

func record_final_stats_sample() -> void:
	record_stats_sample(play_time)
