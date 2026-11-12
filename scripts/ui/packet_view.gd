class_name PacketView
extends Control
## Pacote de dados (envelope com etiqueta do protocolo) que percorre a rede.

var tag := ""
var tint := Palette.STAR


func _init(p_tag: String = "", p_tint: Color = Palette.STAR) -> void:
	tag = p_tag
	tint = p_tint
	size = Vector2(110, 70)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10


func _draw() -> void:
	var c := Vector2(size.x / 2.0, 22)
	draw_circle(c, 26, Color(tint, 0.35))
	Icons.draw(self, "envelope", c, 22, tint.darkened(0.2))
	if tag != "":
		var font := Game.ui_font
		var fsz := Game.fs(18)
		var w := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		var box := Rect2(Vector2(size.x / 2.0 - w / 2.0 - 4, 44), Vector2(w + 8, fsz + 6))
		draw_rect(box, Color.WHITE)
		draw_rect(box, Palette.DEVICE_DARK, false, 1)
		draw_string(font, box.position + Vector2(4, fsz * 0.86 + 2), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Palette.TEXT)
