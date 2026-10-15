extends Node
## Owns the current screen, centres it in the window and does the crayon scribble wipe
## between screens.

var current: Node2D = null
var switching := false
var _wipe: Control
var _wipe_layer: CanvasLayer
var _wipe_amt := 0.0
var _wipe_drawn := 0.0


func _ready() -> void:
	Game.main = self
	_wipe_layer = CanvasLayer.new()
	_wipe_layer.layer = 90
	add_child(_wipe_layer)
	_wipe = Control.new()
	_wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wipe_layer.add_child(_wipe)
	_wipe.draw.connect(_draw_wipe)
	get_viewport().size_changed.connect(_layout)
	RenderingServer.set_default_clear_color(Crayon.PAPER)
	_open("title", null)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest") and ResourceLoader.exists("res://tests/autotest.gd"):
			add_child(load("res://tests/autotest.gd").new())
		elif a.begins_with("--bot") and ResourceLoader.exists("res://tests/bot.gd"):
			add_child(load("res://tests/bot.gd").new())


func switch_to(screen: String, arg: Variant = null) -> void:
	if switching:
		return
	switching = true
	_wipe.mouse_filter = Control.MOUSE_FILTER_STOP
	Audio.sfx("scribble", -6)
	var tw := create_tween()
	tw.tween_property(self, "_wipe_amt", 1.0, 0.35)
	await tw.finished
	Narrator.cancel()
	_open(screen, arg)
	var tw2 := create_tween()
	tw2.tween_property(self, "_wipe_amt", 0.0, 0.35)
	await tw2.finished
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	switching = false


func _open(screen: String, arg: Variant) -> void:
	if current:
		current.queue_free()
		current = null
	Crayon.shake = 1.0
	Narrator.top = false
	var path: String
	if screen == "game":
		path = Game.GAMES[int(arg)].script
	else:
		path = Game.SCREENS[screen]
	var s: Node2D = load(path).new()
	s.set("arg", arg)
	current = s
	add_child(s)
	move_child(s, 0)
	_layout()


func _layout() -> void:
	if current == null:
		return
	var vs := get_viewport().get_visible_rect().size
	current.position = ((vs - Vector2(1280, 720)) * 0.5).floor()


func _process(_dt: float) -> void:
	if _wipe_amt != _wipe_drawn or switching:
		_wipe.queue_redraw()


func _draw_wipe() -> void:
	_wipe_drawn = _wipe_amt
	if _wipe_amt <= 0.0:
		return
	var vs := _wipe.get_viewport_rect().size
	var rows := 9
	var rh := vs.y / rows
	for i in rows:
		var f := clampf(_wipe_amt * 1.6 - float(i) / rows * 0.6, 0.0, 1.0)
		if f <= 0.0:
			continue
		var y := (i + 0.5) * rh
		var col: Color = Crayon.RAINBOW[i % Crayon.RAINBOW.size()]
		var pts := PackedVector2Array()
		var x_end := -40.0 + (vs.x + 80.0) * f
		var x := -40.0
		var k := 0
		while x < x_end:
			pts.append(Vector2(x, y + (rh * 0.75 if k % 2 == 0 else -rh * 0.75) + Crayon.rnd(i * 31 + k) * 10))
			x += 46.0
			k += 1
		pts.append(Vector2(x_end, y))
		if pts.size() >= 2:
			_wipe.draw_polyline(pts, col, rh * 0.95, true)
	if _wipe_amt > 0.9:
		_wipe.draw_rect(Rect2(Vector2.ZERO, vs), Color(Crayon.PAPER, (_wipe_amt - 0.9) * 10.0))
