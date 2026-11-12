class_name ScreenBase
extends Control
## Utilidades comuns às telas de menu.


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	build()


func build() -> void:
	pass


func background(col: Color = Palette.BG_DARK) -> void:
	var bg := ColorRect.new()
	bg.color = col
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)


## Painel centralizado com uma coluna (VBox) dentro.
func centered_column(width: float = 640.0) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var win := UiWindow.create("", width * 0.75)
	center.add_child(win.root)
	return win.body


func heading(parent: Control, text: String, size: int = 34, col: Color = Palette.PRIMARY_DARK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


func text(parent: Control, t: String, size: int = 0) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


func button(parent: Control, t: String, icon: String, cb: Callable, variant: String = "primary", h: float = 76.0) -> BigButton:
	var b := BigButton.new(t, icon, variant, h)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
