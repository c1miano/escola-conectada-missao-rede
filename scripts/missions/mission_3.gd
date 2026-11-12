extends MissionBase
## Missão 3 — O mistério da mensagem perdida (Biblioteca)
## Ping (ICMP), DNS (nome -> IP), HTTP (pedir a página) e camadas de rede.

const SERVER_IP := "192.168.1.10"
const SITE := "feira.escola"

var pc: DeviceView
var server: DeviceView
var sw: SwitchView
var console_panel: PanelContainer
var console_label: Label
var browser: PanelContainer
var browser_page: Label
var browser_bar: Label
var _picked_pc := false
var _tested := false


func setup() -> void:
	place_icon = "report"
	set_objective("Fazer a mensagem chegar ao servidor e abrir o site da feira.")
	pc = DeviceView.new("pc", "Computador da biblioteca", "IP: 192.168.1.20")
	pc.online = true
	pc.clicked.connect(_on_pc)
	place(pc, Vector2(0.13, 0.36))
	server = DeviceView.new("server", "Servidor da escola", "IP: %s\nNome: %s" % [SERVER_IP, SITE])
	server.online = true
	server.clicked.connect(_on_server)
	place(server, Vector2(0.87, 0.36))
	sw = SwitchView.new(2)
	sw.online = true
	place(sw, Vector2(0.5, 0.78))
	_build_console()
	_build_browser()
	_wire.call_deferred()
	story("A biblioteca quer abrir o site da Feira de Tecnologia. O site está no servidor da escola. Vamos mandar uma mensagem até lá?", _begin)


func _wire() -> void:
	cables.add_cable(pc.anchor, func(): return sw.port_anchor(0), "ok")
	cables.add_cable(server.anchor, func(): return sw.port_anchor(1), "ok")
	sw.set_port_used(0, true)
	sw.set_port_used(1, true)


func _build_console() -> void:
	console_panel = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#0b1d33")
	st.set_corner_radius_all(10)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	console_panel.add_theme_stylebox_override("panel", st)
	console_label = Label.new()
	console_label.add_theme_color_override("font_color", Color("#c8f7c5"))
	console_label.add_theme_font_size_override("font_size", 20)
	console_label.text = "Terminal da biblioteca\n> _"
	console_panel.add_child(console_label)
	place(console_panel, Vector2(0.5, 0.18))
	console_panel.visible = false


func _build_browser() -> void:
	browser = PanelContainer.new()
	browser.custom_minimum_size = Vector2(560, 0)
	var v := VBoxContainer.new()
	browser.add_child(v)
	browser_bar = Label.new()
	browser_bar.text = "Endereço:  http://" + SITE
	browser_bar.add_theme_color_override("font_color", Palette.TEXT_SOFT)
	v.add_child(browser_bar)
	browser_page = Label.new()
	browser_page.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	browser_page.custom_minimum_size = Vector2(520, 0)
	browser_page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	browser_page.add_theme_font_size_override("font_size", 30)
	browser_page.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	browser_page.text = "Feira de Tecnologia\nEscola Conectada\n\nBem-vindos! Projetos, robôs e muito mais."
	v.add_child(browser_page)
	place(browser, Vector2(0.5, 0.36))
	browser.visible = false


func _begin() -> void:
	set_step([
		"Primeiro clique no computador da biblioteca. É dele que a mensagem sai.",
		"O computador da biblioteca está piscando. Clique nele.",
		"Veja: clique no computador e depois no servidor.",
	], [pc, server])
	if guided:
		highlight([pc])


func _on_pc(_d) -> void:
	if busy or _picked_pc:
		return
	_picked_pc = true
	pc.selected = true
	Sfx.play("select")
	set_step([
		"Agora clique no servidor da escola. É para lá que a mensagem vai.",
		"O servidor está piscando, do outro lado.",
		"Veja a mãozinha clicando no servidor.",
	], [server])
	if guided:
		highlight([server])


