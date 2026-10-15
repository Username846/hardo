extends Screen
## Present 1: CAKE TOWER (stacking game). Tap to drop each layer. Build it up to the sky...
## where something with a big round face would also like a slice.

const IDX := 0
const GOAL := 15
const LH := 42.0
const BASE_Y := 640.0
const HOVER_Y := 210.0
const MIN_W := 70.0
const PASTEL := [Color(0.98, 0.6, 0.75), Color(1.0, 0.88, 0.45), Color(0.6, 0.9, 0.7), Color(0.75, 0.65, 0.95),
	Color(1.0, 0.72, 0.5), Color(0.55, 0.78, 1.0), Color(0.98, 0.6, 0.75), Color(0.95, 0.95, 0.95)]

var layers: Array = []          # {x, w, col}
var debris: Array = []          # {pos, size, vel, rot, spin, col}
var cur_w := 320.0
var cur_x := 640.0
var phase := 0.0
var speed := 1.6
var falling := false
var fall_t := 0.0
var fall_from_y := 0.0
var cam := 0.0
var perfect := 0
var started := false
var ended := false
var candles := 0.0
var moon_open := 0.0
var misses := 0
var said := {}


func enter() -> void:
	_ensure_layers()
	Narrator.top = true
	Audio.play_music("cake")
	layers.append({"x": 640.0, "w": 360.0, "col": Color(0.9, 0.9, 0.95), "plate": true})
	_intro()


func _intro() -> void:
	locked = true
	await wait(0.4)
	await say("Present number one! A birthday cake! Tap to drop each layer. Let's make the tallest cake ever!")
	started = true
	locked = false


func _top() -> Dictionary:
	return layers[layers.size() - 1]


func _layer_y(i: int) -> float:
	# top edge of layer i in world space (layer 0 is the plate)
	return BASE_Y - i * LH


func press(_p: Vector2) -> void:
	if not started or falling or ended:
		return
	falling = true
	fall_t = 0.0
	fall_from_y = HOVER_Y - cam
	Audio.sfx("whoosh", -8)


func _land() -> void:
	falling = false
	var top := _top()
	var l1 := cur_x - cur_w * 0.5
	var r1 := cur_x + cur_w * 0.5
	var l2: float = top.x - top.w * 0.5
	var r2: float = top.x + top.w * 0.5
	var ol := maxf(l1, l2)
	var orr := minf(r1, r2)
	var y := _layer_y(layers.size())
	var col: Color = _layer_color(layers.size())
	if orr - ol <= 0.0:
		# complete miss: the layer splats on the floor. No biggie.
		debris.append({"pos": Vector2(cur_x, y), "size": Vector2(cur_w, LH), "vel": Vector2(randf_range(-80, 80), 0), "rot": 0.0, "spin": randf_range(-3, 3), "col": col})
		Audio.sfx("splat", -4)
		misses += 1
		if misses % 3 == 1:
			say_bg("Oopsie! Try again!")
		return
	var off := absf(cur_x - top.x)
	var nx := (ol + orr) * 0.5
	var nw := orr - ol
	if off < 9.0:
		nx = top.x
		nw = minf(top.w + 12.0, 360.0) if layers.size() > 1 else cur_w
		perfect += 1
		Audio.sfx("ding", -2)
		confetti_burst(Vector2(nx, y + cam), 18)
	else:
		Audio.sfx("thud", -3, 1.3)
		# trimmed bit falls off
		if l1 < ol:
			debris.append({"pos": Vector2((l1 + ol) * 0.5, y), "size": Vector2(ol - l1, LH), "vel": Vector2(-120, -60), "rot": 0.0, "spin": -2.5, "col": col})
		if r1 > orr:
			debris.append({"pos": Vector2((orr + r1) * 0.5, y), "size": Vector2(r1 - orr, LH), "vel": Vector2(120, -60), "rot": 0.0, "spin": 2.5, "col": col})
	if nw < MIN_W:
		nw = MIN_W
	layers.append({"x": nx, "w": nw, "col": col, "seed": layers.size() * 17})
	cur_w = nw
	speed = minf(1.6 + layers.size() * 0.09, 3.0)
	_milestone(layers.size() - 1)


func _layer_color(i: int) -> Color:
	if i <= 8:
		return PASTEL[(i - 1) % PASTEL.size()]
	var f := clampf((i - 8) / 7.0, 0.0, 1.0)
	return Color(0.55, 0.33, 0.2).lerp(Color(0.12, 0.06, 0.08), f)


func _milestone(n: int) -> void:
	match n:
		3:
			say_bg("Yummy! Higher!")
		5:
			say_bg("Everyone is going to love this cake!")
		8:
			Audio.play_music("cake_dark", 2.5)
			say_bg("Higher, Chumbo. Higher than the clouds.", Narrator.DARK)
		10:
			say_bg("Those are raisins. Don't worry. They're definitely raisins.", Narrator.DARK)
		12:
			say_bg("The moon wants a slice.", Narrator.DARK)
		14:
			say_bg("One more layer. Someone is waiting at the top.", Narrator.DARK)
		GOAL:
			_ending()


