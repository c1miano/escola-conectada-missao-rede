class_name Walker
extends Control
## Personagem (técnico) que anda pelo cenário. Pode andar sozinho até um ponto
## (quando o jogador clica num equipamento) ou ser controlado pelo teclado.

signal arrived

const SPEED := 360.0
const SCALE := 3

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
	else:
		_idle_t += delta
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


var who := "tecnico"
var _idle_t := 0.0


## Nome do quadro atual: caminhada de 4 quadros a 10 por segundo, ou respiração parado (2 quadros).
static func frame_name(p_who: String, p_facing: String, p_moving: bool, walk_t: float, idle_t: float) -> String:
	if p_moving:
		return "%s_%s_%d" % [p_who, p_facing, int(walk_t * 10.0) % 4]
	return "%s_%s_parado_%d" % [p_who, p_facing, int(idle_t * 1.6) % 2]


func _draw() -> void:
	Sprites.draw(self, frame_name(who, facing, moving, _t, _idle_t), Vector2.ZERO, SCALE)
