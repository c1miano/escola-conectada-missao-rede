extends MissionBase
## Missão 1 — A escola desconectada (Laboratório de Informática)
## Topologia em estrela: cada equipamento é ligado a uma porta do switch.

var sw: SwitchView
var devices: Array[DeviceView] = []
var links := {}           # DeviceView -> {port, cable}
var selected_dev: DeviceView = null
var _tried_direct := false


func setup() -> void:
	floor_tile = "piso_tijolo"
	floor_items = [["armario", Vector2(0.975, 0.2)], ["planta", Vector2(0.03, 0.9)], ["cadeira", Vector2(0.37, 0.48)], ["cadeira", Vector2(0.63, 0.48)]]
	place_icon = "cable"
	set_objective("Ligar cada equipamento a uma porta do switch (rede em estrela).")
	var pcs := [["Computador 1", Vector2(0.13, 0.30)], ["Computador 2", Vector2(0.37, 0.24)],
		["Computador 3", Vector2(0.63, 0.24)]]
	for p in pcs:
		_add_device(DeviceView.new("pc", p[0]), p[1])
	_add_device(DeviceView.new("server", "Servidor"), Vector2(0.87, 0.30))
	if not guided:
		_add_device(DeviceView.new("printer", "Impressora"), Vector2(0.13, 0.74))
	sw = SwitchView.new(4 if guided else 6)
	sw.clicked.connect(func(_d): _on_switch_body())
	sw.port_clicked.connect(_on_port)
	place(sw, Vector2(0.5, 0.74))
	story("Os computadores novos chegaram ao laboratório, mas ninguém ligou os cabos. Vamos conectar tudo?", _begin)


func _add_device(d: DeviceView, pos: Vector2) -> void:
	d.clicked.connect(_on_device)
	devices.append(d)
	place(d, pos)


func _begin() -> void:
	_next_step()
	if guided:
		# demonstração da primeira ação
		demonstrate([devices[0], sw.ports[0]])


func _next_device() -> DeviceView:
	for d in devices:
		if not links.has(d):
			return d
	return null


func _next_step() -> void:
	var d := _next_device()
	if d == null:
		return
	var port := sw.free_port()
	set_step([
		"Clique no %s. Depois clique em uma porta livre do switch." % d.name_label.text.to_lower(),
		"Veja o destaque: primeiro o %s, depois a porta %d." % [d.name_label.text.to_lower(), port + 1],
		"Olhe a mãozinha: ela clica no equipamento e depois na porta do switch.",
	], [d, sw.ports[port]])


func _on_device(d: DeviceView) -> void:
	if busy:
		return
	if links.has(d):
		say("O %s já está ligado na porta %d." % [d.name_label.text.to_lower(), links[d].port + 1])
		return
	if selected_dev and selected_dev != d:
		_direct_attempt(selected_dev, d)
		return
	_select(d)


func _select(d: DeviceView) -> void:
	if selected_dev:
		selected_dev.selected = false
	selected_dev = d
	d.selected = true
	Sfx.play("select")
	say("Agora clique em uma porta livre do switch.")
	set_targets([sw.ports[maxi(sw.free_port(), 0)]])
	if guided:
		highlight([sw.ports[maxi(sw.free_port(), 0)]])


## Tentou ligar um equipamento direto no outro: mostramos a bagunça e sugerimos o switch.
func _direct_attempt(a: DeviceView, b: DeviceView) -> void:
	var wrong := cables.add_cable(a.anchor, b.anchor, "wrong")
	_tried_direct = true
	try_again("Ligar um computador direto no outro faz uma bagunça de cabos. Use o switch no centro: todos se ligam nele!")
	highlight([sw])
	a.selected = false
	selected_dev = null
	get_tree().create_timer(2.0).timeout.connect(func(): cables.remove_cable(wrong))


func _on_switch_body() -> void:
	if selected_dev:
		say("Isso, é no switch! Clique em uma das portas numeradas.")
	else:
		say("Este é o switch. Ele fica no centro da rede. Primeiro clique em um equipamento.")


func _on_port(i: int) -> void:
	if busy:
		return
	if sw.port_used[i]:
		if not guided:
			_unplug(i)
		else:
			say("Esta porta já está em uso. Escolha uma porta livre.")
		return
	if selected_dev == null:
		Game.record_attempt(mission_id, false)
		say("Primeiro clique em um equipamento. Depois na porta.", "pensando")
		Sfx.play("retry")
		var nd := _next_device()
		if nd and guided:
			highlight([nd])
		return
	var d := selected_dev
	d.selected = false
	selected_dev = null
	var cable := cables.add_cable(d.anchor, func(): return sw.port_anchor(i), "ok")
	links[d] = {"port": i, "cable": cable}
	sw.set_port_used(i, true)
	d.set_info("Porta %d" % (i + 1))
	Sfx.play("connect")
	if links.size() == 1:
		correct("Cabo ligado!", "Ligou um equipamento ao switch com cabo de rede")
		say("Isso é um cabo de rede (par trançado). Ele leva os dados até o switch.", "feliz")
	else:
		correct("Cabo ligado!")
	if _tried_direct:
		Game.record_skill(mission_id, "Percebeu que o switch é o ponto central da rede")
	if _next_device() == null:
		_all_connected()
	else:
		_next_step.call_deferred()
		if links.size() > 1 and guided:
			say("Muito bem! Agora o próximo equipamento.", "feliz")


func _unplug(i: int) -> void:
	for d in links.keys():
		if links[d].port == i:
			cables.remove_cable(links[d].cable)
			links.erase(d)
			d.set_info("")
			sw.set_port_used(i, false)
			say("Cabo retirado da porta %d. Você pode ligar de novo." % (i + 1))
			_next_step()
			return


func _all_connected() -> void:
	set_step([])
	Game.record_skill(mission_id, "Montou uma rede em estrela com switch")
	var t := animate("m1_luzes")
	t.tween_interval(0.6)
	sw.online = true
	for d in devices:
		t.tween_callback(func():
			d.online = true
			Sfx.play("select"))
		t.tween_interval(0.35)
	t.tween_interval(0.5)
	t.finished.connect(func(): complete("Muito bem! Você construiu uma rede em estrela!"))
	say("Todos ligados no switch! As luzes estão acendendo...", "feliz")


func explorer_quiz() -> Array:
	return [
		{"q": "Na rede em estrela, qual equipamento fica no centro?",
			"options": ["O switch", "A impressora", "O mouse"], "answer": 0,
			"explain": "É o equipamento que tem várias portas e liga todos.",
			"skill": "Identificou o switch como centro da topologia em estrela"},
		{"q": "Qual meio de transmissão usamos para ligar o computador ao switch?",
			"options": ["Cabo de energia", "Cabo de rede (par trançado)", "Cabo HDMI"], "answer": 1,
			"explain": "É o cabo com conector RJ-45 que leva dados.",
			"skill": "Reconheceu o cabo de par trançado como meio de transmissão"},
	]
