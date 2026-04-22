extends CanvasLayer

@onready var title_label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var desc_label = $CenterContainer/Panel/MarginContainer/VBoxContainer/DescLabel
@onready var buttons_container = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer

signal event_resolved(outcome)

func _ready():
	visible = false

# Expected format for event_data:
# {
# 	"title": "A Mysterious Stranger",
# 	"description": "A stranger approaches offering you a deal...",
# 	"choices": [
# 		{"text": "Accept", "outcome": {"money": 500}},
# 		{"text": "Decline", "outcome": {"money": 0}}
# 	]
# }
func show_event(event_data: Dictionary):
	if event_data.has("title"):
		title_label.text = event_data["title"]
	if event_data.has("description"):
		desc_label.text = event_data["description"]
	
	# Clear existing buttons
	for child in buttons_container.get_children():
		child.queue_free()
	
	# Add new buttons
	if event_data.has("choices"):
		for choice in event_data["choices"]:
			var btn = Button.new()
			btn.text = choice["text"]
			btn.custom_minimum_size = Vector2(150, 50)
			
			# Add a simple style for the buttons mimicking the casino theme
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.15, 0.1)
			style.border_color = Color(0.83, 0.68, 0.21)
			style.border_width_bottom = 2
			style.border_width_top = 2
			style.border_width_left = 2
			style.border_width_right = 2
			style.corner_radius_bottom_left = 8
			style.corner_radius_bottom_right = 8
			style.corner_radius_top_left = 8
			style.corner_radius_top_right = 8
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			
			btn.pressed.connect(_on_choice_made.bind(choice))
			buttons_container.add_child(btn)
	
	visible = true
	get_tree().paused = true # Optional: pause game during event

func _on_choice_made(choice: Dictionary):
	# If a choice has an immediate outcome, process it first
	if choice.has("outcome"):
		event_resolved.emit(choice["outcome"])
		
	# If there's another stage to this event, show it
	if choice.has("next_event"):
		show_event(choice["next_event"])
	else:
		# Otherwise, we're done
		visible = false
		get_tree().paused = false
