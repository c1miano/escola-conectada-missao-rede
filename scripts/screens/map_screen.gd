extends ScreenBase
## Mapa da escola visto de cima (pixel art 16x16). O técnico anda pelo corredor até a sala.
## Clique na placa de uma sala (ou use Tab + Enter) e ele vai sozinho.
## Também dá para andar com as setas / WASD e entrar pela porta (seta para cima ou para baixo).

const COLS := 24
const ROWS := 12
const T := 16 * Sprites.SCALE      # tamanho do tile na tela
const SPEED := 300.0

## Salas por andar: id, retângulo (em tiles), piso, se a porta fica em cima do corredor ou embaixo.
## id 0 = Pátio da Feira (térreo); id -1 = Escada (andar de cima).
const FLOOR_NAMES := ["Térreo", "Andar de cima"]
const ROOMS_1 := [
	{"id": 6, "rect": Rect2i(0, 0, 8, 5), "floor": "piso_madeira", "top": true},
	{"id": 7, "rect": Rect2i(8, 0, 8, 5), "floor": "piso_frio", "top": true},
	{"id": 8, "rect": Rect2i(16, 0, 8, 5), "floor": "piso_madeira", "top": true},
	{"id": 9, "rect": Rect2i(0, 7, 8, 5), "floor": "piso_frio", "top": false},
	{"id": 10, "rect": Rect2i(8, 7, 8, 5), "floor": "piso_tijolo", "top": false},
	{"id": -1, "rect": Rect2i(16, 7, 8, 5), "floor": "piso_corredor", "top": false},
]
const ROOMS := [
	{"id": 1, "rect": Rect2i(0, 0, 8, 5), "floor": "piso_tijolo", "top": true},
	{"id": 2, "rect": Rect2i(8, 0, 8, 5), "floor": "piso_madeira", "top": true},
	{"id": 3, "rect": Rect2i(16, 0, 8, 5), "floor": "piso_madeira", "top": true},
	{"id": 4, "rect": Rect2i(0, 7, 8, 5), "floor": "piso_frio", "top": false},
	{"id": 5, "rect": Rect2i(8, 7, 8, 5), "floor": "piso_tijolo", "top": false},
	{"id": 0, "rect": Rect2i(16, 7, 8, 5), "floor": "piso_madeira", "top": false},  # pátio da feira
]
const FURNITURE := {
	1: [["pc_on", Vector2(1.2, 2.2)], ["pc_on", Vector2(4.2, 2.2)], ["armario", Vector2(7.0, 1.6)]],
	2: [["pc_on", Vector2(1.0, 2.2)], ["arquivo", Vector2(6.8, 2.0)], ["planta", Vector2(5.6, 2.6)]],
	3: [["estante", Vector2(0.2, 1.7)], ["estante", Vector2(1.2, 1.7)], ["pc_on", Vector2(5.4, 2.3)]],
	4: [["rack", Vector2(0.3, 2.5)], ["rack", Vector2(1.3, 2.5)], ["servidor_on", Vector2(5.6, 2.9)]],
	5: [["lampada_on", Vector2(0.6, 2.9)], ["sensor_temp", Vector2(5.4, 2.9)], ["ap_on", Vector2(3.0, 3.1)]],
	0: [["mesa", Vector2(1.0, 3.2)], ["mesa", Vector2(5.0, 3.2)], ["planta", Vector2(3.4, 3.0)]],
	6: [["pc_on", Vector2(0.8, 2.2)], ["roteador_on", Vector2(4.6, 2.2)], ["planta", Vector2(7.0, 2.6)]],
	7: [["testador", Vector2(1.0, 2.2)], ["mesa", Vector2(4.4, 3.0)], ["armario", Vector2(7.0, 1.6)]],
	8: [["pc_on", Vector2(1.0, 2.2)], ["firewall_on", Vector2(4.6, 2.0)], ["arquivo", Vector2(6.9, 2.0)]],
	9: [["rack", Vector2(0.3, 2.5)], ["rack", Vector2(1.3, 2.5)], ["rack", Vector2(2.3, 2.5)], ["roteador_on", Vector2(5.4, 2.9)]],
	10: [["palanque", Vector2(3.4, 2.4)], ["cadeira", Vector2(1.2, 3.6)], ["cadeira", Vector2(5.6, 3.6)], ["painel_on", Vector2(5.8, 2.2)]],
	-1: [["planta", Vector2(0.4, 3.0)], ["planta", Vector2(6.8, 3.0)]],
}
const WALL_DECOR := {
	1: [["quadro", 3.5], ["relogio", 6.2]], 2: [["janela", 2.0], ["cartaz_rede", 5.0]],
	3: [["janela", 4.0], ["cartaz_wifi", 6.5]], 4: [["cartaz_rede", 5.0], ["extintor", 7.4]],
	5: [["quadro", 5.0], ["cartaz_wifi", 2.0]], 0: [["janela", 1.5], ["janela", 6.0]],
	6: [["quadro", 3.0], ["relogio", 6.0]], 7: [["cartaz_rede", 2.0], ["extintor", 7.4]],
	8: [["janela", 2.0], ["cartaz_wifi", 6.0]], 9: [["cartaz_rede", 5.0], ["relogio", 6.5]],
	10: [["faixa", 4.0]], -1: [["janela", 2.0], ["janela", 6.0]],
}

