extends MissionBase
## Temporada 2, nível 1 — Monte o computador (Oficina de Montagem)
## Peças: processador, memória RAM, armazenamento (SSD) e fonte. Onde cada uma encaixa e para que serve.

const PARTS := [
	{"kind": "cpu", "name": "Processador", "slot": "cpu", "info": "o cérebro: faz as contas"},
	{"kind": "ram", "name": "Memória RAM", "slot": "ram", "info": "guarda o que está aberto agora"},
	{"kind": "ssd", "name": "SSD", "slot": "m2", "info": "guarda os arquivos para sempre"},
	{"kind": "psu", "name": "Fonte", "slot": "power", "info": "dá energia para tudo"},
]
const SLOTS := [["cpu", "Soquete do processador"], ["ram", "Slot de memória"], ["m2", "Conector do SSD (M.2)"], ["power", "Conector de energia"]]

var parts: Array[DeviceView] = []
var board: DeviceView
var slot_buttons := {}
var monitor: DeviceView
var selected: DeviceView = null
var installed := {}
var _step := ""


func setup() -> void:
	place_icon = "gear"
	floor_tile = "piso_frio"
	wall_items = [["cartaz_rede", 0.3], ["relogio", 0.42], ["quadro", 0.6], ["extintor", 0.97]]
	floor_items = [["mesa", Vector2(0.15, 0.62)]]
	set_objective("Montar o computador: cada peça no seu lugar.")
	var list: Array = PARTS.duplicate()
	if not guided:
		list.append({"kind": "pendrive", "name": "Pen drive", "slot": "", "info": ""})
	var x := 0.08
	for p in list:
		var d := DeviceView.new(p.kind, p.name, "")
		d.show_led = false
		d.set_meta("part", p)
		d.clicked.connect(_on_part)
		place(d, Vector2(x, 0.24))
		parts.append(d)
		x += 0.13
	board = DeviceView.new("board", "Placa-mãe", "")
	board.show_led = false
	place(board, Vector2(0.72, 0.24))
	var row := HFlowContainer.new()
	row.custom_minimum_size.x = 560.0 * Game.ui_scale() / 0.7
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	for s in SLOTS:
		var b := BigButton.new(s[1], "", "secondary", 60)
		var sid: String = s[0]
		b.pressed.connect(func(): _on_slot(sid))
		row.add_child(b)
		slot_buttons[sid] = b
	place(row, Vector2(0.5, 0.62))
	monitor = DeviceView.new("pc", "Monitor", "Desligado")
	place(monitor, Vector2(0.91, 0.24))
	story("Bem-vindo à Central de Suporte! Primeira tarefa: montar um computador novo para a recepção. Cada peça tem o seu lugar na placa-mãe.", _begin)


func _begin() -> void:
	_step = "montar"
	_hint_next()
	if guided:
		demonstrate([parts[0], slot_buttons["cpu"]])


func _next_part() -> DeviceView:
	for d in parts:
		var p: Dictionary = d.get_meta("part")
		if p.slot != "" and not installed.has(p.slot):
			return d
	return null


func _hint_next() -> void:
	var d := _next_part()
	if d == null:
		return
	var p: Dictionary = d.get_meta("part")
	set_step([
		"Clique em uma peça e depois no lugar dela na placa-mãe.",
		"%s: %s. Ela vai no \"%s\"." % [p.name, p.info, _slot_name(p.slot)],
		"Veja a mãozinha: peça e depois o lugar.",
	], [d, slot_buttons[p.slot]])
	if guided:
		highlight([d])


func _slot_name(sid: String) -> String:
	for s in SLOTS:
		if s[0] == sid:
			return s[1]
	return ""


func _on_part(d: DeviceView) -> void:
	if busy or _step != "montar":
		return
	var p: Dictionary = d.get_meta("part")
	if p.slot != "" and installed.has(p.slot):
		say("O %s já está instalado." % p.name.to_lower())
		return
	if selected:
		selected.selected = false
	selected = d
	d.selected = true
	Sfx.play("select")
	say("%s na mão. Agora clique no lugar certo dela na placa-mãe." % p.name)
	if guided and p.slot != "":
		highlight([slot_buttons[p.slot]])


