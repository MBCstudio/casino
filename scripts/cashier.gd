extends StaticBody2D

@export var wait_time: float = 5.0
@export var prestige: int = 0
@export var vip_chance: float = 0.0
@export var win_probability: float = 0.50

func _ready():
    add_to_group("cashier")
    input_pickable = true

func _input_event(viewport, event, shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        open_cashier_ui()

func open_cashier_ui():
    var ui = get_tree().get_first_node_in_group("cashier_ui")
    if ui:
        ui.open(self)
    else:
        var uis = get_tree().get_nodes_in_group("cashier_ui")
        print("CashierUi not found in group cashier_ui")

