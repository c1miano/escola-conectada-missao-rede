extends ScreenBase
## Tela inicial: logotipo, Continuar como <jogador>, Trocar/Novo jogador, Relatório de progresso, Configurações e Sair.



func build() -> void:
	background()
	var deco := Control.new()
	deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.draw.connect(func(): _draw_scene(deco))
	add_child(deco)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	center.add_child(col)

	var logo_panel := PanelContainer.new()
	col.add_child(logo_panel)
	var logo := Control.new()
	logo.custom_minimum_size = Vector2(640, 170)
	logo.draw.connect(func(): _draw_logo(logo))
	logo_panel.add_child(logo)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	buttons.custom_minimum_size = Vector2(300, 0) * (Game.ui_scale() / 0.7)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(buttons)
	var cont: BigButton = null
	if Game.has_save():
		cont = button(buttons, "Continuar como %s" % Game.student_name, "next", func(): Game.goto("map"), "success", 80)
		var who := Label.new()
		who.text = "%d de %d missões · %d pontos · %d estrelas" % [Game.completed.size(), Game.MISSIONS.size(), Game.total_points(), Game.total_stars()]
		who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		who.add_theme_color_override("font_color", Color.WHITE)
		buttons.add_child(who)
	var players := button(buttons, "Novo jogador" if not Game.has_save() else "Trocar de jogador", "user", func(): Game.goto("players"), "primary" if Game.has_save() else "success", 76)
	if Game.has_save():
		button(buttons, "Relatório de progresso", "report", func(): Game.goto("progress"), "star", 72)
	button(buttons, "Configurações", "gear", func(): Game.goto("settings"), "secondary", 72)
	var quit := button(buttons, "Sair", "exit", func(): get_tree().quit(), "secondary", 72)
	quit.visible = not OS.has_feature("web")
	(cont if cont else players).grab_focus.call_deferred()
	Voice.say("Escola Conectada: Missão Rede." + (" Continuar como %s?" % Game.student_name if Game.has_save() else ""))


func _draw_logo(c: Control) -> void:
	var font := Game.ui_font
	var s := c.size
	# ícone de rede em estrela
	var hub := Vector2(90, s.y / 2.0)
	for a in [-2.4, -0.8, 0.8, 2.4]:
		var p: Vector2 = hub + Vector2(cos(a), sin(a)) * 62
		c.draw_line(hub, p, Palette.CABLE, 6)
		c.draw_rect(Rect2(p - Vector2(14, 14), Vector2(28, 28)), Palette.LED_ON)
		c.draw_rect(Rect2(p - Vector2(14, 14), Vector2(28, 28)), Palette.FRAME_DARK, false, 4)
	c.draw_rect(Rect2(hub - Vector2(28, 16), Vector2(56, 32)), Palette.STAR)
	c.draw_rect(Rect2(hub - Vector2(28, 16), Vector2(56, 32)), Palette.FRAME_DARK, false, 4)
	c.draw_string(font, Vector2(180, s.y / 2.0 - 10), "Escola Conectada", HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Palette.PRIMARY_DARK)
	c.draw_string(font, Vector2(184, s.y / 2.0 + 46), "Missão Rede", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Palette.STAR_DARK)


func _draw_scene(c: Control) -> void:
	# laboratório em pixel art ao fundo, com o técnico e o Bit
	Room.draw(c, Rect2(Vector2(10, 10), c.size - Vector2(20, 20)), "piso_tijolo",
		[["janela", 0.12], ["quadro", 0.3], ["relogio", 0.42], ["cartaz_rede", 0.58], ["janela", 0.72], ["cartaz_wifi", 0.86]],
		[["pc_on", Vector2(0.08, 0.3)], ["servidor_on", Vector2(0.92, 0.25)], ["estante", Vector2(0.97, 0.8)], ["planta", Vector2(0.03, 0.9)]])
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.08, 0.1, 0.22, 0.35))
	Sprites.draw_centered(c, "tecnico_baixo_0", Vector2(c.size.x * 0.13, c.size.y * 0.72), 8)
	Sprites.draw_centered(c, "bit_feliz", Vector2(c.size.x * 0.87, c.size.y * 0.72), 8)
