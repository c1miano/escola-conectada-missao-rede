extends MissionBase
## Missão 8 — Escudo da escola (Sala da Direção)
## Senha forte no Wi-Fi, regras de firewall (portas) e e-mail falso (phishing).

var internet: PanelContainer
var firewall: DeviceView
var sw: SwitchView
var server: DeviceView
var pc: DeviceView
var ap: DeviceView
var rules_panel: PanelContainer
var email_panel: PanelContainer
var _step := ""
var _rules_done := 0


func setup() -> void:
	place_icon = "lock"
	floor_tile = "piso_madeira"
	wall_items = [["janela", 0.3], ["cartaz_wifi", 0.42], ["relogio", 0.52], ["quadro", 0.68], ["janela", 0.86]]
	floor_items = [["arquivo", Vector2(0.975, 0.5)], ["planta", Vector2(0.03, 0.9)]]
	set_objective("Proteger a rede da escola.")
	internet = PanelContainer.new()
	var il := Label.new()
	il.text = "INTERNET"
	il.add_theme_font_size_override("font_size", Game.fs(26))
	il.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	internet.add_child(il)
	place(internet, Vector2(0.07, 0.3))
	firewall = DeviceView.new("firewall", "Firewall", "Sem regras")
	firewall.online = true
	firewall.clicked.connect(_on_firewall)
	place(firewall, Vector2(0.26, 0.26))
	sw = SwitchView.new(4)
	sw.online = true
	place(sw, Vector2(0.48, 0.72))
	server = DeviceView.new("server", "Servidor Web", "porta 80 (site)")
	server.online = true
	place(server, Vector2(0.48, 0.24))
	pc = DeviceView.new("pc", "Computador da direção", "")
	pc.online = true
	pc.clicked.connect(_on_pc)
	place(pc, Vector2(0.70, 0.24))
	ap = DeviceView.new("ap", "Wi-Fi da direção", "Senha: 123456")
	ap.online = true
	ap.clicked.connect(_on_ap)
	place(ap, Vector2(0.88, 0.22))
	_wire.call_deferred()
	story("A escola vai receber muitos visitantes na feira. A diretora pediu: vamos proteger a rede! Senhas, firewall e cuidado com e-mails falsos.", _step_password)


func _wire() -> void:
	cables.add_cable(internet.get_global_rect().get_center, firewall.anchor, "ok")
	var i := 0
	for d in [firewall, server, pc, ap]:
		var p := i
		cables.add_cable(d.anchor, func(): return sw.port_anchor(p), "ok")
		sw.set_port_used(i, true)
		i += 1


# ---------------------------------------------------------------- 1. senha forte
func _step_password() -> void:
	_step = "senha"
	set_objective("Trocar a senha fraca do Wi-Fi da direção.")
	say("A senha do Wi-Fi da direção é 123456. Qualquer um adivinha! Clique no Wi-Fi da direção para trocar.", "pensando")
	set_step(["Clique no Wi-Fi da direção (à direita).", "Ele está piscando.", "Veja a mãozinha."], [ap])
	if guided:
		highlight([ap])


func _on_ap(_d) -> void:
	if busy or _step != "senha":
		return
	clear_actions()
	var opts := ["123456", "F3ir@-Rede#26"] if guided else ["escola", "Escola2026", "123456789", "F3ir@-Rede#26"]
	var right: Array = []
	for o in opts:
		var b := add_action("Senha: " + o, "", func(): _choose_password(o), "secondary")
		b.custom_minimum_size.x = 0
		if o == "F3ir@-Rede#26":
			right.append(b)
	set_step([
		"Escolha a senha mais forte: grande, com letras maiúsculas e minúsculas, números e símbolos.",
		"Procure a senha que mistura tudo: letras, números e símbolos como @ e #.",
		"Veja a mãozinha na senha forte.",
	], right)
	say("Qual é a senha mais forte?")


func _choose_password(p: String) -> void:
	match p:
		"F3ir@-Rede#26":
			ap.set_info("Senha forte ativada")
			clear_actions()
			correct("Senha forte!", "Escolheu uma senha forte (tamanho, números, símbolos, maiúsculas)")
			say("Isso! Ela é grande e mistura maiúsculas, minúsculas, números e símbolos.", "feliz")
			_step_firewall.call_deferred()
		"123456", "123456789":
			try_again("Só números em sequência é a primeira coisa que alguém tenta. Escolha outra.")
		"escola":
			try_again("Uma palavra comum, curta e sem números é fácil de adivinhar.")
		_:
			try_again("Melhorou, mas ainda é um nome conhecido e sem símbolos. Procure uma com símbolos.")


# ---------------------------------------------------------------- 2. firewall
const RULES := [
	{"txt": "Site da feira (HTTP, porta 80)", "ok": true, "why": "O site precisa ficar aberto para os visitantes."},
	{"txt": "Acesso remoto de desconhecidos (porta 3389)", "ok": false, "why": "Deixar desconhecidos controlarem os computadores é perigoso."},
	{"txt": "Nomes de sites (DNS, porta 53)", "ok": true, "why": "Sem DNS ninguém acha os sites pelo nome."},
	{"txt": "Programa desconhecido (porta 6666)", "ok": false, "why": "Programa que ninguém conhece pode ser um vírus."},
]


func _step_firewall() -> void:
	_step = "firewall"
	set_objective("Criar as regras do firewall: permitir o que é útil e bloquear o perigoso.")
	set_step([
		"O firewall é o porteiro da rede. Clique nele para criar as regras.",
		"O firewall fica entre a Internet e a escola.",
		"Veja a mãozinha no firewall.",
	], [firewall])
	if guided:
		highlight([firewall])


