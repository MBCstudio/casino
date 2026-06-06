extends CanvasLayer

@onready var play_time_label: Label = %PlayTimeLabel as Label
@onready var tables_label: Label = %TablesLabel as Label
@onready var customers_label: Label = %CustomersLabel as Label
@onready var money_label: Label = %MoneyLabel as Label
@onready var prestige_label: Label = %PrestigeLabel as Label
@onready var play_again_button: Button = %PlayAgainButton as Button
@onready var quit_button: Button = %QuitButton as Button
@onready var header_label: Label = %HeaderLabel as Label
@onready var gradient_bg: TextureRect = %GradientBg as TextureRect

var stats_tabs: TabContainer = null
var stats_charts: Array[GameStatsChart] = []
var leaderboard_button: Button = null
var leaderboard_panel: PanelContainer = null
var leaderboard_tabs: TabContainer = null
var leaderboard_result_label: Label = null

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
	_setup_responsive_layout()
	_setup_stats_chart()
	_setup_leaderboard_button()
	_setup_leaderboard_panel()
	get_viewport().size_changed.connect(_setup_responsive_layout)

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
		var tex: GradientTexture2D = GradientTexture2D.new()
		tex.gradient = grad
		tex.fill_from = Vector2(0, 0.18)
		tex.fill_to   = Vector2(0, 1.0)
		gradient_bg.texture = tex

	# --- Panel border colour ---
	var panel: Panel = get_node_or_null("CenterContainer/Panel") as Panel
	if panel:
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if style:
			style.border_color = accent
			panel.add_theme_stylebox_override("panel", style)

	# --- Stats ---
	var minutes: int = int(GameManager.play_time) / 60
	var seconds: int = int(GameManager.play_time) % 60
	var time_text: String = "%02d:%02d" % [minutes, seconds]

	if play_time_label:
		play_time_label.add_theme_color_override("font_color", accent)
		play_time_label.text = time_text

	if tables_label:
		tables_label.add_theme_color_override("font_color", accent)
		tables_label.text = str(GameManager.count_tables())

	if customers_label:
		customers_label.add_theme_color_override("font_color", accent)
<<<<<<< Updated upstream
		customers_label.text = str(GameManager.total_customers)
=======
		customers_label.text = str(GameManager.total_customers_visited)
>>>>>>> Stashed changes

	if money_label:
		money_label.add_theme_color_override("font_color", accent)
		money_label.text = "$" + str(int(GameManager.money))

	if prestige_label:
		prestige_label.add_theme_color_override("font_color", accent)
		prestige_label.text = str(GameManager.get_total_prestige())

	for chart in stats_charts:
		chart.set_history(GameManager.stats_history, accent)

	if leaderboard_button:
		leaderboard_button.visible = is_win
	if leaderboard_panel:
		leaderboard_panel.hide()
	if is_win:
		_refresh_leaderboard()

func _setup_responsive_layout() -> void:
	offset = Vector2.ZERO
	transform = Transform2D.IDENTITY
	var center: CenterContainer = get_node_or_null("CenterContainer") as CenterContainer
	if center:
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.offset_left = 0.0
		center.offset_top = 0.0
		center.offset_right = 0.0
		center.offset_bottom = 0.0

	var panel: Panel = get_node_or_null("CenterContainer/Panel") as Panel
	if panel:
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		panel.custom_minimum_size = Vector2(
			clampf(viewport_size.x * 0.82, 520.0, 980.0),
			clampf(viewport_size.y * 0.86, 520.0, 780.0)
		)

	var content: VBoxContainer = get_node_or_null("CenterContainer/Panel/VBoxContainer") as VBoxContainer
	if content:
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 36.0
		content.offset_top = 26.0
		content.offset_right = -36.0
		content.offset_bottom = -28.0

func _setup_stats_chart() -> void:
	var content: VBoxContainer = get_node_or_null("CenterContainer/Panel/VBoxContainer") as VBoxContainer
	if content == null:
		return

	stats_tabs = content.get_node_or_null("StatsTabs") as TabContainer
	if stats_tabs == null:
		stats_tabs = TabContainer.new()
		stats_tabs.name = "StatsTabs"
		stats_tabs.custom_minimum_size = Vector2(0.0, 260.0)
		stats_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stats_tabs.add_theme_font_size_override("font_size", 15)
		stats_tabs.add_theme_color_override("font_selected_color", Color.WHITE)
		stats_tabs.add_theme_color_override("font_unselected_color", Color(1.0, 1.0, 1.0, 0.68))
		content.add_child(stats_tabs)
		var stats_container: VBoxContainer = content.get_node_or_null("StatsContainer") as VBoxContainer
		if stats_container:
			content.move_child(stats_tabs, stats_container.get_index() + 1)

	stats_charts.clear()
	_add_stats_tab("Money", "money", "Money", GameStatsChart.MONEY_COLOR, "$")
	_add_stats_tab("Prestige", "prestige", "Prestige", GameStatsChart.PRESTIGE_COLOR)
	_add_stats_tab("Guests", "total_customers", "All guests", GameStatsChart.CUSTOMERS_COLOR)

