extends Node
## Estado global: modo de jogo, progresso, configurações e relatório pedagógico.
## Tudo é salvo localmente (user://), sem internet e sem cadastro.

signal screen_requested(screen: String, params: Dictionary)
signal settings_changed

const SAVE_PATH := "user://progresso.json"
const REPORT_FILE := "relatorio_pedagogico.txt"

const MISSIONS := [
	{"id": 1, "title": "A escola desconectada", "place": "Laboratório de Informática",
		"script": "res://scripts/missions/mission_1.gd",
		"topics": "Topologias, meios de transmissão e equipamentos de rede"},
	{"id": 2, "title": "Cada computador tem seu endereço", "place": "Secretaria",
		"script": "res://scripts/missions/mission_2.gd",
		"topics": "Endereçamento IPv4, máscara de rede e DHCP"},
	{"id": 3, "title": "O mistério da mensagem perdida", "place": "Biblioteca",
		"script": "res://scripts/missions/mission_3.gd",
		"topics": "TCP/IP, protocolos, DNS e camadas de rede"},
	{"id": 4, "title": "O detetive das redes", "place": "Sala de Servidores",
		"script": "res://scripts/missions/mission_4.gd",
		"topics": "Diagnóstico, conectividade, conflitos de IP e serviços"},
	{"id": 5, "title": "A escola inteligente", "place": "Sala de Aula Inteligente",
		"script": "res://scripts/missions/mission_5.gd",
		"topics": "Wi-Fi, Internet das Coisas e comunicação entre dispositivos"},
]

const MODE_GUIDED := "guiado"
const MODE_EXPLORER := "explorador"

var mode: String = MODE_GUIDED
var completed: Array = []          # ids das missões concluídas
var seen_animations: Dictionary = {}
var student_name: String = ""
var settings := {
	"narracao": true,
	"volume": 0.8,
	"pular_animacoes": false,
	"texto_grande": false,
}
## Relatório: chave = id da missão (String). Não guarda nenhum dado médico.
var report: Dictionary = {}

var _theme_builder := preload("res://scripts/ui/theme_builder.gd")
## Fonte em pixel Jersey 10 (licença OFL): números bem distintos, importante para ler IPs.
var ui_font: Font = preload("res://assets/fonts/Jersey10-Regular.woff")
var ui_font_bold: Font = ui_font


## Tamanho de texto do jogo: visual compacto por padrão; "Texto grande" aumenta tudo.
func fs(size: int) -> int:
	return int(round(size * text_scale()))


## A Jersey 10 é condensada: precisa de tamanho nominal maior que fontes comuns.
func text_scale() -> float:
	return 1.25 if settings.texto_grande else 0.98


func ui_scale() -> float:
	return 0.92 if settings.texto_grande else 0.7


func _ready() -> void:
	load_game()
	apply_theme()


# ---------------------------------------------------------------- navegação
func goto(screen: String, params: Dictionary = {}) -> void:
	Voice.stop()
	screen_requested.emit(screen, params)


func mission_info(id: int) -> Dictionary:
	for m in MISSIONS:
		if m.id == id:
			return m
	return {}


func is_completed(id: int) -> bool:
	return completed.has(id)


func is_unlocked(id: int) -> bool:
	return id == 1 or is_completed(id - 1) or is_completed(id)


func all_completed() -> bool:
	return completed.size() >= MISSIONS.size()


func is_guided() -> bool:
	return mode == MODE_GUIDED


# ---------------------------------------------------------------- progresso
func new_game(new_mode: String) -> void:
	mode = new_mode
	completed.clear()
	seen_animations.clear()
	save_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) and (completed.size() > 0 or not report.is_empty())