func _on_firewall(_d) -> void:
	if busy or _step != "firewall" or rules_panel:
		return
	var rules: Array = RULES.slice(0, 2) if guided else RULES
	var win := UiWindow.create("Regras do firewall", 520.0 * Game.ui_scale() / 0.7)
	rules_panel = win.root
	place(rules_panel, Vector2(0.5, 0.42))
	rules_panel.z_index = 9
	var right: Array = []
	for r in rules:
		var row := HBoxContainer.new()
		win.body.add_child(row)
		var l := Label.new()
		l.text = r.txt
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var allow := BigButton.new("Permitir", "check", "secondary", 56)
		var block := BigButton.new("Bloquear", "cross", "secondary", 56)
		row.add_child(allow)
		row.add_child(block)
		var rule: Dictionary = r
		for pair in [[allow, true], [block, false]]:
			var btn: BigButton = pair[0]
			var val: bool = pair[1]
			btn.pressed.connect(func():
				if val == rule.ok:
					allow.disabled = true
					block.disabled = true
					btn.set_variant("success")
					l.text = rule.txt + (" — permitido" if val else " — bloqueado")
					_rules_done += 1
					correct("Regra certa!")
					if _rules_done == rules.size():
						_firewall_done()
				else:
					try_again(rule.why))
		right.append(allow if rule.ok else block)
	set_step([
		"Para cada regra, escolha Permitir ou Bloquear. Permita o que é útil, bloqueie o perigoso.",
		"O site e o DNS são úteis. Acesso de desconhecidos e programas estranhos são perigosos.",
		"Veja a mãozinha nas respostas.",
	], right)
	say("Para cada regra: permitir ou bloquear?")


func _firewall_done() -> void:
	Game.record_skill(mission_id, "Criou regras de firewall (permitir e bloquear portas)")
	firewall.set_info("%d regras ativas" % _rules_done)
	var t := animate("m8_firewall")
	t.tween_interval(0.5)
	t.tween_callback(func(): rules_panel.visible = false)
	send_packet(t, "HTTP :80", [internet, firewall, sw, server], Palette.LED_ON, 0.45)
	send_packet(t, "ataque :3389", [internet, firewall], Palette.ATTENTION, 0.5)
	send_packet(t, "BLOQUEADO", [firewall, internet], Palette.ATTENTION, 0.5)
	t.finished.connect(func():
		say("O site passou e o ataque foi barrado no firewall!", "feliz")
		_step_phishing())


# ---------------------------------------------------------------- 3. e-mail falso
func _step_phishing() -> void:
	_step = "email"
	set_objective("Analisar um e-mail estranho que chegou para a diretora.")
	pc.screen_text = "1 e-mail"
	pc.queue_redraw()
	say("Chegou um e-mail estranho no computador da direção. Clique no computador para ler.", "pensando")
	set_step(["Clique no computador da direção.", "Ele está piscando.", "Veja a mãozinha."], [pc])
	if guided:
		highlight([pc])


func _on_pc(_d) -> void:
	if busy or _step != "email" or email_panel:
		return
	var win := UiWindow.create("E-mail", 480.0 * Game.ui_scale() / 0.7)
	email_panel = win.root
	place(email_panel, Vector2(0.5, 0.4))
	email_panel.z_index = 9
	for line in ["De: premios@escola-c0nectada.com", "Assunto: VOCÊ GANHOU UM NOTEBOOK!!!",
			"Clique no link em 1 hora e digite sua senha para receber o prêmio."]:
		var l := Label.new()
		l.text = line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 440.0 * Game.ui_scale() / 0.7
		win.body.add_child(l)
	clear_actions()
	var opts := ["Apagar e avisar o professor", "Clicar no link"] if guided else ["Clicar no link", "Responder com a senha", "Apagar e avisar o professor", "Mandar para os amigos"]
	var right: Array = []
	for o in opts:
		var b := add_action(o, "", func(): _choose_email(o), "secondary")
		b.custom_minimum_size.x = 0
		if o.begins_with("Apagar"):
			right.append(b)
	set_step([
		"O que fazer com esse e-mail? Olhe o endereço: tem um zero no lugar da letra o.",
		"Pressa, prêmio e pedido de senha são sinais de golpe.",
		"Veja a mãozinha na atitude certa.",
	], right)
	say("O que você faz com esse e-mail?")


func _choose_email(o: String) -> void:
	if o.begins_with("Apagar"):
		clear_actions()
		email_panel.visible = false
		pc.screen_text = ""
		pc.queue_redraw()
		correct("Golpe evitado!", "Reconheceu um e-mail falso (phishing)")
		complete("A rede da escola está protegida: senha forte, firewall e atenção aos golpes!")
	elif o == "Clicar no link" or o == "Responder com a senha":
		try_again("É um golpe! O endereço é falso (escola-c0nectada com zero) e ninguém pede senha por e-mail.")
	else:
		try_again("Mandar para os amigos espalha o golpe. Pense em quem pode ajudar.")


func explorer_quiz() -> Array:
	return [
		{"q": "Para que serve um firewall?",
			"options": ["Esquentar o servidor", "Permitir ou bloquear conexões", "Deixar a internet mais rápida"], "answer": 1,
			"explain": "Lembre: ele foi o porteiro que barrou o ataque.",
			"skill": "Explicou a função do firewall"},
		{"q": "Qual destas é a senha mais forte?",
			"options": ["maria2010", "Bl@c0-Azul#77", "abcdefgh"], "answer": 1,
			"explain": "A forte mistura maiúsculas, minúsculas, números e símbolos.",
			"skill": "Reconheceu uma senha forte"},
	]
