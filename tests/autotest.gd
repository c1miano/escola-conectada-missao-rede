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
	Game.create_profile("Ana Teste", 3, mode)
	await test_map_walk()
	for s in ids:
		await run_mission(int(s), mode)
	await test_progress_report()
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
	# personagem: clica no Computador 3 -> anda até ele -> fica selecionado
	ms.devices[2].use()
	await wait(0.4)
	await shot("m1_andando")
	await wait(2.0)
	await shot("m1_chegou")
	if ms.walker.who != Game.avatar_sprite():
		failures.append("avatar na missão: %s" % ms.walker.who)
	else:
		print("Avatar escolhido aparece na missão (%s)" % ms.walker.who)
	if ms.devices[2].selected:
		print("Personagem andou até o equipamento e usou")
	else:
		failures.append("andar")
	ms.sw.use_port(3)
	await wait(2.5)
	if ms.links.has(ms.devices[2]):
		print("Personagem andou até a porta do switch e ligou o cabo")
	else:
		failures.append("porta")
	# erro proposital: ligar computador direto no outro
	ms._on_device(ms.devices[0])
	ms._on_device(ms.devices[1])
	await wait(0.4)
	await shot("m1_2_erro")
	await wait(2.0)
	var port := 0
	for d in ms.devices:
		if ms.links.has(d):
			continue
		if port == 3:
			port = 4
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


func solve_6(ms) -> void:
	await wait(0.3)
	press_action("Testar (ping)")
	await idle()
	await wait(0.3)
	ms._on_port("a", 1)              # erro: porta antes do roteador
	ms._on_router(null)
	ms._on_port("a", 1)
	await wait(0.3)
	ms._on_router(null)
	ms._on_port("p", 1)
	await wait(0.5)
	await shot("m6_2_roteador")
	ms._on_pc(ms.pc_p)
	await wait(0.3)
	press_action("Gateway: 192.168.1.1")   # erro proposital
	await wait(0.3)
	press_action("Gateway: 192.168.2.1")
	await wait(0.4)
	ms._on_pc(ms.pc_a)
	await wait(0.3)
	press_action("Gateway: 192.168.1.1")
	await wait(0.4)
	await shot("m6_3_gateway")
	press_action("Testar de novo")
	await wait(1.0)
	await shot("m6_4_teste")
	await idle()


func solve_7(ms) -> void:
	await wait(0.3)
	press_action("Chave de fenda")
	await wait(0.2)
	press_action("Alicate de crimpar")
	await wait(0.3)
	press_action("Conector RJ-45")
	await wait(0.3)
	ms._pick("marrom")                   # erro proposital
	for w in ms.ORDER:
		ms._pick(w)
		await wait(0.1)
		if w == "azul":
			await shot("m7_2_fios")
	await wait(0.3)
	press_action("Crimpar com o alicate")
	await idle()
	ms._on_tester(null)
	await wait(1.0)
	await shot("m7_3_teste")
	await idle()
	await wait(0.3)
	press_action("O cabo é azul")
	await wait(0.3)
	await shot("m7_4_defeito")
	press_action("Os fios 3 e 6 estão soltos ou trocados")
	await wait(0.3)


func solve_8(ms) -> void:
	await wait(0.3)
	ms._on_ap(null)
	await wait(0.2)
	press_action("Senha: 123456")
	await wait(0.2)
	press_action("Senha: F3ir@-Rede#26")
	await wait(0.4)
	ms._on_firewall(null)
	await wait(0.4)
	await shot("m8_2_firewall")
	var btns: Array = ms.rules_panel.find_children("*", "Button", true, false)
	var rules: Array = ms.RULES.slice(0, 2) if ms.guided else ms.RULES
	for i in rules.size():
		# botões por linha: [Permitir, Bloquear]
		var b: Button = btns[i * 2] if rules[i].ok else btns[i * 2 + 1]
		b.pressed.emit()
		await wait(0.2)
	await idle()
	await wait(0.3)
	ms._on_pc(null)
	await wait(0.3)
	await shot("m8_3_email")
	press_action("Clicar no link")
	await wait(0.3)
	press_action("Apagar e avisar o professor")
	await wait(0.3)


func solve_9(ms) -> void:
	await wait(0.3)
	press_action("24")
	await wait(0.2)
	press_action("254")
	await wait(0.5)
	for k in 4:
		var d = ms.devices[k]
		ms._on_pc(d)
		await wait(0.2)
		var cards: Array = ms._cards_for(d)
		var aluno: bool = d.get_meta("lado") == "a"
		for ip in cards:
			if not ms._valid(ip, aluno):
				ms._choose_ip(ip)
				break
		await wait(0.2)
		if k == 2:
			await shot("m9_2_subrede")
		for ip in cards:
			if ms._valid(ip, aluno):
				ms._choose_ip(ip)
				break
		await wait(0.3)
	await wait(0.4)
	await shot("m9_3_mascara")
	press_action("/28 (14 computadores)")
	await wait(0.2)
	press_action("/27 (30 computadores)")
	await wait(0.3)