var map: Control
var bubble: Label
var bit: BitSpeaker
var andar := -1                     # andar mostrado (-1 = escolher pelo progresso)
var signs := {}
var player_pos := Vector2.ZERO      # em pixels, relativo à origem do mapa (pés do personagem)
var facing := "baixo"
var _walk_t := 0.0
var _idle_t := 0.0
var _moving := false
var _route: Array = []              # pontos para andar sozinho
var _route_target := 0


func configure(params: Dictionary) -> void:
	andar = int(params.get("andar", -1))


func _rooms() -> Array:
	return ROOMS if andar == 0 else ROOMS_1


func _room(id: int) -> Dictionary:
	for r in _rooms():
		if r.id == id:
			return r
	return {}


func build() -> void:
	if andar < 0:
		andar = int(Game.mission_info(Game.next_mission()).get("andar", 0))
		if not Game.floor_unlocked(andar):
			andar = 0
	background(Palette.FRAME_DARK)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	_top_bar(root)

	map = Control.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.draw.connect(_draw_map)
	map.resized.connect(_layout)
	map.clip_contents = true
	root.add_child(map)
	for r in _rooms():
		if r.id <= 0:
			continue
		var sign := RoomSign.new(Game.mission_info(r.id))
		var id: int = r.id
		sign.pressed.connect(func(): _go_to_room(id))
		map.add_child(sign)
		signs[id] = sign

	# Bit e balão sobre o pátio (canto inferior direito)
	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.position = Vector2(-24, -24)
	add_child(bottom)
	bottom.alignment = BoxContainer.ALIGNMENT_END
	var bp := PanelContainer.new()
	bp.custom_minimum_size = Vector2(250, 0)
	bp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(bp)
	bubble = Label.new()
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_theme_font_size_override("font_size", Game.fs(19))
	bp.add_child(bubble)
	bit = BitSpeaker.new()
	bottom.add_child(bit)
	_greet()
	_focus_next_room.call_deferred()
	set_process(true)


