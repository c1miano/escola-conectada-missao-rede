class_name IpExplainer
extends Control
## Mostra o endereço IP em duas partes: rede (igual para todos) e número do computador (diferente).

var net := "192.168.1"
var host := "11"
var caption := "Exemplo"


func _init() -> void:
	custom_minimum_size = Vector2(500, 120)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_ip(ip: String, p_caption: String) -> void:
	var parts := ip.split(".")
	if parts.size() == 4:
		net = "%s.%s.%s" % [parts[0], parts[1], parts[2]]
		host = parts[3]
	caption = p_caption
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.92))
	draw_rect(Rect2(Vector2.ZERO, size), Palette.PANEL_BORDER, false, 3)
	draw_string(font, Vector2(14, 28), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Palette.TEXT_SOFT)
	var x := 20.0
	var nw := font.get_string_size(net, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	var nbox := Rect2(Vector2(x - 6, 38), Vector2(nw + 12, 46))
	draw_rect(nbox, Color("#dbe9ff"))
	draw_rect(nbox, Palette.PRIMARY, false, 3)
	draw_string(font, Vector2(x, 74), net, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Palette.PRIMARY_DARK)
	draw_string(font, Vector2(x + nw + 10, 74), ".", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Palette.TEXT)
	var hx := x + nw + 26
	var hw := font.get_string_size(host, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	var hbox := Rect2(Vector2(hx - 6, 38), Vector2(hw + 12, 46))
	draw_rect(hbox, Color("#fff1c9"))
	# borda tracejada para diferenciar sem depender da cor
	for i in int(hbox.size.x / 8):
		draw_line(hbox.position + Vector2(i * 8, 0), hbox.position + Vector2(i * 8 + 4, 0), Palette.STAR_DARK, 3)
		draw_line(hbox.position + Vector2(i * 8, hbox.size.y), hbox.position + Vector2(i * 8 + 4, hbox.size.y), Palette.STAR_DARK, 3)
	draw_string(font, Vector2(hx, 74), host, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Palette.TEXT)
	draw_string(font, Vector2(x, 108), "Rede: igual para todos", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Palette.PRIMARY_DARK)
	draw_string(font, Vector2(maxf(hx - 10, x + 210), 108), "Computador: número diferente", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Palette.STAR_DARK)
