extends Node

const LEADERBOARD_PATH: String = "user://leaderboard.json"
const MAX_ENTRIES_PER_DIFFICULTY: int = 20
const DIFFICULTIES: Array[String] = ["easy", "medium", "hard"]

var entries_by_difficulty: Dictionary = {}

func _ready() -> void:
	_load()

func add_result(player_name: String, difficulty: String, finish_time: float) -> void:
	var clean_difficulty: String = difficulty.to_lower()
	if not DIFFICULTIES.has(clean_difficulty):
		return

	var clean_name: String = player_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Player"

	var entries: Array = entries_by_difficulty.get(clean_difficulty, [])
	entries.append({
		"name": clean_name,
		"time": finish_time,
		"finished_at": Time.get_datetime_string_from_system(),
	})
	entries.sort_custom(_sort_by_time)
	if entries.size() > MAX_ENTRIES_PER_DIFFICULTY:
		entries.resize(MAX_ENTRIES_PER_DIFFICULTY)

	entries_by_difficulty[clean_difficulty] = entries
	_save()

func get_entries(difficulty: String, limit: int = 5) -> Array:
	var clean_difficulty: String = difficulty.to_lower()
	var entries: Array = entries_by_difficulty.get(clean_difficulty, [])
	return entries.slice(0, mini(limit, entries.size()))

func get_best_time_text(difficulty: String) -> String:
	var entries: Array = get_entries(difficulty, 1)
	if entries.is_empty():
		return "--:--"
	return format_time(float(entries[0].get("time", 0.0)))

func format_time(seconds_value: float) -> String:
	var total_seconds: int = max(0, int(round(seconds_value)))
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func _load() -> void:
	_init_default_entries()

	if not FileAccess.file_exists(LEADERBOARD_PATH):
		_save()
		return

	var file: FileAccess = FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return

	for difficulty in DIFFICULTIES:
		if not parsed.has(difficulty) or not parsed[difficulty] is Array:
			continue

		var clean_entries: Array = []
		for entry in parsed[difficulty]:
			if entry is Dictionary and entry.has("name") and entry.has("time"):
				var finished_at: String = str(entry.get("finished_at", ""))
				var entry_name: String = str(entry.get("name", "Player"))
				clean_entries.append({
					"name": _migrate_default_name(entry_name) if finished_at.is_empty() else entry_name,
					"time": float(entry.get("time", 0.0)),
					"finished_at": finished_at,
				})
		clean_entries.sort_custom(_sort_by_time)
		entries_by_difficulty[difficulty] = clean_entries.slice(0, mini(MAX_ENTRIES_PER_DIFFICULTY, clean_entries.size()))

func _save() -> void:
	var file: FileAccess = FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("LeaderboardManager: Cannot save leaderboard to " + LEADERBOARD_PATH)
		return

	file.store_string(JSON.stringify(entries_by_difficulty, "\t"))
	file.close()

func _init_default_entries() -> void:
	entries_by_difficulty = {
		"easy": [
			{"name": "CasinoMaster", "time": 1260.0, "finished_at": ""},
			{"name": "Menago1", "time": 1680.0, "finished_at": ""},
			{"name": "ChipBoss", "time": 2100.0, "finished_at": ""},
		],
		"medium": [
			{"name": "RoulettePro", "time": 1980.0, "finished_at": ""},
			{"name": "KasynoKing", "time": 2520.0, "finished_at": ""},
			{"name": "TableTycoon", "time": 3180.0, "finished_at": ""},
		],
		"hard": [
			{"name": "VegasShark", "time": 3300.0, "finished_at": ""},
			{"name": "HighRoller", "time": 4200.0, "finished_at": ""},
			{"name": "CashFlowCEO", "time": 5400.0, "finished_at": ""},
		],
	}

func _migrate_default_name(player_name: String) -> String:
	var replacements: Dictionary = {
		"Mia": "CasinoMaster",
		"Alex": "Menago1",
		"Noah": "ChipBoss",
		"Sofia": "RoulettePro",
		"Kuba": "KasynoKing",
		"Lena": "TableTycoon",
		"Iga": "VegasShark",
		"Oskar": "HighRoller",
		"Nina": "CashFlowCEO",
	}
	return str(replacements.get(player_name, player_name))

func _sort_by_time(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("time", 0.0)) < float(b.get("time", 0.0))