func _top_bar(root: VBoxContainer) -> void:
	var top := PanelContainer.new()
	root.add_child(top)
	var row := HBoxContainer.new()
	top.add_child(row)
	row.add_child(AvatarView.new(Game.avatar, 3))
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", -4)
	row.add_child(who)
	var t := Label.new()
	t.text = Game.student_name
	t.add_theme_font_size_override("font_size", Game.fs(24))
	t.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	who.add_child(t)
	var count := Label.new()
	count.text = "%d de %d missões" % [Game.completed.size(), Game.MISSIONS.size()]
	count.add_theme_color_override("font_color", Palette.TEXT_SOFT)
	who.add_child(count)
	var score := Control.new()
	score.custom_minimum_size = Vector2(230, 40)
	score.draw.connect(func():
		score.draw_colored_polygon(Icons.star_points(Vector2(18, 20), 14), Palette.STAR)
		Icons.draw(score, "star_empty", Vector2(18, 20), 14, Palette.STAR_DARK)
		var f := Game.ui_font
		var fsz := Game.fs(24)
		score.draw_string(f, Vector2(38, 20 + fsz * 0.35), "%d/%d   %d pontos" % [Game.total_stars(), Game.MISSIONS.size() * 3, Game.total_points()], HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Palette.TEXT))
	row.add_child(score)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	for i in FLOOR_NAMES.size():
		var fi := i
		var open := Game.floor_unlocked(i)
		var fb := button(row, FLOOR_NAMES[i], "home" if i == 0 else ("lock" if not open else "next"), func():
			if Game.floor_unlocked(fi):
				Game.goto("map", {"andar": fi})
			else:
				_say("O andar de cima abre quando você terminar a missão 5.", "pensando"), "success" if i == andar else "secondary", 54)
		fb.tooltip_text = "Ir para o %s" % FLOOR_NAMES[i] if open else "Termine a missão 5 para abrir"
	if Game.all_completed():
		button(row, "Certificado", "certificate", func(): Game.goto("final"), "star", 54)
	button(row, "Configurações", "gear", func(): Game.goto("settings"), "secondary", 54)
	button(row, "Início", "home", func(): Game.goto("title"), "secondary", 54)


# ------------------------------------------------------------------ geometria
func _origin() -> Vector2:
	return ((map.size - Vector2(COLS, ROWS) * T) / 2.0).floor()


func _room_px(r: Dictionary) -> Rect2:
	var rr: Rect2i = r.rect
	return Rect2(_origin() + Vector2(rr.position) * T, Vector2(rr.size) * T)


func _door_x(r: Dictionary) -> float:
	var rr: Rect2i = r.rect
	return (rr.position.x + rr.size.x / 2.0) * T


func _corridor_y() -> float:
	return 6.0 * T + 6        # pés do personagem no meio do corredor


func _layout() -> void:
	for r in _rooms():
		if not signs.has(r.id):
			continue
		var sign: Control = signs[r.id]
		sign.reset_size()
		var rp := _room_px(r)
		var floor_top := rp.position.y + 2 * T
		sign.position = Vector2(rp.get_center().x - sign.size.x / 2.0, floor_top + (rp.end.y - floor_top) / 2.0 - sign.size.y / 2.0 + 6).round()
	if player_pos == Vector2.ZERO:
		var r := _room(Game.next_mission())
		if r.is_empty():
			r = _rooms()[0]
		player_pos = Vector2(_door_x(r) - T, _corridor_y())
	map.queue_redraw()


func _greet() -> void:
	var msg := ""
	if Game.all_completed():
		msg = "A escola está toda conectada! A feira pode começar. Você pode repetir qualquer missão."
		bit.mood = "feliz"
	elif Game.completed.is_empty():
		msg = "Olá, %s! Eu sou o Bit. Clique na placa do Laboratório para começar. Você também pode andar com as setas." % Game.student_name
	else:
		var nm := Game.mission_info(Game.next_mission())
		msg = "Muito bem! Agora vá para: %s." % nm.place
		if int(nm.andar) != andar:
			msg += " Fica no %s: use o botão lá em cima." % FLOOR_NAMES[int(nm.andar)]
	_say(msg, bit.mood)


func _say(msg: String, mood: String = "normal") -> void:
	bubble.text = msg
	bit.mood = mood
	bit.talk(msg)
	Voice.say(msg)