func _on_slot(sid: String) -> void:
	if busy or _step != "montar":
		return
	if selected == null:
		say("Primeiro pegue uma peça na mesa.", "pensando")
		Sfx.play("retry")
		return
	var p: Dictionary = selected.get_meta("part")
	if p.slot == "":
		try_again("O pen drive não vai dentro do computador: ele é ligado por fora, na porta USB.")
		selected.selected = false
		selected = null
		return
	if p.slot != sid:
		try_again("O %s não encaixa no \"%s\". Ele vai no \"%s\"." % [p.name.to_lower(), _slot_name(sid), _slot_name(p.slot)] if guided
			else "O %s não encaixa aí. Olhe o formato de cada conector." % p.name.to_lower())
		return
	# no Explorador a ordem conta: processador, memória, SSD e por último a fonte
	var order := ["cpu", "ram", "m2", "power"]
	if not guided and order.find(sid) != installed.size():
		try_again("Encaixe na ordem certa: primeiro o processador, depois a memória, o SSD e por último a fonte.")
		return
	installed[sid] = true
	var b: BigButton = slot_buttons[sid]
	b.text = "%s: OK" % p.name
	b.set_variant("success")
	selected.selected = false
	selected.visible = false
	selected = null
	Sfx.play("connect")
	correct("Encaixou!", "Instalou %s no lugar certo" % p.name.to_lower())
	if installed.size() == 4:
		_step = "ligar"
		_power_on.call_deferred()
	else:
		_hint_next()


func _power_on() -> void:
	set_objective("Ligar o computador montado.")
	clear_actions()
	var b := add_action("Ligar o computador", "play", func():
		clear_actions()
		var t := animate("m11_ligar")
		t.tween_callback(func():
			monitor.online = true
			monitor.screen_text = "Iniciando..."
			monitor.queue_redraw())
		t.tween_interval(1.0)
		t.tween_callback(func():
			monitor.screen_text = "Tudo OK!"
			monitor.set_info("Ligado")
			monitor.queue_redraw()
			Sfx.play("ok"))
		t.finished.connect(_quiz_1), "success")
	set_step(["Clique em \"Ligar o computador\".", "O botão verde está embaixo.", "Veja a mãozinha."], [b])
	say("Todas as peças no lugar! Vamos ligar?", "feliz")


func _quiz_1() -> void:
	set_objective("Mostrar que você sabe para que serve cada peça.")
	var opts := ["SSD", "Memória RAM"] if guided else ["Memória RAM", "Processador", "SSD", "Fonte"]
	choice("Qual peça guarda os arquivos mesmo com o computador desligado?", opts, "SSD",
		{"_dica": "A memória RAM esquece tudo quando desliga.", "Memória RAM": "A RAM esquece tudo quando o computador desliga.",
			"Processador": "O processador faz as contas, mas não guarda arquivos.", "Fonte": "A fonte só dá energia."},
		"Sabe que o SSD guarda os arquivos", _quiz_2)


func _quiz_2() -> void:
	var opts := ["Processador", "Fonte"] if guided else ["Fonte", "SSD", "Processador", "Placa-mãe"]
	choice("Qual peça é o \"cérebro\" que faz as contas?", opts, "Processador",
		{"_dica": "É a peça que você encaixou no soquete.", "Fonte": "A fonte só dá energia.",
			"SSD": "O SSD guarda arquivos.", "Placa-mãe": "A placa-mãe liga as peças, mas quem faz as contas é outra."},
		"Sabe que o processador faz as contas",
		func(): complete("Computador montado e funcionando! Você conhece as peças por dentro."))


func explorer_quiz() -> Array:
	return [
		{"q": "Para que serve a memória RAM?",
			"options": ["Guardar o que está aberto agora", "Guardar fotos para sempre", "Ligar na tomada"], "answer": 0,
			"explain": "Ela é rápida, mas esquece tudo ao desligar.",
			"skill": "Explicou a função da memória RAM"},
		{"q": "Onde todas as peças se conectam?",
			"options": ["No monitor", "Na placa-mãe", "No teclado"], "answer": 1,
			"explain": "É a placa grande onde você encaixou tudo.",
			"skill": "Reconheceu a placa-mãe como base das peças"},
	]
