extends MissionBase
## Missão 10 — A grande Feira de Tecnologia (Auditório da Feira)
## Missão final: montar a rede da feira juntando tudo (estrela, DHCP, Wi-Fi, DNS e diagnóstico).

const TASKS := ["Ligar os equipamentos no switch", "Ativar o DHCP", "Conectar o notebook no Wi-Fi", "Configurar o DNS do site", "Testar o site no totem"]

var sw: SwitchView
var server: DeviceView
var router: DeviceView
var totem: DeviceView
var ap: DeviceView
var notebook: DeviceView
var checklist: PanelContainer
var _check_labels: Array = []
var _done := 0
var _step := ""
var _selected: DeviceView = null
var _linked := {}
var _server_mode := ""


func setup() -> void:
	place_icon = "star"
	floor_tile = "piso_tijolo"
	wall_items = [["janela", 0.3], ["faixa", 0.5], ["relogio", 0.64], ["cartaz_wifi", 0.74], ["janela", 0.86]]
	floor_items = [["palanque", Vector2(0.5, 0.18)], ["cadeira", Vector2(0.36, 0.95)], ["cadeira", Vector2(0.6, 0.95)], ["planta", Vector2(0.03, 0.9)]]
	set_objective("Montar a rede da Feira de Tecnologia do começo ao fim.")
	server = DeviceView.new("server", "Servidor da feira", "IP: 192.168.1.10")
	server.clicked.connect(_on_device)
	place(server, Vector2(0.36, 0.2))
	router = DeviceView.new("router", "Roteador (Internet)", "IP: 192.168.1.1")
	router.clicked.connect(_on_device)
	place(router, Vector2(0.62, 0.2))
	totem = DeviceView.new("pc", "Totem da feira", "Sem endereço")
	totem.clicked.connect(_on_device)
	place(totem, Vector2(0.84, 0.22))
	ap = DeviceView.new("ap", "Wi-Fi da feira", "FeiraConectada")
	ap.clicked.connect(_on_device)
	place(ap, Vector2(0.84, 0.62))
	notebook = DeviceView.new("notebook", "Notebook do visitante", "Sem rede")
	notebook.clicked.connect(_on_device)
	place(notebook, Vector2(0.62, 0.62))
	sw = SwitchView.new(4 if guided else 6)
	sw.port_clicked.connect(_on_port)
	place(sw, Vector2(0.4, 0.78))
	_build_checklist()
	story("Chegou o grande dia! O auditório está vazio e você vai montar toda a rede da feira. Use tudo o que aprendeu. Bit acredita em você!", _task_cables)


func _build_checklist() -> void:
	var win := UiWindow.create("Lista da feira", 0.0)
	checklist = win.root
	for t in TASKS:
		var l := Label.new()
		l.text = "[  ] " + t
		l.add_theme_font_size_override("font_size", Game.fs(19))
		win.body.add_child(l)
		_check_labels.append(l)
	place(checklist, Vector2(0.14, 0.36))


func _tick() -> void:
	(_check_labels[_done] as Label).text = "[OK] " + TASKS[_done]
	(_check_labels[_done] as Label).add_theme_color_override("font_color", Palette.SUCCESS)
	_done += 1
	Sfx.play("ok")


# ---------------------------------------------------------------- 1. estrela
func _cable_targets() -> Array:
	return [server, router, totem, ap]


func _task_cables() -> void:
	_step = "cabos"
	_next_cable_hint()


func _next_cable_hint() -> void:
	for d in _cable_targets():
		if not _linked.has(d):
			set_step([
				"Ligue no switch: servidor, roteador, totem e Wi-Fi. Clique no aparelho e depois numa porta livre.",
				"Agora o %s. Depois uma porta livre do switch." % d.name_label.text.to_lower(),
				"Veja a mãozinha: aparelho e porta.",
			], [d, sw.ports[maxi(sw.free_port(), 0)]])
			if guided:
				highlight([d])
			return
	sw.online = true
	for d in _cable_targets():
		d.online = d != totem
	server.online = true
	_tick()
	correct("Rede em estrela pronta!", "Montou sozinho a rede em estrela da feira")
	_task_dhcp.call_deferred()


