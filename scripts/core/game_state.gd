extends Node
## Estado global: jogadores (perfis), sessão, progresso, pontuação, configurações e relatórios.
## Tudo é salvo localmente (user://), sem internet. O "cadastro" é só nome + avatar, no próprio computador.

signal screen_requested(screen: String, params: Dictionary)
signal settings_changed

const CONFIG_PATH := "user://config.json"
const PROFILES_PATH := "user://jogadores.json"
const OLD_SAVE_PATH := "user://progresso.json"     # versão antiga (um jogador só)
const REPORT_FILE := "relatorio_pedagogico.txt"
const AVATAR_COUNT := 8

## Missões: andar 0 = térreo, 1 = primeiro andar. "dificuldade" cresce a cada missão.
const MISSIONS := [
	{"id": 1, "title": "A escola desconectada", "place": "Laboratório de Informática", "andar": 0,
		"script": "res://scripts/missions/mission_1.gd",
		"topics": "Topologias, meios de transmissão e equipamentos de rede"},
	{"id": 2, "title": "Cada computador tem seu endereço", "place": "Secretaria", "andar": 0,
		"script": "res://scripts/missions/mission_2.gd",
		"topics": "Endereçamento IPv4, máscara de rede e DHCP"},
	{"id": 3, "title": "O mistério da mensagem perdida", "place": "Biblioteca", "andar": 0,
		"script": "res://scripts/missions/mission_3.gd",
		"topics": "TCP/IP, protocolos, DNS e camadas de rede"},
	{"id": 4, "title": "O detetive das redes", "place": "Sala de Servidores", "andar": 0,
		"script": "res://scripts/missions/mission_4.gd",
		"topics": "Diagnóstico, conectividade, conflitos de IP e serviços"},
	{"id": 5, "title": "A escola inteligente", "place": "Sala de Aula Inteligente", "andar": 0,
		"script": "res://scripts/missions/mission_5.gd",
		"topics": "Wi-Fi, Internet das Coisas e comunicação entre dispositivos"},
	{"id": 6, "title": "Duas redes, um caminho", "place": "Sala dos Professores", "andar": 1,
		"script": "res://scripts/missions/mission_6.gd",
		"topics": "Roteador, redes diferentes e gateway padrão"},
	{"id": 7, "title": "O cabo perfeito", "place": "Oficina de Cabos", "andar": 1,
		"script": "res://scripts/missions/mission_7.gd",
		"topics": "Cabeamento estruturado, crimpagem T568B e testador de cabo"},
	{"id": 8, "title": "Escudo da escola", "place": "Sala da Direção", "andar": 1,
		"script": "res://scripts/missions/mission_8.gd",
		"topics": "Segurança: senha forte, firewall e portas, e-mail falso (phishing)"},
	{"id": 9, "title": "Dividir para organizar", "place": "Centro de Dados", "andar": 1,
		"script": "res://scripts/missions/mission_9.gd",
		"topics": "Sub-redes, máscara e prefixo (/24, /25, /27), quantidade de computadores"},
	{"id": 10, "title": "A grande Feira de Tecnologia", "place": "Auditório da Feira", "andar": 1,
		"script": "res://scripts/missions/mission_10.gd",
		"topics": "Projeto completo: topologia, DHCP, gateway, DNS, Wi-Fi e diagnóstico"},
	# ---- Temporada 2: A Central de Suporte (informática em geral)
	{"id": 11, "title": "Monte o computador", "place": "Oficina de Montagem", "andar": 0,
		"script": "res://scripts/missions/mission_11.gd",
		"topics": "Hardware: processador, memória RAM, armazenamento, fonte e suas funções"},
	{"id": 12, "title": "O computador não liga", "place": "Balcão de Atendimento", "andar": 0,
		"script": "res://scripts/missions/mission_12.gd",
		"topics": "Atendimento ao usuário, diagnóstico passo a passo e registro do chamado"},
	{"id": 13, "title": "Arquivos no lugar", "place": "Secretaria Digital", "andar": 0,
		"script": "res://scripts/missions/mission_13.gd",
		"topics": "Sistema operacional: pastas, extensões, caminho do arquivo e nomes claros"},
	{"id": 14, "title": "Instalar com segurança", "place": "Laboratório 2", "andar": 0,
		"script": "res://scripts/missions/mission_14.gd",
		"topics": "Requisitos de software, download seguro, instalação sem programas extras"},
	{"id": 15, "title": "Backup salva o dia", "place": "Sala de Projetos", "andar": 0,
		"script": "res://scripts/missions/mission_15.gd",
		"topics": "Cópia de segurança: o que guardar, onde guardar, backup automático e restauração"},
	{"id": 16, "title": "Programe o robô", "place": "Sala de Robótica", "andar": 1,
		"script": "res://scripts/missions/mission_16.gd",
		"topics": "Lógica de programação: sequência de comandos e repetição"},
	{"id": 17, "title": "Se... então", "place": "Laboratório de Programação", "andar": 1,
		"script": "res://scripts/missions/mission_17.gd",
		"topics": "Lógica de programação: condições SE/SENÃO e prever o resultado"},
	{"id": 18, "title": "Dados protegidos", "place": "Sala de Mídia", "andar": 1,
		"script": "res://scripts/missions/mission_18.gd",
		"topics": "Privacidade e LGPD, verificação em duas etapas, permissões de aplicativos"},
	{"id": 19, "title": "Planilha da feira", "place": "Tesouraria", "andar": 1,
		"script": "res://scripts/missions/mission_19.gd",
		"topics": "Planilha eletrônica: células, fórmulas, SOMA, copiar fórmula e gráficos"},
	{"id": 20, "title": "A Central de Suporte", "place": "Central de Suporte", "andar": 1,
		"script": "res://scripts/missions/mission_20.gd",
		"topics": "Missão final: prioridade de chamados e solução usando toda a temporada"},
]
const SEASON_NAMES := {1: "Temporada 1: Missão Rede", 2: "Temporada 2: A Central de Suporte"}
const SEASON_TITLES := {1: "Técnico de Redes", 2: "Técnico de Suporte em Informática"}
const PER_SEASON := 10

