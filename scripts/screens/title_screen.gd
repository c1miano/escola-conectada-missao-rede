extends ScreenBase
## Tela inicial: logotipo, Jogar, Continuar, Configurações e Sair.

var _confirm: Control


func build() -> void:
	background()
	var deco := Control.new()
	deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.draw.connect(func(): _draw_network(deco))
	add_child(deco)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	center.add_child(col)

	var logo := Control.new()
	logo.custom_minimum_size = Vector2(620, 190)
	logo.draw.connect(func(): _draw_logo(logo))
	col.add_child(logo)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	buttons.custom_minimum_size = Vector2(420, 0)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(buttons)
	var play := button(buttons, "Jogar", "play", _on_play, "success", 80)
	var cont := button(buttons, "Continuar", "next", func(): Game.goto("map"), "primary", 80)
	cont.disabled = not Game.has_save()
	button(buttons, "Configurações", "gear", func(): Game.goto("settings"), "secondary", 72)
	var quit := button(buttons, "Sair", "exit", func(): get_tree().quit(), "secondary", 72)
	quit.visible = not OS.has_feature("web")
	(cont if Game.has_save() else play).grab_focus.call_deferred()
	Voice.say("Escola Conectada: Missão Rede.")


func _on_play() -> void:
	if Game.completed.size() > 0:
		_ask_restart()
	else:
		Game.goto("mode")


func _ask_restart() -> void:
	_confirm = ColorRect.new()
	(_confirm as ColorRect).color = Color(0, 0, 0, 0.6)
	_confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_confirm)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(c)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(620, 0)
	c.add_child(p)
	var box := VBoxContainer.new()
	p.add_child(box)
	heading(box, "Começar do início?", 30)
	text(box, "As missões voltam a ficar fechadas. O relatório do professor continua guardado.")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var yes := button(row, "Sim, começar", "play", func(): Game.goto("mode"), "success")
	button(row, "Não, voltar", "back", func(): _confirm.queue_free(), "secondary")
	yes.grab_focus.call_deferred()
	Voice.say("Começar do início? As missões voltam a ficar fechadas.")


func _draw_logo(c: Control) -> void:
	var font := ThemeDB.fallback_font
	var s := c.size
	# ícone de rede em estrela
	var hub := Vector2(90, s.y / 2.0)
	for a in [-2.4, -0.8, 0.8, 2.4]:
		var p: Vector2 = hub + Vector2(cos(a), sin(a)) * 62
		c.draw_line(hub, p, Palette.SCREEN_ON, 6, true)
		c.draw_circle(p, 16, Palette.LED_ON)
	c.draw_rect(Rect2(hub - Vector2(26, 16), Vector2(52, 32)), Palette.STAR)
	c.draw_string(font, Vector2(180, s.y / 2.0 - 14), "Escola Conectada", HORIZONTAL_ALIGNMENT_LEFT, -1, 56, Color.WHITE)
	c.draw_string(font, Vector2(184, s.y / 2.0 + 44), "Missão Rede", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Palette.STAR)


func _draw_network(c: Control) -> void:
	var s := c.size
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var pts: Array[Vector2] = []
	for i in 18:
		pts.append(Vector2(rng.randf() * s.x, rng.randf() * s.y))
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			if pts[i].distance_to(pts[j]) < 260:
				c.draw_line(pts[i], pts[j], Color(1, 1, 1, 0.07), 2)
	for p in pts:
		c.draw_circle(p, 6, Color(1, 1, 1, 0.15))
