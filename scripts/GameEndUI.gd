extends CanvasLayer

@onready var play_time_label = %PlayTimeLabel
@onready var tables_label = %TablesLabel
@onready var customers_label = %CustomersLabel
@onready var money_label = %MoneyLabel
@onready var prestige_label = %PrestigeLabel
@onready var play_again_button = %PlayAgainButton
@onready var quit_button = %QuitButton
@onready var header_label = %HeaderLabel
@onready var gradient_bg = %GradientBg

# Colour themes ----------------------------------------------------------------
const WIN_ACCENT  := Color(0.98, 0.83, 0.24, 1)   # gold
const LOSE_ACCENT := Color(0.85, 0.18, 0.18, 1)   # red

# WIN gradient: dark green → dark amber (original)
const WIN_GRAD_A  := Color(0.033, 0.080, 0.028, 1)
const WIN_GRAD_B  := Color(0.264, 0.136, 0.006, 1)

# LOSE gradient: very dark red → dark maroon
const LOSE_GRAD_A := Color(0.10, 0.02, 0.02, 1)
const LOSE_GRAD_B := Color(0.30, 0.05, 0.05, 1)
# ------------------------------------------------------------------------------

func _ready():
	visible = false
	add_to_group("game_end_ui")

	# Allow running while the game is paused
	process_mode = PROCESS_MODE_WHEN_PAUSED

	print("GameEndUI: Connecting to GameManager signals")
	GameManager.game_won.connect(_on_game_won)
	GameManager.game_lost.connect(_on_game_lost)
	print("GameEndUI: Signals connected successfully")

	if play_again_button:
		play_again_button.pressed.connect(_on_play_again)
	else:
		print("GameEndUI: ERROR - play_again_button not found!")

	if quit_button:
		quit_button.pressed.connect(_on_quit)
	else:
		print("GameEndUI: ERROR - quit_button not found!")

# ── Signal handlers ────────────────────────────────────────────────────────────
func _on_game_won():
	print("GameEndUI: game_won signal received!")
	show_end_screen(true)

func _on_game_lost():
	print("GameEndUI: game_lost signal received!")
	show_end_screen(false)

# ── Core reusable function ─────────────────────────────────────────────────────
func show_end_screen(is_win: bool) -> void:
	visible = true

	# Hard-stop the game: pause scene tree and reset any speed multiplier
	get_tree().paused = true
	Engine.time_scale = 1.0

	var accent: Color = WIN_ACCENT if is_win else LOSE_ACCENT

	# --- Header text ---
	if header_label:
		header_label.text = "🎉 YOU WIN 🎉" if is_win else "💸 BANKRUPT 💸"
		header_label.add_theme_color_override("font_color", accent)

	# --- Background gradient ---
	if gradient_bg and gradient_bg.texture is GradientTexture2D:
		var grad: Gradient = Gradient.new()
		grad.offsets = PackedFloat32Array([0.011, 1.0])
		if is_win:
			grad.colors = PackedColorArray([WIN_GRAD_A, WIN_GRAD_B])
		else:
			grad.colors = PackedColorArray([LOSE_GRAD_A, LOSE_GRAD_B])
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.fill_from = Vector2(0, 0.18)
		tex.fill_to   = Vector2(0, 1.0)
		gradient_bg.texture = tex

	# --- Panel border colour ---
	var panel = get_node_or_null("CenterContainer/Panel")
	if panel:
		var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if style:
			style.border_color = accent
			panel.add_theme_stylebox_override("panel", style)

	# --- Stats ---
	var minutes := int(GameManager.play_time) / 60
	var seconds  := int(GameManager.play_time) % 60
	var time_text := "%02d:%02d" % [minutes, seconds]

	if play_time_label:
		play_time_label.add_theme_color_override("font_color", accent)
		play_time_label.text = time_text

	if tables_label:
		tables_label.add_theme_color_override("font_color", accent)
		tables_label.text = str(GameManager.count_tables())

	if customers_label:
		customers_label.add_theme_color_override("font_color", accent)
		customers_label.text = str(GameManager.customers)

	if money_label:
		money_label.add_theme_color_override("font_color", accent)
		money_label.text = "$" + str(int(GameManager.money))

	if prestige_label:
		prestige_label.add_theme_color_override("font_color", accent)
		prestige_label.text = str(GameManager.get_total_prestige())

# ── Buttons ────────────────────────────────────────────────────────────────────
func _on_play_again():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit():
	get_tree().paused = false
	get_tree().quit()
