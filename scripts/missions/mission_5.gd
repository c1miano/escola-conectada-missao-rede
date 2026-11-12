extends MissionBase
## Missão 5 — A escola inteligente (Sala de Aula Inteligente)
## Escolher um dispositivo IoT, ligar o ponto de acesso Wi-Fi, associar o dispositivo e ver os dados no painel.

const SSID := "EscolaConectada"
const PASSWORD := "Feira2026"

var sw: SwitchView
var ap: DeviceView
var panel: DeviceView
var iot: DeviceView
var iot_kind := ""
var _ap_selected := false
var _ap_linked := false
var _wifi_ok := false
var note: PanelContainer
var person: Control


func setup() -> void:
	floor_tile = "piso_tijolo"
	wall_items = [["janela", 0.30], ["quadro", 0.62], ["cartaz_wifi", 0.74], ["relogio", 0.52]]
	floor_items = [["mesinha", Vector2(0.55, 0.62)], ["mesinha", Vector2(0.62, 0.62)], ["mesinha", Vector2(0.55, 0.86)], ["mesinha", Vector2(0.62, 0.86)], ["planta", Vector2(0.03, 0.92)]]
	place_icon = "wifi"
	room_color = Color("#e3f1ea")
	set_objective("Instalar um dispositivo inteligente e ver os dados no painel.")
	sw = SwitchView.new(4)
	sw.online = true
	place(sw, Vector2(0.35, 0.78))
	panel = DeviceView.new("panel", "Painel de monitoramento", "Sem dados")
	panel.online = true
	place(panel, Vector2(0.10, 0.36))
	ap = DeviceView.new("ap", "Ponto de acesso Wi-Fi", "Desligado da rede")
	ap.clicked.connect(_on_ap)
	place(ap, Vector2(0.45, 0.24))
	if not guided:
		note = PanelContainer.new()
		var l := Label.new()
		l.text = "Bilhete na parede:\nWi-Fi: %s\nSenha: %s" % [SSID, PASSWORD]
		l.add_theme_font_size_override("font_size", 18)
		note.add_child(l)
		place(note, Vector2(0.88, 0.14))
	_wire.call_deferred()
	story("A rede foi recuperada! A direção quer mostrar uma novidade na feira: uma sala inteligente, com objetos conectados.", _choose_device)


func _wire() -> void:
	cables.add_cable(panel.anchor, func(): return sw.port_anchor(0), "ok")
	sw.set_port_used(0, true)


# ---------------------------------------------------------------- 1. escolher dispositivo
func _choose_device() -> void:
	set_objective("Escolher um dispositivo inteligente para a sala.")
	clear_actions()
	var b1 := add_action("Sensor de temperatura", "", func(): _install("sensor_temp", "Sensor de temperatura"), "secondary")
	add_action("Lâmpada inteligente", "bulb", func(): _install("lamp", "Lâmpada inteligente"), "secondary")
	add_action("Sensor de presença", "user", func(): _install("sensor_pres", "Sensor de presença"), "secondary")
	set_step([
		"Escolha um dispositivo para instalar. Qualquer um serve!",
		"Clique em um dos três botões aqui embaixo.",
		"Veja a mãozinha escolhendo um dispositivo.",
	], [b1])


func _install(kind: String, title: String) -> void:
	iot_kind = kind
	clear_actions()
	iot = DeviceView.new(kind, title, "Sem rede")
	iot.clicked.connect(_on_iot)
	if kind == "sensor_temp":
		iot.value_text = "24 °C"
	place(iot, Vector2(0.76, 0.40))
	correct("Dispositivo instalado!", "Escolheu um dispositivo de Internet das Coisas (%s)" % title.to_lower())
	say("O %s precisa se conectar à rede para mandar informações. Ele usa Wi-Fi. Primeiro, ligue o ponto de acesso no switch." % title.to_lower())
	set_objective("Ligar o ponto de acesso Wi-Fi ao switch.")
	_step_ap.call_deferred()


# ---------------------------------------------------------------- 2. ligar o ponto de acesso
func _step_ap() -> void:
	set_step([
		"Clique no ponto de acesso Wi-Fi e depois em uma porta livre do switch.",
		"Primeiro o ponto de acesso (com antenas), depois a porta 2.",
		"Veja a mãozinha: ponto de acesso e depois porta do switch.",
	], [ap, sw.ports[1]])
	if guided:
		highlight([ap])
	sw.port_clicked.connect(_on_port)


