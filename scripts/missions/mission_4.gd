extends MissionBase
## Missão 4 — O detetive das redes (Sala de Servidores)
## Três falhas: A) cabo solto, B) IP de outra rede, C) serviço Web desligado.

var sw: SwitchView
var server: DeviceView
var pc_a: DeviceView
var pc_b: DeviceView
var loose_cable: Dictionary
var clue_panel: PanelContainer
var clue_label: Label
var services_panel: PanelContainer
var problem := ""
var solved := 0


func setup() -> void:
	floor_tile = "piso_frio"
	wall_items = [["cartaz_rede", 0.32], ["relogio", 0.42], ["extintor", 0.97]]
	floor_items = [["rack", Vector2(0.62, 0.86)], ["rack", Vector2(0.66, 0.86)], ["rack", Vector2(0.97, 0.86)]]
	place_icon = "gear"
	room_color = Color("#d7dde8")
	floor_color = Color("#9aa3b0")
	sw = SwitchView.new(4)
	sw.online = true
	place(sw, Vector2(0.42, 0.78))
	server = DeviceView.new("server", "Servidor Web", "IP: 192.168.1.10")
	server.online = true
	place(server, Vector2(0.08, 0.60))
	pc_a = DeviceView.new("pc", "Computador A", "IP: 192.168.1.30")
	place(pc_a, Vector2(0.28, 0.26))
	pc_b = DeviceView.new("pc", "Computador B", "IP: 10.0.0.25")
	place(pc_b, Vector2(0.56, 0.26))
	clue_panel = PanelContainer.new()
	clue_label = Label.new()
	clue_label.add_theme_font_size_override("font_size", Game.fs(20))
	clue_label.custom_minimum_size = Vector2(330, 0)
	clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clue_panel.add_child(clue_label)
	place(clue_panel, Vector2(0.84, 0.32))
	_wire.call_deferred()
	story("Tudo parecia pronto... mas alguns computadores começaram a dar problema! Vamos investigar como detetives.", _problem_a)


func _wire() -> void:
	cables.add_cable(server.anchor, func(): return sw.port_anchor(0), "ok")
	sw.set_port_used(0, true)
	loose_cable = cables.add_cable(pc_a.anchor, pc_a.anchor, "loose")
	cables.add_cable(pc_b.anchor, func(): return sw.port_anchor(2), "ok")
	sw.set_port_used(2, true)
	pc_b.online = true


func _title(n: int, text: String) -> void:
	set_objective("Problema %d de 3: %s" % [n, text])


func _clue(text: String) -> void:
	clue_label.text = "Pistas\n" + text


# ---------------------------------------------------------------- A: cabo solto
func _problem_a() -> void:
	problem = "a"
	_title(1, "o Computador A está sem rede.")
	pc_a.set_info("Sem conexão")
	_clue("• Luz do Computador A apagada\n• O cabo está pendurado, fora do switch")
	var opts := [["Ligar o cabo no switch", true], ["Trocar o mouse", false]]
	if not guided:
		opts.insert(1, ["Mudar o IP do computador", false])
	_options(opts, "Olhe bem o cabo do Computador A. Ele está ligado em algum lugar?",
		"Siga o cabo do Computador A com os olhos: ele não chega ao switch.", [pc_a], _fix_a)
	say("O Computador A está sem rede. Olhe as pistas e escolha o que fazer.")


func _fix_a() -> void:
	correct("Boa ideia!", "Identificou um cabo desconectado")
	say("Agora clique em uma porta livre do switch para ligar o cabo.")
	var port_ok := [false]
	set_step([
		"Clique em uma porta livre do switch para ligar o cabo.",
		"A porta 2 está livre. Clique nela.",
		"Veja a mãozinha clicando na porta 2.",
	], [sw.ports[1]])
	if guided:
		highlight([sw.ports[1]])
	sw.port_clicked.connect(func(i):
		if port_ok[0] or problem != "a":
			return
		if sw.port_used[i]:
			say("Essa porta já está ocupada. Escolha uma porta livre.")
			return
		port_ok[0] = true
		cables.remove_cable(loose_cable)
		cables.add_cable(pc_a.anchor, func(): return sw.port_anchor(i), "ok")
		sw.set_port_used(i, true)
		pc_a.online = true
		pc_a.set_info("IP: 192.168.1.30")
		Sfx.play("connect")
		correct("Cabo ligado!", "Reconectou o cabo de rede no switch")
		_next_problem.call_deferred())


# ---------------------------------------------------------------- B: IP errado
func _problem_b() -> void:
	problem = "b"
	_title(2, "o Computador B não conversa com ninguém.")
	pc_b.selected = true
	pc_b.screen_text = "10.0.0.25"
	pc_b.queue_redraw()
	_clue("• Teste (ping) do B: sem resposta\n• Os outros usam 192.168.1...\n• O B usa 10.0.0.25")
	var opts := [["IP 192.168.1.25", true], ["IP 10.0.0.26", false]]
	if not guided:
		opts.append(["IP 192.168.1.10", false])
	_options(opts, "Compare o começo do endereço do B com o dos outros computadores.",
		"O começo do endereço precisa ser 192.168.1 e o final não pode repetir.", [pc_b], _fix_b)
	say("O Computador B está ligado, mas não responde. Compare os endereços.")


