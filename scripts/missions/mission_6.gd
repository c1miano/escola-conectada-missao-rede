extends MissionBase
## Missão 6 — Duas redes, um caminho (Sala dos Professores)
## Redes diferentes não se falam só com switch: é preciso um roteador e o gateway padrão em cada computador.

var sw_a: SwitchView
var sw_p: SwitchView
var router: DeviceView
var pc_a: DeviceView
var pc_p: DeviceView
var _router_sel := false
var _links := {}          # "a" / "p" -> porta
var _gw := {}             # DeviceView -> gateway escolhido
var _current: DeviceView = null
var _step := ""


func setup() -> void:
	place_icon = "next"
	floor_tile = "piso_madeira"
	wall_items = [["janela", 0.3], ["quadro", 0.5], ["relogio", 0.63], ["cartaz_rede", 0.74], ["janela", 0.86]]
	floor_items = [["planta", Vector2(0.03, 0.9)], ["arquivo", Vector2(0.975, 0.5)]]
	set_objective("Ligar a rede dos alunos à rede dos professores.")
	pc_a = DeviceView.new("pc", "Computador dos alunos", "IP: 192.168.1.20")
	pc_a.online = true
	pc_a.clicked.connect(_on_pc)
	place(pc_a, Vector2(0.12, 0.2))
	pc_p = DeviceView.new("pc", "Computador do professor", "IP: 192.168.2.30")
	pc_p.online = true
	pc_p.clicked.connect(_on_pc)
	place(pc_p, Vector2(0.86, 0.2))
	sw_a = SwitchView.new(3, "Switch dos alunos (192.168.1.x)")
	sw_a.online = true
	sw_a.port_clicked.connect(func(i): _on_port("a", i))
	place(sw_a, Vector2(0.22, 0.66))
	sw_p = SwitchView.new(3, "Switch dos professores (192.168.2.x)")
	sw_p.online = true
	sw_p.port_clicked.connect(func(i): _on_port("p", i))
	place(sw_p, Vector2(0.72, 0.66))
	router = DeviceView.new("router", "Roteador", "Desligado das redes")
	router.clicked.connect(_on_router)
	place(router, Vector2(0.47, 0.28))
	_wire.call_deferred()
	story("O professor quer mandar as notas para o computador dos alunos. Mas eles estão em redes diferentes: 192.168.1 e 192.168.2. Vamos descobrir como ligar as duas?", _begin)


func _wire() -> void:
	cables.add_cable(pc_a.anchor, func(): return sw_a.port_anchor(0), "ok")
	cables.add_cable(pc_p.anchor, func(): return sw_p.port_anchor(0), "ok")
	sw_a.set_port_used(0, true)
	sw_p.set_port_used(0, true)


# ---------------------------------------------------------------- 1. o problema
func _begin() -> void:
	_step = "teste1"
	clear_actions()
	var b := add_action("Testar (ping)", "retry", _first_ping)
	set_step([
		"Primeiro vamos testar: o professor manda um ping para o computador dos alunos.",
		"Clique no botão \"Testar (ping)\".",
		"Veja a mãozinha no botão de teste.",
	], [b])
	if not guided:
		say("Teste se o professor consegue falar com os alunos.")


func _first_ping() -> void:
	clear_actions()
	var t := animate("m6_ping_falha")
	send_packet(t, "ping 192.168.1.20", [pc_p, sw_p], Palette.SCREEN_ON, 0.6)
	send_packet(t, "Rede diferente!", [sw_p, pc_p], Palette.ATTENTION, 0.6)
	t.finished.connect(func():
		Game.record_skill(mission_id, "Percebeu que redes diferentes precisam de um roteador")
		say("Não chegou! O switch só liga computadores da MESMA rede. Para ligar redes diferentes usamos um ROTEADOR.", "pensando")
		_step_router())


# ---------------------------------------------------------------- 2. ligar o roteador nas duas redes
func _step_router() -> void:
	_step = "roteador"
	set_objective("Ligar o roteador no switch dos alunos e no switch dos professores.")
	set_step([
		"Clique no roteador e depois em uma porta livre de um switch. Faça isso nos dois switches.",
		"Primeiro o roteador (no meio), depois a porta 2 de um switch.",
		"Veja a mãozinha: roteador e depois porta do switch.",
	], [router, sw_a.ports[1]])
	if guided:
		highlight([router])


func _on_router(_d) -> void:
	if busy or _step != "roteador":
		return
	_router_sel = true
	router.selected = true
	Sfx.play("select")
	var next_sw := sw_a if not _links.has("a") else sw_p
	say("Agora clique em uma porta livre do %s." % next_sw.name_label.text.get_slice(" (", 0).to_lower())
	if guided:
		highlight([next_sw.ports[1]])