func _on_ap(_d) -> void:
	if busy or _ap_linked or iot == null:
		return
	_ap_selected = true
	ap.selected = true
	Sfx.play("select")
	say("Agora clique em uma porta livre do switch.")
	if guided:
		highlight([sw.ports[1]])


func _on_port(i: int) -> void:
	if _ap_linked or busy:
		return
	if not _ap_selected:
		say("Primeiro clique no ponto de acesso Wi-Fi.", "pensando")
		Sfx.play("retry")
		return
	if sw.port_used[i]:
		say("Essa porta já está ocupada. Escolha outra.")
		return
	_ap_linked = true
	ap.selected = false
	cables.add_cable(ap.anchor, func(): return sw.port_anchor(i), "ok")
	sw.set_port_used(i, true)
	ap.online = true
	ap.set_info("Wi-Fi: " + SSID)
	Sfx.play("connect")
	correct("Wi-Fi ligado!", "Ligou um ponto de acesso Wi-Fi à rede cabeada")
	set_objective("Conectar o dispositivo ao Wi-Fi da escola.")
	set_step([
		"Agora clique no %s para conectar ele ao Wi-Fi." % iot.name_label.text.to_lower(),
		"O dispositivo está piscando. Clique nele.",
		"Veja a mãozinha clicando no dispositivo.",
	], [iot])
	if guided:
		highlight([iot])


# ---------------------------------------------------------------- 3. associar ao Wi-Fi
func _on_iot(_d) -> void:
	if busy:
		return
	if not _ap_linked:
		say("Antes, ligue o ponto de acesso no switch. Sem ele não existe Wi-Fi.", "pensando")
		return
	if _wifi_ok:
		return
	iot.selected = true
	clear_actions()
	var nets := [SSID, "WiFi_Vizinho"] if guided else ["Cafeteria_Aberta", SSID, "WiFi_Vizinho"]
	var right: Array = []
	for n in nets:
		var b := add_action(n, "wifi", func(): _pick_network(n), "secondary")
		if n == SSID:
			right.append(b)
	set_step([
		"Escolha a rede Wi-Fi da escola: %s." % SSID,
		"Procure o nome %s nos botões." % SSID,
		"Veja a mãozinha mostrando a rede certa.",
	], right)
	if not guided:
		say("Escolha a rede Wi-Fi certa para o dispositivo.")


func _pick_network(n: String) -> void:
	if n != SSID:
		try_again("Essa não é a rede da escola. Conectar em redes estranhas não é seguro. Procure %s." % SSID)
		return
	if guided:
		_associate()
		return
	clear_actions()
	say("Digite a senha... quer dizer, escolha a senha certa. Dica: olhe o bilhete na parede.")
	var right: Array = []
	for p in ["12345", PASSWORD, "senha"]:
		var b := add_action(p, "", func():
			if p == PASSWORD:
				_associate()
			else:
				try_again("Senha errada. Olhe o bilhete na parede: lá está a senha do Wi-Fi."), "secondary")
		if p == PASSWORD:
			right.append(b)
	set_step(["Escolha a senha do Wi-Fi.", "A senha está escrita no bilhete na parede.", "Veja a mãozinha."], [note] + right)


func _associate() -> void:
	_wifi_ok = true
	clear_actions()
	iot.selected = false
	iot.online = true
	iot.set_info("Conectado ao Wi-Fi")
	cables.add_cable(iot.anchor, ap.anchor, "wifi")
	correct("Conectado ao Wi-Fi!", "Conectou um dispositivo IoT ao Wi-Fi")
	set_objective("Ver o dispositivo mandando informações para o painel.")
	say("O dispositivo manda informações pelo ar até o ponto de acesso. Depois, pelo cabo até o painel.", "feliz")
	var t := animate("m5_dados")
	var tag: String = {"sensor_temp": "24 °C", "lamp": "Lâmpada: desligada", "sensor_pres": "Sala vazia"}[iot_kind]
	send_packet(t, tag, [iot, ap, sw, panel], Palette.SCREEN_ON, 0.6)
	t.tween_callback(func():
		panel.set_info(tag)
		panel.screen_text = tag)
	t.finished.connect(_event_step)


