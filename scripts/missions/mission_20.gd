extends MissionBase
## Temporada 2, nível 10 — A Central de Suporte (missão final)
## Fila de chamados: escolher o mais urgente primeiro e resolver cada um com o que foi aprendido.

## Em ordem de prioridade (o primeiro é o mais urgente).
const TICKETS := [
	{"txt": "O sistema de matrículas parou: ninguém consegue se matricular", "who": "Secretaria",
		"q": "O disco do servidor de matrículas queimou. Como voltar a funcionar?",
		"right": "Restaurar o sistema a partir do backup", "wrong": ["Esperar até amanhã", "Formatar todos os computadores"],
		"tip": "Lembre da missão do backup: as cópias existem para isso.", "skill": "Restaurou um serviço crítico pelo backup"},
	{"txt": "A professora esqueceu a senha do e-mail e tem aula agora", "who": "Professora Ana",
		"q": "Como ajudar a professora com a senha?",
		"right": "Confirmar que é ela e criar uma senha nova forte", "wrong": ["Trocar a senha para 123456", "Dar a senha para quem ligar pedindo"],
		"tip": "Primeiro confirme a identidade; depois, senha forte.", "skill": "Redefiniu senha com segurança (identidade + senha forte)"},
	{"txt": "Um computador do laboratório apita e não mostra imagem", "who": "Laboratório",
		"q": "O computador faz bip bip bip e não mostra imagem. O que fazer?",
		"right": "Reencaixar a memória RAM", "wrong": ["Trocar o mouse", "Reinstalar a internet"],
		"tip": "Apitos ao ligar avisam de uma peça de dentro.", "skill": "Resolveu falha de hardware pelos apitos"},
	{"txt": "Um aluno quer instalar um jogo pirata no laboratório", "who": "Aluno Caio",
		"q": "O que responder ao aluno?",
		"right": "Explicar o perigo e indicar um jogo educativo do site oficial", "wrong": ["Instalar escondido", "Desligar o antivírus para instalar"],
		"tip": "Pirata é ilegal e costuma trazer vírus.", "skill": "Orientou o usuário sobre software seguro e legal"},
	{"txt": "Pedido para trocar o papel de parede da recepção", "who": "Recepção",
		"q": "Como atender esse pedido simples?",
		"right": "Trocar o papel de parede pelas configurações", "wrong": ["Formatar o computador", "Comprar um monitor novo"],
		"tip": "Pedido simples, solução simples.", "skill": "Atendeu um pedido simples de configuração"},
]

var queue_win: PanelContainer
var ticket_buttons: Array = []
var _done := 0
var _total := 0
var _step := ""
var _current := -1


func setup() -> void:
	place_icon = "star"
	floor_tile = "piso_frio"
	wall_items = [["janela", 0.3], ["faixa", 0.5], ["relogio", 0.64], ["cartaz_rede", 0.74], ["janela", 0.86]]
	floor_items = [["rack", Vector2(0.975, 0.3)], ["planta", Vector2(0.03, 0.9)]]
	set_objective("Atender a fila de chamados: o mais urgente primeiro.")
	var counter := DeviceView.new("counter", "Balcão da Central", "")
	counter.show_led = false
	place(counter, Vector2(0.1, 0.24))
	story("Último desafio! A Central de Suporte abriu e chegaram vários chamados ao mesmo tempo. Um técnico atende primeiro o que atrapalha mais pessoas. Você consegue!", _build_queue)


func _build_queue() -> void:
	_total = 4 if guided else 5
	var win := UiWindow.create("Fila de chamados", 720.0 * Game.ui_scale() / 0.7)
	queue_win = win.root
	place(queue_win, Vector2(0.52, 0.34))
	var order: Array = [3, 0, 2, 1] if guided else [4, 1, 3, 0, 2]       # embaralhado na tela
	for i in order:
		var t: Dictionary = TICKETS[i]
		var b := BigButton.new("#%d  %s  (%s)" % [2001 + i, t.txt, t.who], "report", "secondary", 56)
		b.set_meta("idx", i)
		b.pressed.connect(func(): _pick(b))
		win.body.add_child(b)
		ticket_buttons.append(b)
	_hint()


func _hint() -> void:
	_step = "escolher"
	queue_win.visible = true
	clear_actions()
	set_objective("Chamados resolvidos: %d de %d. Qual é o mais urgente agora?" % [_done, _total])
	var right: Button = null
	for b in ticket_buttons:
		if b.visible and int(b.get_meta("idx")) == _done:
			right = b
	set_step([
		"Escolha o chamado mais urgente: o que atrapalha mais pessoas ou é mais grave.",
		"Pergunte: quantas pessoas estão paradas por causa disso?",
		"Veja a mãozinha no chamado mais urgente.",
	], [right])
	say("Qual chamado atender agora? Pense em qual é o mais urgente.")


func _pick(b: Button) -> void:
	if busy or _step != "escolher":
		return
	var idx: int = b.get_meta("idx")
	if idx != _done:
		var why := ["Muita gente parada", "uma aula esperando", "um computador parado", "um risco de segurança", "algo que pode esperar"]
		try_again("Esse pode esperar um pouco. Existe um chamado mais urgente: procure o que atrapalha mais pessoas (%s)." % why[_done])
		return
	Game.record_skill(mission_id, "Priorizou chamados pela urgência")
	b.visible = false
	_current = idx
	_step = "resolver"
	queue_win.visible = false
	var t: Dictionary = TICKETS[idx]
	var opts: Array = [t.right, t.wrong[0]] if guided else [t.wrong[0], t.right, t.wrong[1]]
	choice("Chamado #%d (%s): %s" % [2001 + idx, t.who, t.q], opts, t.right,
		{"_dica": t.tip, t.wrong[0]: "Não resolve o problema e pode piorar. " + t.tip, t.wrong[1]: "Não é seguro nem resolve. " + t.tip},
		t.skill, _resolved)


func _resolved() -> void:
	_done += 1
	if _done >= _total:
		queue_win.visible = false
		complete("Fila zerada! A Central de Suporte funcionou perfeitamente com você no comando.")
	else:
		_hint.call_deferred()


func explorer_quiz() -> Array:
	return [
		{"q": "Qual chamado é mais urgente?",
			"options": ["Trocar a cor do mouse", "A internet da escola toda caiu", "Mudar o papel de parede"], "answer": 1,
			"explain": "Atenda primeiro o que para mais pessoas.",
			"skill": "Priorizou um incidente que afeta muitas pessoas"},
		{"q": "Antes de trocar a senha de alguém, o técnico deve:",
			"options": ["Confirmar que é a própria pessoa", "Publicar a senha nova", "Usar 123456"], "answer": 0,
			"explain": "Senão, um golpista pode pedir a senha de outra pessoa.",
			"skill": "Sabe confirmar a identidade antes de redefinir senha"},
	]