func _on_device(d: DeviceView) -> void:
	if busy:
		return
	match _step:
		"cabos":
			if d == notebook:
				say("O notebook do visitante não usa cabo: ele vai entrar pelo Wi-Fi depois.", "pensando")
				return
			if _linked.has(d):
				say("O %s já está ligado." % d.name_label.text.to_lower())
				return
			if _selected:
				_selected.selected = false
			_selected = d
			d.selected = true
			Sfx.play("select")
			say("Agora uma porta livre do switch.")
		"dhcp", "dns":
			if d == server:
				_open_server()
			else:
				say("Essa configuração fica no servidor da feira.", "pensando")
		"wifi":
			if d == notebook:
				_open_wifi()
			else:
				say("Clique no notebook do visitante.", "pensando")
		"teste":
			if d == totem:
				_test_site()
			else:
				say("O teste é no totem da feira.", "pensando")


func _on_port(i: int) -> void:
	if busy or _step != "cabos":
		return
	if _selected == null:
		Game.record_attempt(mission_id, false)
		say("Primeiro clique em um aparelho, depois na porta.", "pensando")
		Sfx.play("retry")
		return
	if sw.port_used[i]:
		say("Essa porta está ocupada.")
		return
	var d := _selected
	_selected = null
	d.selected = false
	_linked[d] = i
	sw.set_port_used(i, true)
	cables.add_cable(d.anchor, func(): return sw.port_anchor(i), "ok")
	Sfx.play("connect")
	Game.record_attempt(mission_id, true)
	_next_cable_hint()


# ---------------------------------------------------------------- 2. DHCP / 4. DNS (no servidor)
func _task_dhcp() -> void:
	_step = "dhcp"
	say("Agora os endereços. Clique no servidor da feira e configure o DHCP.")
	set_step(["Clique no servidor da feira para ligar o DHCP.", "O servidor está piscando.", "Veja a mãozinha."], [server])
	if guided:
		highlight([server])


func _open_server() -> void:
	clear_actions()
	server.selected = true
	var right := ""
	var opts: Array
	var tips := {}
	if _step == "dhcp":
		right = "Distribuir de 192.168.1.100 a .150"
		opts = [right, "Distribuir de 10.0.0.1 a .50"] if guided else ["Distribuir de 192.168.1.1 a .50", right, "Distribuir de 10.0.0.1 a .50"]
		tips = {"Distribuir de 10.0.0.1 a .50": "Essa faixa é de outra rede. A feira usa 192.168.1.",
			"Distribuir de 192.168.1.1 a .50": "Essa faixa inclui o .1 (roteador) e o .10 (servidor): ia dar conflito de IP!"}
		say("Qual faixa de endereços o DHCP vai distribuir?")
	else:
		right = "feira.escola = 192.168.1.10"
		opts = [right, "feira.escola = 192.168.1.1"] if guided else ["feira.escola = 8.8.8.8", "feira.escola = 192.168.1.1", right]
		tips = {"feira.escola = 192.168.1.1": "O .1 é o roteador. O site está no servidor da feira.",
			"feira.escola = 8.8.8.8": "Esse endereço é de fora da escola. O site está no servidor da feira."}
		say("Qual registro de DNS leva o nome do site ao servidor certo?")
	var rb: Array = []
	for o in opts:
		var b := add_action(o, "", func():
			if o == right:
				clear_actions()
				server.selected = false
				if _step == "dhcp":
					_dhcp_done()
				else:
					_dns_done()
			else:
				try_again(tips.get(o, "Pense de novo.")), "secondary")
		b.custom_minimum_size.x = 0
		if o == right:
			rb.append(b)
	set_step(["Escolha a opção certa para o servidor.", tips.values()[0], "Veja a mãozinha."], rb)


func _dhcp_done() -> void:
	correct("DHCP ligado!", "Configurou uma faixa de DHCP sem conflito")
	server.set_info("DHCP: .100 a .150")
	var t := animate("m10_dhcp")
	send_packet(t, "Pedido", [totem, sw, server], Palette.SCREEN_ON, 0.4)
	send_packet(t, "IP .100 + gateway .1", [server, sw, totem], Palette.STAR, 0.4)
	t.finished.connect(func():
		totem.online = true
		totem.set_info("IP: 192.168.1.100")
		_tick()
		_task_wifi())


# ---------------------------------------------------------------- 3. Wi-Fi
func _task_wifi() -> void:
	_step = "wifi"
	say("Um visitante chegou com notebook. Clique nele para conectar no Wi-Fi da feira.")
	set_step(["Clique no notebook do visitante.", "Ele está piscando.", "Veja a mãozinha."], [notebook])
	if guided:
		highlight([notebook])