func _ending() -> void:
	ended = true
	locked = true
	await wait(1.0)
	var tw := create_tween()
	tw.tween_property(self, "candles", 1.0, 3.0)
	for i in 8:
		Audio.sfx("pop", -6, 1.0 + i * 0.1)
		await wait(0.35)
	await say("Look at all those candles. How old are you, really?", Narrator.DARK)
	var tw2 := create_tween()
	tw2.tween_property(self, "moon_open", 1.0, 1.0)
	Audio.sfx("gulp", 0, 0.6)
	await wait(1.2)
	await say("Present number one, done! What a yummy cake!")
	finish_game(IDX, "CAKE DONE!")


func tick(dt: float) -> void:
	if not falling:
		phase += dt * speed
		cur_x = 640.0 + sin(phase) * (440.0 - cur_w * 0.25)
	var want := maxf(0.0, (layers.size() - 1) * LH - 180.0)
	if ended:
		want = maxf(0.0, (layers.size() - 1) * LH - 120.0)
	cam = lerpf(cam, want, minf(1.0, dt * 3.0))
	world.position.y = cam
	if layers.size() != _drawn_layers:
		_drawn_layers = layers.size()
		_refresh_static()
	if falling:
		fall_t += dt
		if fall_t >= 0.22:
			_land()
	for d in debris:
		d.vel.y += 1400.0 * dt
		d.pos += d.vel * dt
		d.rot += d.spin * dt
	debris = debris.filter(func(d): return d.pos.y + cam < H + 300)
	Crayon.shake = 1.0 + clampf((layers.size() - 8) / 7.0, 0.0, 1.0) * 0.8


func _sky(h: float) -> Color:
	var stops := [Color(0.62, 0.84, 1.0), Color(0.7, 0.88, 1.0), Color(1.0, 0.7, 0.45), Color(0.45, 0.25, 0.5), Color(0.06, 0.05, 0.16)]
	var f := clampf(h, 0.0, 1.0) * (stops.size() - 1)
	var i := mini(int(f), stops.size() - 2)
	return (stops[i] as Color).lerp(stops[i + 1], f - i)


## Static layers: the sky (screen space) and the world (scrolls with the camera as a node,
## so the tower is only redrawn when a layer lands).
var world: Node2D = null


func _ensure_layers() -> void:
	if world:
		return
	use_back_layer()
	world = Node2D.new()
	world.show_behind_parent = true
	add_child(world)
	move_child(world, 1)
	world.draw.connect(_draw_world)


func _refresh_static() -> void:
	refresh_back()
	if world:
		world.queue_redraw()


func paint_back() -> void:
	var h := (layers.size() - 1) / float(GOAL)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), _sky(h))
	if h > 0.55:
		var a := clampf((h - 0.55) * 3.0, 0.0, 1.0)
		for i in 30:
			var sp := Vector2(fmod(i * 173.0, W), fmod(i * 97.0, 420.0))
			Crayon.star(pen, sp, 6 + (i % 3) * 2, Color(1, 1, 0.8, a), Color(1, 0.95, 0.5, a), 900 + i)


func _draw_world() -> void:
	var t0 := Time.get_ticks_usec()
	pen = world
	Crayon.freeze(true)
	for i in 4:
		var wy := BASE_Y - (5 + i * 2.2) * LH
		Crayon.cloud(pen, Vector2(180 + i * 300 + sin(i * 1.7) * 30, wy), 70, Color(1, 1, 1, 0.9), 50 + i)
	var gy := BASE_Y + LH
	pen.draw_rect(Rect2(-2000, gy, W + 4000, 2000), Color(0.45, 0.75, 0.4))
	Crayon.line(pen, Vector2(-40, gy), Vector2(W + 40, gy), Crayon.INK, 5, 70)
	for i in layers.size():
		_draw_layer(i, layers[i], _layer_y(i), false)
	Crayon.freeze(false)
	pen = self
	Perf.draw_us += Time.get_ticks_usec() - t0


