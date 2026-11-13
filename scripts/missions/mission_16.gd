extends MissionBase
## Temporada 2, nível 6 — Programe o robô (Sala de Robótica)
## Lógica de programação: sequência de comandos, depuração e repetição.

const DIRS := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]   # direita, baixo, esquerda, cima

var grid: RobotGrid
var program: Array = []
var prog_label: Label
var prog_win: PanelContainer
var puzzles: Array = []
var current := 0
var _running := false


## Grade com o robô (Bit), paredes e a bateria (objetivo).
class RobotGrid extends Control:
	var cols := 7
	var rows := 4
	var walls: Array = []
	var goal := Vector2i(4, 1)
	var robot := Vector2i(0, 1)
	var dir := 0
	var cell := 56.0
	var trail: Array = []

	func _init() -> void:
		cell = round(56.0 * Game.ui_scale() / 0.7)
		custom_minimum_size = Vector2(cols, rows) * cell + Vector2(8, 8)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 6

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.FRAME_DARK)
		for y in rows:
			for x in cols:
				var r := Rect2(Vector2(4, 4) + Vector2(x, y) * cell, Vector2(cell, cell)).grow(-1)
				draw_rect(r, Color("#e8ecf6") if (x + y) % 2 == 0 else Color("#d4dbea"))
		for p in trail:
			draw_circle(Vector2(4, 4) + (Vector2(p) + Vector2(0.5, 0.5)) * cell, cell * 0.1, Palette.FOCUS)
		for w in walls:
			var r := Rect2(Vector2(4, 4) + Vector2(w) * cell, Vector2(cell, cell)).grow(-2)
			draw_rect(r, Color("#94604f"))
			draw_rect(r, Palette.FRAME_DARK, false, 2)
			for i in 3:
				draw_line(r.position + Vector2(0, r.size.y * (i + 1) / 4.0), r.position + Vector2(r.size.x, r.size.y * (i + 1) / 4.0), Palette.FRAME_DARK, 1)
		# bateria (objetivo)
		var g := Vector2(4, 4) + (Vector2(goal) + Vector2(0.5, 0.5)) * cell
		draw_rect(Rect2(g - Vector2(cell * 0.18, cell * 0.28), Vector2(cell * 0.36, cell * 0.56)), Palette.LED_ON)
		draw_rect(Rect2(g - Vector2(cell * 0.18, cell * 0.28), Vector2(cell * 0.36, cell * 0.56)), Palette.FRAME_DARK, false, 2)
		draw_rect(Rect2(g - Vector2(cell * 0.08, cell * 0.36), Vector2(cell * 0.16, cell * 0.08)), Palette.FRAME_DARK)
		Icons.draw(self, "plus", g, cell * 0.12, Color.WHITE)
		# robô + seta da direção
		var c := Vector2(4, 4) + (Vector2(robot) + Vector2(0.5, 0.5)) * cell
		Sprites.draw_centered(self, "bit", c, 3)
		var d := Vector2(DIRS_F[dir])
		var tip := c + d * cell * 0.46
		var side := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([tip, tip - d * 12 + side * 8, tip - d * 12 - side * 8]), Palette.FOCUS)

	const DIRS_F := [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]


func setup() -> void:
	place_icon = "play"
	floor_tile = "piso_frio"
	wall_items = [["quadro", 0.3], ["relogio", 0.42], ["cartaz_rede", 0.6], ["janela", 0.86]]
	floor_items = [["armario", Vector2(0.975, 0.2)]]
	set_objective("Programar o robô para chegar até a bateria.")
	puzzles = [
		{"start": Vector2i(0, 1), "dir": 0, "goal": Vector2i(4, 1), "walls": [], "limit": 0, "loop": false,
			"text": "Fase 1: o robô precisa andar até a bateria."},
		{"start": Vector2i(0, 0), "dir": 0, "goal": Vector2i(3, 2), "walls": [] if guided else [Vector2i(1, 1), Vector2i(2, 1), Vector2i(4, 0)], "limit": 0, "loop": false,
			"text": "Fase 2: agora tem uma curva. Use \"Virar\"."},
		{"start": Vector2i(0, 3), "dir": 3, "goal": Vector2i(3, 0) if guided else Vector2i(6, 0), "walls": [], "limit": 3 if guided else 4, "loop": true,
			"text": "Fase 3: caminho longo e poucos blocos! Use \"Repetir 3 vezes: Andar\"."},
	]
	grid = RobotGrid.new()
	place(grid, Vector2(0.36, 0.36))
	prog_win = info_window("Programa", ["(vazio)"], Vector2(0.82, 0.22), 300.0)
	prog_label = (prog_win.get_meta("body") as VBoxContainer).get_child(0)
	story("A escola ganhou um robô para a feira! Ele só faz o que mandamos, um comando de cada vez, na ordem certa. Isso é programar!", func(): _load(0))


func _load(i: int) -> void:
	current = i
	var p: Dictionary = puzzles[i]
	grid.robot = p.start
	grid.dir = p.dir
	grid.goal = p.goal
	grid.walls = p.walls
	grid.trail = []
	grid.queue_redraw()
	program.clear()
	_refresh_program()
	set_objective(p.text)
	_build_buttons()
	say(p.text + (" Você só pode usar %d blocos." % p.limit if p.limit > 0 else ""))