func _add_stats_tab(tab_name: String, metric_key: String, metric_label: String, metric_color: Color, value_prefix: String = "") -> void:
	if stats_tabs == null:
		return

	var chart: GameStatsChart = stats_tabs.get_node_or_null(tab_name) as GameStatsChart
	if chart == null:
		chart = GameStatsChart.new()
		chart.name = tab_name
		chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stats_tabs.add_child(chart)

	chart.configure(metric_key, metric_label, metric_color, value_prefix)
	stats_charts.append(chart)

# ── Buttons ────────────────────────────────────────────────────────────────────
func _setup_leaderboard_button() -> void:
	if leaderboard_button:
		return

	var button_container: HBoxContainer = get_node_or_null("CenterContainer/Panel/VBoxContainer/ButtonContainer") as HBoxContainer
	if button_container == null:
		return

	if play_again_button:
		play_again_button.custom_minimum_size = Vector2(135.0, 50.0)
	if quit_button:
		quit_button.custom_minimum_size = Vector2(135.0, 50.0)

	leaderboard_button = Button.new()
	leaderboard_button.name = "LeaderboardButton"
	leaderboard_button.custom_minimum_size = Vector2(135.0, 50.0)
	leaderboard_button.text = "Leaderboard"
	leaderboard_button.visible = false
	leaderboard_button.add_theme_font_size_override("font_size", 18)
	leaderboard_button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72, 1.0))
	leaderboard_button.add_theme_color_override("font_hover_color", Color.WHITE)
	leaderboard_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.34, 0.2, 0.08, 1.0), Color(0.98, 0.83, 0.24, 0.68)))
	leaderboard_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.48, 0.28, 0.1, 1.0), Color(1.0, 0.9, 0.34, 0.92)))
	leaderboard_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.2, 0.12, 0.05, 1.0), Color(0.86, 0.62, 0.18, 0.7)))
	leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	button_container.add_child(leaderboard_button)

func _setup_leaderboard_panel() -> void:
	if leaderboard_panel:
		return

	leaderboard_panel = PanelContainer.new()
	leaderboard_panel.name = "LeaderboardPanel"
	leaderboard_panel.visible = false
	leaderboard_panel.custom_minimum_size = Vector2(540.0, 470.0)
	leaderboard_panel.set_anchors_preset(Control.PRESET_CENTER)
	leaderboard_panel.offset_left = -270.0
	leaderboard_panel.offset_top = -235.0
	leaderboard_panel.offset_right = 270.0
	leaderboard_panel.offset_bottom = 235.0
	leaderboard_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	leaderboard_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(leaderboard_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	leaderboard_panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	box.add_child(header_row)

	var title: Label = Label.new()
	title.text = "LEADERBOARD"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", WIN_ACCENT)
	header_row.add_child(title)

	var close_button: Button = Button.new()
	close_button.custom_minimum_size = Vector2(38.0, 34.0)
	close_button.text = "X"
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
	close_button.add_theme_color_override("font_hover_color", Color(1.0, 0.35, 0.35, 1.0))
	close_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.0, 0.0, 0.0, 0.0), Color(1.0, 1.0, 1.0, 0.14)))
	close_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.55, 0.08, 0.08, 0.3), Color(1.0, 0.36, 0.36, 0.7)))
	close_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.26, 0.02, 0.02, 0.55), Color(1.0, 0.36, 0.36, 0.55)))
	close_button.pressed.connect(_on_leaderboard_close_pressed)
	header_row.add_child(close_button)

	leaderboard_result_label = Label.new()
	leaderboard_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_result_label.add_theme_font_size_override("font_size", 15)
	leaderboard_result_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.82, 1.0))
	box.add_child(leaderboard_result_label)

	leaderboard_tabs = TabContainer.new()
	leaderboard_tabs.custom_minimum_size = Vector2(0.0, 320.0)
	leaderboard_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaderboard_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaderboard_tabs.add_theme_font_size_override("font_size", 15)
	leaderboard_tabs.add_theme_color_override("font_selected_color", Color.WHITE)
	leaderboard_tabs.add_theme_color_override("font_unselected_color", Color(1.0, 1.0, 1.0, 0.68))
	box.add_child(leaderboard_tabs)

	for difficulty in LeaderboardManager.DIFFICULTIES:
		var tab: VBoxContainer = VBoxContainer.new()
		tab.name = difficulty.capitalize()
		tab.add_theme_constant_override("separation", 8)
		leaderboard_tabs.add_child(tab)

