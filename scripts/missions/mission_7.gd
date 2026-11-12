extends MissionBase
## Missão 7 — O cabo perfeito (Oficina de Cabos)
## Ferramentas, ordem dos fios no padrão T568B, crimpagem e teste com testador de cabo.

## Padrão T568B: pino 1 a 8
const ORDER := ["branco-laranja", "laranja", "branco-verde", "azul", "branco-azul", "verde", "branco-marrom", "marrom"]

var connector: ConnectorView
var tester: DeviceView
var reference: PanelContainer
var _pins: Array = []
var _step := ""


## Desenho do conector RJ-45 aberto, com os 8 pinos numerados.
class ConnectorView extends Control:
	var pins: Array = []
	var crimped := false
	var leds := -1            # quantos LEDs do testador acesos (-1 = sem teste)
	var bad := []             # pinos com defeito (teste do cabo ruim)

	func _init() -> void:
		custom_minimum_size = Vector2(420, 190)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var f := Game.ui_font
		var fs := Game.fs(18)
		# cabo
		draw_rect(Rect2(Vector2(0, 70), Vector2(80, 50)), Palette.CABLE)
		draw_rect(Rect2(Vector2(0, 70), Vector2(80, 50)), Palette.FRAME_DARK, false, 2)
		# conector transparente
		var body := Rect2(Vector2(80, 30), Vector2(320, 130))
		draw_rect(body, Color(0.85, 0.92, 1.0, 0.9))
		draw_rect(body, Palette.FRAME_DARK, false, 3)
		if crimped:
			draw_rect(Rect2(body.position + Vector2(0, 0), Vector2(body.size.x, 16)), Color("#c9a64a"))
		for i in 8:
			var x := body.position.x + 22 + i * 37
			var slot := Rect2(Vector2(x, body.position.y + 28), Vector2(24, 86))
			draw_rect(slot, Color.WHITE)
			draw_rect(slot, Palette.FRAME_DARK, false, 2)
			if i < pins.size():
				MissionWire.draw_wire(self, slot.grow(-3), pins[i])
			elif i == pins.size():
				draw_rect(slot.grow(3), Palette.FOCUS, false, 3)
			draw_string(f, Vector2(x + 7, body.position.y + 22), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT)
			if leds >= 0:
				var on := i < leds and not bad.has(i + 1)
				var c := Vector2(x + 12, body.end.y + 18)
				draw_circle(c, 9, Palette.LED_ON if on else Color("#cccccc"))
				draw_arc(c, 9, 0, TAU, 16, Palette.FRAME_DARK, 2)
				if on:
					Icons.draw(self, "check", c, 6, Color.WHITE)
				elif i < leds:
					Icons.draw(self, "cross", c, 6, Palette.ATTENTION)


## Botão de fio: cor (listrada quando é "branco-...") + nome escrito.
class WireButton extends Button:
	var wire := ""

	func _init(p_wire: String) -> void:
		wire = p_wire
		text = "      " + p_wire
		custom_minimum_size = Vector2(0, 40)
		focus_mode = Control.FOCUS_ALL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var st := preload("res://scripts/ui/theme_builder.gd").button_box(Color("#ecebe4"), Palette.FRAME_DARK)
		add_theme_stylebox_override("normal", st)
		add_theme_stylebox_override("hover", preload("res://scripts/ui/theme_builder.gd").button_box(Color.WHITE, Palette.FRAME_DARK))
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			add_theme_color_override(c, Palette.TEXT)

	func _draw() -> void:
		MissionWire.draw_wire(self, Rect2(Vector2(8, 8), Vector2(18, size.y - 16)), wire)


func setup() -> void:
	place_icon = "cable"
	floor_tile = "piso_frio"
	wall_items = [["cartaz_rede", 0.3], ["relogio", 0.42], ["quadro", 0.6], ["extintor", 0.97]]
	floor_items = [["armario", Vector2(0.975, 0.2)], ["mesa", Vector2(0.5, 0.9)]]
	set_objective("Montar um cabo de rede no padrão T568B e testar.")
	connector = ConnectorView.new()
	place(connector, Vector2(0.38, 0.42))
	connector.z_index = 6
	tester = DeviceView.new("tester", "Testador de cabo", "")
	tester.clicked.connect(_on_tester)
	place(tester, Vector2(0.84, 0.2))
	reference = _make_reference()
	place(reference, Vector2(0.12, 0.5))
	reference.visible = guided
	story("Precisamos de um cabo novo para a feira. Você vai montar o cabo: escolher as ferramentas, colocar os 8 fios na ordem certa e testar!", _tools_1)