func _on_server(_d) -> void:
	if busy:
		return
	if not _picked_pc:
		Game.record_attempt(mission_id, false)
		say("Primeiro escolha de onde a mensagem sai: o computador da biblioteca.", "pensando")
		Sfx.play("retry")
		if guided:
			highlight([pc])
		return
	if server.selected:
		return
	server.selected = true
	correct("Caminho escolhido!", "Identificou origem e destino de uma mensagem")
	say("A mensagem vai assim: computador, switch, servidor. Olhe o pacote!", "feliz")
	var t := animate("m3_caminho")
	send_packet(t, "Dados", [pc, sw, server], Palette.STAR, 0.8)
	t.finished.connect(_show_main_actions)


func _show_main_actions() -> void:
	clear_actions()
	var test := add_action("Testar conexão", "retry", _do_ping)
	var open := add_action("Abrir site", "play", _open_site, "success")
	if guided and not _tested:
		set_step([
			"Antes de abrir o site, vamos testar se o servidor responde. Clique em \"Testar conexão\".",
			"O botão \"Testar conexão\" está aqui embaixo.",
			"Veja a mãozinha no botão \"Testar conexão\".",
		], [test])
	else:
		set_step([
			"Agora clique em \"Abrir site\" para ver a página da feira.",
			"O botão verde \"Abrir site\" está aqui embaixo.",
			"Veja a mãozinha no botão \"Abrir site\".",
		], [open])
	if not guided:
		say("Escolha: testar a conexão ou abrir o site.")


# ------------------------------------------------------------ ping (ICMP)
func _do_ping() -> void:
	clear_actions()
	console_panel.visible = true
	browser.visible = false
	console_label.text = "Terminal da biblioteca\n> ping %s" % SERVER_IP
	say("O ping manda uma pergunta: você está aí? O servidor responde. Isso usa o protocolo ICMP.")
	var t := animate("m3_ping")
	send_packet(t, "ICMP: pergunta", [pc, sw, server], Palette.SCREEN_ON, 0.6)
	send_packet(t, "ICMP: resposta", [server, sw, pc], Palette.LED_ON, 0.6)
	t.tween_callback(func():
		console_label.text = "Terminal da biblioteca\n> ping %s\nResposta de %s: OK\nO servidor respondeu!" % [SERVER_IP, SERVER_IP])
	t.finished.connect(func():
		_tested = true
		correct("O servidor respondeu!", "Testou a conexão com ping (ICMP)")
		_show_main_actions())


# ------------------------------------------------------------ site: DNS + HTTP
func _open_site() -> void:
	clear_actions()
	console_panel.visible = false
	if guided:
		_do_dns()
	else:
		_ask_protocol("Para descobrir o endereço IP do nome \"%s\", qual protocolo usamos?" % SITE,
			["HTTP", "DNS", "ICMP"], "DNS", _do_dns,
			"Pense no protocolo que funciona como uma agenda de nomes.")


func _ask_protocol(question: String, options: Array, right: String, next: Callable, tip: String) -> void:
	say(question)
	var right_btn: Array = []
	for o in options:
		var b := add_action(o, "", func():
			if o == right:
				clear_actions()
				correct("Protocolo certo!", "Escolheu o protocolo %s para a tarefa certa" % right)
				next.call()
			else:
				try_again(tip), "secondary")
		if o == right:
			right_btn.append(b)
	set_step([question, tip, "Veja a mãozinha mostrando a resposta."], right_btn)


func _do_dns() -> void:
	console_panel.visible = true
	console_label.text = "Navegador da biblioteca\nAbrindo http://%s ..." % SITE
	say("O computador não sabe o número do site. Ele pergunta ao DNS: qual é o IP de %s?" % SITE)
	var t := animate("m3_dns")
	send_packet(t, "DNS: " + SITE + "?", [pc, sw, server], Palette.SCREEN_ON, 0.6)
	send_packet(t, "DNS: " + SERVER_IP, [server, sw, pc], Palette.STAR, 0.6)
	t.tween_callback(func():
		console_label.text = "DNS respondeu:\n%s = %s" % [SITE, SERVER_IP])
	t.tween_interval(0.6)
	t.finished.connect(func():
		Game.record_skill(mission_id, "Explicou que o DNS troca o nome do site pelo endereço IP")
		if guided:
			_do_http()
		else:
			_ask_protocol("Agora o computador vai pedir a página ao servidor. Qual protocolo?",
				["DNS", "HTTP", "DHCP"], "HTTP", _do_http,
				"É o protocolo das páginas da web. Aparece no começo do endereço: http://"))


