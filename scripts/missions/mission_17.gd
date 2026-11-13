extends MissionBase
## Temporada 2, nível 7 — Se... então (Laboratório de Programação)
## Condições SE/SENÃO: escolher a regra certa, prever o resultado, separar peças e achar o erro.

var code_win: PanelContainer
var out_win: PanelContainer
var code_title: Label
var code_label: Label
var out_label: Label
var pc: DeviceView
var _step := ""


func setup() -> void:
	place_icon = "help"
	floor_tile = "piso_tijolo"
	wall_items = [["quadro", 0.3], ["relogio", 0.42], ["janela", 0.6], ["cartaz_rede", 0.74], ["janela", 0.86]]
	floor_items = [["planta", Vector2(0.03, 0.9)], ["armario", Vector2(0.975, 0.2)]]
	set_objective("Ensinar o computador a tomar decisões com SE... ENTÃO... SENÃO.")
	pc = DeviceView.new("pc", "Computador do laboratório", "")
	pc.online = true
	place(pc, Vector2(0.1, 0.22))
	story("Computadores tomam decisões com regras do tipo: SE acontecer isso, ENTÃO faça aquilo, SENÃO faça outra coisa. Vamos programar algumas decisões?", _round_grades)


func _set_code(title: String, lines: Array) -> void:
	_ensure_windows()
	code_title.text = title
	code_label.text = "\n".join(PackedStringArray(lines))


func _set_output(lines: Array) -> void:
	_ensure_windows()
	out_win.visible = true
	out_label.text = "\n".join(PackedStringArray(lines))


## Janelas criadas uma vez só; depois só o texto muda.
func _ensure_windows() -> void:
	if code_win:
		return
	var w1 := UiWindow.create("Programa", 430.0 * Game.ui_scale() / 0.7)
	code_win = w1.root
	code_title = w1.title
	code_label = Label.new()
	w1.body.add_child(code_label)
	place(code_win, Vector2(0.4, 0.2))
	var w2 := UiWindow.create("Saída do programa", 300.0 * Game.ui_scale() / 0.7)
	out_win = w2.root
	out_label = Label.new()
	w2.body.add_child(out_label)
	place(out_win, Vector2(0.8, 0.22))
	out_win.visible = false


# ---------------------------------------------------------------- 1. boletim
func _round_grades() -> void:
	_step = "boletim"
	set_objective("Rodada 1: o boletim. Aprovado com nota 6 ou mais.")
	_set_code("Regra da escola", ["Nota 6 ou mais: Aprovado", "Menos que 6: Recuperação"])
	var right := "SE nota >= 6 ENTÃO \"Aprovado\" SENÃO \"Recuperação\""
	var opts := [right, "SE nota < 6 ENTÃO \"Aprovado\" SENÃO \"Recuperação\""] if guided else [
		"SE nota > 6 ENTÃO \"Aprovado\" SENÃO \"Recuperação\"", right, "SE nota < 6 ENTÃO \"Aprovado\" SENÃO \"Recuperação\""]
	choice("Qual programa segue a regra da escola?", opts, right,
		{"_dica": "O sinal >= quer dizer \"maior ou igual\". Quem tira 6 também passa.",
			"SE nota < 6 ENTÃO \"Aprovado\" SENÃO \"Recuperação\"": "Ao contrário! Assim quem tira nota baixa seria aprovado.",
			"SE nota > 6 ENTÃO \"Aprovado\" SENÃO \"Recuperação\"": "Quase! Com > (maior), quem tira exatamente 6 ia para a recuperação. Precisa ser >= (maior ou igual)."},
		"Escolheu a condição certa (maior ou igual)", _grades_predict)


func _grades_predict() -> void:
	_set_code("Programa", ["SE nota >= 6", "    ENTÃO mostrar \"Aprovado\"", "SENÃO", "    mostrar \"Recuperação\""])
	var right := "Aprovado"
	choice("Antes de rodar: o que o programa mostra para quem tirou exatamente 6?", [right, "Recuperação"], right,
		{"_dica": "6 é maior ou igual a 6?", "Recuperação": "6 >= 6 é verdade (6 é igual a 6). Então entra no ENTÃO."},
		"Previu o resultado de uma condição", _grades_run)


func _grades_run() -> void:
	var notas := [8, 5, 6, 3]
	var t := animate("m17_boletim")
	var lines: Array = []
	_set_output(["(rodando...)"])
	for n in notas:
		var nn: int = n
		t.tween_callback(func():
			lines.append("Nota %d -> %s" % [nn, "Aprovado" if nn >= 6 else "Recuperação"])
			_set_output(lines)
			Sfx.play("select"))
		t.tween_interval(0.4)
	t.finished.connect(func():
		say("Funcionou para todos os alunos!", "feliz")
		_round_sort())


