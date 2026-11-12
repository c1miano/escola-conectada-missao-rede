class_name AvatarView
extends Control
## Mostra o avatar (pixel art) parado, respirando.

var avatar := 0
var scale_px := 4
var _t := 0.0


func _init(p_avatar: int = 0, p_scale: int = 4) -> void:
	avatar = p_avatar
	scale_px = p_scale
	custom_minimum_size = Vector2(16, 16) * p_scale
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var name := Walker.frame_name("avatar_%d" % avatar, "baixo", false, 0.0, _t)
	Sprites.draw(self, name, ((size - Vector2(16, 16) * scale_px) / 2.0).round(), scale_px)