# ---------------------------------------------------------------- 4. evento
func _event_step() -> void:
	clear_actions()
	var b: BigButton
	match iot_kind:
		"sensor_temp":
			b = add_action("A sala esquentou", "plus", _event_temp, "success")
		"lamp":
			b = add_action("Acender pelo painel", "bulb", _event_lamp, "success")
		_:
			b = add_action("Alguém entra na sala", "user", _event_presence, "success")
	set_step([
		"Vamos ver o dispositivo funcionando. Clique no botão verde.",
		"O botão verde está aqui embaixo.",
		"Veja a mãozinha no botão verde.",
	], [b])


func _event_temp() -> void:
	clear_actions()
	var t := animate("m5_temp")
	t.tween_method(func(v: int):
		iot.value_text = "%d °C" % v
		iot.queue_redraw(), 24, 31, 1.5)
	send_packet(t, "31 °C", [iot, ap, sw, panel], Palette.ATTENTION, 0.5)
	t.tween_callback(func():
		panel.screen_text = "ALERTA: 31 °C"
		panel.set_info("Alerta: sala quente! Ligar ventilador.")
		Sfx.play("alert"))
	t.finished.connect(func(): _done("Mostrou um sensor enviando um alerta ao painel"))


func _event_lamp() -> void:
	clear_actions()
	var t := animate("m5_lamp")
	send_packet(t, "Comando: acender", [panel, sw, ap, iot], Palette.STAR, 0.5)
	t.tween_callback(func():
		iot.lamp_on = true
		iot.set_info("Acesa")
		Sfx.play("ok"))
	send_packet(t, "Lâmpada: acesa", [iot, ap, sw, panel], Palette.SCREEN_ON, 0.5)
	t.tween_callback(func():
		panel.screen_text = "Lâmpada acesa"
		panel.set_info("Lâmpada: acesa"))
	t.finished.connect(func(): _done("Controlou uma lâmpada inteligente pelo painel"))


func _event_presence() -> void:
	clear_actions()
	person = Control.new()
	person.custom_minimum_size = Vector2(64, 64)
	person.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var walk := {"t": 0.0, "moving": true}
	person.set_meta("walk", walk)
	person.draw.connect(func():
		var w: Dictionary = person.get_meta("walk")
		Sprites.draw(person, Walker.frame_name("visitante", "esquerda" if w.moving else "baixo", w.moving, w.t, w.t), Vector2.ZERO, 4))
	place(person, Vector2(0.98, 0.62))
	var t := animate("m5_presenca")
	t.tween_method(func(x: float):
		move_to(person, Vector2(x, 0.62))
		var w: Dictionary = person.get_meta("walk")
		w.t += 1.0 / 60.0
		person.queue_redraw(), 0.98, 0.64, 1.4)
	t.tween_callback(func():
		person.get_meta("walk").moving = false
		person.queue_redraw()
		iot.value_text = "Presença!"
		iot.queue_redraw())
	send_packet(t, "Presença detectada", [iot, ap, sw, panel], Palette.ATTENTION, 0.5)
	t.tween_callback(func():
		panel.screen_text = "Presença"
		panel.set_info("Alguém entrou na sala")
		Sfx.play("alert"))
	t.finished.connect(func(): _done("Mostrou um sensor de presença avisando o painel"))


func _done(skill: String) -> void:
	correct("Funcionou!", skill)
	complete("Missão cumprida! A Escola Conectada está pronta para a feira!")


func explorer_quiz() -> Array:
	return [
		{"q": "O que é Internet das Coisas (IoT)?",
			"options": ["Um tipo de cabo", "Objetos do dia a dia conectados à rede", "Um jogo de computador"],
			"answer": 1, "explain": "Pense no sensor e na lâmpada que você conectou.",
			"skill": "Explicou o que é Internet das Coisas"},
		{"q": "Qual equipamento cria a rede Wi-Fi?",
			"options": ["Ponto de acesso", "Monitor", "Teclado"], "answer": 0,
			"explain": "É o aparelho com antenas que você ligou no switch.",
			"skill": "Identificou o ponto de acesso como gerador do Wi-Fi"},
	]