func solve_10(ms) -> void:
	await wait(0.3)
	var port := 0
	for d in ms._cable_targets():
		ms._on_device(d)
		ms._on_port(port)
		port += 1
		await wait(0.2)
	await wait(0.4)
	await shot("m10_2_cabos")
	ms._on_device(ms.server)
	await wait(0.2)
	press_action("Distribuir de 10.0.0.1 a .50")
	await wait(0.2)
	press_action("Distribuir de 192.168.1.100 a .150")
	await idle()
	await wait(0.3)
	ms._on_device(ms.notebook)
	await wait(0.2)
	press_action("FeiraConectada")
	await wait(0.4)
	ms._on_device(ms.server)
	await wait(0.2)
	press_action("feira.escola = 192.168.1.10")
	await wait(0.4)
	ms._on_device(ms.totem)
	await idle()
	await wait(0.3)
	await shot("m10_3_falha")
	press_action("Trocar o cabo do totem")
	await wait(0.2)
	press_action("Ligar o serviço Web no servidor")
	await wait(1.0)
	await shot("m10_4_ok")
	await idle()



## Gera o relatório de progresso em PNG e confere se a imagem saiu com o tamanho certo.
func test_progress_report() -> void:
	Game.goto("progress")
	await wait(0.6)
	await shot("relatorio_tela")
	var png: PackedByteArray = await ProgressCard.render_png(get_parent())
	var img := Image.new()
	img.load_png_from_buffer(png)
	if img.get_width() == int(ProgressCard.W) and img.get_height() == int(ProgressCard.H):
		print("Relatório de progresso gerado (%dx%d, %d bytes)" % [img.get_width(), img.get_height(), png.size()])
		if shots_dir != "":
			img.save_png(shots_dir + "/relatorio_progresso.png")
	else:
		failures.append("relatorio")


func solve_11(ms) -> void:
	await wait(0.3)
	# erro proposital: memória no soquete do processador
	ms._on_part(ms.parts[1])
	ms._on_slot("cpu")
	await wait(0.3)
	for i in 4:
		var d = ms.parts[i]
		ms._on_part(d)
		await wait(0.1)
		ms._on_slot(d.get_meta("part").slot)
		await wait(0.2)
		if i == 1:
			await shot("m11_2_montando")
	await wait(0.3)
	press_action("Ligar o computador")
	await idle()
	await wait(0.3)
	press_action("SSD")
	await wait(0.3)
	press_action("Processador")
	await wait(0.3)


func solve_12(ms) -> void:
	await wait(0.3)
	press_action("Abrir o computador sem falar nada")
	await wait(0.2)
	press_action("Cumprimentar e perguntar o que aconteceu")
	await wait(0.3)
	press_action("O computador está ligado na tomada?")
	await wait(0.3)
	ms._on_pc(null)
	await wait(0.3)
	press_action("Ligar o cabo de energia")
	await wait(0.3)
	await shot("m12_2_bips")
	press_action("Falta de internet")
	await wait(0.2)
	press_action("Memória RAM mal encaixada")
	await wait(0.3)
	ms._on_pc(null)
	await idle()
	await wait(0.3)
	press_action("Cabo de energia solto e memória mal encaixada. Reconectei e reencaixei.")
	await wait(0.3)
	await shot("m12_3_chamado")
	press_action("Explicar o que foi feito e perguntar se está tudo bem")
	await wait(0.3)


func solve_13(ms) -> void:
	await wait(0.4)
	# erro proposital: primeiro arquivo na pasta errada
	ms._on_file(ms.file_buttons[0])
	ms._on_folder("Músicas")
	await wait(0.3)
	for fb in ms.file_buttons:
		ms._on_file(fb)
		await wait(0.1)
		ms._on_folder(fb.folder)
		await wait(0.2)
		if fb.file == "foto_feira.jpg":
			await shot("m13_2_arquivos")
	await wait(0.4)
	press_action("C:\\Usuários\\Secretaria\\Imagens\\foto_feira.jpg")
	await wait(0.3)
	press_action("asdfgh.docx")
	await wait(0.2)
	press_action("relatorio_feira_2026.docx")
	await wait(0.3)


func solve_14(ms) -> void:
	await wait(0.3)
	ms._on_pc(ms.pcs[0])                 # erro: pouca memória
	await wait(0.2)
	ms._on_pc(ms.pcs[1])
	await wait(0.4)
	await shot("m14_2_download")
	press_action("Botão BAIXAR AGORA GRÁTIS!!!")
	await wait(0.2)
	press_action("Site oficial (https://editor.escola.org)")
	await wait(0.3)
	press_action("Aceito os termos e avançar")
	await wait(0.3)
	press_action("Avançar")              # erro: extras ainda marcados
	await wait(0.2)
	await shot("m14_3_extras")
	press_action("Desmarcar programas extras")
	await wait(0.3)
	press_action("Avançar")
	await wait(0.3)
	press_action("Instalar")
	await idle()
	await wait(0.3)
	press_action("Instalar a atualização")
	await wait(0.3)