const MODE_GUIDED := "guiado"
const MODE_EXPLORER := "explorador"

# ---------------------------------------------------------------- jogador atual
var profile_id := ""
var student_name: String = ""
var avatar := 0
var mode: String = MODE_GUIDED
var completed: Array = []          # ids das missões concluídas
var seen_animations: Dictionary = {}
## Melhor pontuação de cada missão: {"3": {"pontos":, "estrelas":, "base":, "precisao":, "autonomia":, "explorador":, "data":}}
var scores: Dictionary = {}
## Relatório: chave = id da missão (String). Não guarda nenhum dado médico.
var report: Dictionary = {}
var created_at := ""

var settings := {
	"narracao": true,
	"volume": 0.8,
	"pular_animacoes": false,
	"texto_grande": false,
}

var _theme_builder := preload("res://scripts/ui/theme_builder.gd")
## Fonte em pixel Jersey 10 (licença OFL): números bem distintos, importante para ler IPs.
var ui_font: Font = preload("res://assets/fonts/Jersey10-Regular.woff")
var ui_font_bold: Font = ui_font


func _ready() -> void:
	_load_config()
	_migrate_old_save()
	var last := last_profile_id()
	if last != "":
		load_profile(last)
	apply_theme()


# ---------------------------------------------------------------- texto e tema
## Tamanho de texto do jogo: visual compacto por padrão; "Texto grande" aumenta tudo.
func fs(size: int) -> int:
	return int(round(size * text_scale()))


## A Jersey 10 é condensada: precisa de tamanho nominal maior que fontes comuns.
func text_scale() -> float:
	return 1.25 if settings.texto_grande else 0.98


func ui_scale() -> float:
	return 0.92 if settings.texto_grande else 0.7


func apply_theme() -> void:
	get_tree().root.theme = _theme_builder.build(settings.texto_grande)


func set_setting(key: String, value) -> void:
	settings[key] = value
	_save_config()
	if key == "texto_grande":
		apply_theme()
	settings_changed.emit()


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


## Temporada (1 ou 2) e nível (1 a 10) de uma missão.
func season_of(id: int) -> int:
	return 1 + (id - 1) / PER_SEASON


func level_of(id: int) -> int:
	return 1 + (id - 1) % PER_SEASON


func season_missions(season: int) -> Array:
	return MISSIONS.filter(func(m): return season_of(m.id) == season)


func is_unlocked(id: int) -> bool:
	return level_of(id) == 1 or is_completed(id - 1) or is_completed(id)


## Andar de cima de cada temporada abre depois do nível 5 dela.
func floor_unlocked(andar: int, season: int = 1) -> bool:
	return andar == 0 or is_completed((season - 1) * PER_SEASON + 5)


func season_completed(season: int) -> bool:
	for m in season_missions(season):
		if not is_completed(m.id):
			return false
	return true


func season_count(season: int) -> int:
	var n := 0
	for m in season_missions(season):
		if is_completed(m.id):
			n += 1
	return n


func all_completed() -> bool:
	return season_completed(1)


## Próxima missão não concluída (da temporada pedida; 0 = a temporada em que o jogador está).
func next_mission(season: int = 0) -> int:
	var seasons := [season] if season > 0 else [1, 2]
	for t in seasons:
		for m in season_missions(t):
			if not is_completed(m.id):
				return m.id
	return (season if season > 0 else 1) * PER_SEASON


