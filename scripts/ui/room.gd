class_name Room
## Desenha uma sala vista de cima (estilo top-down 16x16): moldura, parede com decoração e piso.

const WALL_H := 32 * Sprites.SCALE   # parede tem 2 tiles de altura


## floor: nome do tile do piso. wall_items: [[sprite, x_rel]]. floor_items: [[sprite, Vector2 rel]]
static func draw(ci: CanvasItem, rect: Rect2, floor: String, wall_items: Array, floor_items: Array) -> void:
	var s := Sprites.SCALE
	# moldura azul ao redor (como as paredes vistas de cima)
	ci.draw_rect(rect.grow(10), Palette.FRAME_DARK)
	ci.draw_rect(rect.grow(6), Palette.FRAME)
	# piso
	var floor_rect := Rect2(rect.position + Vector2(0, WALL_H), Vector2(rect.size.x, rect.size.y - WALL_H))
	ci.draw_set_transform(Vector2.ZERO)
	Sprites.tile(ci, floor, floor_rect)
	# parede
	Sprites.tile(ci, "parede", Rect2(rect.position, Vector2(rect.size.x, WALL_H)))
	for it in wall_items:
		var sz := Sprites.size_of(it[0])
		var x: float = rect.position.x + float(it[1]) * rect.size.x - sz.x / 2.0
		var y: float = rect.position.y + 4 * s + (WALL_H - 4 * s - sz.y) / 2.0
		Sprites.draw(ci, it[0], Vector2(x, y).round())
	# sombra da parede no chão
	ci.draw_rect(Rect2(floor_rect.position, Vector2(floor_rect.size.x, s * 2)), Color(0.1, 0.1, 0.25, 0.18))
	for it in floor_items:
		var sz2 := Sprites.size_of(it[0])
		var p: Vector2 = floor_rect.position + (it[1] as Vector2) * floor_rect.size - sz2 / 2.0
		Sprites.draw(ci, it[0], p.round())
	# limita o quadro (corta o que passou da borda)
	ci.draw_rect(rect, Palette.FRAME_DARK, false, 4)
