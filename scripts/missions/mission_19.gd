extends MissionBase
## Temporada 2, nível 9 — Planilha da feira (Tesouraria)
## Células (coluna + linha), fórmulas com =, copiar fórmula, SOMA com intervalo e escolha de gráfico.

const COLS := ["A", "B", "C", "D"]
const ROWS := [
	["Produto", "Quantidade", "Preço (R$)", "Total (R$)"],
	["Pulseira LED", "10", "3", ""],
	["Chaveiro robô", "5", "4", ""],
	["Adesivo", "20", "1", ""],
	["Livro de lógica", "2", "15", ""],
	["TOTAL", "", "", ""],
]

var sheet: PanelContainer
var cells := {}        # "A1" -> Button
var chart: Control
var _target_cell := ""
var _step := ""
var _cell_clicks := 0


func setup() -> void:
	place_icon = "report"
	floor_tile = "piso_madeira"
	wall_items = [["quadro", 0.3], ["relogio", 0.42], ["janela", 0.6], ["cartaz_rede", 0.74], ["janela", 0.86]]
	floor_items = [["arquivo", Vector2(0.975, 0.5)], ["planta", Vector2(0.03, 0.9)], ["pc_on", Vector2(0.08, 0.2)]]
	set_objective("Fazer as contas das vendas da feira na planilha.")
	_build_sheet()
	story("A tesouraria vendeu produtos na feira e precisa das contas. Na planilha, o computador faz as contas sozinho: é só escrever a fórmula certa!", _step_cell)


func _build_sheet() -> void:
	var win := UiWindow.create("Planilha: vendas_feira.xlsx", 0.0)
	sheet = win.root
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	win.body.add_child(grid)
	var k := Game.ui_scale() / 0.7
	grid.add_child(Control.new())
	for c in COLS:
		var h := Label.new()
		h.text = c
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_theme_color_override("font_color", Palette.TEXT_SOFT)
		grid.add_child(h)
	for r in ROWS.size():
		var rl := Label.new()
		rl.text = str(r + 1)
		rl.add_theme_color_override("font_color", Palette.TEXT_SOFT)
		grid.add_child(rl)
		for c in COLS.size():
			var b := Button.new()
			b.text = ROWS[r][c]
			b.custom_minimum_size = Vector2(150 if c == 0 else 120, 34) * k
			b.focus_mode = Control.FOCUS_ALL
			var tb := preload("res://scripts/ui/theme_builder.gd")
			var st := tb._box(Color("#e9eef7") if r == 0 else Color.WHITE, Color("#9aa5b4"), 1, 0, 6, 2)
			b.add_theme_stylebox_override("normal", st)
			b.add_theme_stylebox_override("hover", tb._box(Color("#fff3c4"), Palette.FRAME_DARK, 1, 0, 6, 2))
			b.add_theme_stylebox_override("pressed", st)
			for col in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				b.add_theme_color_override(col, Palette.TEXT)
			var ref: String = COLS[c] + str(r + 1)
			b.tooltip_text = "Célula " + ref
			b.pressed.connect(func(): _on_cell(ref))
			grid.add_child(b)
			cells[ref] = b
	place(sheet, Vector2(0.42, 0.34))


func _mark(ref: String, ok: bool) -> void:
	var b: Button = cells[ref]
	var tb := preload("res://scripts/ui/theme_builder.gd")
	b.add_theme_stylebox_override("normal", tb._box(Color("#d7f5df") if ok else Color("#fff3c4"), Palette.SUCCESS if ok else Palette.FOCUS, 2, 0, 6, 2))


# ---------------------------------------------------------------- 1. endereço da célula
func _step_cell() -> void:
	_step = "celula"
	_target_cell = "C3"
	_ask_cell()


