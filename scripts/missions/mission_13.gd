extends MissionBase
## Temporada 2, nível 3 — Arquivos no lugar (Secretaria Digital)
## Pastas, extensões de arquivo, caminho do arquivo, nomes claros e arquivo suspeito.

const FILES_BASIC := [["relatorio.docx", "Documentos"], ["foto_feira.jpg", "Imagens"], ["hino_escola.mp3", "Músicas"], ["video_robo.mp4", "Vídeos"]]
const FILES_EXTRA := [["notas.xlsx", "Documentos"], ["logo.png", "Imagens"], ["premio.jpg.exe", "Lixeira"]]

var explorer_win: PanelContainer
var file_buttons: Array = []
var folder_buttons := {}
var counts := {}
var selected: Button = null
var _left := 0


## Botão de arquivo: ícone pelo tipo (extensão) + nome completo.
class FileButton extends Button:
	var file := ""
	var folder := ""

	func _init(p_file: String, p_folder: String) -> void:
		file = p_file
		folder = p_folder
		text = p_file
		custom_minimum_size = Vector2(150, 70) * (Game.ui_scale() / 0.7)
		vertical_icon_alignment = VERTICAL_ALIGNMENT_BOTTOM
		alignment = HORIZONTAL_ALIGNMENT_CENTER
		focus_mode = Control.FOCUS_ALL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var tb := preload("res://scripts/ui/theme_builder.gd")
		add_theme_stylebox_override("normal", tb.button_box(Color.WHITE, Palette.FRAME_DARK))
		add_theme_stylebox_override("hover", tb.button_box(Color("#fff3c4"), Palette.FRAME_DARK))
		var st := tb.button_box(Color.WHITE, Palette.FRAME_DARK)
		st.content_margin_top = 30
		add_theme_stylebox_override("normal", st)
		var sth := tb.button_box(Color("#fff3c4"), Palette.FRAME_DARK)
		sth.content_margin_top = 30
		add_theme_stylebox_override("hover", sth)
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			add_theme_color_override(c, Palette.TEXT)
		add_theme_font_size_override("font_size", Game.fs(19))

	func kind() -> String:
		var ext := file.get_extension()
		match ext:
			"docx", "txt": return "doc"
			"xlsx": return "sheet"
			"jpg", "png": return "img"
			"mp3": return "audio"
			"mp4": return "video"
		return "exe"

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, 18)
		match kind():
			"doc":
				draw_rect(Rect2(c - Vector2(9, 12), Vector2(18, 22)), Color.WHITE)
				draw_rect(Rect2(c - Vector2(9, 12), Vector2(18, 22)), Palette.PRIMARY, false, 2)
				for i in 3:
					draw_line(c + Vector2(-5, -5 + i * 5), c + Vector2(5, -5 + i * 5), Palette.PRIMARY, 2)
			"sheet":
				draw_rect(Rect2(c - Vector2(10, 11), Vector2(20, 20)), Color("#2fb86a"))
				for i in 3:
					draw_line(c + Vector2(-10, -4 + i * 6), c + Vector2(10, -4 + i * 6), Color.WHITE, 1)
				draw_line(c + Vector2(0, -11), c + Vector2(0, 9), Color.WHITE, 1)
			"img":
				draw_rect(Rect2(c - Vector2(11, 10), Vector2(22, 18)), Color("#8cd6f4"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 8), c + Vector2(-2, -3), c + Vector2(5, 8)]), Color("#2fb86a"))
				draw_circle(c + Vector2(6, -4), 3, Palette.STAR)
			"audio":
				draw_line(c + Vector2(3, -11), c + Vector2(3, 5), Palette.TEXT, 3)
				draw_line(c + Vector2(3, -11), c + Vector2(10, -8), Palette.TEXT, 3)
				draw_circle(c + Vector2(-1, 6), 5, Palette.TEXT)
			"video":
				draw_rect(Rect2(c - Vector2(11, 9), Vector2(22, 18)), Palette.FRAME_DARK)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -5), c + Vector2(6, 0), c + Vector2(-4, 5)]), Color.WHITE)
			_:
				Icons.draw(self, "gear", c, 11, Palette.ATTENTION)
		if has_focus():
			draw_rect(Rect2(Vector2.ZERO, size), Palette.FOCUS, false, 3)


