extends MissionBase
## Missão 9 — Dividir para organizar (Centro de Dados)
## Quantos endereços cabem em /24, dividir em duas /25 e escolher a máscara certa para 25 computadores.

const NET := "192.168.10"

var bar: SubnetBar
var sw_a: SwitchView
var sw_p: SwitchView
var devices: Array[DeviceView] = []
var _ips := {}
var _current: DeviceView = null
var _step := ""


## Barra de 0 a 255 com as partes da rede. Partes diferenciadas por cor, padrão e texto.
class SubnetBar extends Control:
	var split := false
	var marks: Array = []      # [[numero, rotulo]]

	func _init() -> void:
		custom_minimum_size = Vector2(620, 92) * (Game.ui_scale() / 0.7)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 6

	func _draw() -> void:
		var f := Game.ui_font
		var fs := Game.fs(18)
		var r := Rect2(Vector2(10, 26), Vector2(size.x - 20, 30))
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.95))
		draw_rect(Rect2(Vector2.ZERO, size), Palette.FRAME_DARK, false, 2)
		draw_string(f, Vector2(10, 4 + fs), "Rede %s.0 — números de 0 a 255" % NET, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT_SOFT)
		if not split:
			draw_rect(r, Color("#dbe9ff"))
			draw_string(f, r.position + Vector2(8, 21), "/24: um bloco só (.1 a .254 para computadores)", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.PRIMARY_DARK)
		else:
			var half := Rect2(r.position, Vector2(r.size.x / 2.0, r.size.y))
			draw_rect(half, Color("#dbe9ff"))
			var half2 := Rect2(r.position + Vector2(r.size.x / 2.0, 0), Vector2(r.size.x / 2.0, r.size.y))
			draw_rect(half2, Color("#fff1c9"))
			var x := half2.position.x
			while x < half2.end.x:     # listras na segunda parte (não depender só da cor)
				draw_line(Vector2(x, half2.position.y), Vector2(minf(x + 10, half2.end.x), half2.end.y), Color("#e8c46a"), 2)
				x += 12
			draw_string(f, half.position + Vector2(8, 21), "Alunos: .1 a .126", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.PRIMARY_DARK)
			draw_string(f, half2.position + Vector2(8, 21), "Professores: .129 a .254", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.STAR_DARK)
			draw_line(Vector2(r.get_center().x, r.position.y - 4), Vector2(r.get_center().x, r.end.y + 4), Palette.FRAME_DARK, 3)
		draw_rect(r, Palette.FRAME_DARK, false, 2)
		for n in [0, 128, 255]:
			var px: float = r.position.x + r.size.x * n / 255.0
			draw_string(f, Vector2(px - 8, r.end.y + fs + 2), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT)
		for m in marks:
			var px: float = r.position.x + r.size.x * float(m[0]) / 255.0
			draw_colored_polygon(PackedVector2Array([Vector2(px - 6, r.position.y - 8), Vector2(px + 6, r.position.y - 8), Vector2(px, r.position.y)]), Palette.FOCUS)


func setup() -> void:
	place_icon = "map"
	floor_tile = "piso_frio"
	wall_items = [["cartaz_rede", 0.3], ["relogio", 0.4], ["quadro", 0.6], ["extintor", 0.97]]
	floor_items = [["rack", Vector2(0.03, 0.85)], ["rack", Vector2(0.07, 0.85)], ["rack", Vector2(0.97, 0.3)]]
	set_objective("Organizar a rede em partes (sub-redes).")
	bar = SubnetBar.new()
	place(bar, Vector2(0.5, 0.1))
	story("A escola cresceu! Alunos e professores vão ficar em partes separadas da mesma rede. Isso se chama sub-rede. Vamos fazer as contas?", _step_count)


func _choice(question: String, options: Array, right: String, tips: Dictionary, skill: String, next: Callable) -> void:
	clear_actions()
	var rb: Array = []
	for o in options:
		var b := add_action(o, "", func():
			if o == right:
				clear_actions()
				correct("Certo!", skill)
				next.call()
			else:
				try_again(tips.get(o, "Pense de novo.")), "secondary")
		b.custom_minimum_size.x = 0
		if o == right:
			rb.append(b)
	set_step([question, tips.get("_dica", "Leia com calma."), "Veja a mãozinha na resposta."], rb)
	say(question)


# ---------------------------------------------------------------- 1. quantos cabem
func _step_count() -> void:
	_step = "contar"
	var opts := ["254", "24"] if guided else ["256", "24", "254", "255"]
	_choice("A rede %s.0/24 (máscara 255.255.255.0) tem quantos endereços para computadores?" % NET, opts, "254",
		{"_dica": "São 256 números (0 a 255), mas o primeiro (.0) é o nome da rede e o último (.255) é para falar com todos.",
			"256": "Quase! O .0 e o .255 são reservados. Tire os dois.",
			"255": "Falta tirar mais um: o .0 e o .255 são reservados.",
			"24": "O /24 é o tamanho da máscara (24 bits), não a quantidade de computadores."},
		"Calculou os endereços úteis de uma rede /24", _step_split)


