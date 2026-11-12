extends Node
## Efeitos sonoros gerados por código (não precisa de arquivos de áudio).

var _players: Array[AudioStreamPlayer] = []
var _sounds := {}
var _next := 0


func _ready() -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_sounds["click"] = _make([[880.0, 0.04]], 0.20)
	_sounds["select"] = _make([[660.0, 0.05], [990.0, 0.05]], 0.22)
	_sounds["connect"] = _make([[330.0, 0.05], [660.0, 0.08]], 0.30)
	_sounds["ok"] = _make([[660.0, 0.09], [880.0, 0.09], [1320.0, 0.18]], 0.32)
	_sounds["retry"] = _make([[440.0, 0.12], [392.0, 0.20]], 0.28)
	_sounds["packet"] = _make([[1200.0, 0.03], [1500.0, 0.03]], 0.15)
	_sounds["win"] = _make([[523.0, 0.11], [659.0, 0.11], [784.0, 0.11], [1046.0, 0.40]], 0.34)
	_sounds["alert"] = _make([[740.0, 0.12], [0.0, 0.06], [740.0, 0.12]], 0.28)


func play(sound: String) -> void:
	if not _sounds.has(sound):
		return
	var vol: float = float(Game.settings.volume)
	if vol <= 0.01:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[sound]
	p.volume_db = linear_to_db(vol)
	p.play()


func _make(notes: Array, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var data := PackedByteArray()
	for n in notes:
		var freq: float = n[0]
		var count := int(rate * float(n[1]))
		for i in count:
			var t := float(i) / rate
			var attack := minf(1.0, float(i) / (rate * 0.006))
			var env := attack * (1.0 - float(i) / count)
			var s := 0.0
			if freq > 0.0:
				s = sin(TAU * freq * t) * 0.8 + sin(TAU * freq * 2.0 * t) * 0.12
			var v := int(clampf(s * env * amp, -1.0, 1.0) * 32767.0)
			data.append(v & 0xFF)
			data.append((v >> 8) & 0xFF)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w
