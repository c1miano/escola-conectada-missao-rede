class_name MissionBase
extends Control
## Base de todas as missões: layout padrão, Bit, ajuda em 3 níveis, feedback,
## animações que podem ser puladas, desafio extra do Modo Explorador e tela de conclusão.
##
## Layout: topo = título e objetivo | centro = cenário | baixo = ações
## canto inferior direito = Bit + "Preciso de ajuda" | canto superior direito = voltar ao mapa.

var mission_id := 0
var info: Dictionary = {}
var guided := true

var stage: Control
var cables: CableLayer
var actions: HFlowContainer
var _act_panel: PanelContainer
var _bubble_panel: PanelContainer
var bit: BitSpeaker
var bubble: Label
var title_label: Label
var objective_label: Label
var help_button: BigButton
var skip_button: BigButton
var pointer: PointerView
var _feedback: PanelContainer
var _feedback_icon: Control
var _feedback_label: Label
var _feedback_ok := true
var _overlay: Control

var _hints: Array = []
var _targets: Array = []
var _hint_level := 0
var _placed := {}
var _anim: Tween
var _anim_id := ""
var _highlighted: Array = []
var busy := false
var room_color := Color("#dbe8f6")   # (não usado no visual pixel art)
var floor_color := Color("#c9b79c")
var place_icon := "home"
## Visual da sala (pixel art top-down)
var floor_tile := "piso_tijolo"
var wall_items: Array = [["janela", 0.32], ["quadro", 0.52], ["relogio", 0.64], ["cartaz_rede", 0.74], ["janela", 0.86], ["extintor", 0.97]]
var floor_items: Array = []
var _finished := false
# pontuação desta partida
var _retries := 0
var _hints_used := 0
var _quiz_first_try := 0
var walker: Walker
var use_button: BigButton
var _near: Control = null          # equipamento perto do personagem


func _init(id: int = 0) -> void:
	mission_id = id


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	info = Game.mission_info(mission_id)
	guided = Game.is_guided()
	_build_layout()
	Game.record_start(mission_id)
	DeviceView.interceptor = _walk_and_use
	setup()
	walker = Walker.new()
	walker.visible = false
	stage.add_child(walker)


func _exit_tree() -> void:
	if DeviceView.interceptor == Callable(self, "_walk_and_use"):
		DeviceView.interceptor = Callable()


func _place_walker() -> void:
	walker.set_feet(floor_point(Vector2(0.5, 0.45)))


## Implementado por cada missão.
func setup() -> void:
	pass


## Desafios complementares do Modo Explorador: lista de {"q", "options", "answer", "explain", "skill"}.
func explorer_quiz() -> Array:
	return []


