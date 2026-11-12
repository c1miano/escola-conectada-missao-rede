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
	var c := size / 2.0 + Vector2(0, 6)
	# antena
	draw_line(c + Vector2(0, -38), c + Vector2(0, -54), Palette.DEVICE_DARK, 4)
	draw_circle(c + Vector2(0, -56), 7, Palette.STAR)
	# cabeça
	var head := Rect2(c + Vector2(-44, -40), Vector2(88, 64))
	draw_rect(head, Color("#5fa8ff"))
	draw_rect(head, Palette.DEVICE_DARK, false, 4)
	# rosto (tela)
	var face := head.grow(-10)
	draw_rect(face, Color("#0b2545"))
	var blinking := fmod(_blink, 4.0) < 0.15
	for dx in [-16, 16]:
		var e := face.get_center() + Vector2(dx, -6)
		if blinking:
			draw_line(e + Vector2(-7, 0), e + Vector2(7, 0), Palette.SCREEN_ON, 3)
		elif mood == "feliz":
			draw_arc(e + Vector2(0, 4), 8, PI, TAU, 10, Palette.SCREEN_ON, 4, true)
		else:
			draw_circle(e, 7, Palette.SCREEN_ON)
	var m := face.get_center() + Vector2(0, 12)
	if mood == "pensando":
		draw_line(m + Vector2(-10, 0), m + Vector2(10, 0), Palette.SCREEN_ON, 3)
	else:
		draw_arc(m + Vector2(0, -6), 12, PI * 0.15, PI * 0.85, 12, Palette.SCREEN_ON, 3, true)
	# corpo
	draw_rect(Rect2(c + Vector2(-26, 26), Vector2(52, 24)), Color("#5fa8ff"))
	draw_rect(Rect2(c + Vector2(-26, 26), Vector2(52, 24)), Palette.DEVICE_DARK, false, 3)
	draw_circle(c + Vector2(0, 38), 6, Palette.STAR)