func _focus_next_room() -> void:
	for id in signs:
		if Game.is_unlocked(id) and not Game.is_completed(id):
			signs[id].grab_focus()
			return
	if signs.has(1):
		signs[1].grab_focus()


# ------------------------------------------------------------------ movimento
func _go_to_room(id: int) -> void:
	if not Game.is_unlocked(id):
		_say("Esta sala ainda está fechada. Termine a missão %d primeiro." % (id - 1), "pensando")
		Sfx.play("retry")
		return
	var r: Dictionary = _room(id)
	var dx := _door_x(r)
	var into_y := (4.2 if r.top else 8.6) * T
	_route = [Vector2(player_pos.x, _corridor_y()), Vector2(dx, _corridor_y()), Vector2(dx, into_y)]
	_route_target = id
	if Game.settings.pular_animacoes:
		player_pos = _route[-1]
		_enter(id)


func _enter(id: int) -> void:
	_route.clear()
	Sfx.play("ok")
	Game.goto("mission", {"id": id})


func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if _route.is_empty():
		# controle manual (setas ou WASD)
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			dir.x -= 1
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			dir.x += 1
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
			dir.y -= 1
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
			dir.y += 1
		if dir != Vector2.ZERO:
			_manual_move(dir, delta)
	else:
		var target: Vector2 = _route[0]
		var to := target - player_pos
		if to.length() < 4.0:
			player_pos = target
			_route.pop_front()
			if _route.is_empty():
				_enter(_route_target)
				return
		else:
			dir = to.normalized()
			player_pos += dir * minf(SPEED * delta, to.length())
	_moving = dir != Vector2.ZERO
	_idle_t += delta
	if _moving:
		_walk_t += delta
		if absf(dir.x) > absf(dir.y):
			facing = "direita" if dir.x > 0 else "esquerda"
		else:
			facing = "baixo" if dir.y > 0 else "cima"
	map.queue_redraw()


func _manual_move(dir: Vector2, delta: float) -> void:
	var p := player_pos + dir.normalized() * SPEED * delta
	var cy := _corridor_y()
	# fica no corredor; só sai pelas portas
	p.x = clampf(p.x, T * 0.5, COLS * T - T * 0.5)
	var door_room := _room_at_door(p.x)
	if door_room.is_empty():
		p.y = clampf(p.y, cy - T * 0.6, cy + T * 0.4)
	else:
		p.y = clampf(p.y, cy - T * 1.6, cy + T * 1.6)
		if door_room.top and p.y < cy - T * 1.4 or not door_room.top and p.y > cy + T * 1.4:
			if door_room.id <= 0:
				p.y = clampf(p.y, cy - T * 0.6, cy + T * 0.4)
			elif Game.is_unlocked(door_room.id):
				player_pos = p
				_enter(door_room.id)
				return
			else:
				_go_to_room(door_room.id)   # mostra a mensagem de sala fechada
				p.y = cy
	player_pos = p


func _room_at_door(x: float) -> Dictionary:
	for r in _rooms():
		if absf(x - _door_x(r)) < T * 0.6:
			return r
	return {}


## As setas movem o personagem (Tab continua trocando o foco entre as placas).
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ desenho
func _draw_map() -> void:
	var o := _origin()
	var full := Rect2(o, Vector2(COLS, ROWS) * T)
	map.draw_rect(full.grow(10), Palette.FRAME_DARK)
	map.draw_rect(full.grow(6), Palette.FRAME)
	# corredor
	Sprites.tile(map, "piso_corredor", Rect2(o + Vector2(0, 5 * T), Vector2(COLS * T, 2 * T)))
	for r in _rooms():
		_draw_room(r)
	_draw_player(o)
	if Game.all_completed():
		_draw_party(full)


