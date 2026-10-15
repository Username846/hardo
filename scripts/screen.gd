class_name Screen
extends Node2D
## Base class for every screen and mini-game. Logical canvas is 1280x720; the main scene
## centres it on wider/taller windows and backgrounds paint past the edges.

const W := 1280.0
const H := 720.0

var t := 0.0
var arg: Variant = null
var bg := Crayon.PAPER
var buttons: Array = []
var hover_id := ""
var locked := false
var show_home := true
var mouse := Vector2(W * 0.5, H * 0.5)
var _down := false
## The canvas the paint helpers draw onto: this node normally, the static layer inside
## paint_back(). Screens use `pen` instead of `self` so drawing code works in both.
var pen: CanvasItem = self
var _back: Node2D = null
## When true (and a back layer is used) buttons are drawn into the static layer and only
## hover/press highlights are drawn per frame. Call refresh_back() after changing buttons.
var bake_buttons := false
## Where the lyric ticker sits (y in the 1280x720 space); < 0 hides it on this screen.
var lyrics_y := 690.0


func _ready() -> void:
	if show_home:
		add_button("home", Rect2(14, 12, 74, 64), "", go_home, Crayon.WHITE)
	enter()


## Override: set things up and start scripted sequences.
func enter() -> void:
	pass


## Override: per-frame logic.
func tick(_dt: float) -> void:
	pass


## Override: draw the screen.
func paint() -> void:
	pass


## Override: drawn on top of the buttons.
func paint_top() -> void:
	pass


## Override: static scenery. Only drawn when use_back_layer() was called, and redrawn
## only when refresh_back() is called, so put everything here that does not move.
func paint_back() -> void:
	pass


## Creates the static scenery layer (call from enter()). The scenery is rendered once into
## a texture ("baked") and shown as a single picture, so it costs almost nothing per frame.
func use_back_layer() -> void:
	if _back:
		return
	_bake = SubViewport.new()
	_bake.disable_3d = true
	_bake.transparent_bg = false
	_bake.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_bake)
	_back = Node2D.new()
	_bake.add_child(_back)
	_back.draw.connect(_draw_back)
	_bake_sprite = Sprite2D.new()
	_bake_sprite.centered = false
	_bake_sprite.show_behind_parent = true
	_bake_sprite.texture = _bake.get_texture()
	add_child(_bake_sprite)
	move_child(_bake_sprite, 0)
	_layout_back()


## Redraws the static layer on the next frame (call when the scenery changes).
func refresh_back() -> void:
	if _back:
		_bake.render_target_update_mode = SubViewport.UPDATE_ONCE
		_back.queue_redraw()


var _bake: SubViewport = null
var _bake_sprite: Sprite2D = null
var _baked_pos := Vector2(INF, INF)
var _baked_vs := Vector2.ZERO


func _layout_back() -> void:
	var vs := get_viewport_rect().size
	var px := Vector2(get_window().size)
	var sc := clampf(px.x / maxf(vs.x, 1.0), 0.25, 4.0)
	_baked_pos = position
	_baked_vs = vs
	_bake.size = Vector2i(maxi(16, ceili(vs.x * sc)), maxi(16, ceili(vs.y * sc)))
	_bake.size_2d_override = Vector2i(ceili(vs.x), ceili(vs.y))
	_bake.size_2d_override_stretch = true
	_back.position = position
	_bake_sprite.position = -position
	_bake_sprite.scale = Vector2(ceili(vs.x), ceili(vs.y)) / Vector2(_bake.size)
	refresh_back()


func _draw_back() -> void:
	var t0 := Time.get_ticks_usec()
	pen = _back
	Crayon.freeze(true)
	_back.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), bg)
	paint_back()
	if bake_buttons:
		for b in buttons:
			if b.visible:
				_draw_button(b, b.rect)
	Crayon.freeze(false)
	pen = self
	Perf.draw_us += Time.get_ticks_usec() - t0