func setup() -> void:
	place_icon = "report"
	floor_tile = "piso_madeira"
	wall_items = [["janela", 0.3], ["cartaz_rede", 0.42], ["relogio", 0.52], ["quadro", 0.68], ["janela", 0.86]]
	floor_items = [["arquivo", Vector2(0.975, 0.5)], ["planta", Vector2(0.03, 0.9)], ["pc_on", Vector2(0.08, 0.2)]]
	set_objective("Organizar os arquivos da área de trabalho em pastas.")
	story("A área de trabalho da secretaria está uma bagunça! Cada tipo de arquivo tem sua pasta. A pista é o final do nome: a EXTENSÃO.", _build_explorer)


func _build_explorer() -> void:
	var win := UiWindow.create("Explorador de arquivos  —  C:\\Usuários\\Secretaria", 760.0 * Game.ui_scale() / 0.7)
	explorer_win = win.root
	place(explorer_win, Vector2(0.43, 0.42))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	win.body.add_child(row)
	var folders := VBoxContainer.new()
	row.add_child(folders)
	var names := ["Documentos", "Imagens", "Músicas", "Vídeos"]
	if not guided:
		names.append("Lixeira")
	for n in names:
		var b := BigButton.new(n, "save" if n != "Lixeira" else "cross", "star" if n != "Lixeira" else "secondary", 58)
		b.custom_minimum_size.x = 210
		var folder: String = n
		b.pressed.connect(func(): _on_folder(folder))
		folders.add_child(b)
		folder_buttons[n] = b
		counts[n] = 0
	var desk := VBoxContainer.new()
	desk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(desk)
	var hl := Label.new()
	hl.text = "Área de trabalho"
	hl.add_theme_color_override("font_color", Palette.TEXT_SOFT)
	desk.add_child(hl)
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	desk.add_child(grid)
	var files: Array = FILES_BASIC.duplicate()
	if not guided:
		files.append_array(FILES_EXTRA)
	for f in files:
		var fb := FileButton.new(f[0], f[1])
		fb.pressed.connect(func(): _on_file(fb))
		grid.add_child(fb)
		file_buttons.append(fb)
	_left = files.size()
	_next_hint()


func _next_hint() -> void:
	for fb in file_buttons:
		if is_instance_valid(fb) and fb.visible:
			set_step([
				"Clique em um arquivo e depois na pasta dele. Olhe a extensão: .docx, .jpg, .mp3, .mp4...",
				"O arquivo %s vai para a pasta %s." % [fb.file, fb.folder] if fb.folder != "Lixeira" else "Desconfie de um arquivo com duas extensões.",
				"Veja a mãozinha: arquivo e depois pasta.",
			], [fb, folder_buttons[fb.folder]])
			if guided:
				highlight([fb])
			return


func _on_file(fb: Button) -> void:
	if busy:
		return
	if selected:
		selected.modulate = Color.WHITE
	selected = fb
	fb.modulate = Color(1, 0.85, 0.5)
	Sfx.play("select")
	say("Arquivo %s selecionado. Em qual pasta ele fica?" % fb.file)
	if guided:
		highlight([folder_buttons[fb.folder]])


func _on_folder(folder: String) -> void:
	if busy:
		return
	if selected == null:
		say("Primeiro clique em um arquivo.", "pensando")
		Sfx.play("retry")
		return
	var fb: FileButton = selected
	if fb.folder != folder:
		var tip := _tip(fb)
		try_again(tip)
		return
	fb.visible = false
	selected = null
	counts[folder] += 1
	(folder_buttons[folder] as BigButton).text = "%s (%d)" % [folder, counts[folder]]
	_left -= 1
	if folder == "Lixeira":
		correct("Arquivo perigoso descartado!", "Reconheceu um arquivo executável disfarçado (.jpg.exe)")
	else:
		correct("Na pasta certa!", "Organizou arquivo pela extensão (.%s)" % fb.file.get_extension())
	if _left == 0:
		explorer_win.visible = false
		_path_question.call_deferred()
	else:
		_next_hint()


