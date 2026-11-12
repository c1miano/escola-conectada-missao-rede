extends ScreenBase
## Escolher quem vai jogar: lista de jogadores salvos neste computador + "Novo jogador".


func build() -> void:
	background()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var win := UiWindow.create("Quem vai jogar?", 620.0 * Game.ui_scale() / 0.7)
	center.add_child(win.root)
	var body: VBoxContainer = win.body
	var profiles := Game.list_profiles()
	if profiles.is_empty():
		text(body, "Ainda não há jogadores neste computador. Crie o seu!")
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, minf(profiles.size(), 4) * 78.0 * Game.ui_scale() / 0.7)
	body.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var first: Control = null
	for p in profiles:
		var row := _row(p)
		list.add_child(row)
		if first == null:
			first = row.get_meta("play")
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(bottom)
	var novo := button(bottom, "Novo jogador", "plus", func(): Game.goto("new_player"), "success", 70)
	button(bottom, "Voltar", "back", func(): Game.goto("title"), "secondary", 70)
	(first if first else novo).grab_focus.call_deferred()
	Voice.say("Quem vai jogar? Escolha seu nome ou crie um novo jogador.")


func _row(p: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color.WHITE if str(p.id) != Game.profile_id else Color("#fff3c4")
	st.border_color = Palette.FRAME_DARK
	st.set_border_width_all(2)
	st.set_corner_radius_all(5)
	st.content_margin_left = 6
	st.content_margin_right = 8
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", st)
	var row := HBoxContainer.new()
	panel.add_child(row)
	row.add_child(AvatarView.new(int(p.avatar), 4))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)
	var n := Label.new()
	n.text = str(p.nome)
	n.add_theme_font_size_override("font_size", Game.fs(26))
	info.add_child(n)
	var d := Label.new()
	d.text = "%d de %d missões · %d pontos" % [int(p.concluidas), Game.MISSIONS.size(), int(p.pontos)]
	d.add_theme_color_override("font_color", Palette.TEXT_SOFT)
	info.add_child(d)
	var id := str(p.id)
	var play := button(row, "Jogar", "play", func():
		Game.load_profile(id)
		Game.goto("map"), "success", 64)
	button(row, "Relatório", "report", func():
		Game.load_profile(id)
		Game.goto("progress"), "secondary", 64)
	var del := button(row, "", "cross", func(): _confirm_delete(id, str(p.nome)), "secondary", 64)
	del.tooltip_text = "Apagar este jogador"
	panel.set_meta("play", play)
	return panel


func _confirm_delete(id: String, nome: String) -> void:
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.55)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ov)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(c)
	var win := UiWindow.create("Apagar jogador", 420.0)
	c.add_child(win.root)
	text(win.body, "Apagar %s e todo o progresso? Isso não pode ser desfeito." % nome)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	win.body.add_child(row)
	var no := button(row, "Não, voltar", "back", func(): ov.queue_free(), "secondary", 64)
	button(row, "Sim, apagar", "cross", func():
		Game.delete_profile(id)
		Game.goto("players"), "primary", 64)
	no.grab_focus.call_deferred()