func _do_http() -> void:
	say("Agora o computador pede a página com HTTP. O servidor responde com a página da feira.")
	var t := animate("m3_http")
	send_packet(t, "HTTP: pedido", [pc, sw, server], Palette.SCREEN_ON, 0.6)
	send_packet(t, "HTTP: página", [server, sw, pc], Palette.LED_ON, 0.6)
	t.finished.connect(_show_page)


func _show_page() -> void:
	console_panel.visible = false
	browser.visible = true
	pc.screen_text = "Feira"
	pc.queue_redraw()
	correct("Página aberta!", "Abriu uma página usando DNS e HTTP")
	say("A página da feira apareceu! Quer ver como a mensagem passou pelas camadas da rede?", "feliz")
	clear_actions()
	var b := add_action("Ver as camadas", "play", _show_layers, "success")
	set_step([
		"Clique em \"Ver as camadas\" para ver a viagem da mensagem.",
		"O botão verde \"Ver as camadas\" está aqui embaixo.",
		"Veja a mãozinha no botão.",
	], [b])


# ------------------------------------------------------------ camadas
func _show_layers() -> void:
	clear_actions()
	browser.visible = false
	for n in [pc, server, sw, cables]:
		n.visible = false
	var layers := ["Aplicação\n(HTTP, DNS)", "Transporte\n(TCP)", "Internet\n(endereço IP)", "Acesso à rede\n(cabo, switch)"]
	var left := _stack("Computador", layers)
	var right := _stack("Servidor", layers)
	place(left, Vector2(0.33, 0.45))
	place(right, Vector2(0.67, 0.45))
	var cap := Label.new()
	cap.text = "Modelo TCP/IP: 4 camadas. (O modelo OSI divide o mesmo caminho em 7 camadas.)"
	cap.add_theme_font_size_override("font_size", 19)
	var cap_panel := PanelContainer.new()
	cap_panel.add_child(cap)
	place(cap_panel, Vector2(0.5, 0.94))
	say("A mensagem desce as camadas no computador, passa pelo cabo e sobe as camadas no servidor.")
	await get_tree().process_frame
	await get_tree().process_frame
	var t := animate("m3_camadas")
	var path: Array = []
	for i in 4:
		path.append(left.get_meta("rows")[i])
	for i in range(3, -1, -1):
		path.append(right.get_meta("rows")[i])
	send_packet(t, "Mensagem", path, Palette.STAR, 0.55)
	t.tween_interval(0.4)
	t.finished.connect(func():
		Game.record_skill(mission_id, "Observou a mensagem passando pelas camadas de rede")
		complete("Mensagem entregue! Os computadores estão se comunicando!"))


func _stack(title: String, layers: Array) -> PanelContainer:
	var p := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var h := Label.new()
	h.text = title
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	v.add_child(h)
	var rows: Array = []
	var colors := [Color("#dbe9ff"), Color("#e3f6e8"), Color("#fff1c9"), Color("#f1e3ff")]
	for i in layers.size():
		var row := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = colors[i]
		st.border_color = Palette.PANEL_BORDER
		st.set_border_width_all(2)
		st.set_corner_radius_all(8)
		st.content_margin_left = 10
		st.content_margin_right = 10
		row.add_theme_stylebox_override("panel", st)
		row.custom_minimum_size = Vector2(250, 0)
		var l := Label.new()
		l.text = "%d. %s" % [4 - i, layers[i]]
		l.add_theme_font_size_override("font_size", 18)
		row.add_child(l)
		v.add_child(row)
		rows.append(row)
	p.set_meta("rows", rows)
	return p


func explorer_quiz() -> Array:
	return [
		{"q": "Qual comando testa se outro computador responde?",
			"options": ["ping", "http", "dns"], "answer": 0,
			"explain": "Ele manda uma pergunta ICMP e espera a resposta.",
			"skill": "Reconheceu o ping como teste de conectividade"},
		{"q": "Em qual camada ficam os protocolos HTTP e DNS?",
			"options": ["Acesso à rede", "Internet", "Aplicação"], "answer": 2,
			"explain": "É a camada mais perto do usuário, onde ficam os programas.",
			"skill": "Relacionou HTTP e DNS à camada de aplicação"},
	]
