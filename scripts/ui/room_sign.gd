class_name RoomSign
extends Button
## Placa de uma sala no mapa: cadeado / estrela vazia / estrela cheia + texto do estado.

var mission: Dictionary
var state := "locked"  # locked, open, done


func _init(m: Dictionary) -> void:
	mission = m
	custom_minimum_size = Vector2(336, 80)
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
		s.set_border_width_all(4 if st != "focus" else 6)
		s.border_width_bottom = 8
		s.set_corner_radius_all(3)
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
	var font := ThemeDB.fallback_font
	var s := size
	var dark := Palette.TEXT if state != "locked" else Color("#3d4452")
	var ic := Vector2(36, s.y / 2.0 - 4)
	match state:
		"locked":
			Icons.draw(self, "lock", ic, 22, Color("#3d4452"))
		"open":
			Icons.draw(self, "star_empty", ic, 26, Palette.STAR_DARK)
		"done":
			draw_colored_polygon(Icons.star_points(ic, 26), Palette.STAR)
			Icons.draw(self, "star_empty", ic, 26, Palette.STAR_DARK)
	draw_string(font, Vector2(72, 30), "Missão %d · %s" % [mission.id, status_text()], HORIZONTAL_ALIGNMENT_LEFT, s.x - 80, 18, Palette.TEXT_SOFT if state != "locked" else dark)
	draw_string(font, Vector2(72, 58), mission.place, HORIZONTAL_ALIGNMENT_LEFT, s.x - 80, 19, dark)