func _ask_cell() -> void:
	var q := "Clique na célula %s (coluna %s, linha %s)." % [_target_cell, _target_cell[0], _target_cell.substr(1)] if guided else "Clique na célula %s." % _target_cell
	set_objective(q)
	say(q + " A letra é a coluna e o número é a linha.")
	set_step([q, "Ache a coluna %s lá em cima e desça até a linha %s." % [_target_cell[0], _target_cell.substr(1)], "Veja a mãozinha na célula."], [cells[_target_cell]])


func _on_cell(ref: String) -> void:
	if busy or _step != "celula":
		return
	if ref != _target_cell:
		try_again("Essa é a célula %s. Procure a coluna %s e a linha %s." % [ref, _target_cell[0], _target_cell.substr(1)])
		return
	_mark(ref, true)
	_cell_clicks += 1
	correct("Achou a %s!" % ref, "Localizou células pelo endereço (coluna e linha)")
	if not guided and _cell_clicks == 1:
		_target_cell = "B5"
		_ask_cell()
		return
	_step = "formula"
	_step_formula.call_deferred()


# ---------------------------------------------------------------- 2. fórmula e copiar
func _step_formula() -> void:
	set_objective("Calcular o total da pulseira (quantidade x preço) na célula D2.")
	_mark("D2", false)
	var right := "=B2*C2"
	var opts := [right, "=B2+C2"] if guided else ["B2*C2", "=B2+C2", right, "=10*3"]
	choice("Qual fórmula vai na célula D2 para calcular quantidade vezes preço?", opts, right,
		{"_dica": "Fórmula começa com = e o sinal de vezes na planilha é o asterisco *.",
			"=B2+C2": "Com + o computador soma (10 + 3 = 13). O total é quantidade VEZES preço.",
			"B2*C2": "Faltou o sinal de = no começo. Sem ele, a planilha acha que é só um texto.",
			"=10*3": "Dá 30, mas se a quantidade mudar o total fica errado. Use as células (B2 e C2)."},
		"Escreveu uma fórmula de multiplicação com referências", func():
			(cells["D2"] as Button).text = "30"
			_mark("D2", true)
			_step_copy())


func _step_copy() -> void:
	set_objective("Copiar a fórmula para os outros produtos.")
	clear_actions()
	var b := add_action("Copiar a fórmula para baixo", "next", func():
		clear_actions()
		var t := animate("m19_copiar")
		for r in [3, 4, 5]:
			var rr: int = r
			t.tween_callback(func():
				var q := int(ROWS[rr - 1][1])
				var p := int(ROWS[rr - 1][2])
				(cells["D%d" % rr] as Button).text = str(q * p)
				_mark("D%d" % rr, true)
				Sfx.play("select"))
			t.tween_interval(0.3)
		t.finished.connect(_copy_question), "success")
	set_step(["Clique em \"Copiar a fórmula para baixo\".", "Assim não precisa escrever a fórmula de novo em cada linha.", "Veja a mãozinha."], [b])
	say("Não precisa escrever tudo de novo: dá para copiar a fórmula para baixo!")


func _copy_question() -> void:
	if guided:
		_step_sum()
		return
	choice("Quando a fórmula =B2*C2 é copiada para a linha 3, ela vira:", ["=B2*C2", "=B3*C3", "=B3*C2"], "=B3*C3",
		{"_dica": "A planilha ajusta a linha sozinha ao copiar para baixo.",
			"=B2*C2": "Se ficasse igual, todas as linhas mostrariam o total da pulseira.",
			"=B3*C2": "As duas referências descem juntas: B3 e C3."},
		"Entendeu como a fórmula se ajusta ao ser copiada", _step_sum)


