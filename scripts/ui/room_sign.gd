class_name RoomSign
extends Button
## Placa de uma sala no mapa: cadeado / estrela vazia / estrela cheia + texto do estado.

var mission: Dictionary
var state := "locked"  # locked, open, done


func _init(m: Dictionary) -> void:
	mission = m
	custom_minimum_size = Vector2(250, 52) * (Game.ui_scale() / 0.7)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Missão %d — %s" % [m.id, m.title]
	if Game.is_completed(m.id):
		state = "done"
	elif Game.is_unlocked(m.id):
		state = "open"
	var bg := Palette.CREAM
	match state:
		"locked": bg = Color("#c9cdd8")
		"done": bg = Color("#fff1b8")
	for st in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxFlat.new()
		s.bg_color = bg if st != "hover" else bg.lightened(0.25)
		s.border_color = Palette.FOCUS if st == "focus" else Palette.FRAME_DARK
		s.set_border_width_all(2 if st != "focus" else 4)
		s.border_width_bottom = 4
		s.set_corner_radius_all(5)
		if st == "focus":
			s.draw_center = false
		add_theme_stylebox_override(st, s)
	pressed.connect(func(): Sfx.play("click"))


func status_text() -> String:
	match state:
		"done": return "Concluída"
		"open": return "Disponível"
	return "Fechada"


func _draw() -> void:
	var font := Game.ui_font
	var s := size
	var dark := Palette.TEXT if state != "locked" else Color("#3d4452")
	var k := s.y / 52.0
	var ic := Vector2(22 * k, s.y / 2.0 - 1)
	var r := 14.0 * k
	match state:
		"locked":
			Icons.draw(self, "lock", ic, r * 0.85, Color("#3d4452"))
		"open":
			Icons.draw(self, "star_empty", ic, r, Palette.STAR_DARK)
		"done":
			draw_colored_polygon(Icons.star_points(ic, r), Palette.STAR)
			Icons.draw(self, "star_empty", ic, r, Palette.STAR_DARK)
	var f1 := Game.fs(18)
	var f2 := Game.fs(21)
	var bold := Game.ui_font_bold
	var line1 := "Missão %d · %s" % [mission.id, status_text()]
	if state == "done":
		line1 = "Missão %d · %d pontos" % [mission.id, Game.mission_points(mission.id)]
		# estrelas ganhas (1 a 3) à direita
		for i in 3:
			var c := Vector2(s.x - 14 * k - (2 - i) * 15 * k, s.y / 2.0 - 9 * k)
			if i < Game.mission_stars(mission.id):
				draw_colored_polygon(Icons.star_points(c, 6 * k), Palette.STAR)
			Icons.draw(self, "star_empty", c, 6 * k, Palette.STAR_DARK)
	draw_string(font, Vector2(44 * k, s.y / 2.0 - 4 * k), line1, HORIZONTAL_ALIGNMENT_LEFT, s.x - 100 * k, f1, Palette.TEXT_SOFT if state != "locked" else dark)
	draw_string(bold, Vector2(44 * k, s.y / 2.0 + 14 * k), mission.place, HORIZONTAL_ALIGNMENT_LEFT, s.x - 50 * k, f2, dark)
