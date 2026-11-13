extends MissionBase
## Temporada 2, nível 5 — Backup salva o dia (Sala de Projetos)
## O que guardar, onde guardar (lugares diferentes, um fora da escola), backup automático e restauração.

const ITEMS := [["Trabalhos dos alunos", true], ["Fotos da feira", true], ["Notas e boletins", true],
	["Arquivos temporários", false], ["Lixeira", false]]

var pc: DeviceView
var hd: DeviceView
var cloud: DeviceView
var pen: DeviceView
var _picked := {}
var _places := []
var _step := ""


func setup() -> void:
	place_icon = "save"
	floor_tile = "piso_madeira"
	wall_items = [["janela", 0.3], ["cartaz_wifi", 0.42], ["relogio", 0.52], ["quadro", 0.68], ["janela", 0.86]]
	floor_items = [["planta", Vector2(0.03, 0.9)], ["arquivo", Vector2(0.975, 0.5)]]
	set_objective("Fazer o backup dos arquivos importantes da escola.")
	pc = DeviceView.new("pc", "Computador da coordenação", "Arquivos da escola")
	pc.online = true
	pc.clicked.connect(_on_place)
	place(pc, Vector2(0.2, 0.22))
	hd = DeviceView.new("hdext", "HD externo", "Fica na escola")
	hd.show_led = false
	hd.clicked.connect(_on_place)
	place(hd, Vector2(0.46, 0.22))
	cloud = DeviceView.new("cloud", "Nuvem da escola", "Fica na internet")
	cloud.show_led = false
	cloud.clicked.connect(_on_place)
	place(cloud, Vector2(0.68, 0.22))
	if not guided:
		pen = DeviceView.new("pendrive", "Pen drive", "Fica na escola")
		pen.show_led = false
		pen.clicked.connect(_on_place)
		place(pen, Vector2(0.88, 0.22))
	story("Todos os trabalhos da feira estão em um computador só. Se ele quebrar, perde tudo! Vamos fazer cópias de segurança: o BACKUP.", _step_what)


# ---------------------------------------------------------------- 1. o que guardar
func _step_what() -> void:
	_step = "escolher"
	set_objective("Escolher o que é importante guardar.")
	clear_actions()
	var list: Array = ITEMS.slice(0, 4) if guided else ITEMS
	var good: Array = []
	for it in list:
		var item_name: String = it[0]
		var b := add_action(item_name, "minus", func(): pass, "secondary")
		b.custom_minimum_size.x = 0
		b.pressed.connect(func():
			_picked[item_name] = not _picked.get(item_name, false)
			b.set_variant("success" if _picked[item_name] else "secondary")
			b.icon_kind = "check" if _picked[item_name] else "minus"
			b.queue_redraw())
		if it[1]:
			good.append(b)
	var done := add_action("Pronto", "next", func(): _check_what(list), "star")
	set_step([
		"Marque só o que é importante e não pode ser perdido. Depois clique em Pronto.",
		"Trabalhos, fotos e notas são importantes. Temporários e lixeira não.",
		"Veja a mãozinha nos itens importantes.",
	], good + [done])
	say("O que precisa de backup? Marque os itens importantes e clique em Pronto.")


func _check_what(list: Array) -> void:
	for it in list:
		var on: bool = _picked.get(it[0], false)
		if on and not it[1]:
			try_again("%s não precisa de backup: são arquivos que já podem ser apagados." % it[0])
			return
		if not on and it[1]:
			try_again("Faltou marcar: %s. Isso é importante para a escola!" % it[0])
			return
	clear_actions()
	correct("Escolha certa!", "Escolheu o que é importante para o backup")
	_step_where.call_deferred()


# ---------------------------------------------------------------- 2. onde guardar
func _step_where() -> void:
	_step = "onde"
	set_objective("Guardar as cópias em DOIS lugares diferentes do computador.")
	set_step([
		"Clique em dois lugares para guardar as cópias. Não vale o próprio computador!",
		"Um lugar na escola (HD externo) e outro fora dela (nuvem) é o mais seguro.",
		"Veja a mãozinha: HD externo e nuvem.",
	], [hd, cloud])
	say("Onde guardar as cópias? Escolha dois lugares.")
	if guided:
		highlight([hd, cloud])