# ================================================================== layout
func _build_layout() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# ---- topo
	var top := PanelContainer.new()
	root.add_child(top)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 2)
	top_row.add_child(titles)
	title_label = Label.new()
	title_label.text = "Missão %d — %s   ·   Nível %d de %d" % [mission_id, info.get("title", ""), mission_id, Game.MISSIONS.size()]
	title_label.add_theme_font_size_override("font_size", Game.fs(28))
	title_label.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	titles.add_child(title_label)
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(objective_label)
	var listen := BigButton.new("Ouvir de novo", "speaker", "secondary", 64)
	listen.tooltip_text = "Ouvir a instrução outra vez"
	listen.pressed.connect(func(): Voice.repeat())
	listen.visible = Voice.available()
	top_row.add_child(listen)
	var back := BigButton.new("Voltar ao mapa", "map", "secondary", 64)
	back.pressed.connect(func(): Game.goto("map"))
	top_row.add_child(back)

	# ---- centro (cenário)
	stage = Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.clip_contents = false
	stage.draw.connect(_draw_room)
	stage.resized.connect(func(): stage.queue_redraw())
	root.add_child(stage)
	cables = CableLayer.new()
	stage.add_child(cables)

	# ---- dentro da sala: Bit (assistente), balão, ajuda e painel de opções flutuante
	bit = BitSpeaker.new()
	bit.z_index = 8
	stage.add_child(bit)

	_bubble_panel = PanelContainer.new()
	_bubble_panel.z_index = 8
	_bubble_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color("#ffffff")
	bs.border_color = Palette.FRAME_DARK
	bs.set_border_width_all(2)
	bs.set_corner_radius_all(6)
	bs.content_margin_left = 10
	bs.content_margin_right = 10
	bs.content_margin_top = 5
	bs.content_margin_bottom = 6
	bs.shadow_color = Color(0.05, 0.05, 0.15, 0.3)
	bs.shadow_size = 1
	bs.shadow_offset = Vector2(2, 2)
	_bubble_panel.add_theme_stylebox_override("panel", bs)
	# pontinha do balão apontando para baixo, para o Bit
	_bubble_panel.draw.connect(func():
		var r := _bubble_panel.size
		var x := r.x - 34.0
		_bubble_panel.draw_colored_polygon(PackedVector2Array([Vector2(x - 8, r.y - 2), Vector2(x, r.y + 9), Vector2(x + 8, r.y - 2)]), Palette.FRAME_DARK)
		_bubble_panel.draw_colored_polygon(PackedVector2Array([Vector2(x - 5, r.y - 3), Vector2(x, r.y + 5), Vector2(x + 5, r.y - 3)]), Color.WHITE))
	stage.add_child(_bubble_panel)
	bubble = Label.new()
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.custom_minimum_size = Vector2(300, 0)
	bubble.add_theme_font_size_override("font_size", Game.fs(21))
	var bubble_col := VBoxContainer.new()
	bubble_col.add_theme_constant_override("separation", 0)
	var who := Label.new()
	who.text = "Bit"
	who.add_theme_font_override("font", Game.ui_font_bold)
	who.add_theme_font_size_override("font_size", Game.fs(19))
	who.add_theme_color_override("font_color", Palette.PRIMARY)
	bubble_col.add_child(who)
	bubble_col.add_child(bubble)
	_bubble_panel.add_child(bubble_col)

	help_button = BigButton.new("Preciso\nde ajuda", "help", "star", 84)
	help_button.add_theme_font_size_override("font_size", Game.fs(20))
	help_button.z_index = 8
	help_button.pressed.connect(_on_help)
	stage.add_child(help_button)

	_act_panel = PanelContainer.new()
	_act_panel.z_index = 9
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(Palette.CREAM, 0.96)
	ps.border_color = Palette.FRAME_DARK
	ps.set_border_width_all(4)
	ps.border_width_bottom = 8
	ps.set_corner_radius_all(3)
	for side in ["left", "right", "top", "bottom"]:
		ps.set("content_margin_" + side, 10)
	_act_panel.add_theme_stylebox_override("panel", ps)
	stage.add_child(_act_panel)
	actions = HFlowContainer.new()
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("h_separation", 12)
	actions.add_theme_constant_override("v_separation", 8)
	_act_panel.add_child(actions)

	# ---- camadas sobrepostas
	_build_feedback()
	skip_button = BigButton.new("Pular animação", "skip", "secondary", 60)
	skip_button.visible = false
	skip_button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	skip_button.position = Vector2(-120, 110)
	skip_button.pressed.connect(skip_animation)
	add_child(skip_button)
	pointer = PointerView.new()
	add_child(pointer)
	use_button = BigButton.new("Usar", "play", "star", 58)
	use_button.add_theme_font_size_override("font_size", Game.fs(20))
	use_button.visible = false
	use_button.z_index = 30
	use_button.pressed.connect(_use_near)
	add_child(use_button)


func _build_feedback() -> void:
	_feedback = PanelContainer.new()
	_feedback.visible = false
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_feedback.z_index = 40
	add_child(_feedback)
	var row := HBoxContainer.new()
	_feedback.add_child(row)
	_feedback_icon = Control.new()
	_feedback_icon.custom_minimum_size = Vector2(36, 36)
	_feedback_icon.draw.connect(func():
		var c := _feedback_icon.size / 2.0
		_feedback_icon.draw_circle(c, 17, Palette.SUCCESS if _feedback_ok else Palette.ATTENTION)
		Icons.draw(_feedback_icon, "check" if _feedback_ok else "retry", c, 12, Color.WHITE))
	row.add_child(_feedback_icon)
	_feedback_label = Label.new()
	_feedback_label.add_theme_font_size_override("font_size", Game.fs(30))
	_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_feedback_label)


