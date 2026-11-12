extends Node
## Teste automático: abre cada missão, resolve como um jogador e confere se foi concluída.
## Uso: godot -- --autoteste=1,2,3[:guiado|:explorador][:pasta_capturas]

var shots_dir := ""
var failures: Array = []


func _ready() -> void:
	var parts := str(get_meta("args")).split(":")
	var ids := parts[0].split(",")
	var mode := parts[1] if parts.size() > 1 else "guiado"
	shots_dir = parts[2] if parts.size() > 2 else ""
	Game.settings.narracao = false
	Game.new_game(mode)
	await test_map_walk()
	for s in ids:
		await run_mission(int(s), mode)
	print("AUTOTESTE ", "OK" if failures.is_empty() else "FALHOU: " + str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)


func m() -> MissionBase:
	return get_parent().current as MissionBase


func wait(sec: float = 0.3) -> void:
	await get_tree().create_timer(sec).timeout


func idle() -> void:
	var n := 0
	while m() and m().busy and n < 200:
		await wait(0.1)
		n += 1


func shot(name: String) -> void:
	if shots_dir == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [shots_dir, name])


func press_overlay_button(label_prefix: String) -> bool:
	for b in m().find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and str(b.text).begins_with(label_prefix):
			b.pressed.emit()
			return true
	return false


## Responde os desafios do Explorador escolhendo pela resposta certa.
func answer_quizzes(mission: MissionBase, mode: String) -> void:
	if mode != "explorador":
		return
	for q in mission.explorer_quiz():
		await wait(0.4)
		await shot("m%d_quiz" % mission.mission_id)
		press_overlay_button(q.options[q.answer])
	await wait(0.4)


func run_mission(id: int, mode: String) -> void:
	Game.goto("mission", {"id": id})
	await wait(0.6)
	await shot("m%d_0_historia" % id)
	press_overlay_button("Começar")
	await wait(0.5)
	await shot("m%d_1_inicio" % id)
	var mission := m()
	if has_method("solve_%d" % id):
		await call("solve_%d" % id, mission)
	await idle()
	await answer_quizzes(mission, mode)
	await wait(0.8)
	await shot("m%d_9_fim" % id)
	if Game.is_completed(id):
		print("Missão %d concluída (%s)" % [id, mode])
	else:
		failures.append(id)
		print("Missão %d NÃO concluída" % id)


# ------------------------------------------------------------- soluções
func solve_1(ms) -> void:
	# erro proposital: ligar computador direto no outro
	ms._on_device(ms.devices[0])
	ms._on_device(ms.devices[1])
	await wait(0.4)
	await shot("m1_2_erro")
	await wait(2.0)
	var port := 0
	for d in ms.devices:
		ms._on_device(d)
		await wait(0.2)
		if port == 2:
			await shot("m1_3_meio")
		ms._on_port(port)
		port += 1
		await wait(0.3)


func solve_2(ms) -> void:
	await wait(0.5)
	for k in 2:
		var d = ms._next_pc()
		ms._on_pc(d)
		await wait(0.3)
		# primeiro um cartão errado (se existir), depois o certo
		var cards: Array = ms._cards_for(d)
		for ip in cards:
			if ms._problem(ip) != "":
				ms._choose(ip)
				break
		await wait(0.3)
		await shot("m2_2_cartoes_%d" % k)
		for ip in cards:
			if ms._problem(ip) == "":
				ms._choose(ip)
				break
		await wait(0.4)
	await wait(0.5)
	await shot("m2_3_dhcp")
	ms._run_dhcp()
	await wait(1.5)
	await shot("m2_4_dhcp_anim")


func solve_3(ms) -> void:
	ms._on_server(null)          # erro: servidor antes do computador
	await wait(0.3)
	ms._on_pc(null)
	ms._on_server(null)
	await idle()
	await wait(0.3)
	ms._do_ping()
	await wait(1.2)
	await shot("m3_2_ping")
	await idle()
	await wait(0.3)
	ms._open_site()
	await wait(0.3)
	if not ms.guided:
		press_action("DNS")
	await wait(0.5)
	await idle()
	await wait(0.3)
	if not ms.guided:
		press_action("HTTP")
	await idle()
	await wait(0.4)
	await shot("m3_3_site")
	ms._show_layers()
	await wait(1.5)
	await shot("m3_4_camadas")
	await idle()


func press_action(label: String) -> void:
	for b in m().actions.get_children():
		if b is Button and b.text == label:
			b.pressed.emit()
			return


func solve_4(ms) -> void:
	for k in 3:
		await wait(0.4)
		# erra primeiro, depois acerta
		var btns: Array = ms.actions.get_children()
		for b in btns:
			if b.text.begins_with("Trocar"):
				b.pressed.emit()
				break
		await wait(0.4)
		await shot("m4_%d_problema" % k)
		for b in ms.actions.get_children():
			if b.text.begins_with("Ligar o cabo") or b.text == "IP 192.168.1.25" or b.text.begins_with("Verificar"):
				b.pressed.emit()
				break
		await wait(0.4)
		if k == 0:
			ms.sw.port_clicked.emit(1)
		if k == 2:
			await shot("m4_servicos")
			for b in ms.services_panel.find_children("*", "Button", true, false):
				b.pressed.emit()
		await idle()
		await wait(0.3)


func solve_5(ms) -> void:
	await wait(0.3)
	press_action("Sensor de temperatura")
	await wait(0.5)
	ms._on_port(1)               # erro: porta antes do ponto de acesso
	ms._on_ap(null)
	ms._on_port(1)
	await wait(0.4)
	ms._on_iot(null)
	await wait(0.3)
	press_action("WiFi_Vizinho")
	await wait(0.3)
	press_action("EscolaConectada")
	await wait(0.3)
	if not ms.guided:
		press_action("Feira2026")
	await wait(1.2)
	await shot("m5_2_dados")
	await idle()
	await wait(0.3)
	press_action("A sala esquentou")
	await idle()
	await shot("m5_3_alerta")



## Clica na placa da missão 1 no mapa: o técnico deve andar até a porta e abrir a missão.
func test_map_walk() -> void:
	Game.goto("map")
	await wait(0.6)
	var mp = get_parent().current
	mp.signs[1].pressed.emit()
	await wait(0.7)
	await shot("mapa_andando")
	var n := 0
	while not (get_parent().current is MissionBase) and n < 60:
		await wait(0.1)
		n += 1
	if get_parent().current is MissionBase:
		print("Mapa: técnico andou até a sala e abriu a missão")
	else:
		failures.append("mapa")