# ---------------------------------------------------------------- 2. separar peças
func _round_sort() -> void:
	_step = "esteira"
	set_objective("Rodada 2: a esteira de peças da feira.")
	var right: String
	var opts: Array
	var tips := {}
	if guided:
		_set_code("Pedido", ["Peças AZUIS vão para a caixa A.", "As outras vão para a caixa B."])
		right = "SE cor = azul ENTÃO caixa A SENÃO caixa B"
		opts = [right, "SE cor = vermelho ENTÃO caixa A SENÃO caixa B"]
		tips = {"_dica": "A condição precisa falar da cor que vai para a caixa A.",
			"SE cor = vermelho ENTÃO caixa A SENÃO caixa B": "Assim as vermelhas iriam para a A, e o pedido era das azuis."}
	else:
		_set_code("Pedido", ["Só as peças AZUIS E GRANDES vão para a caixa A.", "Todas as outras vão para a caixa B."])
		right = "SE cor = azul E tamanho = grande ENTÃO caixa A SENÃO caixa B"
		opts = ["SE cor = azul OU tamanho = grande ENTÃO caixa A SENÃO caixa B", right, "SE cor = azul ENTÃO caixa A SENÃO caixa B"]
		tips = {"_dica": "As DUAS coisas precisam ser verdade ao mesmo tempo.",
			"SE cor = azul OU tamanho = grande ENTÃO caixa A SENÃO caixa B": "Com OU, basta uma ser verdade: uma peça vermelha grande ia para a A.",
			"SE cor = azul ENTÃO caixa A SENÃO caixa B": "Falta o tamanho: uma peça azul pequena iria para a A."}
	choice("Qual regra faz a esteira separar as peças certinho?", opts, right, tips,
		"Escreveu regra com condição composta (E)" if not guided else "Escreveu regra SE/SENÃO para separar itens", _sort_run)


func _sort_run() -> void:
	var items := [["azul", "grande"], ["vermelha", "grande"], ["azul", "pequena"], ["verde", "pequena"]]
	var t := animate("m17_esteira")
	var lines: Array = []
	for it in items:
		var a: bool = it[0] == "azul" and (guided or it[1] == "grande")
		var label := "Peça %s %s -> caixa %s" % [it[0], it[1], "A" if a else "B"]
		t.tween_callback(func():
			lines.append(label)
			_set_output(lines)
			Sfx.play("connect"))
		t.tween_interval(0.4)
	t.finished.connect(func():
		say("Todas as peças foram para a caixa certa!", "feliz")
		_round_bug())


# ---------------------------------------------------------------- 3. achar o erro
func _round_bug() -> void:
	_step = "erro"
	set_objective("Rodada 3: achar o erro no programa do Wi-Fi.")
	_set_code("Programa com erro", ["SE senha = \"Feira2026\"", "    ENTÃO mostrar \"Acesso liberado\"", "SENÃO", "    mostrar \"Acesso liberado\""])
	_set_output(["Senha Feira2026 -> Acesso liberado", "Senha 1234 -> Acesso liberado (?!)"])
	var right := "Trocar o SENÃO para mostrar \"Senha errada\""
	var opts := [right, "Apagar o SE"] if guided else ["Apagar o SE", "Trocar a senha para 1234", right]
	choice("Qualquer senha libera o Wi-Fi! Como corrigir o programa?", opts, right,
		{"_dica": "Olhe o que acontece nos dois caminhos: ENTÃO e SENÃO.",
			"Apagar o SE": "Sem o SE, o programa nem confere a senha.",
			"Trocar a senha para 1234": "O problema não é a senha: é que o SENÃO também libera o acesso."},
		"Encontrou e corrigiu um erro de lógica (depuração)", func():
			_set_code("Programa corrigido", ["SE senha = \"Feira2026\"", "    ENTÃO mostrar \"Acesso liberado\"", "SENÃO", "    mostrar \"Senha errada\""])
			_set_output(["Senha Feira2026 -> Acesso liberado", "Senha 1234 -> Senha errada"])
			complete("Seus programas agora tomam decisões certas: SE, ENTÃO e SENÃO!"))


func explorer_quiz() -> Array:
	return [
		{"q": "Na regra \"SE chover ENTÃO levo guarda-chuva SENÃO levo boné\", o que levo num dia de sol?",
			"options": ["Guarda-chuva", "Boné", "Nada"], "answer": 1,
			"explain": "Sem chuva, a condição é falsa: vale o SENÃO.",
			"skill": "Interpretou uma condição falsa (SENÃO)"},
		{"q": "Quando \"A E B\" é verdade?",
			"options": ["Quando só A é verdade", "Quando A e B são verdade ao mesmo tempo", "Sempre"], "answer": 1,
			"explain": "Lembre da peça azul E grande.",
			"skill": "Explicou o operador lógico E"},
	]
