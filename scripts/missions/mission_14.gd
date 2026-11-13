extends MissionBase
## Temporada 2, nível 4 — Instalar com segurança (Laboratório 2)
## Requisitos do programa, download no site oficial, instalador sem programas extras e atualização.

const PCS := [
	{"name": "Computador A", "info": "64 bits · 4 GB · 80 GB livres", "ok": false, "why": "Só tem 4 GB de memória. O programa precisa de 8 GB."},
	{"name": "Computador B", "info": "64 bits · 8 GB · 50 GB livres", "ok": true, "why": ""},
	{"name": "Computador C", "info": "32 bits · 16 GB · 200 GB livres", "ok": false, "why": "O sistema é de 32 bits. O programa só funciona em 64 bits."},
	{"name": "Computador D", "info": "64 bits · 8 GB · 5 GB livres", "ok": false, "why": "Só tem 5 GB livres. O programa precisa de 10 GB."},
]

var pcs: Array[DeviceView] = []
var req: PanelContainer
var wizard: PanelContainer
var wizard_title: Label
var wizard_label: Label
var _chosen: DeviceView = null
var _step := ""
var _extras_checked := true


func setup() -> void:
	place_icon = "save"
	floor_tile = "piso_tijolo"
	wall_items = [["quadro", 0.3], ["relogio", 0.42], ["janela", 0.6], ["cartaz_wifi", 0.74], ["janela", 0.86]]
	floor_items = [["planta", Vector2(0.03, 0.9)]]
	set_objective("Instalar o Editor de Vídeo Escolar do jeito seguro.")
	var list: Array = PCS.slice(0, 3) if guided else PCS
	var x := 0.12
	for p in list:
		var d := DeviceView.new("pc", p.name, p.info)
		d.online = true
		d.set_meta("pc", p)
		d.clicked.connect(_on_pc)
		place(d, Vector2(x, 0.62))
		pcs.append(d)
		x += 0.2 if guided else 0.16
	req = info_window("Requisitos do programa", ["Editor de Vídeo Escolar precisa de:", "• Windows 64 bits", "• 8 GB de memória (ou mais)", "• 10 GB livres no disco"], Vector2(0.2, 0.16), 330.0)
	story("Os professores querem um editor de vídeo para a feira. Instalar programa parece fácil, mas um técnico confere tudo antes para não estragar o computador.", _step_requirements)


# ---------------------------------------------------------------- 1. requisitos
func _step_requirements() -> void:
	_step = "requisitos"
	var right: DeviceView = pcs[1]
	set_step([
		"Compare cada computador com os requisitos e clique no que pode receber o programa.",
		"Confira os três: 64 bits, pelo menos 8 GB e pelo menos 10 GB livres.",
		"Veja a mãozinha no computador certo.",
	], [right])
	say("Em qual computador o programa pode ser instalado? Compare com a lista de requisitos.")


func _on_pc(d: DeviceView) -> void:
	if busy or _step != "requisitos":
		return
	var p: Dictionary = d.get_meta("pc")
	if not p.ok:
		try_again(p.why)
		return
	_chosen = d
	d.selected = true
	correct("Esse serve!", "Conferiu os requisitos do programa (sistema, memória e espaço)")
	_step_download.call_deferred()


# ---------------------------------------------------------------- 2. download seguro
func _step_download() -> void:
	_step = "download"
	set_objective("Baixar o programa no lugar certo.")
	var page := info_window("Navegador: pesquisa \"editor de vídeo escolar\"", [
		"[ANÚNCIO]  BAIXAR AGORA GRÁTIS!!! CLIQUE AQUI!!!",
		"programas-crackeados.biz — Editor PRO liberado de graça",
		"https://editor.escola.org — Download oficial do Editor de Vídeo Escolar",
	], Vector2(0.64, 0.1), 470.0)
	page.set_meta("tmp", true)
	var right := "Site oficial (https://editor.escola.org)"
	var opts := [right, "Botão BAIXAR AGORA GRÁTIS!!!"] if guided else ["Botão BAIXAR AGORA GRÁTIS!!!", "programas-crackeados.biz", right]
	choice("Onde é seguro baixar o programa?", opts, right,
		{"_dica": "Programa seguro vem do site de quem fez o programa.",
			"Botão BAIXAR AGORA GRÁTIS!!!": "Esse botão é um anúncio: costuma baixar outro programa, às vezes vírus.",
			"programas-crackeados.biz": "Programa pirata é ilegal e muitas vezes vem com vírus."},
		"Baixou o programa do site oficial", func():
			page.visible = false
			_step_wizard(1))