func _draw_room(r: Dictionary) -> void:
	var rp := _room_px(r)
	var floor_rect := Rect2(rp.position + Vector2(0, 2 * T), Vector2(rp.size.x, rp.size.y - 2 * T))
	Sprites.tile(map, r.floor, floor_rect)
	Sprites.tile(map, "parede", Rect2(rp.position, Vector2(rp.size.x, 2 * T)))
	for d in WALL_DECOR.get(r.id, []):
		var sz := Sprites.size_of(d[0])
		Sprites.draw(map, d[0], (rp.position + Vector2(float(d[1]) * T - sz.x / 2.0, 4 * Sprites.SCALE + (2 * T - 4 * Sprites.SCALE - sz.y) / 2.0)).round())
	map.draw_rect(Rect2(floor_rect.position, Vector2(floor_rect.size.x, 6)), Color(0.1, 0.1, 0.25, 0.18))
	for f in FURNITURE.get(r.id, []):
		Sprites.draw(map, f[0], (rp.position + (f[1] as Vector2) * T).round())
	# paredes laterais e porta
	var dx := rp.position.x + rp.size.x / 2.0
	map.draw_rect(Rect2(rp.position, Vector2(6, rp.size.y)), Palette.FRAME_DARK)
	map.draw_rect(Rect2(Vector2(rp.end.x - 6, rp.position.y), Vector2(6, rp.size.y)), Palette.FRAME_DARK)
	if r.top:
		# parede de baixo com abertura da porta
		map.draw_rect(Rect2(Vector2(rp.position.x, rp.end.y - 6), Vector2(rp.size.x / 2.0 - T * 0.7, 6)), Palette.FRAME_DARK)
		map.draw_rect(Rect2(Vector2(dx + T * 0.7, rp.end.y - 6), Vector2(rp.size.x / 2.0 - T * 0.7, 6)), Palette.FRAME_DARK)
	else:
		Sprites.draw(map, "porta", Vector2(dx - T / 2.0, rp.position.y + 2 * T - Sprites.size_of("porta").y))
		map.draw_rect(Rect2(Vector2(dx - T / 2.0, rp.position.y + 2 * T - 4), Vector2(T, 6)), Palette.FRAME)
	# sala fechada: escurecida + cadeado grande (além do texto na placa)
	if r.id > 0 and not Game.is_unlocked(r.id):
		map.draw_rect(rp, Color(0.08, 0.1, 0.2, 0.45))
	if r.id <= 0:
		var font := Game.ui_font
		var label := "Pátio da Feira" if r.id == 0 else "Escada"
		var fsz := Game.fs(20)
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		var box := Rect2(Vector2(rp.get_center().x - w / 2.0 - 8, rp.position.y + 2 * T + 8), Vector2(w + 16, fsz + 10))
		map.draw_rect(box, Palette.CREAM)
		map.draw_rect(box, Palette.FRAME_DARK, false, 2)
		map.draw_string(font, box.position + Vector2(8, fsz * 0.86 + 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Palette.TEXT)


func _draw_player(o: Vector2) -> void:
	var name := Walker.frame_name(Game.avatar_sprite(), facing, _moving, _walk_t, _idle_t)
	var sz := Sprites.size_of(name)
	var feet := o + player_pos
	map.draw_rect(Rect2(feet + Vector2(-sz.x * 0.3, -6), Vector2(sz.x * 0.6, 8)), Color(0.1, 0.1, 0.25, 0.3))
	Sprites.draw(map, name, (feet - Vector2(sz.x / 2.0, sz.y - 4)).round())


func _draw_party(full: Rect2) -> void:
	# escola iluminada: luzes coloridas no corredor
	var cols := [Palette.STAR, Palette.LED_ON, Palette.SCREEN_ON, Color("#f29aa0")]
	for i in 32:
		var x := full.position.x + 12 + i * (full.size.x - 24) / 31.0
		var y := full.position.y + 5 * T + 6 + (i % 2) * 6
		map.draw_rect(Rect2(Vector2(x - 4, y - 4), Vector2(8, 8)), cols[i % cols.size()])
