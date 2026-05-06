## BarShopUI.gd
## Attach to a CanvasLayer node.
## Emituje sygnał `bar_purchased` gdy gracz kupi bar.
extends CanvasLayer

signal bar_purchased
# ── definicja baru ───────────────────────────────────────────────────────────
var BAR_PRICE: int

	
const BAR_SCENE: String = "res://scenes/bar/bar.tscn"

# ── internal ─────────────────────────────────────────────────────────────────
var _pending_spot: Area2D = null

# ── UI refs ───────────────────────────────────────────────────────────────────
var _money_label: Label
var _buy_button: Button
var _close_button: Button
var _cancel_btn: Button


func _ready() -> void:
	# !! KLUCZOWE: CanvasLayer i cały UI musi działać gdy gra jest spauzowana
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_ui_refs()
	hide()


# ============================================================
#  PUBLIC API
# ============================================================

func open(spot: Area2D) -> void:
	_pending_spot = spot
	BAR_PRICE = spot.price
	_refresh_money()
	_refresh_button()
	show()
	get_tree().paused = true


func close() -> void:
	_pending_spot = null
	hide()
	get_tree().paused = false


func get_pending_spot() -> Area2D:
	return _pending_spot

func get_bar_price() -> int:
	return BAR_PRICE

func get_bar_scene() -> String:
	return BAR_SCENE


# ============================================================
#  CALLBACKS
# ============================================================

func _on_buy_bar_pressed() -> void:
	emit_signal("bar_purchased")
	close()

func _on_cancel_pressed() -> void:
	close()


# ============================================================
#  REFRESH
# ============================================================

func _refresh_money() -> void:
	_money_label.text = "Your money: $%.0f" % GameManager.money

func _refresh_button() -> void:
	var can_buy = GameManager.money >= BAR_PRICE
	_buy_button.disabled = not can_buy
	_buy_button.modulate.a = 1.0 if can_buy else 0.45


# ============================================================
#  UI INITIALIZATION
# ============================================================

func _init_ui_refs() -> void:
	"""Załaduj referencje do węzłów ze sceny"""
	_money_label = $CenterContainer/Panel/VBoxContainer/Margin/ContentVBox/MoneyLabel
	_buy_button = $CenterContainer/Panel/VBoxContainer/Margin/ContentVBox/ButtonsVBox/BuyBarBtn
	_close_button = $CenterContainer/Panel/VBoxContainer/Header/CloseButton
	_cancel_btn = $CenterContainer/Panel/VBoxContainer/Margin/ContentVBox/CancelBtn
	
	# podłącz przyciski
	_close_button.pressed.connect(_on_cancel_pressed)
	_cancel_btn.pressed.connect(_on_cancel_pressed)
	_buy_button.pressed.connect(_on_buy_bar_pressed)
