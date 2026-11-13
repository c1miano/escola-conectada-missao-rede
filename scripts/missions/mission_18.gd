extends MissionBase
## Temporada 2, nível 8 — Dados protegidos (Sala de Mídia)
## Dados pessoais (LGPD), verificação em duas etapas e permissões de aplicativos.

const DATA_BASIC := [["Nome do projeto", "publico"], ["CPF do aluno", "pessoal"], ["Foto do trabalho (sem rostos)", "publico"], ["Endereço de casa", "pessoal"]]
const DATA_EXTRA := [["Senha do e-mail", "pessoal"], ["Telefone do responsável", "pessoal"], ["Nome da escola", "publico"]]

var data_win: PanelContainer
var item_buttons: Array = []
var bins := {}
var selected: Button = null
var phone: DeviceView
var laptop: DeviceView
var _left := 0
var _step := ""


func setup() -> void:
	place_icon = "lock"
	floor_tile = "piso_madeira"
	wall_items = [["cartaz_wifi", 0.3], ["janela", 0.45], ["relogio", 0.56], ["quadro", 0.7], ["janela", 0.86]]
	floor_items = [["arquivo", Vector2(0.975, 0.5)], ["planta", Vector2(0.03, 0.9)]]
	set_objective("Proteger os dados das pessoas da escola.")
	laptop = DeviceView.new("notebook", "Notebook do site da feira", "")
	laptop.online = true
	place(laptop, Vector2(0.1, 0.22))
	phone = DeviceView.new("phone", "Celular da coordenadora", "")
	phone.show_led = false
	place(phone, Vector2(0.9, 0.24))
	story("O site da feira vai mostrar os projetos dos alunos. Mas cuidado: alguns dados são pessoais e a lei (LGPD) manda proteger. Vamos separar o que pode aparecer?", _step_classify)


# ---------------------------------------------------------------- 1. classificar dados
func _step_classify() -> void:
	_step = "classificar"
	var win := UiWindow.create("Dados recebidos para o site", 680.0 * Game.ui_scale() / 0.7)
	data_win = win.root
	place(data_win, Vector2(0.48, 0.34))
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	win.body.add_child(grid)
	var items: Array = DATA_BASIC.duplicate()
	if not guided:
		items.append_array(DATA_EXTRA)
	for it in items:
		var b := BigButton.new(it[0], "report", "secondary", 56)
		b.set_meta("tipo", it[1])
		b.pressed.connect(func(): _on_item(b))
		grid.add_child(b)
		item_buttons.append(b)
	_left = items.size()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	win.body.add_child(row)
	bins["publico"] = BigButton.new("Pode aparecer no site", "check", "success", 64)
	bins["pessoal"] = BigButton.new("Dado pessoal: proteger", "lock", "star", 64)
	for k in bins:
		var kind: String = k
		(bins[k] as BigButton).pressed.connect(func(): _on_bin(kind))
		row.add_child(bins[k])
	_hint()


func _hint() -> void:
	for b in item_buttons:
		if b.visible:
			var t: String = b.get_meta("tipo")
			set_step([
				"Clique em um dado e depois escolha: pode aparecer no site ou é pessoal?",
				"Dado pessoal identifica ou expõe uma pessoa: CPF, endereço, senha, telefone.",
				"Veja a mãozinha: dado e depois a escolha certa.",
			], [b, bins[t]])
			if guided:
				highlight([b])
			return


func _on_item(b: Button) -> void:
	if busy or _step != "classificar":
		return
	if selected:
		selected.modulate = Color.WHITE
	selected = b
	b.modulate = Color(1, 0.85, 0.5)
	Sfx.play("select")
	say("\"%s\": pode aparecer no site ou é um dado pessoal?" % b.text)