## Override: pointer callbacks (positions are in the 1280x720 space).
func press(_p: Vector2) -> void:
	pass


func release(_p: Vector2) -> void:
	pass


func drag(_p: Vector2) -> void:
	pass


func go_home() -> void:
	Game.back_to_party()


func _process(dt: float) -> void:
	t += dt
	if _bake and (position != _baked_pos or get_viewport_rect().size != _baked_vs):
		_layout_back()
	tick(dt)
	queue_redraw()


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	if _back == null:
		draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), bg)
	paint()
	_draw_buttons()
	paint_top()
	if finished:
		_draw_finished()
	Perf.draw_us += Time.get_ticks_usec() - t0


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var p := to_local(e.position)
		mouse = p
		if e.pressed:
			_down = true
			if _press_button(p):
				get_viewport().set_input_as_handled()
				return
			if not locked:
				press(p)
		else:
			_down = false
			if not locked:
				release(p)
	elif e is InputEventMouseMotion:
		var p := to_local(e.position)
		mouse = p
		hover_id = ""
		for b in buttons:
			if b.visible and b.rect.has_point(p):
				hover_id = b.id
		if _down and not locked:
			drag(p)


# ------------------------------------------------------------------ buttons


func add_button(id: String, r: Rect2, label: String, cb: Callable, col: Color = Crayon.YELLOW, size: int = 34) -> Dictionary:
	var b := {"id": id, "rect": r, "label": label, "cb": cb, "col": col, "visible": true, "size": size, "pop": 0.0, "seed": buttons.size() * 41 + 7}
	buttons.append(b)
	return b


func get_button(id: String) -> Dictionary:
	for b in buttons:
		if b.id == id:
			return b
	return {}


func remove_button(id: String) -> void:
	for i in range(buttons.size() - 1, -1, -1):
		if buttons[i].id == id:
			buttons.remove_at(i)


func _press_button(p: Vector2) -> bool:
	for i in range(buttons.size() - 1, -1, -1):
		var b: Dictionary = buttons[i]
		if not b.visible or not b.rect.grow(6).has_point(p):
			continue
		if locked and not (b.id == "home" or b.id == "done"):
			return true
		b.pop = 1.0
		Audio.sfx("click", -4)
		b.cb.call()
		return true
	return false


func _draw_buttons() -> void:
	var dt := get_process_delta_time()
	for b in buttons:
		if not b.visible:
			continue
		if b.pop > 0.0:
			b.pop = maxf(0.0, b.pop - dt * 5.0)
		var r: Rect2 = b.rect
		if bake_buttons and _back:
			# the button itself is baked; just light it up when touched
			if b.pop > 0.0:
				pen.draw_rect(r.grow(-3), Color(1, 1, 0.4, 0.55 * b.pop))
			elif hover_id == b.id:
				pen.draw_rect(r.grow(-3), Color(1, 1, 1, 0.25))
			continue
		var grow: float = (3.0 if hover_id == b.id else 0.0) - b.pop * 6.0
		_draw_button(b, r.grow(grow))


func _draw_button(b: Dictionary, r: Rect2) -> void:
	Crayon.rect(pen, r, Crayon.INK, 5, b.col, b.seed)
	if b.id == "home":
		Crayon.house(pen, r.get_center() + Vector2(0, 2), 44, 3)
	elif b.label != "":
		var fs: int = b.size
		Crayon.text(pen, r.get_center() + Vector2(0, -2), b.label, fs, Crayon.INK, 1, b.seed, null, 1.0, false)


# ------------------------------------------------------------------ helpers

var finished := false
var _finish_t := 0.0
var _finish_msg := ""


## Marks this present as opened and shows the "back to the party" button
## (idx -1 = not one of the ten presents).
func finish_game(idx: int, msg: String = "PRESENT DONE!") -> void:
	if finished:
		return
	if idx >= 0:
		Game.complete(idx)
	finished = true
	_finish_msg = msg
	_finish_t = Time.get_ticks_msec() * 0.001
	locked = true
	Audio.sfx("tada")
	Audio.sfx("cheer", -6)
	confetti_burst(Vector2(W * 0.5, 160), 70)
	add_button("done", Rect2(W * 0.5 - 220, H * 0.5 + 40, 440, 84), "back to the party!", Game.back_to_party, Crayon.GREEN, 40)


