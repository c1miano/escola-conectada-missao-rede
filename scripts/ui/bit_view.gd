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
	# flutua 1 "pixel" do sprite para cima e para baixo (movimento em degraus, sem borrar)
	var bob := -6.0 if fmod(_blink, 1.2) < 0.6 else 0.0
	Sprites.draw_centered(self, name, size / 2.0 + Vector2(0, bob), 6)