func solve_15(ms) -> void:
	await wait(0.3)
	# marca os importantes e um que não é (erro), depois corrige
	press_action("Arquivos temporários")
	press_action("Pronto")
	await wait(0.2)
	press_action("Arquivos temporários")
	for n in ["Trabalhos dos alunos", "Fotos da feira", "Notas e boletins"]:
		press_action(n)
	await wait(0.2)
	await shot("m15_2_escolha")
	press_action("Pronto")
	await wait(0.4)
	ms._on_place(ms.pc)                  # erro: o próprio computador
	await wait(0.2)
	ms._on_place(ms.hd)
	ms._on_place(ms.cloud)
	await idle()
	await wait(0.3)
	press_action("Automático, todo dia")
	await idle()
	await wait(0.3)
	await shot("m15_3_pane")
	ms._on_place(ms.hd)
	await idle()


func _robot_run(ms, cmds: Array) -> void:
	for c in cmds:
		ms._add(c)
	await wait(0.2)
	ms._run()
	await idle()
	await wait(0.4)


func solve_16(ms) -> void:
	await wait(0.3)
	await _robot_run(ms, ["Andar", "Andar", "Andar"])      # erro: para antes
	await _robot_run(ms, ["Andar"])                         # completa o programa
	await shot("m16_2_fase2")
	await _robot_run(ms, ["Andar", "Andar", "Andar", "Virar à direita", "Andar", "Andar"])
	await shot("m16_3_fase3")
	if ms.guided:
		await _robot_run(ms, ["Repetir 3 vezes: Andar", "Virar à direita", "Repetir 3 vezes: Andar"])
	else:
		await _robot_run(ms, ["Repetir 3 vezes: Andar", "Virar à direita", "Repetir 3 vezes: Andar", "Repetir 3 vezes: Andar"])


func solve_17(ms) -> void:
	await wait(0.3)
	press_action("SE nota < 6 ENTÃO \"Aprovado\" SENÃO \"Recuperação\"")
	await wait(0.2)
	press_action("SE nota >= 6 ENTÃO \"Aprovado\" SENÃO \"Recuperação\"")
	await wait(0.3)
	press_action("Aprovado")
	await idle()
	await wait(0.3)
	await shot("m17_2_esteira")
	if ms.guided:
		press_action("SE cor = azul ENTÃO caixa A SENÃO caixa B")
	else:
		press_action("SE cor = azul OU tamanho = grande ENTÃO caixa A SENÃO caixa B")
		await wait(0.2)
		press_action("SE cor = azul E tamanho = grande ENTÃO caixa A SENÃO caixa B")
	await idle()
	await wait(0.3)
	await shot("m17_3_erro")
	press_action("Trocar o SENÃO para mostrar \"Senha errada\"")
	await wait(0.3)


func solve_18(ms) -> void:
	await wait(0.4)
	# erro proposital: CPF como público
	var cpf = ms.item_buttons[1]
	ms._on_item(cpf)
	ms._on_bin("publico")
	await wait(0.3)
	for b in ms.item_buttons:
		ms._on_item(b)
		await wait(0.1)
		ms._on_bin(b.get_meta("tipo"))
		await wait(0.2)
		if b == cpf:
			await shot("m18_2_dados")
	await wait(0.3)
	press_action("Ativar verificação em duas etapas")
	await wait(0.3)
	press_action("428913")
	await wait(0.2)
	press_action("482913")
	await wait(0.3)
	await shot("m18_3_app")
	press_action("Permitir só a câmera (é o flash)")
	await wait(0.3)


func solve_19(ms) -> void:
	await wait(0.4)
	ms._on_cell("B3")                    # erro proposital
	await wait(0.2)
	ms._on_cell("C3")
	await wait(0.3)
	if not ms.guided:
		ms._on_cell("B5")
		await wait(0.3)
	press_action("=B2+C2")
	await wait(0.2)
	press_action("=B2*C2")
	await wait(0.3)
	press_action("Copiar a fórmula para baixo")
	await idle()
	await wait(0.3)
	if not ms.guided:
		press_action("=B3*C3")
		await wait(0.3)
	await shot("m19_2_planilha")
	press_action("=SOMA(D2:D5)")
	await wait(0.3)
	press_action("Gráfico de linha")
	await wait(0.2)
	press_action("Gráfico de colunas")
	await wait(0.5)
	await shot("m19_3_grafico")


func solve_20(ms) -> void:
	await wait(0.4)
	await shot("m20_2_fila")
	# erro proposital: escolher um chamado menos urgente primeiro
	for b in ms.ticket_buttons:
		if int(b.get_meta("idx")) == ms._total - 1:
			ms._pick(b)
			break
	await wait(0.3)
	for k in ms._total:
		for b in ms.ticket_buttons:
			if b.visible and int(b.get_meta("idx")) == ms._done:
				ms._pick(b)
				break
		await wait(0.3)
		press_action(ms.TICKETS[ms._current].right)
		await wait(0.4)