# ---------------------------------------------------------------- 3. SOMA
func _step_sum() -> void:
	set_objective("Somar todos os totais na célula D6.")
	_mark("D6", false)
	var right := "=SOMA(D2:D5)"
	var opts := [right, "=MÉDIA(D2:D5)"] if guided else ["=SOMA(D2;D5)", right, "=MÉDIA(D2:D5)", "=D2+D5"]
	choice("Qual fórmula soma os totais de D2 até D5?", opts, right,
		{"_dica": "Os dois-pontos (:) querem dizer \"de ... até ...\".",
			"=MÉDIA(D2:D5)": "MÉDIA calcula a média, não o total. Queremos somar tudo.",
			"=SOMA(D2;D5)": "Com ponto e vírgula, soma só D2 e D5, pulando D3 e D4. Use dois-pontos.",
			"=D2+D5": "Assim ficam de fora D3 e D4."},
		"Usou a função SOMA com um intervalo de células", func():
			(cells["D6"] as Button).text = "100"
			_mark("D6", true)
			_step_chart())


# ---------------------------------------------------------------- 4. gráfico
func _step_chart() -> void:
	set_objective("Escolher o gráfico para mostrar as vendas de cada produto.")
	var right := "Gráfico de colunas"
	var opts := [right, "Gráfico de linha"] if guided else ["Gráfico de linha", right, "Nenhum gráfico, só números"]
	choice("Para comparar quanto cada produto vendeu, qual gráfico é melhor?", opts, right,
		{"_dica": "Uma barra para cada produto deixa fácil comparar.",
			"Gráfico de linha": "O gráfico de linha mostra mudança ao longo do tempo (meses, dias). Aqui são produtos diferentes.",
			"Nenhum gráfico, só números": "O gráfico deixa a comparação muito mais fácil de ver na apresentação."},
		"Escolheu o tipo de gráfico adequado", _show_chart)


func _show_chart() -> void:
	sheet.visible = false
	chart = Control.new()
	chart.custom_minimum_size = Vector2(520, 260) * (Game.ui_scale() / 0.7)
	chart.z_index = 6
	var data := [["Pulseira", 30], ["Chaveiro", 20], ["Adesivo", 20], ["Livro", 30]]
	chart.draw.connect(func():
		var s := chart.size
		chart.draw_rect(Rect2(Vector2.ZERO, s), Color.WHITE)
		chart.draw_rect(Rect2(Vector2.ZERO, s), Palette.FRAME_DARK, false, 2)
		var f := Game.ui_font
		var fsz := Game.fs(20)
		chart.draw_string(f, Vector2(12, fsz + 6), "Vendas da feira (R$)", HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Palette.PRIMARY_DARK)
		var base := s.y - fsz - 14
		var bw := (s.x - 60) / data.size()
		for i in data.size():
			var h: float = (s.y - 90) * float(data[i][1]) / 30.0
			var r := Rect2(Vector2(30 + i * bw + bw * 0.15, base - h), Vector2(bw * 0.7, h))
			chart.draw_rect(r, Palette.PRIMARY if i % 2 == 0 else Palette.STAR)
			chart.draw_rect(r, Palette.FRAME_DARK, false, 2)
			chart.draw_string(f, r.position + Vector2(4, -4), str(data[i][1]), HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Palette.TEXT)
			chart.draw_string(f, Vector2(r.position.x, s.y - 8), data[i][0], HORIZONTAL_ALIGNMENT_LEFT, bw, fsz, Palette.TEXT))
	place(chart, Vector2(0.42, 0.34))
	Sfx.play("ok")
	complete("Contas feitas e gráfico pronto para a apresentação da tesouraria!")


func explorer_quiz() -> Array:
	return [
		{"q": "Toda fórmula na planilha começa com:",
			"options": ["#", "=", "?"], "answer": 1,
			"explain": "Sem ele, a planilha acha que é texto.",
			"skill": "Sabe que fórmulas começam com ="},
		{"q": "O que é a célula B5?",
			"options": ["Coluna B, linha 5", "Linha B, coluna 5", "A quinta planilha"], "answer": 0,
			"explain": "Letra = coluna; número = linha.",
			"skill": "Leu o endereço de uma célula"},
	]