func _on_port(side: String, i: int) -> void:
	if busy or _step != "roteador":
		return
	var sw := sw_a if side == "a" else sw_p
	if not _router_sel:
		Game.record_attempt(mission_id, false)
		say("Primeiro clique no roteador. Depois na porta do switch.", "pensando")
		Sfx.play("retry")
		return
	if _links.has(side):
		say("O roteador já está ligado neste switch. Agora ligue no outro.")
		return
	if sw.port_used[i]:
		say("Essa porta já está ocupada. Escolha uma porta livre.")
		return
	_router_sel = false
	router.selected = false
	_links[side] = i
	sw.set_port_used(i, true)
	var port := i
	cables.add_cable(router.anchor, func(): return sw.port_anchor(port), "ok")
	Sfx.play("connect")
	if _links.size() == 1:
		correct("Primeira rede ligada!")
		say("Agora ligue o roteador no outro switch.")
		if guided:
			highlight([router])
	else:
		router.online = true
		router.set_info("192.168.1.1  |  192.168.2.1")
		correct("Roteador ligado nas duas redes!", "Ligou duas redes diferentes com um roteador")
		say("O roteador tem um endereço em cada rede: 192.168.1.1 do lado dos alunos e 192.168.2.1 do lado dos professores.", "feliz")
		_step_gateway.call_deferred()


# ---------------------------------------------------------------- 3. gateway padrão
func _step_gateway() -> void:
	_step = "gateway"
	set_objective("Configurar o gateway (porta de saída) de cada computador.")
	var nxt := pc_p if not _gw.has(pc_p) else pc_a
	set_step([
		"Cada computador precisa saber por onde sair da sua rede: o GATEWAY. Clique no %s." % nxt.name_label.text.to_lower(),
		"O gateway é o endereço do roteador na MESMA rede do computador.",
		"Veja a mãozinha clicando no computador.",
	], [nxt])
	if guided:
		highlight([nxt])


func _on_pc(d: DeviceView) -> void:
	if busy or _step != "gateway":
		return
	if _gw.has(d):
		say("Esse computador já tem gateway: %s." % _gw[d])
		return
	_current = d
	d.selected = true
	Sfx.play("select")
	clear_actions()
	var net := "192.168.2" if d == pc_p else "192.168.1"
	var own := "192.168.2.30" if d == pc_p else "192.168.1.20"
	var other := "192.168.1.1" if d == pc_p else "192.168.2.1"
	var cards := [net + ".1", other] if guided else [other, own, net + ".1", net + ".255"]
	var right: Array = []
	for c in cards:
		var b := add_action("Gateway: " + c, "", func(): _choose_gw(c, net, own), "secondary")
		b.custom_minimum_size.x = 0
		if c == net + ".1":
			right.append(b)
	set_step([
		"Escolha o gateway do %s. Ele começa com %s." % [d.name_label.text.to_lower(), net],
		"O roteador, do lado desta rede, tem o final .1.",
		"Veja a mãozinha no gateway certo.",
	], right)
	say("Qual é o gateway do %s?" % d.name_label.text.to_lower())


func _choose_gw(ip: String, net: String, own: String) -> void:
	if _current == null:
		return
	if ip == net + ".1":
		_gw[_current] = ip
		_current.selected = false
		_current.set_info(_current.info_label.text.get_slice("\n", 0) + "\nGateway: " + ip)
		correct("Gateway certo!", "Configurou o gateway padrão na mesma rede do computador")
		_current = null
		clear_actions()
		if _gw.size() == 2:
			_final_test.call_deferred()
		else:
			_step_gateway()
	elif ip == own:
		try_again("Esse é o endereço do próprio computador. O gateway é o roteador, a porta de saída.")
	elif ip.ends_with(".255"):
		try_again("O final .255 é reservado (é para falar com todos da rede ao mesmo tempo). Não pode ser gateway.")
	else:
		try_again("Esse é o roteador do lado da OUTRA rede. O gateway precisa começar igual ao computador: %s." % net)


# ---------------------------------------------------------------- 4. teste final
func _final_test() -> void:
	_step = "teste2"
	set_objective("Testar de novo a comunicação entre as duas redes.")
	var b := add_action("Testar de novo", "retry", func():
		clear_actions()
		var t := animate("m6_ping_ok")
		send_packet(t, "ping", [pc_p, sw_p, router, sw_a, pc_a], Palette.SCREEN_ON, 0.45)
		send_packet(t, "resposta", [pc_a, sw_a, router, sw_p, pc_p], Palette.LED_ON, 0.45)
		t.finished.connect(func():
			correct("Chegou!", "Testou a comunicação entre redes diferentes")
			complete("Agora as duas redes conversam pelo roteador!")), "success")
	set_step(["Clique em \"Testar de novo\".", "O botão verde está embaixo.", "Veja a mãozinha."], [b])


func explorer_quiz() -> Array:
	return [
		{"q": "O que o roteador faz?",
			"options": ["Liga redes diferentes", "Aumenta a tela", "Carrega a bateria"], "answer": 0,
			"explain": "Lembre: o switch liga a mesma rede; o roteador liga redes diferentes.",
			"skill": "Explicou a função do roteador"},
		{"q": "Um computador tem IP 10.0.5.8. Qual pode ser o gateway dele?",
			"options": ["192.168.1.1", "10.0.5.1", "10.0.5.255"], "answer": 1,
			"explain": "O gateway fica na mesma rede (10.0.5) e não pode ser o final .255.",
			"skill": "Escolheu o gateway de uma rede nova"},
	]
