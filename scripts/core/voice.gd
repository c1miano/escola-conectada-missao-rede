extends Node
## Narração opcional usando a voz do sistema (texto para fala, funciona offline no Windows).

var last_text := ""
var _voice_id := ""


func available() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)


func _pick_voice() -> void:
	if not available() or _voice_id != "":
		return
	var pt := DisplayServer.tts_get_voices_for_language("pt")
	if pt.size() > 0:
		# Prefere português do Brasil quando houver.
		for v in DisplayServer.tts_get_voices():
			if str(v.get("language", "")).to_lower().begins_with("pt_br") or str(v.get("language", "")).to_lower().begins_with("pt-br"):
				_voice_id = v.id
				return
		_voice_id = pt[0]


## Guarda o texto para "Ouvir de novo" e fala se a narração estiver ligada.
func say(text: String) -> void:
	last_text = text
	if Game.settings.narracao:
		speak(text)


func speak(text: String) -> void:
	if not available() or text.strip_edges() == "":
		return
	_pick_voice()
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(_clean(text), _voice_id, int(clampf(Game.settings.volume, 0.0, 1.0) * 100.0))


func repeat() -> void:
	speak(last_text)


func stop() -> void:
	if available():
		DisplayServer.tts_stop()


func _clean(text: String) -> String:
	# Quebras de linha viram espaços para a voz não fazer pausas estranhas.
	return text.replace("\n", " ")
