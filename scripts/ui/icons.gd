class_name Icons
## Ícones desenhados por código. Assim o jogo não depende de fontes com emoji.


static func star_points(c: Vector2, r: float, inner := 0.45) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * inner
		pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
	return pts


static func _text(ci: CanvasItem, c: Vector2, r: float, s: String, col: Color) -> void:
	var font := Game.ui_font
	var size := int(r * 1.5)
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(font, c + Vector2(-w / 2.0, size * 0.36), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func draw(ci: CanvasItem, kind: String, c: Vector2, r: float, col: Color) -> void:
	var w := maxf(2.0, r * 0.2)
	match kind:
		"star":
			ci.draw_colored_polygon(star_points(c, r), col)
		"star_empty":
			var p := star_points(c, r * 0.92)
			p.append(p[0])
			ci.draw_polyline(p, col, w, true)
		"lock":
			ci.draw_arc(c + Vector2(0, -r * 0.15), r * 0.42, PI, TAU, 16, col, w, true)
			ci.draw_line(c + Vector2(-r * 0.42, -r * 0.15), c + Vector2(-r * 0.42, r * 0.05), col, w)
			ci.draw_line(c + Vector2(r * 0.42, -r * 0.15), c + Vector2(r * 0.42, r * 0.05), col, w)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.7, 0), Vector2(r * 1.4, r * 0.95)), col)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-0.62, 0.02) * r, c + Vector2(-0.18, 0.48) * r, c + Vector2(0.68, -0.52) * r]), col, w * 1.4, true)
		"cross":
			ci.draw_line(c + Vector2(-0.5, -0.5) * r, c + Vector2(0.5, 0.5) * r, col, w * 1.3, true)
			ci.draw_line(c + Vector2(0.5, -0.5) * r, c + Vector2(-0.5, 0.5) * r, col, w * 1.3, true)
		"retry":
			ci.draw_arc(c, r * 0.62, -PI * 0.15, PI * 1.45, 24, col, w * 1.2, true)
			var tip := c + Vector2(cos(-PI * 0.15), sin(-PI * 0.15)) * r * 0.62
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-0.35, -0.3) * r, tip + Vector2(0.32, -0.22) * r, tip + Vector2(0.05, 0.32) * r]), col)
		"speaker":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.8, -0.25) * r, c + Vector2(-0.4, -0.25) * r, c + Vector2(0.05, -0.7) * r, c + Vector2(0.05, 0.7) * r, c + Vector2(-0.4, 0.25) * r, c + Vector2(-0.8, 0.25) * r]), col)
			ci.draw_arc(c + Vector2(0.1, 0) * r, r * 0.4, -PI / 3.5, PI / 3.5, 10, col, w, true)
			ci.draw_arc(c + Vector2(0.1, 0) * r, r * 0.75, -PI / 3.5, PI / 3.5, 12, col, w, true)
		"speaker_off":
			draw(ci, "speaker", c + Vector2(-0.15, 0) * r, r * 0.9, col)
			ci.draw_line(c + Vector2(-0.9, -0.8) * r, c + Vector2(0.9, 0.8) * r, col, w * 1.1, true)
		"help":
			ci.draw_arc(c, r * 0.85, 0, TAU, 32, col, w, true)
			_text(ci, c, r, "?", col)
		"info":
			ci.draw_arc(c, r * 0.85, 0, TAU, 32, col, w, true)
			_text(ci, c, r, "i", col)
		"map":
			var pts := PackedVector2Array([c + Vector2(-0.85, -0.55) * r, c + Vector2(-0.3, -0.75) * r, c + Vector2(0.3, -0.55) * r, c + Vector2(0.85, -0.75) * r, c + Vector2(0.85, 0.55) * r, c + Vector2(0.3, 0.75) * r, c + Vector2(-0.3, 0.55) * r, c + Vector2(-0.85, 0.75) * r, c + Vector2(-0.85, -0.55) * r])
			ci.draw_polyline(pts, col, w, true)
			ci.draw_line(c + Vector2(-0.3, -0.75) * r, c + Vector2(-0.3, 0.55) * r, col, w * 0.7)
			ci.draw_line(c + Vector2(0.3, -0.55) * r, c + Vector2(0.3, 0.75) * r, col, w * 0.7)
		"back":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.8, 0) * r, c + Vector2(-0.1, -0.7) * r, c + Vector2(-0.1, -0.3) * r, c + Vector2(0.8, -0.3) * r, c + Vector2(0.8, 0.3) * r, c + Vector2(-0.1, 0.3) * r, c + Vector2(-0.1, 0.7) * r]), col)
		"next":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.8, 0) * r, c + Vector2(0.1, -0.7) * r, c + Vector2(0.1, -0.3) * r, c + Vector2(-0.8, -0.3) * r, c + Vector2(-0.8, 0.3) * r, c + Vector2(0.1, 0.3) * r, c + Vector2(0.1, 0.7) * r]), col)
		"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.5, -0.75) * r, c + Vector2(0.75, 0) * r, c + Vector2(-0.5, 0.75) * r]), col)
		"skip":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.85, -0.6) * r, c + Vector2(0.0, 0) * r, c + Vector2(-0.85, 0.6) * r]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.05, -0.6) * r, c + Vector2(0.8, 0) * r, c + Vector2(-0.05, 0.6) * r]), col)
		"gear":
			var g := PackedVector2Array()
			for i in 32:
				var a := i * TAU / 32.0
				var rr := r * (0.85 if (i / 2) % 2 == 0 else 0.62)
				g.append(c + Vector2(cos(a), sin(a)) * rr)
			ci.draw_colored_polygon(g, col)
			ci.draw_circle(c, r * 0.28, Color.WHITE if col.get_luminance() < 0.5 else Palette.PRIMARY)
		"exit":
			ci.draw_rect(Rect2(c + Vector2(-0.8, -0.8) * r, Vector2(0.9, 1.6) * r), col, false, w)
			draw(ci, "next", c + Vector2(0.3, 0) * r, r * 0.6, col)
		"bulb":
			ci.draw_circle(c + Vector2(0, -0.2) * r, r * 0.55, col)
			ci.draw_rect(Rect2(c + Vector2(-0.28, 0.3) * r, Vector2(0.56, 0.45) * r), col)
		"home":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -0.85) * r, c + Vector2(0.85, -0.05) * r, c + Vector2(0.6, -0.05) * r, c + Vector2(0.6, 0.8) * r, c + Vector2(-0.6, 0.8) * r, c + Vector2(-0.6, -0.05) * r, c + Vector2(-0.85, -0.05) * r]), col)
		"wifi":
			for i in 3:
				ci.draw_arc(c + Vector2(0, 0.55) * r, r * (0.4 + i * 0.4), -PI * 0.78, -PI * 0.22, 14, col, w, true)
			ci.draw_circle(c + Vector2(0, 0.55) * r, r * 0.14, col)
		"envelope":
			ci.draw_rect(Rect2(c + Vector2(-0.85, -0.55) * r, Vector2(1.7, 1.1) * r), col)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-0.85, -0.55) * r, c + Vector2(0, 0.1) * r, c + Vector2(0.85, -0.55) * r]), Color.WHITE, w * 0.8, true)
		"plus":
			ci.draw_line(c + Vector2(-0.6, 0) * r, c + Vector2(0.6, 0) * r, col, w * 1.4)
			ci.draw_line(c + Vector2(0, -0.6) * r, c + Vector2(0, 0.6) * r, col, w * 1.4)
		"minus":
			ci.draw_line(c + Vector2(-0.6, 0) * r, c + Vector2(0.6, 0) * r, col, w * 1.4)
		"report":
			ci.draw_rect(Rect2(c + Vector2(-0.6, -0.85) * r, Vector2(1.2, 1.7) * r), col, false, w)
			for i in 3:
				ci.draw_line(c + Vector2(-0.35, -0.4 + i * 0.4) * r, c + Vector2(0.35, -0.4 + i * 0.4) * r, col, w * 0.8)
		"user":
			ci.draw_circle(c + Vector2(0, -0.35) * r, r * 0.35, col)
			ci.draw_arc(c + Vector2(0, 0.85) * r, r * 0.75, PI, TAU, 18, col, w * 1.5)
		"cable":
			ci.draw_rect(Rect2(c + Vector2(-0.35, -0.85) * r, Vector2(0.7, 0.8) * r), col)
			ci.draw_line(c + Vector2(-0.15, -0.85) * r, c + Vector2(-0.15, -1.05) * r, col, w * 0.6)
			ci.draw_line(c + Vector2(0.15, -0.85) * r, c + Vector2(0.15, -1.05) * r, col, w * 0.6)
			ci.draw_line(c + Vector2(0, -0.05) * r, c + Vector2(0, 0.9) * r, col, w * 1.3)
		"save":
			ci.draw_rect(Rect2(c + Vector2(-0.75, -0.75) * r, Vector2(1.5, 1.5) * r), col, false, w)
			ci.draw_rect(Rect2(c + Vector2(-0.4, -0.75) * r, Vector2(0.8, 0.5) * r), col)
			ci.draw_rect(Rect2(c + Vector2(-0.45, 0.15) * r, Vector2(0.9, 0.6) * r), col, false, w * 0.7)
		"certificate":
			ci.draw_rect(Rect2(c + Vector2(-0.85, -0.65) * r, Vector2(1.7, 1.1) * r), col, false, w)
			ci.draw_circle(c + Vector2(0.4, 0.45) * r, r * 0.3, col)
		_:
			ci.draw_circle(c, r * 0.5, col)