func _draw_finished() -> void:
	var k := clampf((Time.get_ticks_msec() * 0.001 - _finish_t) * 3.0, 0.0, 1.0)
	var r := Rect2(W * 0.5 - 330, H * 0.5 - 150 - (1.0 - k) * 300, 660, 300)
	Crayon.rect(self, r, Crayon.INK, 7, Color(1, 0.97, 0.75), 4444)
	Crayon.text(self, Vector2(W * 0.5, r.position.y + 70), _finish_msg, 64, Crayon.RED, 1, 4445, Crayon.title_font())
	for i in 5:
		Crayon.star(self, Vector2(W * 0.5 - 160 + i * 80, r.position.y + 140), 26, Crayon.INK, Crayon.YELLOW, 4450 + i)
	# the button is drawn by _draw_buttons, so draw a copy on top of the banner
	var b := get_button("done")
	if not b.is_empty():
		Crayon.rect(self, b.rect, Crayon.INK, 5, b.col, b.seed)
		Crayon.text(self, b.rect.get_center(), b.label, 40, Crayon.INK, 1, b.seed, null, 1.0, false)



## Waits without surviving the screen (if the screen is freed the coroutine just stops).
func wait(sec: float) -> void:
	var tm := Timer.new()
	tm.one_shot = true
	add_child(tm)
	tm.start(maxf(sec, 0.001))
	await tm.timeout
	tm.queue_free()


## Shows a narration line and waits until it is finished (tap to continue when blocking).
func say(text: String, mood: int = Narrator.CUTE, blocking: bool = true) -> void:
	var tk := Node.new()
	tk.add_user_signal("done")
	add_child(tk)
	Narrator.show_line(text, mood, blocking, tk)
	await Signal(tk, "done")
	tk.queue_free()


## Fire-and-forget subtitle that does not stop gameplay.
func say_bg(text: String, mood: int = Narrator.CUTE) -> void:
	say(text, mood, false)


func paper_bg(col: Color = Crayon.PAPER) -> void:
	bg = col


func title_text(p: Vector2, s: String, size: int = 64, col: Color = Crayon.INK, sd: int = 0) -> void:
	Crayon.text(pen, p, s, size, col, 1, sd, Crayon.title_font())


## Draws the little scoreboard / progress label top-right.
func hud(label: String, col: Color = Crayon.INK, y: float = 44.0) -> void:
	if Narrator.top and Narrator.is_active():
		y += 120.0
	Crayon.text(self, Vector2(W - 24, y), label, 34, col, 2, 4242)


func confetti_burst(at: Vector2, n: int = 40) -> void:
	var c := Confetti.new()
	c.position = at
	c.count = n
	add_child(c)


class Confetti extends Node2D:
	var count := 40
	var bits: Array = []
	var age := 0.0

	func _ready() -> void:
		z_index = 20
		for i in count:
			var a := randf() * TAU
			var sp := randf_range(200, 650)
			bits.append({"p": Vector2.ZERO, "v": Vector2(cos(a), sin(a) - 0.8) * sp, "c": Crayon.RAINBOW[i % Crayon.RAINBOW.size()], "r": randf() * TAU, "s": randf_range(6, 12)})

	func _process(dt: float) -> void:
		age += dt
		for b in bits:
			b.v.y += 900 * dt
			b.p += b.v * dt
			b.r += dt * 8
		queue_redraw()
		if age > 2.5:
			queue_free()

	func _draw() -> void:
		for b in bits:
			var d: Vector2 = Vector2(cos(b.r), sin(b.r)) * b.s
			draw_line(b.p - d, b.p + d, b.c, 5.0, true)
