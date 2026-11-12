extends ScreenBase
## Configurações: modo, narração, volume, animações, tamanho do texto, nome (opcional) e relatório.

var _rows: VBoxContainer


func build() -> void:
	background()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0) * (Game.ui_scale() / 0.7)
	center.add_child(panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 12)
	panel.add_child(_rows)
	_fill()


func _fill() -> void:
	for c in _rows.get_children():
		c.queue_free()
	heading(_rows, "Configurações", 34)

	var mode_row := _row("Modo de jogo")
	var g := button(mode_row, "Guiado", "help", func(): _set_mode(Game.MODE_GUIDED), "success" if Game.is_guided() else "secondary", 64)
	button(mode_row, "Explorador", "map", func(): _set_mode(Game.MODE_EXPLORER), "success" if not Game.is_guided() else "secondary", 64)
	g.grab_focus.call_deferred()
	_toggle("Narração das instruções", "narracao", "speaker")
	if not Voice.available():
		text(_rows, "Narração não disponível neste computador (sem voz do sistema).", 18)

	var vol_row := _row("Volume: %d%%" % int(round(Game.settings.volume * 100)))
	button(vol_row, "Diminuir", "minus", func(): _volume(-0.2), "secondary", 64)
	button(vol_row, "Aumentar", "plus", func(): _volume(0.2), "secondary", 64)

	_toggle("Pular animações repetidas", "pular_animacoes", "skip")
	_toggle("Texto grande", "texto_grande", "plus")

	var name_row := _row("Nome do estudante (opcional)")
	var le := LineEdit.new()
	le.text = Game.student_name
	le.placeholder_text = "Pode deixar em branco"
	le.custom_minimum_size = Vector2(240, 0)
	le.max_length = 40
	le.text_changed.connect(func(t):
		Game.student_name = t
		Game.save_game())
	name_row.add_child(le)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	_rows.add_child(bottom)
	button(bottom, "Relatório do professor", "report", func(): Game.goto("report"), "secondary", 72)
	button(bottom, "Voltar", "back", func(): Game.goto("map" if Game.has_save() else "title"), "primary", 72)


func _row(label: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	_rows.add_child(row)
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	return row


func _toggle(label: String, key: String, icon: String) -> void:
	var row := _row(label)
	var on: bool = Game.settings[key]
	var b := button(row, "Ligado" if on else "Desligado", "check" if on else "minus", func():
		Game.set_setting(key, not Game.settings[key])
		_refresh(), "success" if on else "secondary", 64)
	b.custom_minimum_size.x = 190


func _set_mode(m: String) -> void:
	Game.mode = m
	Game.save_game()
	_refresh()


func _volume(d: float) -> void:
	Game.set_setting("volume", clampf(snappedf(Game.settings.volume + d, 0.2), 0.0, 1.0))
	Sfx.play("ok")
	_refresh()


func _refresh() -> void:
	# reconstrói mantendo o foco aproximado
	_fill.call_deferred()