func _on_place(d: DeviceView) -> void:
	if busy:
		return
	if _step == "restaurar":
		_restore(d)
		return
	if _step != "onde":
		return
	if d == pc:
		try_again("Se o computador quebrar, perde o original E a cópia. A cópia precisa ficar em outro lugar.")
		return
	if _places.has(d):
		return
	_places.append(d)
	d.selected = true
	Sfx.play("select")
	if _places.size() < 2:
		say("Boa! Agora escolha o segundo lugar.")
		return
	if not guided and not _places.has(cloud):
		for p in _places:
			p.selected = false
		_places.clear()
		try_again("Os dois ficam dentro da escola. Se acontecer algo no prédio (enchente, incêndio), perde tudo. Use a nuvem como um dos lugares.")
		return
	correct("Dois lugares diferentes!", "Guardou cópias em lugares diferentes (um fora da escola)")
	var t := animate("m15_copiar")
	for p in _places:
		send_packet(t, "cópia", [pc, p], Palette.STAR, 0.6)
		t.tween_callback(func(): (p as DeviceView).set_info("Cópia guardada"))
	t.finished.connect(_step_when)


# ---------------------------------------------------------------- 3. quando
func _step_when() -> void:
	for p in _places:
		p.selected = false
	var right := "Automático, todo dia"
	var opts := [right, "Quando alguém lembrar"] if guided else ["Uma vez por ano", right, "Quando alguém lembrar"]
	choice("De quanto em quanto tempo fazer o backup?", opts, right,
		{"_dica": "Os trabalhos mudam todo dia.",
			"Quando alguém lembrar": "As pessoas esquecem! O backup automático não esquece.",
			"Uma vez por ano": "Se o computador quebrar em novembro, perde quase um ano de trabalho."},
		"Configurou backup automático e frequente", _disaster)


# ---------------------------------------------------------------- 4. pane e restauração
func _disaster() -> void:
	set_objective("Recuperar os arquivos depois da pane.")
	var t := animate("m15_pane")
	t.tween_interval(0.5)
	t.tween_callback(func():
		pc.online = false
		pc.screen_text = "ERRO NO DISCO"
		pc.set_info("Arquivos perdidos!")
		pc.queue_redraw()
		Sfx.play("alert"))
	t.tween_property(pc, "rotation", 0.05, 0.08)
	t.tween_property(pc, "rotation", -0.05, 0.08)
	t.tween_property(pc, "rotation", 0.0, 0.08)
	t.finished.connect(func():
		_step = "restaurar"
		say("Oh não! O disco do computador queimou. Ainda bem que temos backup! Clique em um lugar onde está a cópia.", "pensando")
		set_step(["Clique no HD externo ou na nuvem para restaurar.", "As cópias estão no HD externo e na nuvem.", "Veja a mãozinha."], [_places[0]])
		if guided:
			highlight(_places))


func _restore(d: DeviceView) -> void:
	if not _places.has(d):
		try_again("Aí não tem cópia. Use um dos lugares onde você guardou o backup.")
		return
	_step = "fim"
	var t := animate("m15_restaurar")
	send_packet(t, "restaurando", [d, pc], Palette.LED_ON, 0.7)
	t.tween_callback(func():
		pc.online = true
		pc.screen_text = "Arquivos OK"
		pc.set_info("Arquivos restaurados")
		pc.queue_redraw())
	t.finished.connect(func():
		correct("Arquivos de volta!", "Restaurou arquivos a partir do backup")
		complete("Graças ao backup, nenhum trabalho da feira foi perdido!"))


func explorer_quiz() -> Array:
	return [
		{"q": "O que é backup?",
			"options": ["Uma cópia de segurança dos arquivos", "Um tipo de vírus", "Um cabo de rede"], "answer": 0,
			"explain": "Foi o que salvou os trabalhos quando o disco queimou.",
			"skill": "Explicou o que é backup"},
		{"q": "Por que ter uma cópia fora da escola (na nuvem)?",
			"options": ["Para ficar mais bonito", "Se algo acontecer no prédio, a cópia continua segura", "Não precisa"], "answer": 1,
			"explain": "Enchente ou incêndio podem estragar tudo o que está no mesmo lugar.",
			"skill": "Entende a importância de cópia fora do local"},
	]
