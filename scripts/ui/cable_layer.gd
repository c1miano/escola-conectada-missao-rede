class_name CableLayer
extends Control
## Desenha cabos (linhas), cabos soltos e ligações Wi-Fi entre pontos de tela.
## Cada ponta é um Callable que retorna uma posição global (assim os cabos acompanham o layout).

var cables: Array = []  # {a: Callable, b: Callable, style: String}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func add_cable(a: Callable, b: Callable, style: String = "ok") -> Dictionary:
	var c := {"a": a, "b": b, "style": style}
	cables.append(c)
	queue_redraw()
	return c


func remove_cable(c: Dictionary) -> void:
	cables.erase(c)
	queue_redraw()


func clear() -> void:
	cables.clear()
	queue_redraw()


func _process(_d: float) -> void:
	queue_redraw()


func _local(p: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * p


func _draw() -> void:
	for c in cables:
		var a := _local(c.a.call())
		var b := _local(c.b.call())
		match c.style:
			"ok":
				_curve(a, b, Palette.CABLE, 7)
			"loose":
				var end := a + Vector2(70, 60)
				_curve(a, end, Palette.CABLE_LOOSE, 7)
				draw_rect(Rect2(end - Vector2(9, 0), Vector2(18, 22)), Palette.DEVICE_DARK)
				draw_line(end + Vector2(-5, 22), end + Vector2(-5, 30), Palette.DEVICE_DARK, 3)
				draw_line(end + Vector2(5, 22), end + Vector2(5, 30), Palette.DEVICE_DARK, 3)
			"wifi":
				_dashed(a, b, Palette.CABLE, 4)
				var mid := (a + b) / 2.0
				draw_circle(mid, 22, Color.WHITE)
				Icons.draw(self, "wifi", mid, 18, Palette.CABLE)
			"wrong":
				_dashed(a, b, Palette.ATTENTION, 5)


func _curve(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	var sag := minf(60.0, a.distance_to(b) * 0.12)
	for i in 21:
		var t := i / 20.0
		var p := a.lerp(b, t)
		p.y += sin(t * PI) * sag
		pts.append(p)
	draw_polyline(pts, col.darkened(0.35), w + 4, true)
	draw_polyline(pts, col, w, true)


func _dashed(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var length := a.distance_to(b)
	var dir := (b - a).normalized()
	var d := 0.0
	while d < length:
		draw_line(a + dir * d, a + dir * minf(d + 14.0, length), col, w, true)
		d += 24.0
