extends StaticBody2D

@export var passive_income: int = 0
@export var prestige: int = 0
@export var vip_percentage: float = 0.0
@export var cashier_upgraded: bool = false
@export var drinks_upgraded: bool = false
@export var live_band_upgraded: bool = false

func _ready():
	add_to_group("bars")
	input_pickable = true

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		open_bar_ui()

func open_bar_ui():
	var ui = get_tree().get_first_node_in_group("bar_ui")
	if ui:
		ui.open(self)
	else:
		print("BarUi not found in group bar_ui")
