class_name RoomCard
extends Button
## Cartão de uma área da escola no mapa: cadeado / estrela vazia / estrela cheia + texto do estado.

const PLACE_ICONS := {1: "cable", 2: "user", 3: "report", 4: "gear", 5: "wifi"}

var mission: Dictionary
var state := "locked"  # locked, open, done


func _init(m: Dictionary) -> void:
	mission = m
	custom_minimum_size = Vector2(380, 212)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if Game.is_completed(m.id):
		state = "done"
	elif Game.is_unlocked(m.id):
		state = "open"
	var bg := Color("#fffdf5")
	var border := Palette.PRIMARY
	match state:
		"locked":
			bg = Color("#e3e7ec")
			border = Color("#8a96a8")
		"done":
			bg = Color("#fff4cc")
			border = Palette.STAR_DARK
	for st in ["normal", "hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.bg_color = bg if st == "normal" else bg.darkened(0.06)
		s.border_color = border
		s.set_border_width_all(4 if st == "normal" else 6)
		s.set_corner_radius_all(18)
		add_theme_stylebox_override(st, s)
	pressed.connect(func(): Sfx.play("click"))


func status_text() -> String:
	match state:
		"done": return "Concluída"
		"open": return "Disponível"
	return "Fechada"


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var s := size
	var dark := Palette.TEXT if state != "locked" else Color("#56606e")
	# ícone do local
	draw_circle(Vector2(52, 58), 34, Palette.PRIMARY if state != "locked" else Color("#9aa5b4"))
	Icons.draw(self, PLACE_ICONS.get(mission.id, "home"), Vector2(52, 58), 20, Color.WHITE)
	draw_string(font, Vector2(98, 50), "Missão %d" % mission.id, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.TEXT_SOFT)
	draw_multiline_string(font, Vector2(20, 126), mission.title, HORIZONTAL_ALIGNMENT_LEFT, s.x - 40, 23, 2, dark)
	draw_string(font, Vector2(20, s.y - 16), mission.place, HORIZONTAL_ALIGNMENT_LEFT, s.x - 40, 19, Palette.TEXT_SOFT)
	# estado: ícone + palavra (não depende só da cor)
	var ic := Vector2(s.x - 50, 44)
	match state:
		"locked":
			Icons.draw(self, "lock", ic, 26, Color("#56606e"))
		"open":
			Icons.draw(self, "star_empty", ic, 30, Palette.STAR_DARK)
		"done":
			Icons.draw(self, "star", ic, 30, Palette.STAR)
			var p := Icons.star_points(ic, 30)
			p.append(p[0])
			draw_polyline(p, Palette.STAR_DARK, 3, true)
	var st := status_text()
	var w := font.get_string_size(st, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, Vector2(s.x - 50 - w / 2.0, 94), st, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, dark)
	if has_focus():
		draw_rect(Rect2(Vector2(-4, -4), s + Vector2(8, 8)), Palette.FOCUS, false, 5)