func save_game() -> void:
	var data := {
		"versao": 1,
		"modo": mode,
		"concluidas": completed,
		"animacoes_vistas": seen_animations,
		"nome": student_name,
		"config": settings,
		"relatorio": report,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	mode = str(data.get("modo", MODE_GUIDED))
	completed.clear()
	for v in data.get("concluidas", []):
		completed.append(int(v))
	seen_animations = data.get("animacoes_vistas", {})
	student_name = str(data.get("nome", ""))
	var cfg: Dictionary = data.get("config", {})
	for k in cfg:
		settings[k] = cfg[k]
	report = data.get("relatorio", {})


func set_setting(key: String, value) -> void:
	settings[key] = value
	save_game()
	if key == "texto_grande":
		apply_theme()
	settings_changed.emit()


func apply_theme() -> void:
	get_tree().root.theme = _theme_builder.build(settings.texto_grande)


# ---------------------------------------------------------------- animações
func animation_seen(id: String) -> bool:
	return seen_animations.has(id)


func mark_animation_seen(id: String) -> void:
	if not seen_animations.has(id):
		seen_animations[id] = true
		save_game()


# ---------------------------------------------------------------- relatório
func _entry(id: int) -> Dictionary:
	var key := str(id)
	if not report.has(key):
		report[key] = {
			"iniciada": 0, "concluida": 0, "tentativas": 0, "acertos": 0,
			"tentar_de_novo": 0, "dicas": [0, 0, 0], "habilidades": [],
			"modos": [], "ultima_vez": "",
		}
	return report[key]


func record_start(id: int) -> void:
	var e := _entry(id)
	e.iniciada += 1
	if not e.modos.has(mode):
		e.modos.append(mode)
	e.ultima_vez = Time.get_datetime_string_from_system(false, true)
	save_game()


func record_attempt(id: int, correct: bool) -> void:
	var e := _entry(id)
	e.tentativas += 1
	if correct:
		e.acertos += 1
	else:
		e.tentar_de_novo += 1
	save_game()


func record_hint(id: int, level: int) -> void:
	var e := _entry(id)
	var i := clampi(level - 1, 0, 2)
	e.dicas[i] = int(e.dicas[i]) + 1
	save_game()


func record_skill(id: int, skill: String) -> void:
	var e := _entry(id)
	if not e.habilidades.has(skill):
		e.habilidades.append(skill)
	save_game()


func complete_mission(id: int) -> void:
	var e := _entry(id)
	e.concluida += 1
	if not completed.has(id):
		completed.append(id)
		completed.sort()
	save_game()


func clear_report() -> void:
	report.clear()
	save_game()


func report_text() -> String:
	var lines: PackedStringArray = []
	lines.append("RELATÓRIO PEDAGÓGICO — Escola Conectada: Missão Rede")
	lines.append("Gerado em: %s" % Time.get_datetime_string_from_system(false, true))
	if student_name.strip_edges() != "":
		lines.append("Estudante: %s" % student_name)
	lines.append("Modo atual: %s" % ("Guiado" if is_guided() else "Explorador"))
	lines.append("Missões concluídas: %d de %d" % [completed.size(), MISSIONS.size()])
	lines.append("")
	for m in MISSIONS:
		var key := str(m.id)
		lines.append("Missão %d — %s (%s)" % [m.id, m.title, m.place])
		if not report.has(key):
			lines.append("  Ainda não iniciada.")
			lines.append("")
			continue
		var e: Dictionary = report[key]
		lines.append("  Conteúdos: %s" % m.topics)
		lines.append("  Vezes iniciada: %d | Vezes concluída: %d" % [e.iniciada, e.concluida])
		lines.append("  Tentativas: %d (acertos: %d, tentar de novo: %d)" % [e.tentativas, e.acertos, e.tentar_de_novo])
		lines.append("  Dicas usadas: nível 1 = %d, nível 2 = %d, nível 3 = %d" % [e.dicas[0], e.dicas[1], e.dicas[2]])
		lines.append("  Modos usados: %s" % ", ".join(PackedStringArray(e.modos)))
		lines.append("  Habilidades demonstradas:")
		if e.habilidades.is_empty():
			lines.append("    —")
		for h in e.habilidades:
			lines.append("    • %s" % h)
		lines.append("  Última vez: %s" % e.ultima_vez)
		lines.append("")
	lines.append("Observação: este relatório registra apenas ações no jogo.")
	lines.append("Ele não contém nem produz diagnóstico ou classificação do estudante.")
	return "\n".join(lines)


## Salva o relatório. No Windows abre a pasta; no navegador faz o download.
## Retorna uma mensagem curta para mostrar ao professor.
func export_report() -> String:
	var text := report_text()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), REPORT_FILE, "text/plain")
		return "Relatório baixado pelo navegador."
	var path := "user://" + REPORT_FILE
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return "Não foi possível salvar o relatório."
	f.store_string(text)
	f.close()
	var global := ProjectSettings.globalize_path(path)
	if not OS.has_feature("headless") and DisplayServer.get_name() != "headless":
		OS.shell_open(ProjectSettings.globalize_path("user://"))
	return "Relatório salvo em:\n" + global
