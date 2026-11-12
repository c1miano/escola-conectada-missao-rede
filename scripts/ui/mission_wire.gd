class_name MissionWire
## Desenha um fio do cabo de rede: cor sólida ou branco com listras da cor ("branco-laranja").

const COLORS := {"laranja": Color("#ec8a2e"), "verde": Color("#2fb86a"), "azul": Color("#2a6fdb"), "marrom": Color("#8f5634")}


static func draw_wire(ci: CanvasItem, r: Rect2, wire: String) -> void:
	var striped := wire.begins_with("branco-")
	var col: Color = COLORS.get(wire.trim_prefix("branco-"), Color.GRAY)
	ci.draw_rect(r, Color("#f4f4f4") if striped else col)
	if striped:
		var y := r.position.y
		while y < r.end.y:
			ci.draw_rect(Rect2(Vector2(r.position.x, y), Vector2(r.size.x, minf(4.0, r.end.y - y))), col)
			y += 9.0
	ci.draw_rect(r, Palette.FRAME_DARK, false, 1)
