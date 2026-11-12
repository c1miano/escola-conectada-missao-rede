class_name UiWindow
## Janela compacta com barra de título (estilo jogos sociais em pixel art).
## create(titulo) devolve {"root": PanelContainer, "body": VBoxContainer}.


static func create(title: String, width: float = 0.0) -> Dictionary:
	var root := PanelContainer.new()
	var st := preload("res://scripts/ui/theme_builder.gd").panel_box()
	st.content_margin_left = 0
	st.content_margin_right = 0
	st.content_margin_top = 0
	st.content_margin_bottom = 0
	root.add_theme_stylebox_override("panel", st)
	if width > 0.0:
		root.custom_minimum_size.x = width
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	root.add_child(col)
	# barra de título
	var bar := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Palette.FRAME_DARK
	bs.corner_radius_top_left = 5
	bs.corner_radius_top_right = 5
	bs.content_margin_left = 10
	bs.content_margin_right = 10
	bs.content_margin_top = 4
	bs.content_margin_bottom = 4
	bar.add_theme_stylebox_override("panel", bs)
	var t := Label.new()
	t.text = title
	t.add_theme_font_override("font", Game.ui_font_bold)
	t.add_theme_color_override("font_color", Color.WHITE)
	bar.add_child(t)
	bar.visible = title != ""
	col.add_child(bar)
	# corpo
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	col.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)
	return {"root": root, "body": body, "title": t}
