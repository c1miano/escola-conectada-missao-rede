class_name IpExplainer
extends Control
## Mostra o endereço IP em duas partes: rede (igual para todos) e número do computador (diferente).

var net := "192.168.1"
var host := "11"
var caption := "Exemplo"


func _init() -> void:
	var k := Game.ui_scale() / 0.7
	custom_minimum_size = Vector2(330, 84) * k
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 6


func show_ip(ip: String, p_caption: String) -> void:
	var parts := ip.split(".")
	if parts.size() == 4:
		net = "%s.%s.%s" % [parts[0], parts[1], parts[2]]
		host = parts[3]
	caption = p_caption
	queue_redraw()


func _draw() -> void:
	var font := Game.ui_font
	var bold := Game.ui_font_bold
	var k := size.y / 84.0
	var small := Game.fs(18)
	var big := int(round(26 * k))
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.95))
	draw_rect(Rect2(Vector2.ZERO, size), Palette.FRAME_DARK, false, 2)
	draw_string(font, Vector2(10, 6 + small), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, small, Palette.TEXT_SOFT)
	var x := 14.0
	var y := 28.0 * k
	var nw := bold.get_string_size(net, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	var nbox := Rect2(Vector2(x - 4, y), Vector2(nw + 8, big + 6))
	draw_rect(nbox, Color("#dbe9ff"))
	draw_rect(nbox, Palette.PRIMARY, false, 2)
	draw_string(bold, Vector2(x, y + big * 0.9), net, HORIZONTAL_ALIGNMENT_LEFT, -1, big, Palette.PRIMARY_DARK)
	draw_string(bold, Vector2(x + nw + 6, y + big * 0.9), ".", HORIZONTAL_ALIGNMENT_LEFT, -1, big, Palette.TEXT)
	var hx := x + nw + 18
	var hw := bold.get_string_size(host, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	var hbox := Rect2(Vector2(hx - 4, y), Vector2(hw + 8, big + 6))
	draw_rect(hbox, Color("#fff1c9"))
	# borda tracejada para diferenciar sem depender da cor
	for i in int(hbox.size.x / 6):
		draw_line(hbox.position + Vector2(i * 6, 0), hbox.position + Vector2(i * 6 + 3, 0), Palette.STAR_DARK, 2)
		draw_line(hbox.position + Vector2(i * 6, hbox.size.y), hbox.position + Vector2(i * 6 + 3, hbox.size.y), Palette.STAR_DARK, 2)
	draw_string(bold, Vector2(hx, y + big * 0.9), host, HORIZONTAL_ALIGNMENT_LEFT, -1, big, Palette.TEXT)
	draw_string(font, Vector2(x, size.y - 8), "Rede: igual para todos", HORIZONTAL_ALIGNMENT_LEFT, -1, small, Palette.PRIMARY_DARK)
	draw_string(font, Vector2(maxf(hx - 6, x + 150 * k), size.y - 8), "Computador: diferente", HORIZONTAL_ALIGNMENT_LEFT, -1, small, Palette.STAR_DARK)