func _draw_room() -> void:
	var s := stage.size
	Room.draw(stage, Rect2(Vector2.ZERO, s), floor_tile, wall_items, floor_items)
	# placa com o nome do local, na parede
	var font := Game.ui_font
	var place: String = info.get("place", "")
	var fsz := Game.fs(20)
	var w := font.get_string_size(place, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
	var sign := Rect2(Vector2(14, 28), Vector2(w + 40, fsz + 14))
	stage.draw_rect(sign, Palette.CREAM)
	stage.draw_rect(sign, Palette.FRAME_DARK, false, 2)
	Icons.draw(stage, place_icon, sign.position + Vector2(15, sign.size.y / 2.0), 8, Palette.PRIMARY_DARK)
	stage.draw_string(font, sign.position + Vector2(28, sign.size.y / 2.0 + fsz * 0.36), place, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Palette.TEXT)


## Converte posição relativa (0..1) para a área do piso.
func floor_point(rel: Vector2) -> Vector2:
	var top := float(Room.WALL_H)
	return Vector2(rel.x * stage.size.x, top + rel.y * (stage.size.y - top))


func _process(_d: float) -> void:
	_update_walker(_d)
	_layout_overlays()
	for n in _placed:
		if is_instance_valid(n):
			n.position = (floor_point(_placed[n]) - n.size / 2.0).round()
	if _feedback.visible:
		_feedback.position.x = (size.x - _feedback.size.x) / 2.0
		_feedback.position.y = 90


# ================================================================== Bit, balão, ajuda e opções dentro da sala
func _layout_overlays() -> void:
	var sz := stage.size
	if sz.y < 100:
		return
	# Bit no canto inferior direito, ajuda à esquerda dele
	bit.position = Vector2(sz.x - bit.size.x - 18, sz.y - bit.size.y - 6).round()
	help_button.reset_size()
	help_button.position = Vector2(bit.position.x - help_button.size.x - 10, sz.y - help_button.size.y - 14).round()
	# balão acima do Bit (some quando não há texto)
	_bubble_panel.visible = bubble.text.strip_edges() != ""
	var bw := minf(400.0 * Game.ui_scale() / 0.7, sz.x * 0.4)
	bubble.custom_minimum_size.x = bw - 20
	_bubble_panel.reset_size()
	_bubble_panel.position = Vector2(sz.x - _bubble_panel.size.x - 14, bit.position.y - _bubble_panel.size.y - 10).round()
	# painel de opções: embaixo, no meio da área livre (só quando há opções)
	var has_actions := false
	for c in actions.get_children():
		if not c.is_queued_for_deletion():
			has_actions = true
			break
	_act_panel.visible = has_actions
	if has_actions:
		var free_w := help_button.position.x - 24
		var content := 0.0
		for c in actions.get_children():
			if not c.is_queued_for_deletion():
				content += (c as Control).get_combined_minimum_size().x + 12.0
		actions.custom_minimum_size.x = minf(free_w - 24, content)
		_act_panel.reset_size()
		_act_panel.position = Vector2(maxf(12, (free_w - _act_panel.size.x) / 2.0), sz.y - _act_panel.size.y - 10).round()


# ================================================================== personagem (andar até o equipamento)
## Área do piso onde o personagem pode andar (coordenadas do cenário).
func walk_bounds() -> Rect2:
	var top := float(Room.WALL_H) + 30.0
	return Rect2(Vector2(30, top), Vector2(stage.size.x - 60, stage.size.y - top - 8))


## Ponto do chão em frente a um equipamento ou porta.
func stand_point(target: Control) -> Vector2:
	var r := target.get_global_rect()
	var inv := stage.get_global_transform().affine_inverse()
	var below := inv * Vector2(r.get_center().x, r.end.y + 62)
	var b := walk_bounds()
	if below.y > b.end.y:
		below = inv * Vector2(r.get_center().x, r.position.y - 6)
	return Vector2(clampf(below.x, b.position.x, b.end.x), clampf(below.y, b.position.y, b.end.y))


## Clique num equipamento: o técnico anda até ele e só então a ação acontece.
func _walk_and_use(target: Control, action: Callable) -> void:
	if busy or walker == null:
		return
	var dest := stand_point(target)
	if walker.feet().distance_to(dest) < 40.0:
		action.call()
		return
	Sfx.play("select")
	walker.walk_to(dest, func():
		if is_instance_valid(target) and not busy:
			action.call())


func _interactives() -> Array:
	var out: Array = []
	for n in stage.find_children("*", "DeviceView", true, false):
		if n.is_interactive():
			out.append(n)
		if n is SwitchView and n.port_clicked.get_connections().size() > 0:
			for p in n.ports:
				out.append(p)
	return out


func _update_walker(delta: float) -> void:
	if walker == null:
		return
	if not walker.visible:
		# só posiciona quando a sala já tem o tamanho final
		if stage.size.y < Room.WALL_H + 120:
			return
		_place_walker()
		walker.visible = true
	if not walker.walking_to_target() and not busy:
		var dir := Vector2.ZERO
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			dir.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			dir.x += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			dir.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			dir.y += 1
		walker.step(dir, delta, walk_bounds())
	# equipamento mais próximo -> botão "Usar"
	var best: Control = null
	var best_d := 120.0
	var feet_g := stage.get_global_transform() * walker.feet()
	for n in _interactives():
		var r: Rect2 = n.get_global_rect()
		var d := feet_g.distance_to(Vector2(r.get_center().x, clampf(feet_g.y, r.position.y, r.end.y + 30)))
		if d < best_d:
			best_d = d
			best = n
	_near = best if not walker.walking_to_target() else null
	use_button.visible = _near != null and not busy and not _finished
	if use_button.visible:
		var label := "Usar"
		if _near is DeviceView:
			label = "Usar: " + (_near as DeviceView).name_label.text
		elif _near is Button:
			label = "Usar: " + str((_near as Button).text).get_slice("\n", 0)
		if use_button.text != label:
			use_button.text = label
			use_button.reset_size()
		# flutua sobre a cabeça do técnico (dentro da sala)
		var r2: Rect2 = stage.get_global_rect()
		var head: Vector2 = stage.get_global_transform() * (walker.position + Vector2(walker.size.x / 2.0, 0))
		var pos := head - Vector2(use_button.size.x / 2.0, use_button.size.y + 6)
		pos.x = clampf(pos.x, r2.position.x + 8, r2.end.x - use_button.size.x - 8)
		pos.y = clampf(pos.y, r2.position.y + 8, r2.end.y - use_button.size.y - 8)
		use_button.global_position = pos.round()


func _use_near() -> void:
	if _near == null or busy:
		return
	if _near is DeviceView:
		(_near as DeviceView).use()
	elif _near is Button:
		(_near as Button).pressed.emit()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			# setas andam com o personagem (Tab troca o foco dos botões)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E and use_button.visible:
			get_viewport().set_input_as_handled()
			_use_near()
		elif event.keycode in [KEY_SPACE, KEY_ENTER] and use_button.visible and get_viewport().gui_get_focus_owner() == null:
			get_viewport().set_input_as_handled()
			_use_near()


# ================================================================== helpers para as missões
## Coloca um elemento no cenário. rel = posição relativa (0..1) do centro.
func place(node: Control, rel: Vector2) -> Control:
	if node is PanelContainer:
		node.z_index = 6       # painéis de informação ficam na frente do técnico
	stage.add_child(node)
	_placed[node] = rel
	node.reset_size()
	return node


func move_to(node: Control, rel: Vector2) -> void:
	_placed[node] = rel


func unplace(node: Control) -> void:
	_placed.erase(node)
	node.queue_free()


func set_objective(text: String) -> void:
	objective_label.text = "Objetivo: " + text


## Bit fala (balão + narração opcional).
func say(text: String, mood: String = "normal") -> void:
	bubble.text = text
	bit.mood = mood
	bit.talk(text)
	Voice.say(text)


## Define a etapa atual: dicas graduais e objetos que a ajuda deve destacar.
## No Modo Guiado a primeira dica fica sempre visível no balão.
func set_step(hints: Array, targets: Array = []) -> void:
	_hints = hints
	_targets = targets
	_hint_level = 0
	clear_highlights()
	if guided and hints.size() > 0:
		say(hints[0])


func set_targets(targets: Array) -> void:
	_targets = targets


func clear_actions() -> void:
	for c in actions.get_children():
		c.queue_free()


func add_action(text: String, icon: String, callback: Callable, variant: String = "primary") -> BigButton:
	var b := BigButton.new(text, icon, variant, 72)
	b.custom_minimum_size.x = 200
	b.pressed.connect(func():
		if busy:
			return
		callback.call())
	actions.add_child(b)
	return b


func highlight(nodes: Array) -> void:
	clear_highlights()
	for n in nodes:
		if not is_instance_valid(n):
			continue
		if n is DeviceView:
			n.highlighted = true
		elif n is Control:
			n.modulate = Color(1.15, 1.15, 0.8)
			_pulse(n)
		_highlighted.append(n)


func _pulse(n: Control) -> void:
	n.pivot_offset = n.size / 2.0
	var t := n.create_tween().set_loops(4)
	t.tween_property(n, "scale", Vector2(1.08, 1.08), 0.3)
	t.tween_property(n, "scale", Vector2.ONE, 0.3)


func clear_highlights() -> void:
	for n in _highlighted:
		if is_instance_valid(n):
			if n is DeviceView:
				n.highlighted = false
			else:
				n.modulate = Color.WHITE
				n.scale = Vector2.ONE
	_highlighted.clear()


## Resposta certa: registra, mostra ícone de check + texto e toca som.
func correct(text: String = "Certo!", skill: String = "") -> void:
	Game.record_attempt(mission_id, true)
	if skill != "":
		Game.record_skill(mission_id, skill)
	clear_highlights()
	show_feedback(true, text)


## Resposta para tentar de novo: sem punição. Explica e, no Modo Guiado, destaca o objeto certo.
func try_again(explanation: String) -> void:
	Game.record_attempt(mission_id, false)
	_retries += 1
	show_feedback(false, "Vamos tentar de novo")
	say(explanation, "pensando")
	if guided and not _targets.is_empty():
		highlight(_targets)


func show_feedback(ok: bool, text: String) -> void:
	_feedback_ok = ok
	_feedback_label.text = text
	_feedback_icon.queue_redraw()
	_feedback.visible = true
	_feedback.modulate.a = 0.0
	_feedback.reset_size()
	Sfx.play("ok" if ok else "retry")
	if ok:
		bit.celebrate()
	var t := create_tween()
	t.tween_property(_feedback, "modulate:a", 1.0, 0.15)
	t.tween_interval(1.6)
	t.tween_property(_feedback, "modulate:a", 0.0, 0.3)
	t.tween_callback(func(): _feedback.visible = false)


# ================================================================== ajuda (3 níveis)
func _on_help() -> void:
	_hint_level = mini(_hint_level + 1, 3)
	_hints_used += 1
	Game.record_hint(mission_id, _hint_level)
	if _hints.is_empty():
		say("Leia o objetivo lá em cima. Você consegue!")
		return
	var text: String = _hints[mini(_hint_level - 1, _hints.size() - 1)]
	say(text, "pensando")
	match _hint_level:
		2:
			highlight(_targets)
		3:
			highlight(_targets)
			demonstrate(_targets)


## Mostra a mãozinha clicando nos objetos, um depois do outro.
func demonstrate(nodes: Array) -> void:
	var valid: Array = nodes.filter(func(n): return is_instance_valid(n))
	if valid.is_empty():
		return
	pointer.visible = true
	pointer.global_position = (valid[0] as Control).get_global_rect().get_center() + Vector2(80, 80)
	var t := create_tween()
	for n in valid:
		var target: Vector2 = (n as Control).get_global_rect().get_center()
		t.tween_property(pointer, "global_position", target, 0.7).set_trans(Tween.TRANS_SINE)
		t.tween_callback(pointer.click_effect)
		t.tween_interval(0.6)
	t.tween_callback(func(): pointer.visible = false)


# ================================================================== animações
## Cria uma animação que pode ser pulada. Se o jogador escolheu
## "pular animações repetidas" e já viu esta, ela termina na hora.
func animate(id: String) -> Tween:
	_anim_id = id
	busy = true
	_anim = create_tween()
	_anim.finished.connect(_on_anim_done.bind(_anim))
	skip_button.visible = true
	if Game.settings.pular_animacoes and Game.animation_seen(id):
		_auto_skip.call_deferred(_anim)
	return _anim


func _auto_skip(t: Tween) -> void:
	if is_instance_valid(t) and t.is_valid() and t.is_running():
		t.custom_step(9999.0)


func skip_animation() -> void:
	if _anim and _anim.is_valid() and _anim.is_running():
		_anim.custom_step(9999.0)


func _on_anim_done(t: Tween) -> void:
	Game.mark_animation_seen(_anim_id)
	if t == _anim:
		busy = false
		skip_button.visible = false


## Pacote percorrendo uma lista de nós (ou posições globais).
func send_packet(tw: Tween, tag: String, path: Array, tint: Color = Palette.STAR, step_time: float = 0.7) -> PacketView:
	var pk := PacketView.new(tag, tint)
	pk.visible = false
	add_child(pk)
	var pts: Array = []
	for p in path:
		pts.append(p.anchor() if p is DeviceView else (p as Control).get_global_rect().get_center() if p is Control else p)
	tw.tween_callback(func():
		pk.visible = true
		pk.global_position = pts[0] - pk.size / 2.0
		Sfx.play("packet"))
	for i in range(1, pts.size()):
		tw.tween_property(pk, "global_position", pts[i] - pk.size / 2.0, step_time).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(pk.queue_free)
	return pk


# ================================================================== conclusão
func complete(message: String) -> void:
	if _finished:
		return
	_finished = true
	var quizzes := explorer_quiz() if not guided else []
	_run_quizzes(quizzes, 0, message)


func _run_quizzes(quizzes: Array, i: int, message: String) -> void:
	if i >= quizzes.size():
		_finish(message)
		return
	ask_question(quizzes[i], func(): _run_quizzes(quizzes, i + 1, message),
		"Desafio extra do Explorador (%d de %d)" % [i + 1, quizzes.size()])


## Pergunta em tela própria (uma tarefa por tela). Erros não tiram pontos.
func ask_question(quiz: Dictionary, on_done: Callable, header: String = "Pergunta") -> void:
	var ov := _make_overlay(header)
	var box := ov.get_meta("box") as VBoxContainer
	box.add_child(Control.new())   # (mantém a ordem: pergunta, pista, opções)
	var q := Label.new()
	q.text = quiz.q
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.add_theme_font_size_override("font_size", Game.fs(28))
	box.add_child(q)
	var tip := Label.new()
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.visible = false
	box.add_child(tip)
	Voice.say(quiz.q)
	for i in quiz.options.size():
		var b := BigButton.new(quiz.options[i], "", "secondary", 70)
		var idx: int = i
		b.pressed.connect(func():
			if idx == int(quiz.answer):
				if not quiz.get("_errou", false):
					_quiz_first_try += 1
				Game.record_attempt(mission_id, true)
				Game.record_skill(mission_id, "Desafio extra: " + str(quiz.get("skill", quiz.q)))
				Sfx.play("ok")
				ov.queue_free()
				on_done.call()
			else:
				Game.record_attempt(mission_id, false)
				_retries += 1
				quiz["_errou"] = true
				Sfx.play("retry")
				b.disabled = true
				b.text = "Tente outra: " + str(quiz.options[idx])
				tip.text = "Pista: " + str(quiz.explain)
				tip.visible = true
				Voice.say(tip.text))
		box.add_child(b)
	box.get_child(3).grab_focus.call_deferred()


## Tela de história no início da missão (uma tarefa por tela). Depois chama on_start.
func story(text: String, on_start: Callable) -> void:
	var ov := _make_overlay("Missão %d — %s" % [mission_id, info.get("title", "")])
	var box := ov.get_meta("box") as VBoxContainer
	var row := HBoxContainer.new()
	box.add_child(row)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(80, 140)
	row.add_child(holder)
	var b := BitSpeaker.new()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = b.custom_minimum_size
	holder.add_child(b)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var place := Label.new()
	place.text = "Bit diz:"
	place.add_theme_font_override("font", Game.ui_font_bold)
	place.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(place)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", Game.fs(28))
	col.add_child(l)
	var go := BigButton.new("Começar", "play", "success", 80)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.custom_minimum_size.x = 280
	go.pressed.connect(func():
		ov.queue_free()
		on_start.call())
	box.add_child(go)
	go.grab_focus.call_deferred()
	Voice.say(text)


func _make_overlay(title: String = "", width: float = 560.0) -> Control:
	var ov := ColorRect.new()
	ov.color = Color(0.05, 0.08, 0.15, 0.55)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.z_index = 60
	add_child(ov)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)
	var win := UiWindow.create(title, width)
	center.add_child(win.root)
	ov.set_meta("box", win.body)
	return ov


