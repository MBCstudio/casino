extends Control
class_name GameStatsChart

const MONEY_COLOR := Color(0.98, 0.83, 0.24, 1.0)
const PRESTIGE_COLOR := Color(0.35, 0.78, 1.0, 1.0)
const CUSTOMERS_COLOR := Color(0.45, 0.92, 0.55, 1.0)
const GRID_COLOR := Color(1.0, 1.0, 1.0, 0.12)
const TEXT_COLOR := Color(1.0, 1.0, 1.0, 0.78)

var history: Array[Dictionary] = []
var accent_color: Color = MONEY_COLOR
var metric_key: String = "money"
var metric_label: String = "Money"
var metric_color: Color = MONEY_COLOR
var value_prefix: String = "$"

func configure(new_key: String, new_label: String, new_color: Color, new_value_prefix: String = "") -> void:
	metric_key = new_key
	metric_label = new_label
	metric_color = new_color
	value_prefix = new_value_prefix
	queue_redraw()

func set_history(new_history: Array, new_accent_color: Color) -> void:
	history.clear()
	for sample in new_history:
		if sample is Dictionary:
			history.append(sample)
	accent_color = new_accent_color
	queue_redraw()

func _draw() -> void:
	var chart_rect: Rect2 = Rect2(Vector2(76.0, 36.0), size - Vector2(100.0, 78.0))
	if chart_rect.size.x < 80.0 or chart_rect.size.y < 70.0:
		return

	_draw_background(chart_rect)

	if history.is_empty():
		_draw_empty_state(chart_rect)
		return

	var max_time: float = _get_max_time()
	var value_bounds: Vector2 = _get_value_bounds()
	_draw_grid(chart_rect, max_time, value_bounds)
	_draw_series(chart_rect, max_time, value_bounds)
	_draw_legend(chart_rect)

func _draw_background(chart_rect: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.02, 0.22), true)
	draw_rect(chart_rect, Color(0.0, 0.0, 0.0, 0.24), true)
	draw_rect(chart_rect, Color(1.0, 1.0, 1.0, 0.18), false, 1.0)

func _draw_empty_state(chart_rect: Rect2) -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = 16
	draw_string(font, chart_rect.get_center() - Vector2(72.0, -5.0), "No timeline data", HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, TEXT_COLOR)

func _draw_grid(chart_rect: Rect2, max_time: float, value_bounds: Vector2) -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = 13
	for i in range(5):
		var t: float = float(i) / 4.0
		var y: float = chart_rect.position.y + chart_rect.size.y * t
		draw_line(Vector2(chart_rect.position.x, y), Vector2(chart_rect.end.x, y), GRID_COLOR, 1.0)
		var value: float = lerpf(value_bounds.y, value_bounds.x, t)
		var value_label: String = _format_value(value)
		draw_string(font, Vector2(8.0, y + 5.0), value_label, HORIZONTAL_ALIGNMENT_LEFT, 62.0, font_size, TEXT_COLOR)

	for i in range(5):
		var t: float = float(i) / 4.0
		var x: float = chart_rect.position.x + chart_rect.size.x * t
		draw_line(Vector2(x, chart_rect.position.y), Vector2(x, chart_rect.end.y), GRID_COLOR, 1.0)
		var minute_label: String = "%dm" % int(round((max_time / 60.0) * t))
		draw_string(font, Vector2(x - 12.0, chart_rect.end.y + 19.0), minute_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, TEXT_COLOR)

	draw_string(font, Vector2(chart_rect.position.x, 20.0), metric_label + " over time", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, metric_color)

func _draw_series(chart_rect: Rect2, max_time: float, value_bounds: Vector2) -> void:
	var min_value: float = value_bounds.x
	var max_value: float = value_bounds.y
	var value_range: float = max_value - min_value
	var is_flat: bool = value_range <= 0.001
	value_range = maxf(value_range, 1.0)
	var points: PackedVector2Array = PackedVector2Array()
	for sample in history:
		var sample_time: float = float(sample.get("time", 0.0))
		var value: float = float(sample.get(metric_key, 0.0))
		var x_ratio: float = 0.0 if max_time <= 0.0 else clampf(sample_time / max_time, 0.0, 1.0)
		var y_ratio: float = 0.5 if is_flat else 1.0 - ((value - min_value) / value_range)
		points.append(Vector2(
			chart_rect.position.x + chart_rect.size.x * x_ratio,
			chart_rect.position.y + chart_rect.size.y * y_ratio
		))

	if points.size() == 1:
		draw_circle(points[0], 3.5, metric_color)
	else:
		draw_polyline(points, metric_color, 3.0, true)
		for point in points:
			draw_circle(point, 2.4, metric_color)

func _draw_legend(chart_rect: Rect2) -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = 13
	var last_sample: Dictionary = history[history.size() - 1]
	var x: float = chart_rect.position.x
	var y: float = chart_rect.end.y + 43.0
	var label_text: String = "%s: %s" % [metric_label, _format_value(float(last_sample.get(metric_key, 0.0)))]
	draw_circle(Vector2(x + 6.0, y - 5.0), 4.0, metric_color)
	draw_string(font, Vector2(x + 16.0, y), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, TEXT_COLOR)

func _get_max_time() -> float:
	var max_time: float = 0.0
	for sample in history:
		max_time = maxf(max_time, float(sample.get("time", 0.0)))
	return maxf(max_time, 60.0)

func _get_value_bounds() -> Vector2:
	var min_value: float = INF
	var max_value: float = -INF
	for sample in history:
		var value: float = float(sample.get(metric_key, 0.0))
		min_value = minf(min_value, value)
		max_value = maxf(max_value, value)

	if min_value == INF:
		return Vector2(0.0, 1.0)

	if abs(max_value - min_value) <= 0.001:
		var padding: float = maxf(abs(max_value) * 0.1, 1.0)
		return Vector2(min_value - padding, max_value + padding)

	var value_span: float = max_value - min_value
	var padded_min: float = min_value - value_span * 0.08
	var padded_max: float = max_value + value_span * 0.08
	return Vector2(padded_min, padded_max)

func _format_value(value: float) -> String:
	return value_prefix + str(int(round(value)))
