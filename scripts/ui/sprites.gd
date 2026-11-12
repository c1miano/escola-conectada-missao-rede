class_name Sprites
## Acesso às texturas de pixel art (assets/sprites, geradas por tools/pixelart/gerar_sprites.py).
## Sempre desenhadas em escala inteira com filtro "nearest" para manter os pixels nítidos.

const SCALE := 3
static var _cache := {}


static func tex(name: String) -> Texture2D:
	if not _cache.has(name):
		_cache[name] = load("res://assets/sprites/%s.png" % name)
	return _cache[name]


## Desenha o sprite com o canto superior esquerdo em pos, ampliado por scale.
static func draw(ci: CanvasItem, name: String, pos: Vector2, scale: int = SCALE, modulate: Color = Color.WHITE) -> void:
	var t := tex(name)
	if t:
		ci.draw_texture_rect(t, Rect2(pos.floor(), t.get_size() * scale), false, modulate)


## Desenha centralizado em c.
static func draw_centered(ci: CanvasItem, name: String, c: Vector2, scale: int = SCALE) -> void:
	var t := tex(name)
	if t:
		draw(ci, name, c - t.get_size() * scale / 2.0, scale)


static func size_of(name: String, scale: int = SCALE) -> Vector2:
	var t := tex(name)
	return t.get_size() * scale if t else Vector2.ZERO


## Preenche um retângulo repetindo um tile.
static func tile(ci: CanvasItem, name: String, rect: Rect2, scale: int = SCALE) -> void:
	var t := tex(name)
	if t == null:
		return
	var step := t.get_size() * scale
	var y := rect.position.y
	while y < rect.end.y:
		var x := rect.position.x
		while x < rect.end.x:
			ci.draw_texture_rect(t, Rect2(Vector2(x, y), step), false)
			x += step.x
		y += step.y
