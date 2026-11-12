extends MissionBase
## Missão 2 — Cada computador tem seu endereço (Secretaria)
## IPv4: mesma rede (192.168.1.x), números diferentes, máscara 255.255.255.0 e DHCP.

const NET := "192.168.1"

var sw: SwitchView
var server: DeviceView
var pcs: Array[DeviceView] = []
var notebooks: Array[DeviceView] = []
var ips := {}             # DeviceView -> ip
var current: DeviceView = null
var explainer: IpExplainer
var sheet: Label
var sheet_panel: PanelContainer


func setup() -> void:
	floor_tile = "piso_madeira"
	wall_items = [["janela", 0.30], ["cartaz_rede", 0.40], ["relogio", 0.52], ["bilhete", 0.58], ["janela", 0.72], ["quadro", 0.88]]
	floor_items = [["arquivo", Vector2(0.975, 0.85)], ["planta", Vector2(0.62, 0.92)]]
	place_icon = "user"
	set_objective("Dar um endereço IP diferente para cada computador da mesma rede.")
	sw = SwitchView.new(6)
	sw.online = true
	place(sw, Vector2(0.40, 0.76))
	server = DeviceView.new("server", "Servidor", "IP: 192.168.1.10")
	server.online = true
	place(server, Vector2(0.07, 0.64))
	ips[server] = NET + ".10"
	var pos := [Vector2(0.12, 0.22), Vector2(0.30, 0.22), Vector2(0.48, 0.22)]
	for i in 3:
		var d := DeviceView.new("pc", "Computador %d" % (i + 1), "Sem endereço")
		d.clicked.connect(_on_pc)
		pcs.append(d)
		place(d, pos[i])
	explainer = IpExplainer.new()
	place(explainer, Vector2(0.79, 0.12))
	sheet_panel = PanelContainer.new()
	sheet = Label.new()
	sheet.add_theme_font_size_override("font_size", 20)
	sheet_panel.add_child(sheet)
	place(sheet_panel, Vector2(0.80, 0.37))
	_connect_all.call_deferred()
	story("Os computadores da secretaria já estão ligados no switch. Mas eles ainda não têm endereço para conversar!", _begin)


func _connect_all() -> void:
	var port := 0
	for d in [server] + pcs:
		var p := port
		cables.add_cable(d.anchor, func(): return sw.port_anchor(p), "ok")
		sw.set_port_used(p, true)
		port += 1


func _begin() -> void:
	# exemplo correto já aparece na primeira tentativa
	_assign(pcs[0], NET + ".11")
	explainer.show_ip(NET + ".11", "Exemplo: endereço do Computador 1")
	say("Veja o exemplo: o Computador 1 recebeu 192.168.1.11. O começo é a rede. O final é o número do computador.")
	_update_sheet()
	_next_pc_step.call_deferred()


func _next_pc_step() -> void:
	var d := _next_pc()
	if d == null:
		return
	set_step([
		"Clique no %s para abrir a ficha dele." % d.name_label.text.to_lower(),
		"O %s está piscando. Clique nele." % d.name_label.text.to_lower(),
		"Veja: clique no computador e depois em um cartão com endereço.",
	], [d])
	if guided:
		highlight([d])


func _next_pc() -> DeviceView:
	for d in pcs:
		if not ips.has(d):
			return d
	return null


func _on_pc(d: DeviceView) -> void:
	if busy:
		return
	if ips.has(d):
		say("O %s já tem o endereço %s." % [d.name_label.text.to_lower(), ips[d]])
		return
	if current:
		current.selected = false
	current = d
	d.selected = true
	Sfx.play("select")
	_update_sheet()
	_show_cards(d)


func _cards_for(d: DeviceView) -> Array:
	var n := pcs.find(d) + 11      # Computador 2 -> .12, Computador 3 -> .13
	if guided:
		if n == 12:
			return [NET + ".12", NET + ".11"]
		return ["10.0.0.13", NET + ".13"]
	return [NET + ".11", NET + ".%d" % n, "10.0.0.%d" % n, NET + ".300", NET + ".%d" % (n + 20)]


func _show_cards(d: DeviceView) -> void:
	clear_actions()
	var cards := _cards_for(d)
	var right: Array = []
	for ip in cards:
		var b := add_action(ip, "", func(): _choose(ip), "secondary")
		b.custom_minimum_size.x = 0
		if _problem(ip) == "":
			right.append(b)
	set_step([
		"Escolha um cartão: o começo deve ser 192.168.1 e o final não pode repetir.",
		"Procure o cartão que começa com 192.168.1 e tem um final novo.",
		"Olhe a mãozinha: ela mostra um cartão certo.",
	], right.slice(0, 1))
	if guided:
		say("Escolha o endereço do %s. Lembre: começa com 192.168.1 e o final é diferente." % d.name_label.text.to_lower())


