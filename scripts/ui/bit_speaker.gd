class_name BitSpeaker
extends Control
## Bit como assistente inteligente (tipo Alexa) em cima de uma mesinha, dentro da sala.
## O anel de luz pulsa quando ele fala e pisca colorido quando o jogador acerta.
## Clicar no Bit repete a última instrução.

const SCALE := 3

var mood := "normal":
	set(v):
		mood = v
		queue_redraw()
var _talk := 0.0        # segundos restantes "falando"
var _party := 0.0       # segundos de comemoração
var _t := 0.0
var _hop := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(16, 34) * SCALE
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Bit: clique para ouvir de novo"


func talk(text: String) -> void:
	_talk = clampf(text.length() / 14.0, 1.2, 6.0)


func celebrate() -> void:
	mood = "feliz"
	_party = 1.4
	var t := create_tween()
	t.tween_property(self, "_hop", 1.0, 0.12)
	t.tween_property(self, "_hop", 0.0, 0.18)
	t.tween_property(self, "_hop", 1.0, 0.12)
	t.tween_property(self, "_hop", 0.0, 0.18)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		Voice.repeat()
		talk(Voice.last_text)


func _process(delta: float) -> void:
	_t += delta
	_talk = maxf(0.0, _talk - delta)
	_party = maxf(0.0, _party - delta)
	queue_redraw()


func _draw() -> void:
	var table_y := 18.0 * SCALE
	Sprites.draw(self, "mesinha", Vector2(0, table_y), SCALE)
	var lit := _party > 0.0 or (_talk > 0.0 and fmod(_t, 0.5) < 0.3)
	var name := "bit_caixa_%s%s" % [mood, "" if lit else "_apagado"]
	var hop: float = -round(_hop * 2.0) * SCALE
	Sprites.draw(self, name, Vector2(0, hop), SCALE)
	if _party > 0.0:
		# anel colorido girando (comemoração)
		var cols := [Palette.STAR, Palette.LED_ON, Color("#f29aa0"), Palette.SCREEN_ON]
		for i in 4:
			var a := _t * 8.0 + i * PI / 2.0
			var p := Vector2(8 * SCALE + cos(a) * 5.5 * SCALE, 4 * SCALE + hop + sin(a) * 2.2 * SCALE)
			draw_rect(Rect2(p - Vector2(SCALE, SCALE), Vector2(SCALE * 2, SCALE * 2)), cols[i])
