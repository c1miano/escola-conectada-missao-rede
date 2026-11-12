extends ScreenBase
## Relatório pedagógico local para o professor.

var _msg: Label


func build() -> void:
	background()
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	heading(col, "Relatório do professor", 32)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var body := Label.new()
	body.text = Game.report_text()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 19)
	scroll.add_child(body)
	_msg = Label.new()
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg.add_theme_color_override("font_color", Palette.SUCCESS)
	col.add_child(_msg)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	var save := button(row, "Salvar relatório", "save", func(): _msg.text = Game.export_report(), "success", 70)
	button(row, "Apagar relatório", "cross", _confirm_clear, "secondary", 70)
	button(row, "Voltar", "back", func(): Game.goto("settings"), "primary", 70)
	save.grab_focus.call_deferred()


func _confirm_clear() -> void:
	if _msg.get_meta("confirm", false):
		Game.clear_report()
		Game.goto("report")
	else:
		_msg.set_meta("confirm", true)
		_msg.add_theme_color_override("font_color", Palette.ATTENTION)
		_msg.text = "Clique em \"Apagar relatório\" de novo para confirmar. As missões concluídas não são apagadas."