## Retorna "" se o IP é válido para esta rede, ou o motivo do problema.
func _problem(ip: String) -> String:
	var parts := ip.split(".")
	if parts.size() != 4:
		return "formato"
	for p in parts:
		if int(p) > 255:
			return "maior"
	if "%s.%s.%s" % [parts[0], parts[1], parts[2]] != NET:
		return "rede"
	if int(parts[3]) == 0 or int(parts[3]) == 255:
		return "reservado"
	for k in ips:
		if ips[k] == ip:
			return "duplicado"
	return ""


func _choose(ip: String) -> void:
	if current == null:
		say("Primeiro clique em um computador.")
		return
	match _problem(ip):
		"":
			_assign(current, ip)
			correct("Endereço certo!", "Escolheu um IP válido, da mesma rede e sem repetir")
			explainer.show_ip(ip, "Endereço do %s" % current.name_label.text)
			current.selected = false
			current = null
			clear_actions()
			_update_sheet()
			if _next_pc() == null:
				_dhcp_part.call_deferred()
			else:
				_next_pc_step()
		"duplicado":
			explainer.show_ip(ip, "Este número já está em uso!")
			try_again("O endereço %s já é de outro computador. Cada computador precisa de um número final diferente." % ip)
		"rede":
			explainer.show_ip(ip, "Começo diferente = outra rede!")
			try_again("Esse endereço é de outra rede. O começo precisa ser igual: 192.168.1.")
		"maior":
			try_again("Cada parte do endereço vai só de 0 até 255. O número 300 não existe!")
		"reservado":
			try_again("Os finais 0 e 255 são reservados. Escolha outro número.")


func _assign(d: DeviceView, ip: String) -> void:
	ips[d] = ip
	d.online = true
	d.set_info("IP: " + ip)


func _update_sheet() -> void:
	var who := current.name_label.text if current else "—"
	var ip: String = ips.get(current, "?") if current else "?"
	sheet.text = "Ficha de configuração\nComputador: %s\nEndereço IP: %s\nMáscara: 255.255.255.0" % [who, ip]


# ---------------------------------------------------------------- DHCP
func _dhcp_part() -> void:
	set_objective("Usar o servidor DHCP para dar endereços aos notebooks novos.")
	var pos := [Vector2(0.72, 0.24), Vector2(0.89, 0.24)]
	explainer.visible = false
	sheet_panel.visible = false
	for i in 2:
		var n := DeviceView.new("notebook", "Notebook %d" % (i + 1), "Sem endereço")
		notebooks.append(n)
		place(n, pos[i])
		var p := 4 + i
		cables.add_cable(n.anchor, func(): return sw.port_anchor(p), "ok")
		sw.set_port_used(p, true)
	server.set_title("Servidor DHCP")
	server.set_info("DHCP desligado")
	server.online = false
	clear_actions()
	var b := add_action("Ativar o DHCP", "play", _run_dhcp, "success")
	if not guided:
		add_action("Configurar à mão", "gear", func():
			say("Daria certo, mas com muitos computadores dá muito trabalho. O DHCP faz isso sozinho. Experimente!"), "secondary")
	set_step([
		"Chegaram notebooks novos! Clique em \"Ativar o DHCP\": o servidor vai dar os endereços sozinho.",
		"O botão verde \"Ativar o DHCP\" está aqui embaixo.",
		"Veja a mãozinha clicando em \"Ativar o DHCP\".",
	], [b])
	if not guided:
		say("Chegaram notebooks novos sem endereço. Configure à mão ou use o DHCP.")


func _run_dhcp() -> void:
	clear_actions()
	server.online = true
	server.set_info("DHCP ligado")
	correct("DHCP ligado!", "Ativou um servidor DHCP para distribuir endereços")
	say("Cada notebook pede um endereço. O servidor DHCP oferece um livre. Pronto!", "feliz")
	var t := animate("m2_dhcp")
	t.tween_interval(0.8)
	var next := 100
	for n in notebooks:
		var ip := "%s.%d" % [NET, next]
		next += 1
		send_packet(t, "Pedido", [n, sw, server], Palette.SCREEN_ON, 0.55)
		send_packet(t, "Oferta: " + ip, [server, sw, n], Palette.STAR, 0.55)
		t.tween_callback(func():
			_assign(n, ip)
			Sfx.play("connect"))
		t.tween_interval(0.3)
	t.tween_interval(0.5)
	t.finished.connect(func(): complete("Agora cada computador tem seu próprio endereço!"))


func explorer_quiz() -> Array:
	return [
		{"q": "Para que serve a máscara 255.255.255.0?",
			"options": ["Deixar a internet mais rápida", "Mostrar qual parte do IP é a rede", "Proteger contra vírus"],
			"answer": 1, "explain": "Ela separa a parte da rede da parte do computador.",
			"skill": "Explicou a função da máscara de rede"},
		{"q": "O que o servidor DHCP faz?",
			"options": ["Entrega endereços IP automaticamente", "Liga os cabos", "Abre sites"],
			"answer": 0, "explain": "Lembre dos notebooks novos: quem deu o endereço para eles?",
			"skill": "Reconheceu a função do DHCP"},
	]