func is_guided() -> bool:
	return mode == MODE_GUIDED


func avatar_sprite() -> String:
	return "avatar_%d" % avatar


# ---------------------------------------------------------------- perfis e sessão
func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())


func _write_json(path: String, data: Variant) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func _profiles_index() -> Dictionary:
	var d = _read_json(PROFILES_PATH)
	if typeof(d) != TYPE_DICTIONARY:
		d = {"ultimo": "", "lista": []}
	return d


## Lista de jogadores salvos neste computador: [{id, nome, avatar}] com resumo do progresso.
func list_profiles() -> Array:
	var out: Array = []
	for p in _profiles_index().lista:
		var data = _read_json(_profile_path(p.id))
		var info: Dictionary = p.duplicate()
		info["concluidas"] = (data.get("concluidas", []) as Array).size() if typeof(data) == TYPE_DICTIONARY else 0
		info["pontos"] = _sum_points(data.get("pontuacao", {})) if typeof(data) == TYPE_DICTIONARY else 0
		out.append(info)
	return out


func last_profile_id() -> String:
	return str(_profiles_index().get("ultimo", ""))


func _profile_path(id: String) -> String:
	return "user://jogador_%s.json" % id


func has_save() -> bool:
	return profile_id != ""


## Cria um jogador e já o deixa como atual.
func create_profile(p_name: String, p_avatar: int, p_mode: String) -> String:
	var idx := _profiles_index()
	var id := "%d%03d" % [int(Time.get_unix_time_from_system()), randi() % 1000]
	idx.lista.append({"id": id, "nome": p_name.strip_edges(), "avatar": p_avatar})
	idx.ultimo = id
	_write_json(PROFILES_PATH, idx)
	profile_id = id
	student_name = p_name.strip_edges()
	avatar = p_avatar
	mode = p_mode
	completed.clear()
	seen_animations.clear()
	scores.clear()
	report.clear()
	created_at = Time.get_datetime_string_from_system(false, true)
	save_game()
	return id


func load_profile(id: String) -> bool:
	var data = _read_json(_profile_path(id))
	if typeof(data) != TYPE_DICTIONARY:
		return false
	profile_id = id
	student_name = str(data.get("nome", "Jogador"))
	avatar = clampi(int(data.get("avatar", 0)), 0, AVATAR_COUNT - 1)
	mode = str(data.get("modo", MODE_GUIDED))
	completed.clear()
	for v in data.get("concluidas", []):
		completed.append(int(v))
	seen_animations = data.get("animacoes_vistas", {})
	scores = data.get("pontuacao", {})
	report = data.get("relatorio", {})
	created_at = str(data.get("criado", ""))
	var idx := _profiles_index()
	idx.ultimo = id
	_write_json(PROFILES_PATH, idx)
	return true


func delete_profile(id: String) -> void:
	var idx := _profiles_index()
	idx.lista = (idx.lista as Array).filter(func(p): return str(p.id) != id)
	if idx.ultimo == id:
		idx.ultimo = ""
	_write_json(PROFILES_PATH, idx)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_profile_path(id)))
	if profile_id == id:
		profile_id = ""


## Recomeça o progresso do jogador atual (ou cria um jogador de teste se não houver).
func new_game(new_mode: String) -> void:
	if profile_id == "":
		create_profile("Jogador", 0, new_mode)
		return
	mode = new_mode
	completed.clear()
	seen_animations.clear()
	scores.clear()
	save_game()


func save_game() -> void:
	if profile_id == "":
		return
	_write_json(_profile_path(profile_id), {
		"versao": 2,
		"nome": student_name,
		"avatar": avatar,
		"modo": mode,
		"concluidas": completed,
		"animacoes_vistas": seen_animations,
		"pontuacao": scores,
		"relatorio": report,
		"criado": created_at,
		"atualizado": Time.get_datetime_string_from_system(false, true),
	})
	# mantém o nome/avatar do índice em dia
	var idx := _profiles_index()
	for p in idx.lista:
		if str(p.id) == profile_id:
			p.nome = student_name
			p.avatar = avatar
	_write_json(PROFILES_PATH, idx)


func _load_config() -> void:
	var d = _read_json(CONFIG_PATH)
	if typeof(d) == TYPE_DICTIONARY:
		for k in d:
			settings[k] = d[k]


func _save_config() -> void:
	_write_json(CONFIG_PATH, settings)


## Converte o salvamento da versão com um jogador só em um perfil.
func _migrate_old_save() -> void:
	if FileAccess.file_exists(PROFILES_PATH) or not FileAccess.file_exists(OLD_SAVE_PATH):
		return
	var data = _read_json(OLD_SAVE_PATH)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var cfg: Dictionary = data.get("config", {})
	for k in cfg:
		settings[k] = cfg[k]
	_save_config()
	var nome := str(data.get("nome", "")).strip_edges()
	create_profile(nome if nome != "" else "Jogador", 0, str(data.get("modo", MODE_GUIDED)))
	for v in data.get("concluidas", []):
		completed.append(int(v))
	report = data.get("relatorio", {})
	save_game()


