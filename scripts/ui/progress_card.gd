class_name ProgressCard
extends Control
## Cartão do relatório de progresso do jogador (vira uma imagem PNG para enviar ao professor).
## Tamanho fixo 1080 x 1350, desenhado por código para ficar nítido.

const W := 1080.0
const H := 1350.0

var generated_at := ""


func _init() -> void:
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var d := Time.get_datetime_dict_from_system()
	generated_at = "%02d/%02d/%04d às %02d:%02d" % [d.day, d.month, d.year, d.hour, d.minute]


func _txt(s: String, pos: Vector2, size_px: int, col: Color = Palette.TEXT, width: float = -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(Game.ui_font, pos, s, align, width, size_px, col)


func _stars(c: Vector2, n: int, r: float = 11.0) -> void:
	for i in 3:
		var p := c + Vector2(i * r * 2.3, 0)
		if i < n:
			draw_colored_polygon(Icons.star_points(p, r), Palette.STAR)
		Icons.draw(self, "star_empty", p, r, Palette.STAR_DARK)


func _draw() -> void:
	# fundo e moldura
	draw_rect(Rect2(Vector2.ZERO, size), Palette.FRAME_DARK)
	var page := Rect2(Vector2(24, 24), size - Vector2(48, 48))
	draw_rect(page, Palette.CREAM)
	# faixa de título
	draw_rect(Rect2(page.position, Vector2(page.size.x, 96)), Palette.PRIMARY_DARK)
	_txt("RELATÓRIO DE PROGRESSO", page.position + Vector2(28, 48), 46, Color.WHITE)
	_txt("Escola Conectada: Missão Rede", page.position + Vector2(30, 84), 30, Palette.STAR)
	Sprites.draw(self, "bit_caixa_feliz", page.position + Vector2(page.size.x - 76, 8), 3)

	# jogador
	var y := page.position.y + 120
	draw_rect(Rect2(Vector2(page.position.x + 24, y), Vector2(150, 150)), Color("#fff3c4"))
	draw_rect(Rect2(Vector2(page.position.x + 24, y), Vector2(150, 150)), Palette.FRAME_DARK, false, 3)
	Sprites.draw(self, "avatar_%d_baixo_parado_0" % Game.avatar, Vector2(page.position.x + 35, y + 11), 8)
	var x := page.position.x + 200
	_txt(Game.student_name, Vector2(x, y + 46), 52, Palette.PRIMARY_DARK)
	_txt("Modo: %s" % ("Guiado" if Game.is_guided() else "Explorador"), Vector2(x, y + 86), 28)
	_txt("Gerado em: %s" % generated_at, Vector2(x, y + 120), 28, Palette.TEXT_SOFT)
	# resumo (3 caixas)
	y += 172
	var boxes := [["Missões", "%d de %d" % [Game.completed.size(), Game.MISSIONS.size()]],
		["Pontos", str(Game.total_points())],
		["Estrelas", "%d de %d" % [Game.total_stars(), Game.MISSIONS.size() * 3]]]
	var bw := (page.size.x - 48 - 2 * 16) / 3.0
	for i in 3:
		var r := Rect2(Vector2(page.position.x + 24 + i * (bw + 16), y), Vector2(bw, 92))
		draw_rect(r, Color.WHITE)
		draw_rect(r, Palette.FRAME_DARK, false, 3)
		_txt(boxes[i][0], r.position + Vector2(0, 32), 26, Palette.TEXT_SOFT, bw, HORIZONTAL_ALIGNMENT_CENTER)
		_txt(boxes[i][1], r.position + Vector2(0, 76), 42, Palette.PRIMARY_DARK, bw, HORIZONTAL_ALIGNMENT_CENTER)

	# tabela das missões
	y += 120
	var cols := [[24, "#"], [70, "Missão"], [520, "Situação"], [680, "Estrelas"], [790, "Pontos"], [880, "Tent."], [950, "Dicas"]]
	draw_rect(Rect2(Vector2(page.position.x + 16, y), Vector2(page.size.x - 32, 40)), Palette.FRAME)
	for c in cols:
		_txt(c[1], Vector2(page.position.x + c[0], y + 29), 26, Color.WHITE)
	y += 40
	var row_h := 50.0
	for m in Game.MISSIONS:
		var id: int = m.id
		var e: Dictionary = Game.report.get(str(id), {})
		var bg := Color.WHITE if id % 2 == 1 else Color("#f1eee2")
		draw_rect(Rect2(Vector2(page.position.x + 16, y), Vector2(page.size.x - 32, row_h)), bg)
		var status := "Concluída" if Game.is_completed(id) else ("Em andamento" if not e.is_empty() else "Não iniciada")
		var st_col := Palette.SUCCESS if Game.is_completed(id) else (Palette.ATTENTION if not e.is_empty() else Palette.TEXT_SOFT)
		var base := Vector2(page.position.x, y + 34)
		_txt(str(id), base + Vector2(cols[0][0], 0), 28)
		_txt(m.title, base + Vector2(cols[1][0], 0), 26, Palette.TEXT, 440)
		_txt(status, base + Vector2(cols[2][0], 0), 26, st_col)
		_stars(base + Vector2(cols[3][0] + 12, -9), Game.mission_stars(id), 10)
		_txt(str(Game.mission_points(id)) if Game.is_completed(id) else "—", base + Vector2(cols[4][0], 0), 28)
		var dicas := 0
		for v in e.get("dicas", [0, 0, 0]):
			dicas += int(v)
		_txt(str(int(e.get("tentativas", 0))) if not e.is_empty() else "—", base + Vector2(cols[5][0], 0), 28)
		_txt(str(dicas) if not e.is_empty() else "—", base + Vector2(cols[6][0], 0), 28)
		y += row_h
	draw_rect(Rect2(Vector2(page.position.x + 16, y - row_h * Game.MISSIONS.size() - 40), Vector2(page.size.x - 32, row_h * Game.MISSIONS.size() + 40)), Palette.FRAME_DARK, false, 2)

	# habilidades demonstradas
	y += 26
	_txt("Habilidades demonstradas", Vector2(page.position.x + 24, y + 24), 32, Palette.PRIMARY_DARK)
	y += 40
	var skills: Array = []
	for m in Game.MISSIONS:
		for h in Game.report.get(str(m.id), {}).get("habilidades", []):
			if not str(h).begins_with("Desafio extra"):
				skills.append("M%d · %s" % [m.id, h])
	if skills.is_empty():
		_txt("Ainda nenhuma. Jogue a primeira missão!", Vector2(page.position.x + 24, y + 26), 26, Palette.TEXT_SOFT)
	var max_lines := int((page.end.y - 70 - y) / 30.0) * 2
	for i in mini(skills.size(), max_lines):
		var colx := page.position.x + 24 + (i % 2) * (page.size.x - 48) / 2.0
		_txt("• " + skills[i], Vector2(colx, y + 26 + (i / 2) * 30), 22, Palette.TEXT, (page.size.x - 60) / 2.0)
	if skills.size() > max_lines:
		_txt("... e mais %d" % (skills.size() - max_lines), Vector2(page.position.x + 24, page.end.y - 56), 22, Palette.TEXT_SOFT)
	# rodapé
	_txt("Este relatório mostra apenas o que foi feito no jogo. Não contém diagnóstico nem classificação do estudante.",
		Vector2(page.position.x + 24, page.end.y - 18), 20, Palette.TEXT_SOFT, page.size.x - 48)


## Gera a imagem PNG do cartão (renderiza fora da tela).
static func render_png(host: Node) -> PackedByteArray:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(W), int(H))
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	host.add_child(vp)
	var card := ProgressCard.new()
	vp.add_child(card)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img.save_png_to_buffer()
