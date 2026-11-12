extends ScreenBase
## Mapa da escola com as cinco áreas. Quando tudo é concluído, a escola aparece iluminada.

var bubble: Label
var bit: BitView


func build() -> void:
	background(Color("#8ecae6") if not Game.all_completed() else Color("#1b2a4a"))
	var art := Control.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(func(): _draw_school(art))
	add_child(art)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var root := VBoxContainer.new()
	margin.add_child(root)

	var top := PanelContainer.new()
	root.add_child(top)
	var row := HBoxContainer.new()
	top.add_child(row)
	var t := Label.new()
	t.text = "Mapa da Escola"
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	row.add_child(t)
	var stars := Control.new()
	stars.custom_minimum_size = Vector2(260, 50)
	stars.draw.connect(func():
		for i in Game.MISSIONS.size():
			var c := Vector2(30 + i * 48, 25)
			if Game.is_completed(i + 1):
				stars.draw_colored_polygon(Icons.star_points(c, 20), Palette.STAR)
			Icons.draw(stars, "star_empty", c, 21, Palette.STAR_DARK))
	row.add_child(stars)
	var count := Label.new()
	count.text = "%d de %d missões" % [Game.completed.size(), Game.MISSIONS.size()]
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(count)
	button(row, "Configurações", "gear", func(): Game.goto("settings"), "secondary", 60)
	button(row, "Início", "home", func(): Game.goto("title"), "secondary", 60)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var grid := VBoxContainer.new()
	grid.add_theme_constant_override("separation", 18)
	center.add_child(grid)
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 18)
	r1.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_child(r1)
	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 18)
	r2.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_child(r2)
	var first_focus: Control = null
	for m in Game.MISSIONS:
		var card := RoomCard.new(m)
		var id: int = m.id
		card.pressed.connect(func(): _open(id))
		(r1 if id <= 3 else r2).add_child(card)
		if first_focus == null and card.state == "open":
			first_focus = card
	if Game.all_completed():
		var cert := button(r2, "Ver certificado", "certificate", func(): Game.goto("final"), "star", 180)
		cert.custom_minimum_size.x = 300
		first_focus = cert
	if first_focus:
		first_focus.grab_focus.call_deferred()

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(bottom)
	var bp := PanelContainer.new()
	bp.custom_minimum_size = Vector2(520, 0)
	bottom.add_child(bp)
	bubble = Label.new()
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bp.add_child(bubble)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(110, 100)
	bottom.add_child(holder)
	bit = BitView.new()
	holder.add_child(bit)
	_greet()


func _greet() -> void:
	var msg := ""
	if Game.all_completed():
		msg = "A escola está toda conectada! A feira pode começar. Você pode repetir qualquer missão."
		bit.mood = "feliz"
	elif Game.completed.is_empty():
		msg = "Olá! Eu sou o Bit. A feira de tecnologia precisa da sua ajuda. Comece pelo Laboratório!"
	else:
		var next := Game.completed.size() + 1
		msg = "Muito bem! Agora vá para: %s." % Game.mission_info(next).place
	bubble.text = msg
	Voice.say(msg)


func _open(id: int) -> void:
	if not Game.is_unlocked(id):
		var msg := "Esta área ainda está fechada. Termine a missão %d primeiro." % (id - 1)
		bubble.text = msg
		bit.mood = "pensando"
		Voice.say(msg)
		Sfx.play("retry")
		return
	Game.goto("mission", {"id": id})


func _draw_school(c: Control) -> void:
	var s := c.size
	var lit := Game.all_completed()
	var wall := Color("#f2e3c6") if not lit else Color("#ffe8a3")
	# chão e prédio
	c.draw_rect(Rect2(Vector2(0, s.y * 0.86), Vector2(s.x, s.y * 0.14)), Color("#7cb342") if not lit else Color("#2e5d34"))
	var b := Rect2(Vector2(s.x * 0.04, s.y * 0.17), Vector2(s.x * 0.92, s.y * 0.72))
	if lit:
		c.draw_rect(b.grow(26), Color(1, 0.85, 0.3, 0.18))
		c.draw_rect(b.grow(12), Color(1, 0.85, 0.3, 0.25))
	c.draw_rect(b, wall)
	c.draw_rect(b, Color("#8d6e63"), false, 6)
	c.draw_colored_polygon(PackedVector2Array([b.position + Vector2(-20, 0), Vector2(b.get_center().x, b.position.y - 40), b.position + Vector2(b.size.x + 20, 0)]), Color("#c0504d"))
	if lit:
		# luzes da feira
		for i in 24:
			var x := b.position.x + i * b.size.x / 23.0
			c.draw_circle(Vector2(x, b.position.y + 8 + sin(i) * 4), 6, [Palette.STAR, Palette.LED_ON, Palette.SCREEN_ON][i % 3])
