class_name Walker
extends Control
## Personagem (técnico) que anda pelo cenário. Pode andar sozinho até um ponto
## (quando o jogador clica num equipamento) ou ser controlado pelo teclado.

signal arrived

const SPEED := 360.0
const SCALE := 4

var facing := "baixo"
var moving := false
var _t := 0.0
var _target := Vector2.INF
var _on_arrive: Callable


func _init() -> void:
	size = Vector2(16, 16) * SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5


## Pés do personagem (ponto de referência no chão).
func feet() -> Vector2:
	return position + Vector2(size.x / 2.0, size.y - 4)


func set_feet(p: Vector2) -> void:
	position = (p - Vector2(size.x / 2.0, size.y - 4)).round()


func walk_to(p: Vector2, on_arrive: Callable = Callable()) -> void:
	_target = p
	_on_arrive = on_arrive
	if Game.settings.pular_animacoes:
		set_feet(p)
		_finish()


func walking_to_target() -> bool:
	return _target != Vector2.INF


func step(dir: Vector2, delta: float, bounds: Rect2) -> void:
	_target = Vector2.INF
	if dir == Vector2.ZERO:
		moving = false
		return
	var p := feet() + dir.normalized() * SPEED * delta
	set_feet(Vector2(clampf(p.x, bounds.position.x, bounds.end.x), clampf(p.y, bounds.position.y, bounds.end.y)))
	_face(dir)
	moving = true


func _process(delta: float) -> void:
	if _target != Vector2.INF:
		var to := _target - feet()
		if to.length() < 6.0:
			set_feet(_target)
			_finish()
		else:
			set_feet(feet() + to.normalized() * minf(SPEED * delta, to.length()))
			_face(to)
			moving = true
	if moving:
		_t += delta
	queue_redraw()


func _finish() -> void:
	_target = Vector2.INF
	moving = false
	facing = "cima"
	queue_redraw()
	var cb := _on_arrive
	_on_arrive = Callable()
	arrived.emit()
	if cb.is_valid():
		cb.call()


func _face(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing = "direita" if dir.x > 0 else "esquerda"
	else:
		facing = "baixo" if dir.y > 0 else "cima"


func _draw() -> void:
	var frame := int(_t * 8.0) % 2 if moving else 0
	draw_rect(Rect2(Vector2(size.x * 0.2, size.y - 8), Vector2(size.x * 0.6, 8)), Color(0.1, 0.1, 0.25, 0.3))
	Sprites.draw(self, "tecnico_%s_%d" % [facing, frame], Vector2.ZERO, SCALE)