func _make_reference() -> PanelContainer:
	var p := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var h := Label.new()
	h.text = "Padrão T568B"
	h.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	v.add_child(h)
	for i in ORDER.size():
		var l := Label.new()
		l.text = "%d. %s" % [i + 1, ORDER[i]]
		l.add_theme_font_size_override("font_size", Game.fs(18))
		v.add_child(l)
	return p


static func shuffled(arr: Array, seed_v: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
	return a


# ---------------------------------------------------------------- 1. ferramentas
func _choice(question: String, options: Array, right: String, wrong_tips: Dictionary, skill: String, next: Callable) -> void:
	clear_actions()
	var right_btn: Array = []
	for o in options:
		var b := add_action(o, "", func():
			if o == right:
				clear_actions()
				correct("Certo!", skill)
				next.call()
			else:
				try_again(wrong_tips.get(o, "Pense de novo. Leia a pergunta com calma.")), "secondary")
		b.custom_minimum_size.x = 0
		if o == right:
			right_btn.append(b)
	set_step([question, "Pense para que serve cada coisa.", "Veja a mãozinha na resposta."], right_btn)
	say(question)


func _tools_1() -> void:
	_step = "ferramentas"
	var opts := ["Alicate de crimpar", "Chave de fenda"] if guided else ["Tesoura", "Alicate de crimpar", "Chave de fenda", "Fita adesiva"]
	_choice("Qual ferramenta prende o conector no cabo?", opts, "Alicate de crimpar",
		{"Chave de fenda": "A chave de fenda serve para parafusos.", "Tesoura": "A tesoura só corta, não prende o conector.",
			"Fita adesiva": "Fita não prende o conector: o cabo ia soltar."},
		"Escolheu o alicate de crimpar", _tools_2)


func _tools_2() -> void:
	var opts := ["Conector RJ-45", "Conector USB"] if guided else ["Conector USB", "Conector RJ-45", "Plugue de tomada"]
	_choice("Qual peça vai na ponta do cabo de rede?", opts, "Conector RJ-45",
		{"Conector USB": "USB é para pen drive, mouse e teclado.", "Plugue de tomada": "A tomada é de energia, não de dados."},
		"Reconheceu o conector RJ-45", _wires_start)


# ---------------------------------------------------------------- 2. ordem dos fios
func _wires_start() -> void:
	_step = "fios"
	set_objective("Colocar os 8 fios no conector, na ordem do padrão T568B.")
	if guided:
		say("Agora os fios! Siga a tabela do padrão T568B, do pino 1 ao 8. Clique no fio certo para cada pino.")
	else:
		say("Agora os fios, do pino 1 ao 8, no padrão T568B. Se precisar, abra a tabela.")
	_show_wires()


func _show_wires() -> void:
	clear_actions()
	var need: String = ORDER[_pins.size()]
	var remaining: Array = ORDER.slice(_pins.size())
	var opts: Array
	if guided:
		# poucas escolhas: o fio certo + 2 dos que faltam
		opts = [need]
		for w in shuffled(remaining, _pins.size()):
			if opts.size() >= 3:
				break
			if not opts.has(w):
				opts.append(w)
		opts = shuffled(opts, 7 + _pins.size())
	else:
		opts = shuffled(remaining, 3 + _pins.size())
	var right: Array = []
	for w in opts:
		var b := WireButton.new(w)
		var wire: String = w
		b.pressed.connect(func():
			if not busy:
				Sfx.play("click")
				_pick(wire))
		actions.add_child(b)
		if w == need:
			right.append(b)
	if not guided and not reference.visible:
		add_action("Ver tabela", "help", func():
			reference.visible = true
			_hints_used += 1
			Game.record_hint(mission_id, 1), "star")
	set_step([
		"Pino %d: qual fio vai aqui? Olhe a tabela T568B." % (_pins.size() + 1),
		"No pino %d vai o fio %s." % [_pins.size() + 1, need],
		"Veja a mãozinha no fio %s." % need,
	], right)


func _pick(w: String) -> void:
	var need: String = ORDER[_pins.size()]
	if w != need:
		if guided:
			try_again("No pino %d não vai o %s. Olhe a tabela: no pino %d vai o %s." % [_pins.size() + 1, w, _pins.size() + 1, need])
		else:
			try_again("No pino %d não vai o %s. Confira a linha %d do padrão T568B." % [_pins.size() + 1, w, _pins.size() + 1])
		if not guided and not reference.visible:
			say("Dica: abra a tabela do padrão T568B no botão \"Ver tabela\".", "pensando")
		return
	_pins.append(w)
	connector.pins = _pins
	connector.queue_redraw()
	Sfx.play("connect")
	if _pins.size() == ORDER.size():
		correct("Fios na ordem certa!", "Montou os 8 fios no padrão T568B")
		_crimp_step.call_deferred()
	else:
		Game.record_attempt(mission_id, true)
		_show_wires()


# ---------------------------------------------------------------- 3. crimpar e testar
func _crimp_step() -> void:
	_step = "crimpar"
	clear_actions()
	set_objective("Crimpar o conector e testar o cabo.")
	var b := add_action("Crimpar com o alicate", "play", func():
		clear_actions()
		var t := animate("m7_crimpar")
		t.tween_property(connector, "scale", Vector2(0.96, 0.96), 0.15)
		t.tween_property(connector, "scale", Vector2.ONE, 0.15)
		t.tween_callback(func():
			connector.crimped = true
			connector.queue_redraw()
			Sfx.play("ok"))
		t.finished.connect(_test_step), "success")
	connector.pivot_offset = connector.size / 2.0
	set_step(["Clique em \"Crimpar com o alicate\".", "O botão verde está embaixo.", "Veja a mãozinha."], [b])
	say("Todos os fios no lugar! Agora é só apertar o conector com o alicate.")


func _test_step() -> void:
	_step = "testar"
	say("Cabo pronto! Agora clique no testador de cabo para conferir se os 8 fios conduzem.")
	set_step(["Clique no testador de cabo (lá em cima, à direita).", "O testador está piscando.", "Veja a mãozinha."], [tester])
	if guided:
		highlight([tester])


func _on_tester(_d) -> void:
	if busy or _step != "testar":
		return
	_step = "testando"
	var t := animate("m7_teste")
	connector.leds = 0
	for i in 8:
		t.tween_callback(func():
			connector.leds = i + 1
			connector.queue_redraw()
			Sfx.play("select"))
		t.tween_interval(0.18)
	t.finished.connect(func():
		correct("Os 8 fios funcionam!", "Testou o cabo com o testador")
		_bad_cable())


## Desafio mais difícil: um cabo com defeito para diagnosticar.
func _bad_cable() -> void:
	_step = "defeito"
	connector.bad = [3, 6]
	connector.leds = 8
	connector.queue_redraw()
	set_objective("Descobrir o defeito de um cabo antigo.")
	say("Agora um cabo antigo da escola. O testador acendeu todos, menos os pinos 3 e 6. O que aconteceu?", "pensando")
	var opts := ["Os fios 3 e 6 estão soltos ou trocados", "O cabo é azul"] if guided else ["O cabo é muito curto", "Os fios 3 e 6 estão soltos ou trocados", "Falta energia na tomada", "O cabo é azul"]
	_choice("Por que os pinos 3 e 6 não acenderam?", opts, "Os fios 3 e 6 estão soltos ou trocados",
		{"O cabo é azul": "A cor da capa não muda o funcionamento.", "O cabo é muito curto": "Se fosse isso, nenhum pino ia acender.",
			"Falta energia na tomada": "O cabo de rede não usa a tomada. E os outros pinos acenderam."},
		"Diagnosticou fios soltos ou trocados com o testador",
		func(): complete("Cabo perfeito! Você montou e testou como um técnico."))


func explorer_quiz() -> Array:
	return [
		{"q": "Quantos fios tem um cabo de rede de par trançado?",
			"options": ["4", "8", "2"], "answer": 1,
			"explain": "Conte os pinos do conector que você montou.",
			"skill": "Sabe que o cabo de par trançado tem 8 fios"},
		{"q": "No padrão T568B, qual fio vai no pino 1?",
			"options": ["Branco-verde", "Laranja", "Branco-laranja"], "answer": 2,
			"explain": "É o par laranja que começa o padrão B.",
			"skill": "Lembrou o início do padrão T568B"},
	]
