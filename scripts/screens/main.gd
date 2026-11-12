extends Control
## Troca de telas. Cada tela é criada por código (sem cenas complexas para manter).

const SCREENS := {
	"title": "res://scripts/screens/title_screen.gd",
	"mode": "res://scripts/screens/mode_screen.gd",
	"players": "res://scripts/screens/players_screen.gd",
	"new_player": "res://scripts/screens/new_player_screen.gd",
	"progress": "res://scripts/screens/progress_screen.gd",
	"map": "res://scripts/screens/map_screen.gd",
	"settings": "res://scripts/screens/settings_screen.gd",
	"report": "res://scripts/screens/report_screen.gd",
	"final": "res://scripts/screens/final_screen.gd",
}

var current: Control


func _ready() -> void:
	Game.screen_requested.connect(_show)
	var start := "title"
	# Permite abrir direto uma tela em testes: godot -- --tela=mission:3
	var shot := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tela="):
			start = arg.trim_prefix("--tela=")
		elif arg.begins_with("--captura="):
			shot = arg.trim_prefix("--captura=")
		elif arg.begins_with("--autoteste="):
			# Teste automático (desenvolvimento): joga as missões sozinho.
			var tester: Node = load("res://tests/autotest.gd").new()
			tester.set_meta("args", arg.trim_prefix("--autoteste="))
			add_child.call_deferred(tester)
			return
	if shot != "":
		_capture(shot)
	if start.begins_with("mission:"):
		_show("mission", {"id": int(start.get_slice(":", 1))})
	else:
		_show(start, {})


func _show(screen: String, params: Dictionary) -> void:
	if current:
		current.queue_free()
	var node: Control
	if screen == "mission":
		var id: int = params.get("id", 1)
		node = load(Game.mission_info(id).script).new(id)
	else:
		node = load(SCREENS.get(screen, SCREENS.title)).new()
		if node.has_method("configure"):
			node.configure(params)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(node)
	current = node
	_focus_first.call_deferred(node)


func _focus_first(node: Control) -> void:
	if not is_instance_valid(node) or get_viewport().gui_get_focus_owner() != null:
		return
	var b := _find_button(node)
	if b:
		b.grab_focus()


func _find_button(n: Node) -> Button:
	for c in n.get_children():
		if c is Button and c.visible and not c.disabled:
			return c
		var r := _find_button(c)
		if r:
			return r
	return null


## Ferramenta de desenvolvimento: salva uma captura de tela e fecha o jogo.
func _capture(path: String) -> void:
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
