extends MissionBase
## Temporada 2, nível 2 — O computador não liga (Balcão de Atendimento)
## Atendimento ao usuário, diagnóstico do mais simples ao mais difícil e registro do chamado.

var counter: DeviceView
var person: Control
var pc: DeviceView
var ticket: PanelContainer
var _step := ""
var _person_text := ""


func setup() -> void:
	place_icon = "user"
	floor_tile = "piso_madeira"
	wall_items = [["janela", 0.3], ["quadro", 0.5], ["relogio", 0.64], ["cartaz_rede", 0.74], ["janela", 0.86]]
	floor_items = [["planta", Vector2(0.03, 0.9)], ["arquivo", Vector2(0.975, 0.5)]]
	set_objective("Atender a professora e consertar o computador dela.")
	person = Control.new()
	person.custom_minimum_size = Vector2(16, 16) * 4
	person.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t0 := {"t": 0.0}
	person.draw.connect(func():
		t0.t += 0.016
		Sprites.draw(person, Walker.frame_name("visitante", "baixo", false, 0.0, t0.t), Vector2.ZERO, 4)
		person.queue_redraw())
	place(person, Vector2(0.28, 0.16))
	counter = DeviceView.new("counter", "Balcão de atendimento", "")
	counter.show_led = false
	place(counter, Vector2(0.28, 0.36))
	pc = DeviceView.new("pc", "Computador da professora", "Não liga")
	pc.clicked.connect(_on_pc)
	place(pc, Vector2(0.62, 0.3))
	ticket = info_window("Chamado #1024", ["Pedido: \"Meu computador não liga!\"", "Situação: aberto"], Vector2(0.84, 0.18), 330.0)
	story("A professora Marta chegou no balcão com um problema. Um bom técnico primeiro atende bem, depois investiga do mais simples para o mais difícil.", _greet)


func _ticket(lines: Array) -> void:
	var body: VBoxContainer = ticket.get_meta("body")
	for c in body.get_children():
		c.queue_free()
	for line in lines:
		var l := Label.new()
		l.text = line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 300.0 * Game.ui_scale() / 0.7
		body.add_child(l)


# ---------------------------------------------------------------- atendimento
func _greet() -> void:
	_step = "atender"
	var right := "Cumprimentar e perguntar o que aconteceu"
	var opts := [right, "Abrir o computador sem falar nada"] if guided else ["Dizer que deve ser culpa dela", right, "Abrir o computador sem falar nada"]
	choice("A professora chegou. O que você faz primeiro?", opts, right,
		{"_dica": "Atendimento começa com educação e escuta.",
			"Abrir o computador sem falar nada": "Antes de mexer, é preciso ouvir: o usuário sabe o que aconteceu.",
			"Dizer que deve ser culpa dela": "Culpar o usuário deixa a pessoa chateada e não ajuda a resolver."},
		"Atendeu o usuário com educação e escuta", _ask)


func _ask() -> void:
	var right := "O computador está ligado na tomada?"
	var opts := [right, "Qual é a cor do seu mouse?"] if guided else ["Você instalou algum jogo?", "Qual é a cor do seu mouse?", right]
	choice("A professora diz: \"Liguei e nem luz acende.\" Qual pergunta ajuda a começar pelo mais simples?", opts, right,
		{"_dica": "\"Nem luz\" quer dizer que não chega energia.",
			"Qual é a cor do seu mouse?": "A cor do mouse não muda nada no problema.",
			"Você instalou algum jogo?": "Programa não impede o computador de acender a luz. Pense em energia."},
		"Fez a pergunta certa para começar o diagnóstico", _check_cable)


func _check_cable() -> void:
	_step = "olhar"
	_ticket(["Pedido: \"Meu computador não liga!\"", "Sintoma: nenhuma luz acende", "Situação: em diagnóstico"])
	say("Vamos olhar o computador. Clique nele para investigar.")
	set_step(["Clique no computador da professora.", "Ele está piscando.", "Veja a mãozinha."], [pc])
	if guided:
		highlight([pc])