# ---------------------------------------------------------------- 2. dividir em duas /25
func _step_split() -> void:
	_step = "dividir"
	bar.split = true
	bar.queue_redraw()
	set_objective("Colocar cada computador na parte certa da rede.")
	say("Dividimos a rede em duas partes de /25: alunos de .1 a .126 e professores de .129 a .254. Agora dê o endereço certo para cada computador.", "feliz")
	sw_a = SwitchView.new(2, "Switch dos alunos")
	sw_a.online = true
	place(sw_a, Vector2(0.25, 0.8))
	sw_p = SwitchView.new(2, "Switch dos professores")
	sw_p.online = true
	place(sw_p, Vector2(0.72, 0.8))
	var info := [["Aluno 1", "a", Vector2(0.14, 0.42)], ["Aluno 2", "a", Vector2(0.34, 0.42)],
		["Professor 1", "p", Vector2(0.62, 0.42)], ["Professor 2", "p", Vector2(0.84, 0.42)]]
	for i in info.size():
		var d := DeviceView.new("pc", info[i][0], "Sem endereço")
		d.set_meta("lado", info[i][1])
		d.set_meta("n", i)
		d.clicked.connect(_on_pc)
		place(d, info[i][2])
		devices.append(d)
		var sw := sw_a if info[i][1] == "a" else sw_p
		var port := i % 2
		cables.add_cable(d.anchor, func(): return sw.port_anchor(port), "ok")
		sw.set_port_used(port, true)
	_next_pc()


func _next_pc() -> void:
	for d in devices:
		if not _ips.has(d):
			set_step(["Clique no %s para dar um endereço." % d.name_label.text.to_lower(), "Ele está piscando.", "Veja a mãozinha."], [d])
			if guided:
				highlight([d])
			return
	_step_mask.call_deferred()


func _cards_for(d: DeviceView) -> Array:
	var aluno: bool = d.get_meta("lado") == "a"
	var n: int = d.get_meta("n")
	var good := "%s.%d" % [NET, (10 + n) if aluno else (140 + n)]
	var other := "%s.%d" % [NET, (150 + n) if aluno else (20 + n)]
	if guided:
		return [good, other] if n % 2 == 0 else [other, good]
	return [other, "%s.%d" % [NET, 128 if aluno else 127], good, "%s.255" % NET]


func _on_pc(d: DeviceView) -> void:
	if busy or _step != "dividir" or _ips.has(d):
		return
	_current = d
	d.selected = true
	Sfx.play("select")
	clear_actions()
	var aluno: bool = d.get_meta("lado") == "a"
	var rb: Array = []
	for ip in _cards_for(d):
		var b := add_action(ip, "", func(): _choose_ip(ip), "secondary")
		b.custom_minimum_size.x = 0
		if _valid(ip, aluno):
			rb.append(b)
	set_step([
		"O %s fica na parte dos %s: de .%s." % [d.name_label.text.to_lower(), "alunos" if aluno else "professores", "1 a .126" if aluno else "129 a .254"],
		"Olhe a barra lá em cima: compare o número final do endereço.",
		"Veja a mãozinha no endereço certo.",
	], rb)
	say("Qual endereço serve para o %s?" % d.name_label.text.to_lower())


func _valid(ip: String, aluno: bool) -> bool:
	var last := int(ip.get_slice(".", 3))
	return (last >= 1 and last <= 126) if aluno else (last >= 129 and last <= 254)


func _choose_ip(ip: String) -> void:
	if _current == null:
		return
	var aluno: bool = _current.get_meta("lado") == "a"
	var last := int(ip.get_slice(".", 3))
	bar.marks = [[last, ""]]
	bar.queue_redraw()
	if _valid(ip, aluno):
		_ips[_current] = ip
		_current.selected = false
		_current.online = true
		_current.set_info("IP: " + ip)
		correct("Na parte certa!", "Colocou computadores na sub-rede certa (/25)")
		_current = null
		clear_actions()
		_next_pc()
	elif last in [127, 128, 255]:
		try_again("O .%d é reservado: é o começo ou o fim de uma parte da rede. Escolha outro." % last)
	else:
		try_again("Esse número fica na parte dos %s. O %s é da parte dos %s." % ["professores" if aluno else "alunos", _current.name_label.text.to_lower(), "alunos" if aluno else "professores"])


# ---------------------------------------------------------------- 3. escolher a máscara
func _step_mask() -> void:
	_step = "mascara"
	set_objective("Escolher a máscara certa para o laboratório novo, com 25 computadores.")
	var opts := ["/27 (30 computadores)", "/28 (14 computadores)"] if guided else ["/24 (254 computadores)", "/26 (62 computadores)", "/27 (30 computadores)", "/28 (14 computadores)"]
	_choice("O laboratório novo terá 25 computadores. Qual é a MENOR parte da rede em que todos cabem?", opts, "/27 (30 computadores)",
		{"_dica": "Procure a menor opção que ainda tenha lugar para os 25.",
			"/28 (14 computadores)": "Só cabem 14. Faltariam 11 computadores!",
			"/26 (62 computadores)": "Cabe, mas sobra muito. Existe uma parte menor em que os 25 cabem.",
			"/24 (254 computadores)": "Cabe, mas desperdiça mais de 200 endereços. Procure uma parte menor."},
		"Escolheu a máscara certa para a quantidade de computadores",
		func(): complete("A rede está organizada em partes. Você já pensa como um técnico de redes!"))


func explorer_quiz() -> Array:
	return [
		{"q": "Qual máscara é a mesma coisa que /24?",
			"options": ["255.255.255.0", "255.0.0.0", "255.255.255.255"], "answer": 0,
			"explain": "24 bits = três blocos de 255.",
			"skill": "Relacionou /24 com 255.255.255.0"},
		{"q": "Na rede 192.168.10.128/25, qual endereço pode ser de um computador?",
			"options": ["192.168.10.128", "192.168.10.200", "192.168.10.255"], "answer": 1,
			"explain": "O primeiro e o último da parte são reservados.",
			"skill": "Identificou endereço válido em uma /25"},
	]