func _finish(message: String) -> void:
	Game.complete_mission(mission_id)
	var sc := Game.compute_score(mission_id, _retries, _hints_used, not guided, _quiz_first_try)
	var record := Game.record_score(mission_id, sc)
	Sfx.play("win")
	bit.celebrate()
	var ov := _make_overlay("Missão %d concluída" % mission_id, 470.0)
	var box := ov.get_meta("box") as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	# estrelas ganhas (1 a 3), animadas uma de cada vez
	var stars := Control.new()
	stars.custom_minimum_size = Vector2(0, 74)
	var shown := {"n": 0}
	stars.draw.connect(func():
		for i in 3:
			var c := Vector2(stars.size.x / 2.0 + (i - 1) * 70, 38)
			var r := 30.0 if i == 1 else 26.0
			if i < shown.n:
				stars.draw_colored_polygon(Icons.star_points(c, r), Palette.STAR)
			Icons.draw(stars, "star_empty", c, r, Palette.STAR_DARK))
	box.add_child(stars)
	var title := Label.new()
	title.text = "%d estrela%s!" % [sc.estrelas, "" if sc.estrelas == 1 else "s"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", Game.fs(30))
	title.add_theme_color_override("font_color", Palette.SUCCESS)
	box.add_child(title)
	var msg := Label.new()
	msg.text = message
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(msg)
	# quadro de pontos (só soma: tentativas e dicas reduzem o bônus, nunca tiram pontos)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 2)
	var rows := [["Missão concluída (nível %d)" % mission_id, sc.base], ["Bônus de precisão", sc.precisao],
		["Bônus de autonomia", sc.autonomia]]
	if not guided:
		rows.append(["Bônus do Explorador", sc.explorador])
	for r in rows:
		var a := Label.new()
		a.text = r[0]
		grid.add_child(a)
		var b := Label.new()
		b.text = "+%d" % r[1]
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(b)
	var ta := Label.new()
	ta.text = "Total"
	ta.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	grid.add_child(ta)
	var tb := Label.new()
	tb.text = "%d pontos" % sc.pontos
	tb.add_theme_color_override("font_color", Palette.PRIMARY_DARK)
	tb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(tb)
	var center := CenterContainer.new()
	center.add_child(grid)
	box.add_child(center)
	var note := Label.new()
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Palette.TEXT_SOFT)
	note.text = ("Novo recorde nesta missão!" if record else "Seu recorde nesta missão: %d pontos." % Game.mission_points(mission_id)) + "  Total: %d pontos." % Game.total_points()
	box.add_child(note)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var cont := BigButton.new("Continuar", "next", "success", 80)
	cont.pressed.connect(func():
		Game.goto("final" if Game.all_completed() and mission_id == Game.MISSIONS.size() else "map"))
	row.add_child(cont)
	var again := BigButton.new("Jogar de novo", "retry", "secondary", 80)
	again.pressed.connect(func(): Game.goto("mission", {"id": mission_id}))
	row.add_child(again)
	cont.grab_focus.call_deferred()
	say(message + " Você ganhou %d estrela%s e %d pontos." % [sc.estrelas, "" if sc.estrelas == 1 else "s", sc.pontos], "feliz")
	var t := stars.create_tween()
	for i in sc.estrelas:
		t.tween_interval(0.3)
		t.tween_callback(func():
			shown.n += 1
			stars.queue_redraw()
			Sfx.play("select"))