func _tip(fb: FileButton) -> String:
	match fb.kind():
		"doc", "sheet": return "%s é um documento (.%s). Vai em Documentos." % [fb.file, fb.file.get_extension()] if guided else "A extensão .%s é de documento ou planilha." % fb.file.get_extension()
		"img": return "%s é uma imagem (.%s). Vai em Imagens." % [fb.file, fb.file.get_extension()] if guided else "A extensão .%s é de imagem." % fb.file.get_extension()
		"audio": return "%s é um áudio (.mp3). Vai em Músicas." % fb.file if guided else "A extensão .mp3 é de áudio."
		"video": return "%s é um vídeo (.mp4). Vai em Vídeos." % fb.file if guided else "A extensão .mp4 é de vídeo."
	return "Cuidado! O nome termina em .exe: é um PROGRAMA disfarçado de foto. Pode ser vírus: vai para a Lixeira."


func _path_question() -> void:
	set_objective("Achar o caminho de um arquivo e dar um nome claro.")
	var right := "C:\\Usuários\\Secretaria\\Imagens\\foto_feira.jpg"
	var opts := [right, "C:\\Usuários\\Secretaria\\Músicas\\foto_feira.jpg"] if guided else ["foto_feira.jpg\\Imagens\\C:", right, "C:\\Usuários\\Secretaria\\Músicas\\foto_feira.jpg"]
	choice("Onde está a foto_feira.jpg agora? Qual é o CAMINHO dela?", opts, right,
		{"_dica": "O caminho vai do disco (C:) até a pasta e termina no nome do arquivo.",
			"C:\\Usuários\\Secretaria\\Músicas\\foto_feira.jpg": "A foto foi para Imagens, não para Músicas.",
			"foto_feira.jpg\\Imagens\\C:": "O caminho começa pelo disco (C:) e termina no arquivo. Aqui está invertido."},
		"Escreveu o caminho completo de um arquivo", _rename)


func _rename() -> void:
	var right := "relatorio_feira_2026.docx"
	var opts := [right, "asdfgh.docx"] if guided else ["relatório final final 2 (1).docx", "asdfgh.docx", right, "relatorio_feira_2026"]
	choice("Qual é o melhor nome para o relatório da feira?", opts, right,
		{"_dica": "Um bom nome diz o que é, tem a data e mantém a extensão.",
			"asdfgh.docx": "Ninguém vai saber o que é esse arquivo pelo nome.",
			"relatório final final 2 (1).docx": "Confuso: qual é a versão certa? Use um nome claro com data.",
			"relatorio_feira_2026": "Sem a extensão .docx, o computador não sabe com qual programa abrir."},
		"Escolheu um nome de arquivo claro, com data e extensão",
		func(): complete("Tudo organizado! Agora qualquer pessoa acha os arquivos da secretaria."))


func explorer_quiz() -> Array:
	return [
		{"q": "O que a extensão do arquivo (.jpg, .mp3...) indica?",
			"options": ["O tamanho do arquivo", "O tipo do arquivo", "A data de criação"], "answer": 1,
			"explain": "Foi assim que você soube em qual pasta colocar cada um.",
			"skill": "Explicou o que é a extensão de arquivo"},
		{"q": "Um arquivo chamado \"jogo_gratis.pdf.exe\" é:",
			"options": ["Um PDF normal", "Um programa disfarçado, pode ser vírus", "Uma foto"], "answer": 1,
			"explain": "O que vale é a ÚLTIMA extensão.",
			"skill": "Identificou arquivo executável disfarçado"},
	]