# ---------------------------------------------------------------- animações
func animation_seen(id: String) -> bool:
	return seen_animations.has(id)


func mark_animation_seen(id: String) -> void:
	if not seen_animations.has(id):
		seen_animations[id] = true
		save_game()


# ---------------------------------------------------------------- pontuação
## Pontos de uma missão. Nunca há pontos negativos: tentativas e dicas só diminuem o BÔNUS.
static func compute_score(id: int, retries: int, hints: int, explorer: bool, quiz_first_try: int) -> Dictionary:
	var base := 100 + 25 * (id - 1)                      # missões mais difíceis valem mais
	var precisao := maxi(0, 50 - 10 * retries)
	var autonomia := maxi(0, 30 - 10 * hints)
	var bonus_exp := (20 + 10 * quiz_first_try) if explorer else 0
	var estrelas := 1
	if precisao >= 30 and autonomia >= 20:
		estrelas = 3
	elif precisao >= 10 or autonomia >= 10:
		estrelas = 2
	return {"base": base, "precisao": precisao, "autonomia": autonomia, "explorador": bonus_exp,
		"pontos": base + precisao + autonomia + bonus_exp, "estrelas": estrelas}


## Guarda a pontuação se for a melhor do jogador nesta missão. Retorna true se for recorde.
func record_score(id: int, detail: Dictionary) -> bool:
	var key := str(id)
	var best: Dictionary = scores.get(key, {})
	var record := best.is_empty() or int(detail.pontos) > int(best.get("pontos", 0))
	if record:
		var d := detail.duplicate()
		d["data"] = Time.get_datetime_string_from_system(false, true)
		d["modo"] = mode
		scores[key] = d
		save_game()
	return record


func mission_points(id: int) -> int:
	return int(scores.get(str(id), {}).get("pontos", 0))


func mission_stars(id: int) -> int:
	return int(scores.get(str(id), {}).get("estrelas", 1 if is_completed(id) else 0))


static func _sum_points(sc: Dictionary) -> int:
	var t := 0
	for k in sc:
		t += int(sc[k].get("pontos", 0))
	return t


func total_points() -> int:
	return _sum_points(scores)


func total_stars() -> int:
	var t := 0
	for m in MISSIONS:
		t += mission_stars(m.id)
	return t


# ---------------------------------------------------------------- relatório (dados por missão)
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
	lines.append("Estudante: %s" % (student_name if student_name != "" else "—"))
	lines.append("Modo atual: %s" % ("Guiado" if is_guided() else "Explorador"))
	lines.append("Missões concluídas: %d de %d" % [completed.size(), MISSIONS.size()])
	lines.append("Pontuação total: %d pontos | Estrelas: %d de %d" % [total_points(), total_stars(), MISSIONS.size() * 3])
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
		lines.append("  Melhor pontuação: %d pontos, %d estrela(s)" % [mission_points(m.id), mission_stars(m.id)])
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


## Salva um arquivo para o usuário: no Windows grava em user:// e abre a pasta; no navegador baixa.
func save_user_file(file_name: String, bytes: PackedByteArray, mime: String) -> String:
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(bytes, file_name, mime)
		return "Arquivo baixado pelo navegador: " + file_name
	var dir := "user://relatorios"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := dir + "/" + file_name
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return "Não foi possível salvar o arquivo."
	f.store_buffer(bytes)
	f.close()
	if DisplayServer.get_name() != "headless":
		OS.shell_open(ProjectSettings.globalize_path(dir))
	return "Arquivo salvo em:\n" + ProjectSettings.globalize_path(path)


func export_report() -> String:
	return save_user_file(safe_file_name("relatorio_pedagogico") + ".txt", report_text().to_utf8_buffer(), "text/plain")


## Nome de arquivo com o nome do jogador e a data, sem acentos nem espaços.
func safe_file_name(prefix: String) -> String:
	var n := student_name.to_lower().strip_edges()
	var from := "áàâãäéèêëíìîïóòôõöúùûüçñ"
	var to := "aaaaaeeeeiiiiooooouuuucn"
	var out := ""
	for ch in n:
		var i := from.find(ch)
		var c2: String = to[i] if i >= 0 else ch
		out += c2 if (c2 >= "a" and c2 <= "z") or (c2 >= "0" and c2 <= "9") else "_"
	var d := Time.get_date_dict_from_system()
	return "%s_%s_%04d-%02d-%02d" % [prefix, out if out != "" else "jogador", d.year, d.month, d.day]
