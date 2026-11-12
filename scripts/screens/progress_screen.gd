extends ScreenBase
## Relatório de progresso do jogador: mostra o cartão e salva como imagem PNG para enviar ao professor.

var _msg: Label
var _save: BigButton


func build() -> void:
	background()
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	# prévia do cartão (reduzida para caber na tela)
	var holder := Control.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.clip_contents = true
	row.add_child(holder)
	var card := ProgressCard.new()
	holder.add_child(card)
	holder.resized.connect(func():
		var k := minf(holder.size.x / ProgressCard.W, holder.size.y / ProgressCard.H)
		card.scale = Vector2(k, k)
		card.position = Vector2((holder.size.x - ProgressCard.W * k) / 2.0, 0).round())

	var win := UiWindow.create("Relatório de progresso", 340.0)
	win.root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(win.root)
	var body: VBoxContainer = win.body
	text(body, "Salve a imagem e envie para o seu professor.")
	_save = button(body, "Salvar imagem", "save", _save_png, "success", 76)
	button(body, "Jogar", "play", func(): Game.goto("map"), "primary", 70)
	button(body, "Voltar ao início", "home", func(): Game.goto("title"), "secondary", 70)
	_msg = Label.new()
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg.custom_minimum_size = Vector2(300, 0)
	_msg.add_theme_color_override("font_color", Palette.SUCCESS)
	body.add_child(_msg)
	_save.grab_focus.call_deferred()
	Voice.say("Relatório de progresso de %s. Clique em Salvar imagem e envie para o seu professor." % Game.student_name)


func _save_png() -> void:
	_save.disabled = true
	_msg.text = "Gerando a imagem..."
	var png: PackedByteArray = await ProgressCard.render_png(self)
	_msg.text = Game.save_user_file(Game.safe_file_name("progresso") + ".png", png, "image/png")
	Sfx.play("ok")
	_save.disabled = false