func _on_pc(_d) -> void:
	if busy:
		return
	match _step:
		"olhar":
			_step = "cabo"
			pc.set_info("Cabo de energia: SOLTO")
			var right := "Ligar o cabo de energia"
			var opts := [right, "Formatar o computador"] if guided else ["Trocar o monitor", right, "Formatar o computador"]
			choice("Atrás do computador, o cabo de energia está solto. O que fazer?", opts, right,
				{"_dica": "Resolva primeiro o problema que você viu.",
					"Formatar o computador": "Formatar apaga tudo e não resolve falta de energia.",
					"Trocar o monitor": "O monitor não é o problema: o computador nem acende a luz."},
				"Resolveu primeiro a causa mais simples (energia)", _beeps)
		"memoria":
			_step = "reencaixar"
			var t := animate("m12_memoria")
			t.tween_callback(func():
				pc.set_info("Memória reencaixada")
				Sfx.play("connect"))
			t.tween_interval(0.6)
			t.tween_callback(func():
				pc.online = true
				pc.screen_text = "Funcionando!"
				pc.queue_redraw()
				Sfx.play("ok"))
			t.finished.connect(func():
				correct("Ligou!", "Reencaixou a memória RAM")
				_write_ticket())


func _beeps() -> void:
	pc.set_info("Ligado, mas sem imagem")
	pc.screen_text = "bip bip bip"
	pc.queue_redraw()
	Sfx.play("alert")
	var right := "Memória RAM mal encaixada"
	var opts := [right, "Falta de internet"] if guided else ["Falta de internet", "Mouse quebrado", right, "Vírus"]
	choice("Agora ele liga, mas só apita (bip bip bip) e não mostra imagem. O que pode ser?", opts, right,
		{"_dica": "Os apitos ao ligar avisam que uma peça de dentro não foi reconhecida.",
			"Falta de internet": "Sem internet o computador liga normal e mostra imagem.",
			"Mouse quebrado": "O mouse não impede a imagem de aparecer.",
			"Vírus": "Vírus só age depois que o sistema liga. Aqui nem chega a mostrar imagem."},
		"Interpretou os apitos de erro do computador", func():
			_step = "memoria"
			say("Vamos reencaixar a memória. Clique no computador.")
			set_step(["Clique no computador para reencaixar a memória.", "Ele está piscando.", "Veja a mãozinha."], [pc])
			if guided:
				highlight([pc]))


func _write_ticket() -> void:
	var right := "Cabo de energia solto e memória mal encaixada. Reconectei e reencaixei."
	var opts := [right, "Arrumei."] if guided else ["Arrumei.", "Era um vírus.", right]
	choice("Como registrar o chamado para a equipe saber o que aconteceu?", opts, right,
		{"_dica": "O registro diz o problema e o que foi feito.",
			"Arrumei.": "Curto demais: ninguém vai saber o que foi o problema.",
			"Era um vírus.": "Não foi isso que aconteceu. O registro precisa ser verdadeiro."},
		"Registrou o chamado com problema e solução", _close)


func _close() -> void:
	_ticket(["Pedido: \"Meu computador não liga!\"", "Causa: cabo solto + memória mal encaixada", "Solução: reconectado e reencaixada", "Situação: RESOLVIDO"])
	var right := "Explicar o que foi feito e perguntar se está tudo bem"
	var opts := [right, "Ir embora sem falar nada"] if guided else ["Ir embora sem falar nada", right, "Falar só termos técnicos difíceis"]
	choice("Para terminar o atendimento, o que você faz?", opts, right,
		{"_dica": "O usuário precisa saber que pode voltar a usar o computador.",
			"Ir embora sem falar nada": "A professora nem sabe se pode usar. Explique e confirme.",
			"Falar só termos técnicos difíceis": "Use palavras simples para a pessoa entender."},
		"Encerrou o atendimento explicando e confirmando com o usuário",
		func(): complete("Chamado resolvido! A professora saiu feliz com o atendimento."))


func explorer_quiz() -> Array:
	return [
		{"q": "No suporte, por onde começar o diagnóstico?",
			"options": ["Pelo mais difícil", "Pelo mais simples", "Formatando"], "answer": 1,
			"explain": "Cabo solto e tomada desligada são os problemas mais comuns.",
			"skill": "Sabe começar o diagnóstico pelo mais simples"},
		{"q": "Para que serve registrar o chamado?",
			"options": ["Para a equipe saber o problema e a solução", "Para gastar papel", "Não serve para nada"], "answer": 0,
			"explain": "Se o problema voltar, a equipe sabe o que já foi feito.",
			"skill": "Entende a importância do registro de chamados"},
	]