func _build_buttons() -> void:
	clear_actions()
	var p: Dictionary = puzzles[current]
	var first := add_action("Andar", "next", func(): _add("Andar"))
	add_action("Virar à direita", "retry", func(): _add("Virar à direita"))
	add_action("Virar à esquerda", "back", func(): _add("Virar à esquerda"))
	var loop_b: BigButton = null
	if p.loop:
		loop_b = add_action("Repetir 3 vezes: Andar", "skip", func(): _add("Repetir 3 vezes: Andar"), "star")
	add_action("Apagar último", "minus", func():
		if not program.is_empty():
			program.pop_back()
			_refresh_program(), "secondary")
	var run := add_action("Executar", "play", _run, "success")
	set_step([
		"Monte o programa clicando nos comandos, na ordem. Depois clique em Executar.",
		"Conte quantos quadrados o robô precisa andar e para onde ele precisa virar." if not p.loop else "Um bloco \"Repetir 3 vezes: Andar\" anda 3 quadrados de uma vez.",
		"Veja a mãozinha no primeiro comando.",
	], [loop_b if loop_b else first, run])


func _add(cmd: String) -> void:
	var p: Dictionary = puzzles[current]
	if p.limit > 0 and program.size() >= p.limit:
		say("Limite de %d blocos! Use o bloco de repetição para economizar." % p.limit, "pensando")
		Sfx.play("retry")
		return
	program.append(cmd)
	Sfx.play("click")
	_refresh_program()


func _refresh_program() -> void:
	if program.is_empty():
		prog_label.text = "(vazio) — clique nos comandos"
		return
	var lines: PackedStringArray = []
	for i in program.size():
		lines.append("%d. %s" % [i + 1, program[i]])
	var p: Dictionary = puzzles[current]
	if p.limit > 0:
		lines.append("Blocos: %d de %d" % [program.size(), p.limit])
	prog_label.text = "\n".join(lines)


func _expanded() -> Array:
	var out: Array = []
	for c in program:
		if c == "Repetir 3 vezes: Andar":
			out.append_array(["Andar", "Andar", "Andar"])
		else:
			out.append(c)
	return out


func _run() -> void:
	if _running:
		return
	if program.is_empty():
		say("O programa está vazio. Clique nos comandos primeiro.", "pensando")
		return
	_running = true
	var p: Dictionary = puzzles[current]
	grid.robot = p.start
	grid.dir = p.dir
	grid.trail = [p.start]
	var steps := _expanded()
	var t := animate("m16_robo_%d" % current)
	var sim_pos: Vector2i = p.start
	var sim_dir: int = p.dir
	var crash := -1
	for i in steps.size():
		var cmd: String = steps[i]
		if cmd == "Andar":
			var nxt: Vector2i = sim_pos + DIRS[sim_dir]
			if nxt.x < 0 or nxt.y < 0 or nxt.x >= grid.cols or nxt.y >= grid.rows or grid.walls.has(nxt):
				crash = i
				break
			sim_pos = nxt
		elif cmd == "Virar à direita":
			sim_dir = (sim_dir + 1) % 4
		else:
			sim_dir = (sim_dir + 3) % 4
		var pos_now := sim_pos
		var dir_now := sim_dir
		t.tween_callback(func():
			grid.robot = pos_now
			grid.dir = dir_now
			if not grid.trail.has(pos_now):
				grid.trail.append(pos_now)
			grid.queue_redraw()
			Sfx.play("select"))
		t.tween_interval(0.35)
	t.finished.connect(func():
		_running = false
		if crash >= 0:
			try_again("Opa! O robô ia bater na parede ou sair da grade no passo %d. Corrija o programa (use \"Apagar último\") e tente de novo." % (crash + 1))
			_reset_robot()
		elif sim_pos != grid.goal:
			try_again("O robô parou longe da bateria. Confira quantos passos faltam e para onde virar.")
			_reset_robot()
		else:
			_solved())


func _reset_robot() -> void:
	var p: Dictionary = puzzles[current]
	grid.robot = p.start
	grid.dir = p.dir
	grid.trail = []
	grid.queue_redraw()


func _solved() -> void:
	var skills := ["Programou uma sequência de comandos", "Usou comandos de virar para fazer curvas", "Usou repetição para economizar comandos"]
	correct("O robô chegou!", skills[current])
	if current + 1 < puzzles.size():
		_load.call_deferred(current + 1)
	else:
		clear_actions()
		complete("Você programou o robô com sequência e repetição. Já é um programador!")


func explorer_quiz() -> Array:
	return [
		{"q": "O que é um algoritmo?",
			"options": ["Uma sequência de passos para resolver algo", "Um tipo de robô", "Uma peça do computador"], "answer": 0,
			"explain": "Foi o que você montou para o robô.",
			"skill": "Explicou o que é algoritmo"},
		{"q": "Para que serve o bloco de repetição?",
			"options": ["Para apagar o programa", "Para fazer o mesmo comando várias vezes com um bloco só", "Para desligar o robô"], "answer": 1,
			"explain": "Lembre da fase 3, com poucos blocos.",
			"skill": "Explicou a função da repetição (laço)"},
	]