func _on_bin(kind: String) -> void:
	if busy or _step != "classificar":
		return
	if selected == null:
		say("Primeiro clique em um dado.", "pensando")
		return
	var t: String = selected.get_meta("tipo")
	if t != kind:
		if t == "pessoal":
			try_again("\"%s\" é um dado pessoal: com ele alguém pode encontrar ou prejudicar a pessoa. Precisa ser protegido." % selected.text)
		else:
			try_again("\"%s\" não identifica ninguém. Pode aparecer no site da feira." % selected.text)
		return
	selected.visible = false
	selected = null
	_left -= 1
	correct("Certo!", "Identificou dados pessoais que devem ser protegidos (LGPD)")
	if _left == 0:
		data_win.visible = false
		_step_2fa.call_deferred()
	else:
		_hint()


# ---------------------------------------------------------------- 2. verificação em duas etapas
func _step_2fa() -> void:
	_step = "2fa"
	set_objective("Proteger a conta da coordenadora com verificação em duas etapas.")
	var right := "Ativar verificação em duas etapas"
	var opts := [right, "Mostrar a senha para todos"] if guided else ["Usar a mesma senha em tudo", right, "Mostrar a senha para todos"]
	choice("A conta do site da feira só tem senha. Como deixar mais segura?", opts, right,
		{"_dica": "Além da senha, peça uma segunda prova: um código no celular.",
			"Mostrar a senha para todos": "Senha é segredo! Mostrar deixa qualquer um entrar.",
			"Usar a mesma senha em tudo": "Se descobrirem uma senha, entram em tudo. É o contrário do seguro."},
		"Ativou a verificação em duas etapas", _code)


func _code() -> void:
	phone.screen_text = "482913"
	phone.set_info("Código: 4 8 2 9 1 3")
	phone.queue_redraw()
	Sfx.play("alert")
	var right := "482913"
	var opts := ["428913", right] if guided else ["482193", "428913", right]
	choice("O celular recebeu um código. Qual digitar? (olhe com atenção no celular)", opts, right,
		{"_dica": "Compare número por número: 4, 8, 2, 9, 1, 3.",
			"428913": "Olhe de novo: o código começa com 4 8, não 4 2.",
			"482193": "Quase! Confira o final: é 9 1 3."},
		"Usou o código da verificação em duas etapas com atenção", _step_permissions)


# ---------------------------------------------------------------- 3. permissões do aplicativo
func _step_permissions() -> void:
	_step = "permissoes"
	set_objective("Decidir as permissões de um aplicativo.")
	phone.screen_text = "Lanterna"
	phone.set_info("App Lanterna pede: câmera, contatos, localização")
	phone.queue_redraw()
	var right := "Permitir só a câmera (é o flash)"
	var opts := [right, "Permitir tudo"] if guided else ["Permitir tudo", right, "Permitir contatos e localização"]
	choice("Um app de LANTERNA pede câmera (para o flash), contatos e localização. O que permitir?", opts, right,
		{"_dica": "Permita só o que o app precisa para funcionar.",
			"Permitir tudo": "Uma lanterna não precisa dos seus contatos nem de onde você está.",
			"Permitir contatos e localização": "Justamente esses a lanterna não precisa. Ela só usa o flash da câmera."},
		"Concedeu só as permissões necessárias ao aplicativo",
		func(): complete("Dados das pessoas protegidos: LGPD, duas etapas e permissões certas!"))


func explorer_quiz() -> Array:
	return [
		{"q": "O que a LGPD protege?",
			"options": ["Os dados pessoais das pessoas", "Os cabos de rede", "A velocidade da internet"], "answer": 0,
			"explain": "LGPD = Lei Geral de Proteção de Dados.",
			"skill": "Sabe o que a LGPD protege"},
		{"q": "Na verificação em duas etapas, a segunda etapa costuma ser:",
			"options": ["Um código no celular", "A cor favorita", "O nome da escola"], "answer": 0,
			"explain": "É algo que só você tem com você.",
			"skill": "Explicou a verificação em duas etapas"},
	]