# ---------------------------------------------------------------- 3. instalador
func _step_wizard(page: int) -> void:
	_step = "instalador"
	set_objective("Instalar sem aceitar programas extras.")
	var lines: Array
	match page:
		1: lines = ["Bem-vindo ao instalador do Editor de Vídeo Escolar.", "Termos de uso: o programa é gratuito para escolas."]
		2: lines = ["Instalação rápida (recomendada!)", ("[X]" if _extras_checked else "[  ]") + " Instalar também o Navegador Turbo e a Barra de Pesquisas Mega"]
		3: lines = ["Pasta: C:\\Programas\\Editor de Vídeo Escolar", "Pronto para instalar."]
	if wizard == null:
		var w := UiWindow.create("Instalador", 470.0 * Game.ui_scale() / 0.7)
		wizard = w.root
		wizard_title = w.title
		wizard_label = Label.new()
		w.body.add_child(wizard_label)
		place(wizard, Vector2(0.64, 0.1))
	wizard_title.text = "Instalador — passo %d de 3" % page
	wizard_label.text = "\n".join(PackedStringArray(lines))
	clear_actions()
	match page:
		1:
			var b := add_action("Aceito os termos e avançar", "next", func(): _step_wizard(2), "success")
			set_step(["Leia e clique em \"Aceito os termos e avançar\".", "O botão verde está embaixo.", "Veja a mãozinha."], [b])
			say("O instalador abriu. Leia cada tela antes de avançar.")
		2:
			var un := add_action("Desmarcar programas extras", "minus", func():
				_extras_checked = false
				correct("Desmarcado!", "Recusou programas extras no instalador")
				_step_wizard(2), "secondary")
			var nx := add_action("Avançar", "next", func():
				if _extras_checked:
					try_again("Atenção! Ainda está marcado para instalar o Navegador Turbo e a Barra Mega. Eles não foram pedidos e deixam o computador lento.")
				else:
					_step_wizard(3), "success")
			set_step(["Leia com atenção: tem algo marcado que você não pediu?", "Desmarque o Navegador Turbo e a Barra de Pesquisas antes de avançar.", "Veja a mãozinha."], [un if _extras_checked else nx])
			if _extras_checked:
				say("Leia essa tela com atenção antes de avançar...", "pensando")
		3:
			var b2 := add_action("Instalar", "play", func():
				clear_actions()
				var t := animate("m14_instalar")
				for i in 5:
					t.tween_callback(func():
						_chosen.screen_text = "%d%%" % ((i + 1) * 20)
						_chosen.queue_redraw())
					t.tween_interval(0.3)
				t.tween_callback(func():
					_chosen.screen_text = "Editor OK"
					_chosen.queue_redraw()
					wizard.visible = false
					Sfx.play("ok"))
				t.finished.connect(_step_update), "success")
			set_step(["Clique em \"Instalar\".", "O botão verde está embaixo.", "Veja a mãozinha."], [b2])


# ---------------------------------------------------------------- 4. atualização
func _step_update() -> void:
	set_objective("Manter o computador atualizado.")
	var right := "Instalar a atualização"
	var opts := [right, "Ignorar para sempre"] if guided else ["Ignorar para sempre", "Desligar o antivírus para ficar mais rápido", right]
	choice("Apareceu: \"Atualização de segurança disponível para o Windows\". O que fazer?", opts, right,
		{"_dica": "Atualização de segurança corrige falhas que os vírus usam.",
			"Ignorar para sempre": "Sem atualizar, o computador fica com falhas que os vírus usam.",
			"Desligar o antivírus para ficar mais rápido": "Sem antivírus o computador fica desprotegido. Nunca faça isso."},
		"Sabe a importância das atualizações de segurança",
		func(): complete("Programa instalado do jeito seguro e computador atualizado!"))


func explorer_quiz() -> Array:
	return [
		{"q": "Antes de instalar um programa, o que conferir primeiro?",
			"options": ["A cor do ícone", "Os requisitos do programa", "Se o nome é bonito"], "answer": 1,
			"explain": "Sistema, memória e espaço livre precisam ser suficientes.",
			"skill": "Sabe conferir requisitos antes de instalar"},
		{"q": "No instalador, uma caixa já vem marcada para instalar outro programa. O que fazer?",
			"options": ["Desmarcar, se não foi pedido", "Deixar marcado sempre", "Desligar o computador"], "answer": 0,
			"explain": "Leia cada tela: programas extras deixam o computador lento.",
			"skill": "Recusa programas extras em instaladores"},
	]
