class_name PointerView
extends Control
## Mãozinha/seta usada para demonstrar ações (dica nível 3 e modo guiado).

var _ripple := 0.0


func _init() -> void:
	size = Vector2(60, 60)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	visible = false


func click_effect() -> void:
	var t := create_tween()
	t.tween_method(func(v): _ripple = v; queue_redraw(), 0.0, 1.0, 0.45)
	t.tween_callback(func(): _ripple = 0.0; queue_redraw())


func _draw() -> void:
	if _ripple > 0.0:
		draw_arc(Vector2.ZERO, 12 + _ripple * 30, 0, TAU, 32, Color(Palette.FOCUS, 1.0 - _ripple), 5, true)
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(0, 42), Vector2(11, 32), Vector2(19, 50), Vector2(27, 46), Vector2(19, 29), Vector2(33, 28)])
	draw_colored_polygon(pts, Color.WHITE)
	pts.append(pts[0])
	draw_polyline(pts, Palette.TEXT, 4, true)