func _open_wifi() -> void:
	clear_actions()
	var opts := ["FeiraConectada", "Vizinho_5G"] if guided else ["Gratis_WiFi", "Vizinho_5G", "FeiraConectada"]
	var rb: Array = []
	for o in opts:
		var b := add_action(o, "wifi", func():
			if o == "FeiraConectada":
				clear_actions()
				cables.add_cable(notebook.anchor, ap.anchor, "wifi")
				notebook.online = true
				notebook.set_info("IP: 192.168.1.101")
				correct("Conectado!", "Conectou um visitante na rede Wi-Fi certa")
				_tick()
				_task_dns.call_deferred()
			else:
				try_again("Essa rede não é da feira. Redes desconhecidas podem ser armadilhas."), "secondary")
		if o == "FeiraConectada":
			rb.append(b)
	set_step(["Escolha a rede da feira.", "A rede da feira se chama FeiraConectada.", "Veja a mãozinha."], rb)


func _task_dns() -> void:
	_step = "dns"
	say("Os visitantes vão digitar feira.escola. Configure o DNS no servidor da feira.")
	set_step(["Clique no servidor da feira para configurar o DNS.", "O servidor está piscando.", "Veja a mãozinha."], [server])
	if guided:
		highlight([server])


func _dns_done() -> void:
	correct("DNS configurado!", "Criou o registro de DNS do site")
	server.set_info("DHCP + DNS")
	_tick()
	_step = "teste"
	say("Último passo: teste o site no totem da feira.")
	set_step(["Clique no totem da feira para abrir o site.", "O totem está piscando.", "Veja a mãozinha."], [totem])
	if guided:
		highlight([totem])


# ---------------------------------------------------------------- 5. teste e falha surpresa
func _test_site() -> void:
	_step = "diagnostico"
	var t := animate("m10_teste")
	send_packet(t, "DNS: feira.escola?", [totem, sw, server], Palette.SCREEN_ON, 0.4)
	send_packet(t, "192.168.1.10", [server, sw, totem], Palette.STAR, 0.4)
	send_packet(t, "HTTP: pedido", [totem, sw, server], Palette.SCREEN_ON, 0.4)
	send_packet(t, "sem resposta", [server, sw, totem], Palette.ATTENTION, 0.4)
	t.finished.connect(func():
		totem.screen_text = "Erro"
		totem.queue_redraw()
		say("Ih! O DNS respondeu, mas a página não abriu. Hora de ser detetive: o que está faltando?", "pensando")
		clear_actions()
		var right := "Ligar o serviço Web no servidor"
		var opts := [right, "Trocar o cabo do totem"] if guided else ["Trocar o cabo do totem", "Mudar o IP do totem", right]
		var rb: Array = []
		for o in opts:
			var b := add_action(o, "", func():
				if o == right:
					clear_actions()
					_fix_web()
				elif o == "Trocar o cabo do totem":
					try_again("O cabo funciona: o DNS respondeu pelo mesmo cabo.")
				else:
					try_again("O IP está certo: o totem recebeu resposta do DNS."), "secondary")
			b.custom_minimum_size.x = 0
			if o == right:
				rb.append(b)
		set_step(["O DNS funcionou, mas o site não. O que falta no servidor?", "Pense no serviço que entrega páginas (HTTP).", "Veja a mãozinha."], rb))


func _fix_web() -> void:
	correct("Achou o problema!", "Diagnosticou o serviço Web desligado na missão final")
	server.set_info("DHCP + DNS + Web")
	var t := animate("m10_ok")
	send_packet(t, "HTTP: pedido", [totem, sw, server], Palette.SCREEN_ON, 0.4)
	send_packet(t, "Página da feira", [server, sw, totem], Palette.LED_ON, 0.4)
	send_packet(t, "Página da feira", [server, sw, ap, notebook], Palette.LED_ON, 0.4)
	t.tween_callback(func():
		totem.screen_text = "Feira"
		totem.queue_redraw()
		notebook.screen_text = "Feira")
	t.finished.connect(func():
		_tick()
		complete("A Feira de Tecnologia está no ar! Você montou a rede inteira, do cabo ao site."))


func explorer_quiz() -> Array:
	return [
		{"q": "Por que o DHCP não pode distribuir o endereço do servidor (.10)?",
			"options": ["Daria conflito de IP", "O servidor ficaria mais rápido", "Não faz diferença"], "answer": 0,
			"explain": "Dois aparelhos com o mesmo endereço não funcionam.",
			"skill": "Explicou por que excluir IPs fixos da faixa do DHCP"},
		{"q": "Qual a ordem de uma visita ao site feira.escola?",
			"options": ["HTTP, depois DNS", "DNS, depois HTTP", "Só ping"], "answer": 1,
			"explain": "Primeiro descobre o endereço pelo nome; depois pede a página.",
			"skill": "Ordenou DNS e HTTP no acesso a um site"},
	]