func _fix_b() -> void:
	pc_b.selected = false
	pc_b.screen_text = ""
	pc_b.set_info("IP: 192.168.1.25")
	correct("Endereço corrigido!", "Corrigiu um IP que estava em outra rede")
	var t := animate("m4_ping_b")
	send_packet(t, "ping", [pc_b, sw, server], Palette.SCREEN_ON, 0.5)
	send_packet(t, "resposta", [server, sw, pc_b], Palette.LED_ON, 0.5)
	t.finished.connect(_next_problem)


# ---------------------------------------------------------------- C: serviço Web desligado
func _problem_c() -> void:
	problem = "c"
	_title(3, "o site da feira não abre.")
	pc_a.screen_text = "Erro"
	pc_a.queue_redraw()
	_clue("• Ping para o servidor: responde\n• Navegador: \"não foi possível abrir a página\"\n• Então a rede funciona...")
	var opts := [["Verificar o servidor Web", true], ["Trocar o cabo", false]]
	if not guided:
		opts.append(["Mudar o IP do computador", false])
	_options(opts, "O ping funciona, então o cabo e o IP estão certos. O problema está no serviço do servidor.",
		"Se a rede responde mas o site não abre, olhe o programa que entrega o site: o servidor Web.", [server], _fix_c)
	say("O ping funciona, mas o site não abre. O que será?")


func _fix_c() -> void:
	correct("Boa investigação!", "Diferenciou falha de rede de falha de serviço")
	clear_actions()
	clue_panel.visible = false
	services_panel = PanelContainer.new()
	var v := VBoxContainer.new()
	services_panel.add_child(v)
	var h := Label.new()
	h.text = "Serviços do servidor"
	h.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	v.add_child(h)
	var net := Label.new()
	net.text = "Rede: LIGADA"
	v.add_child(net)
	var web := Label.new()
	web.text = "Serviço Web (HTTP): DESLIGADO"
	v.add_child(web)
	var b := BigButton.new("Ligar o serviço Web", "play", "success", 70)
	v.add_child(b)
	place(services_panel, Vector2(0.84, 0.36))
	set_step([
		"Clique em \"Ligar o serviço Web\".",
		"O botão verde está no painel de serviços.",
		"Veja a mãozinha no botão.",
	], [b])
	say("Achamos! O serviço Web está desligado. Ligue o serviço.")
	b.pressed.connect(func():
		if busy:
			return
		web.text = "Serviço Web (HTTP): LIGADO"
		b.disabled = true
		Game.record_skill(mission_id, "Ativou o serviço Web no servidor")
		var t := animate("m4_http")
		send_packet(t, "HTTP: pedido", [pc_a, sw, server], Palette.SCREEN_ON, 0.5)
		send_packet(t, "HTTP: página", [server, sw, pc_a], Palette.LED_ON, 0.5)
		t.tween_callback(func():
			pc_a.screen_text = "Feira"
			pc_a.queue_redraw())
		t.finished.connect(_next_problem))


# ---------------------------------------------------------------- comum
## Mostra as opções de solução. Cada opção: [texto, certa?]
func _options(opts: Array, hint2: String, hint_wrong: String, focus: Array, on_right: Callable) -> void:
	clear_actions()
	var right: Array = []
	for o in opts:
		var ok: bool = o[1]
		var b := add_action(o[0], "", func():
			if ok:
				clear_actions()
				on_right.call()
			else:
				try_again(hint_wrong), "secondary")
		b.custom_minimum_size.x = 0
		if ok:
			right.append(b)
	set_step([
		"Leia as pistas e escolha a solução.",
		hint2,
		"Veja a mãozinha mostrando a solução.",
	], focus + right)
	if guided:
		highlight(focus)


func _next_problem() -> void:
	solved += 1
	match solved:
		1: _problem_b()
		2: _problem_c()
		_:
			_title(3, "todos resolvidos!")
			complete("Parabéns! Você identificou e corrigiu os problemas!")


func explorer_quiz() -> Array:
	return [
		{"q": "Dois computadores com o mesmo endereço IP causam:",
			"options": ["Mais velocidade", "Conflito de IP", "Nada acontece"], "answer": 1,
			"explain": "Lembre: cada computador precisa de um número diferente.",
			"skill": "Reconheceu um conflito de IP"},
		{"q": "Qual é o primeiro teste para saber se dois computadores se comunicam?",
			"options": ["Ping", "Trocar o monitor", "Reinstalar tudo"], "answer": 0,
			"explain": "É o teste que manda uma pergunta e espera resposta.",
			"skill": "Escolheu o ping como primeiro passo de diagnóstico"},
	]