func paint() -> void:
	var h := (layers.size() - 1) / float(GOAL)
	# the moon (with a face) near the top
	var moon_y := BASE_Y - (GOAL + 3.5) * LH + cam
	if moon_y > -200:
		var mc := Vector2(980, moon_y)
		Crayon.circle(pen, mc, 90, Crayon.INK, 5, Color(1, 0.98, 0.8), 60)
		var look := (Vector2(cur_x, HOVER_Y) - mc).normalized()
		Crayon.face(pen, mc, 80, "o" if moon_open > 0.5 else ("wide" if h > 0.8 else "smirk"), look, 61)
	# "raisins" that watch the moving layer
	for i in range(10, layers.size()):
		_raisins(i, layers[i], _layer_y(i) + cam)
	# candles on top at the end
	if candles > 0.0:
		var top := _top()
		var n := int(candles * 40)
		var ty := _layer_y(layers.size() - 1) + cam
		for k in n:
			var cx: float = top.x - top.w * 0.5 + 8 + fmod(k * 37.0, maxf(top.w - 16, 1))
			var hgt := 30.0 + (k % 5) * 6
			var r := Rect2(cx - 4, ty - hgt - (k / 8) * 12.0, 8, hgt)
			Crayon.rect(pen, r, Crayon.INK, 2, Crayon.RAINBOW[k % 7], 1200 + k)
			Crayon.flame(pen, Vector2(cx, r.position.y - 8), 7, 1300 + k)
		var count: String = ["1", "2", "3", "10", "50", "99", "999", "TOO MANY"][mini(int(candles * 7.99), 7)]
		Crayon.text(pen, Vector2(W * 0.5, 150), "CANDLES: " + count, 56, Crayon.WHITE, 1, 1400, Crayon.title_font())
	# moving layer
	if started and not ended:
		var y := HOVER_Y
		if falling:
			var target := _layer_y(layers.size()) + cam
			y = lerpf(HOVER_Y, target, clampf(fall_t / 0.22, 0, 1) ** 2)
		_draw_layer(layers.size(), {"x": cur_x, "w": cur_w, "col": _layer_color(layers.size()), "seed": 999}, y, true)
		if not falling:
			Crayon.line(pen, Vector2(cur_x, y + LH + 8), Vector2(cur_x, y + LH + 40), Color(1, 1, 1, 0.6), 3, 998, 0.5)
	for d in debris:
		var c := Vector2(d.pos.x, d.pos.y + cam + LH * 0.5)
		pen.draw_set_transform(c, d.rot, Vector2.ONE)
		Crayon.rect(pen, Rect2(-d.size * 0.5, d.size), Crayon.INK, 3, d.col, 1500)
		pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


var _drawn_layers := -1


func paint_top() -> void:
	if started and not ended:
		var ink := Crayon.INK if layers.size() < 9 else Crayon.WHITE
		hud("LAYERS: %d / %d" % [layers.size() - 1, GOAL], ink)
		if perfect > 0:
			Crayon.text(pen, Vector2(W - 24, 88), "PERFECT x%d" % perfect, 28, Crayon.YELLOW if layers.size() >= 9 else Crayon.ORANGE, 2, 4243)
		if layers.size() == 1 and not falling:
			Crayon.text(pen, Vector2(W * 0.5, 140), "TAP TO DROP!", 48, Crayon.RED, 1, 4244, Crayon.title_font())


func _draw_layer(i: int, l: Dictionary, y: float, with_eyes: bool) -> void:
	var w: float = l.w
	var x: float = l.x
	var r := Rect2(x - w * 0.5, y, w, LH)
	if l.has("plate"):
		Crayon.rect(pen, Rect2(x - w * 0.5 - 20, y + 10, w + 40, 18), Crayon.INK, 4, Crayon.WHITE, 3)
		Crayon.line(pen, Vector2(x, y + 28), Vector2(x, y + LH + 2), Crayon.INK, 8, 4)
		return
	var col: Color = l.col
	var sd: int = l.get("seed", i * 17)
	Crayon.rect(pen, r, Crayon.INK, 4, col, sd)
	# frosting drips
	var frost := Crayon.WHITE if i < 9 else Color(0.35, 0.15, 0.2)
	Crayon.poly(pen, Crayon.icing(r, sd), Crayon.INK, 2.5, frost, sd + 5)
	if i < 9:
		for k in int(w / 30.0):
			var sp := Vector2(r.position.x + 12 + fmod(k * 29.0 + i * 7, w - 20), y + 18 + fmod(k * 13.0, LH - 24))
			Crayon.line(pen, sp, sp + Vector2(6, 3 - (k % 3) * 3), Crayon.RAINBOW[(k + i) % 7], 4, sd + 40 + k, 0.2)
	elif i >= 10 and with_eyes:
		_raisins(i, l, y)


func _raisins(i: int, l: Dictionary, y: float) -> void:
	var w: float = l.w
	var x: float = l.x
	var r := Rect2(x - w * 0.5, y, w, LH)
	var sd: int = l.get("seed", i * 17)
	for k in maxi(1, int(w / 70.0)):
		var e := Vector2(r.position.x + 30 + k * 60, y + LH * 0.6)
		if e.x > r.end.x - 20:
			break
		var blink := fmod(t * 0.7 + k * 1.3 + i, 4.0) < 0.15
		if blink:
			Crayon.line(pen, e - Vector2(8, 0), e + Vector2(8, 0), Crayon.BLACK, 3, sd + 60 + k, 0.3)
		else:
			pen.draw_circle(e, 9, Color(0.95, 0.92, 0.85))
			var look := (Vector2(cur_x, HOVER_Y) - e).normalized()
			pen.draw_circle(e + look * 4.0, 4.5, Crayon.BLACK)
