extends Area2D

## Emitowany gdy gracz kliknie w slot.
## Przekazuje referencję do siebie, żeby CasinoFloor wiedział który slot kliknięto.
signal slot_clicked(slot: Area2D)

func _ready() -> void:
	input_pickable = true
	add_to_group("table_slots")
	z_index = 0  # renderuj pod postaciami klientów (domyślnie z=0)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("slot_clicked", self)
