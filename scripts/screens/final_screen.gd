extends ScreenBase
## Final: escola iluminada + certificado entregue pelo Bit.


var temporada := 1


func configure(params: Dictionary) -> void:
	temporada = int(params.get("temporada", 1))


func build() -> void:
	background(Color("#1b2a4a"))
	var glow := Control.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.draw.connect(func():
		var s := glow.size
		for i in 40:
			var p := Vector2(fmod(i * 197.0, s.x), fmod(i * 113.0, s.y * 0.5))
			glow.draw_circle(p, 3 + i % 3, Color(1, 0.9, 0.5, 0.5)))
	add_child(glow)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	center.add_child(col)

	var cert := Control.new()
	cert.custom_minimum_size = Vector2(900, 440)
	cert.draw.connect(func(): _draw_certificate(cert))
	col.add_child(cert)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	var save := button(row, "Salvar certificado", "save", func(): _save(cert), "success", 72)
	button(row, "Voltar ao mapa", "map", func(): Game.goto("map"), "primary", 72)
	save.grab_focus.call_deferred()

	cert.pivot_offset = cert.custom_minimum_size / 2.0
	cert.scale = Vector2(0.6, 0.6)
	cert.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(cert, "modulate:a", 1.0, 0.4)
	t.parallel().tween_property(cert, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	Sfx.play("win")
	Voice.say("Parabéns! Bit entrega o seu certificado: %s. %s concluída!" % [Game.SEASON_TITLES[temporada], Game.SEASON_NAMES[temporada]])


func _draw_certificate(c: Control) -> void:
	var s := c.size
	var font := Game.ui_font
	c.draw_rect(Rect2(Vector2.ZERO, s), Color("#fffaf0"))
	c.draw_rect(Rect2(Vector2(10, 10), s - Vector2(20, 20)), Palette.STAR_DARK, false, 6)
	c.draw_rect(Rect2(Vector2(22, 22), s - Vector2(44, 44)), Palette.PRIMARY, false, 2)
	var lines := [
		["CERTIFICADO", 52, Palette.PRIMARY_DARK, 90],
		[Game.SEASON_TITLES[temporada], 46, Palette.TEXT, 170],
		[Game.SEASON_NAMES[temporada] + " concluída!", 30, Palette.SUCCESS, 225],
	]
	var who: String = Game.student_name.strip_edges()
	if who != "":
		lines.append(["Entregue a: " + who, 28, Palette.TEXT, 280])
	var pts := 0
	var st := 0
	for m in Game.season_missions(temporada):
		pts += Game.mission_points(m.id)
		st += Game.mission_stars(m.id)
	lines.append(["%d pontos  ·  %d de %d estrelas" % [pts, st, Game.PER_SEASON * 3], 26, Palette.PRIMARY_DARK, 312])
	var dd := Time.get_date_dict_from_system()
	lines.append(["Data: %02d/%02d/%04d" % [dd.day, dd.month, dd.year], 22, Palette.TEXT_SOFT, 345])
	for l in lines:
		var w := font.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, l[1]).x
		c.draw_string(font, Vector2((s.x - w) / 2.0, l[3]), l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, l[1], l[2])
	Sprites.draw(c, "avatar_%d_baixo_parado_0" % Game.avatar, Vector2(60, s.y - 150), 6)
	for i in 5:
		var p := Vector2(s.x / 2.0 - 120 + i * 60, 390)
		c.draw_colored_polygon(Icons.star_points(p, 24), Palette.STAR)
	c.draw_string(font, Vector2(s.x - 190, s.y - 40), "Assinado: Bit", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.TEXT_SOFT)


func _save(cert: Control) -> void:
	# Captura a tela inteira (o certificado ocupa o centro).
	var part := get_viewport().get_texture().get_image()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(part.save_png_to_buffer(), "certificado.png", "image/png")
	else:
		var path := "user://certificado.png"
		part.save_png(path)
		OS.shell_open(ProjectSettings.globalize_path("user://"))
	Sfx.play("ok")
