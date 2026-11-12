class_name BitView
extends Control
## Bit, o robô ajudante.

var mood := "normal":
	set(v):
		mood = v
		queue_redraw()
var _blink := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(110, 120)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_blink += delta
	if fmod(_blink, 4.0) < 0.15 or fmod(_blink, 4.0) > 3.85:
		queue_redraw()


func celebrate() -> void:
	mood = "feliz"
	var t := create_tween()
	t.tween_property(self, "position:y", position.y - 22, 0.18).set_trans(Tween.TRANS_QUAD)
	t.tween_property(self, "position:y", position.y, 0.22).set_trans(Tween.TRANS_BOUNCE)
	t.tween_property(self, "position:y", position.y - 12, 0.15)
	t.tween_property(self, "position:y", position.y, 0.2).set_trans(Tween.TRANS_BOUNCE)


func _draw() -> void:
	var name := "bit"
	if mood == "feliz":
		name = "bit_feliz"
	elif mood == "pensando":
		name = "bit_pensando"
	if fmod(_blink, 4.0) < 0.15 and mood == "normal":
		name = "bit_pensando"
	Sprites.draw_centered(self, name, size / 2.0, 6)
