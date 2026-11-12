extends ScreenBase
## Tela inicial: logotipo, Jogar, Continuar, Configurações e Sair.

var _confirm: Control


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