func _refresh_leaderboard() -> void:
	if leaderboard_tabs == null:
		return

	var current_difficulty: String = GameManager.current_difficulty.to_lower()
	var current_time: float = GameManager.play_time
	var player_name: String = GameManager.player_nickname.strip_edges()
	if player_name.is_empty():
		player_name = "Player"

	if leaderboard_result_label:
		var difficulty_text: String = current_difficulty.capitalize() if not current_difficulty.is_empty() else "Unknown"
		leaderboard_result_label.text = "This run: %s | %s | %s" % [
			player_name.left(16),
			difficulty_text,
			LeaderboardManager.format_time(current_time),
		]

	for difficulty in LeaderboardManager.DIFFICULTIES:
		var tab: VBoxContainer = leaderboard_tabs.get_node_or_null(difficulty.capitalize()) as VBoxContainer
		if tab == null:
			continue

		for child in tab.get_children():
			tab.remove_child(child)
			child.queue_free()

		var target_label: Label = Label.new()
		target_label.text = "Beat this for #1: " + LeaderboardManager.get_best_time_text(difficulty)
		target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		target_label.add_theme_font_size_override("font_size", 15)
		target_label.add_theme_color_override("font_color", WIN_ACCENT)
		tab.add_child(target_label)

		_add_leaderboard_row(tab, "Rank", "Player", "Time", Color(0.62, 0.62, 0.72, 1.0), 13)

		var entries: Array = LeaderboardManager.get_entries(difficulty, 8)
		if entries.is_empty():
			var empty_label: Label = Label.new()
			empty_label.text = "No wins yet"
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78, 1.0))
			tab.add_child(empty_label)
			continue

		for i in range(entries.size()):
			var entry: Dictionary = entries[i] as Dictionary
			var rank: String = "#%d" % (i + 1)
			var name: String = str(entry.get("name", "Player")).left(16)
			var entry_time: float = float(entry.get("time", 0.0))
			var time_text: String = LeaderboardManager.format_time(entry_time)
			var row_color: Color = Color(0.92, 0.92, 0.96, 1.0)
			var font_size: int = 15
			var is_current_run: bool = difficulty == current_difficulty and name == player_name.left(16) and abs(entry_time - current_time) <= 0.5
			if is_current_run:
				row_color = WIN_ACCENT
				font_size = 16
			_add_leaderboard_row(tab, rank, name, time_text, row_color, font_size)

	var current_tab: int = LeaderboardManager.DIFFICULTIES.find(current_difficulty)
	if current_tab >= 0:
		leaderboard_tabs.current_tab = current_tab

func _add_leaderboard_row(parent: VBoxContainer, rank: String, player_name: String, time_text: String, color: Color, font_size: int) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var rank_label: Label = _make_leaderboard_cell(rank, color, font_size, HORIZONTAL_ALIGNMENT_LEFT)
	rank_label.custom_minimum_size = Vector2(54.0, 0.0)
	row.add_child(rank_label)

	var name_label: Label = _make_leaderboard_cell(player_name, color, font_size, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var time_label: Label = _make_leaderboard_cell(time_text, color, font_size, HORIZONTAL_ALIGNMENT_RIGHT)
	time_label.custom_minimum_size = Vector2(72.0, 0.0)
	row.add_child(time_label)

func _make_leaderboard_cell(text: String, color: Color, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _on_leaderboard_button_pressed() -> void:
	if leaderboard_panel == null:
		return

	_refresh_leaderboard()
	leaderboard_panel.visible = not leaderboard_panel.visible

func _on_leaderboard_close_pressed() -> void:
	if leaderboard_panel:
		leaderboard_panel.hide()

func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 14.0
	style.content_margin_top = 8.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 8.0
	return style

func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.05, 0.94)
	style.border_color = Color(0.98, 0.83, 0.24, 0.58)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 18
	return style

func _on_play_again():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit():
	get_tree().paused = false
	get_tree().quit()
