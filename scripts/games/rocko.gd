extends Screen
## SECRET (tap the cake after the credits): ???
## Chumbo closes the birthday game on his phone and chills on the couch. His cat Rocko comes
## over for pets. Rocko would like Chumbo to go back to his party. Rocko insists. RUN!
## Chase: a three-lane street runner - tap above or below Chumbo to change lanes and dodge.

const LANES := [470.0, 565.0, 660.0]
const ME_X := 640.0
const RUN_TIME := 70.0
const HIP := Vector2(450, 472)
const CAT_SEAT := Vector2(660, 458)
const DOOR := Rect2(1070, 190, 150, 370)
const PHONE := Rect2(770, 70, 290, 470)
const TILE := Vector2(1280, 330)
const TILE_Y := 80.0

var phase := "intro"
var phone_k := 0.0
var screen_off := 0.0
var cat_pos := Vector2(1400, 560)
var cat_face := -1.0
var cat_pose := "walk"
var cat_hop := 0.0
var bubble := ""
var bubble_t := 0.0
var pets := 0
var pet_t := 0.0
var hearts: Array = []
var demon := 0.0
var grow := 1.0
var lamp := 1.0
var flicker := 0.0
var quake := 0.0
var black := 0.0
var me_pos := HIP
var me_mood := "happy"
var me_pose := "sit"
var door_open := 0.0

# the chase
var lane := 1
var me_y := 565.0
var dist := 0.0
var speed := 0.0
var scroll := 0.0
var obstacles: Array = []
var throws: Array = []
var spawn_t := 1.0
var throw_t := 6.0
var gap := 3
var rocko_x := -300.0
var rocko_y := 565.0
var hurt := 0.0
var safe_t := 0.0
var pops: Array = []
var said := {}
var party_tile := -1
var house_x := INF
var guests_out := 0.0
var run_ph := 0.0
var _tiles: Array[Texture2D] = []
var _q := Vector2.ZERO

var LINES := [
	["Come back, Chumbo! The cake is getting cold!", Narrator.ROCKO],
	["Why does every house have balloons now?", Narrator.DARK],
	["Everybody is waiting for you, Chumbo.", Narrator.ROCKO],
	["Don't look at the guests. Keep running.", Narrator.DARK],
	["You can't run away from your birthday!", Narrator.ROCKO],
	["Look! A house! Hide in there!", Narrator.DARK],
]
## How far down the street (0..1) each of the LINES is said.
const LINE_AT := [0.1, 0.28, 0.45, 0.6, 0.78, 0.92]


func enter() -> void:
	use_back_layer()
	Audio.play_music("rocko")
	Audio.preload_music("hub")
	_run()


func _chasing() -> bool:
	return phase in ["chase_intro", "chase", "caught", "arrive", "knock_wait", "knock", "party"]


# ------------------------------------------------------------------ the couch


func _run() -> void:
	locked = true
	await wait(0.6)
	await say("The party is over. Chumbo is home on his comfy couch, playing a game on his phone.")
	phase = "phone"
	_tw("phone_k", 1.0, 0.45)
	await wait(0.5)
	await say("That's enough birthday for today. Tap the X to close the game.")
	locked = false


func _x_rect() -> Rect2:
	var sc := _phone_screen()
	return Rect2(sc.end.x - 58, sc.position.y + 12, 46, 46)


func _phone_screen() -> Rect2:
	var r := PHONE.grow(-22)
	r.position.y += 30
	r.size.y -= 60
	return r


func _close_phone() -> void:
	phase = "closing"
	locked = true
	Audio.sfx("slide_down")
	_tw("screen_off", 1.0, 0.4)
	await wait(0.9)
	_tw("phone_k", 0.0, 0.35)
	await wait(0.5)
	phase = "rest"
	await say("Ahh. Finally. Peace and quiet.", Narrator.CHUMBO)
	await wait(0.3)
	# here comes Rocko
	phase = "cat"
	Audio.sfx("meow_small", -6)
	var tw := create_tween()
	tw.tween_property(self, "cat_pos", Vector2(930, 560), 2.4)
	await wait(2.5)
	cat_pose = "sit"
	_meow("Meow!")
	await wait(1.0)
	await say("Oh hi Rocko!", Narrator.CHUMBO)
	# hop up onto the couch
	cat_pose = "walk"
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(self, "cat_pos", CAT_SEAT, 0.55)
	tw2.tween_method(func(k: float) -> void: cat_hop = sin(k * PI) * 90.0, 0.0, 1.0, 0.55)
	Audio.sfx("boing", -10, 1.4)
	await wait(0.6)
	cat_pose = "sit"
	await say("Rocko wants pets! Tap Rocko to pet him.")
	phase = "pets"
	locked = false


func _meow(s: String, small: bool = false) -> void:
	bubble = s
	bubble_t = 1.6
	if s.begins_with("Meow"):
		Audio.sfx("meow_small" if small else "meow", -2, randf_range(0.95, 1.08))


func _cat_rect() -> Rect2:
	return Rect2(cat_pos + Vector2(-60, -130), Vector2(120, 140))


func _pet() -> void:
	pets += 1
	pet_t = 0.7
	hearts.append({"p": cat_pos + Vector2(randf_range(-30, 30), -110), "t": 0.0, "s": randi() % 100})
	Audio.sfx("purr", -4, randf_range(0.95, 1.05))
	if pets == 2:
		_meow("Prrrr...")
	elif pets == 4:
		_meow("Meow!", true)
	if pets >= 6:
		phase = "turn"
		_turn()


func _turn() -> void:
	locked = true
	await wait(1.0)
	_meow("...")
	Audio.stop_music(0.3)
	await wait(1.2)
	Audio.sfx("switch")
	flicker = 1.4
	_tw("lamp", 0.2, 1.2)
	await wait(1.2)
	Audio.sfx("meow_demon")
	Audio.sfx("storm", -6)
	quake = 1.0
	me_mood = "o"
	_tw("demon", 1.0, 2.4)
	_tw("grow", 2.1, 2.4)
	await say("Rocko? Why is Rocko getting bigger?", Narrator.DARK)
	await wait(0.4)
	await say("You closed the party, Chumbo.", Narrator.ROCKO)
	await say("Nobody leaves the party.", Narrator.ROCKO)
	Audio.sfx("hiss")
	await say("Nope! Nope nope nope!", Narrator.CHUMBO)
	# out the door!
	phase = "flee"
	me_pose = "run"
	me_pos = Vector2(HIP.x + 30, 560)
	Audio.sfx("run")
	var tw := create_tween()
	tw.tween_property(self, "me_pos", Vector2(DOOR.get_center().x, 560), 1.0)
	await wait(0.45)
	Audio.sfx("creak")
	_tw("door_open", 1.0, 0.3)
	await wait(0.7)
	_tw("black", 1.0, 0.35)
	await wait(0.45)
	_start_chase()
	me_mood = "o"
	_tw("black", 0.0, 0.5)
	await wait(0.3)
	await say("Run, Chumbo! Tap above or below Chumbo to dodge everything!", Narrator.DARK)
	phase = "chase"
	locked = false


func _tw(prop: String, to: float, sec: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, prop, to, sec)


# ------------------------------------------------------------------ the chase


func _start_chase() -> void:
	phase = "chase_intro"
	Narrator.top = true
	lyrics_y = 34.0
	refresh_back()
	_make_tiles()
	Audio.play_music("rocko_dark", 0.4)
	me_pose = "run"
	me_mood = "o"
	door_open = 0.0
	lane = 1
	me_y = LANES[1]
	rocko_y = me_y
	rocko_x = -300.0
	speed = 330.0
	demon = 1.0
	grow = 1.9


func _make_tiles() -> void:
	if not _tiles.is_empty():
		return
	var px := Vector2(get_window().size)
	var sc := clampf(px.x / maxf(get_viewport_rect().size.x, 1.0), 1.0, 2.0)
	for v in 2:
		var vp := SubViewport.new()
		vp.disable_3d = true
		vp.transparent_bg = true
		vp.size = Vector2i(ceili(TILE.x * sc), ceili(TILE.y * sc))
		vp.size_2d_override = Vector2i(TILE)
		vp.size_2d_override_stretch = true
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		var n := Node2D.new()
		vp.add_child(n)
		n.draw.connect(_draw_tile.bind(n, v))
		add_child(vp)
		_tiles.append(vp.get_texture())


func press(p: Vector2) -> void:
	match phase:
		"phone":
			if _x_rect().grow(16).has_point(p):
				_close_phone()
		"pets":
			if _cat_rect().grow(20).has_point(p):
				_pet()
		"chase", "chase_intro":
			if p.y < me_y - 70.0:
				_move(-1)
			elif p.y > me_y + 10.0:
				_move(1)
		"knock":
			if _house_door().grow(40).has_point(p) or p.x > ME_X:
				_party()


func drag(p: Vector2) -> void:
	# swiping up/down also works
	if phase == "chase" or phase == "chase_intro":
		var target := 0
		var best := INF
		for i in 3:
			var d := absf(p.y - (LANES[i] - 50.0))
			if d < best:
				best = d
				target = i
		if target != lane and absf(p.y - (LANES[lane] - 50.0)) > 70.0:
			_move(signi(target - lane))


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (phase == "chase" or phase == "chase_intro"):
		if e.keycode in [KEY_UP, KEY_W]:
			_move(-1)
		elif e.keycode in [KEY_DOWN, KEY_S]:
			_move(1)


func _move(d: int) -> void:
	var nl := clampi(lane + d, 0, 2)
	if nl != lane:
		lane = nl
		Audio.sfx("whoosh", -12, 1.4)


func tick(dt: float) -> void:
	flicker = maxf(0.0, flicker - dt)
	quake = maxf(0.0, quake - dt * 0.5)
	bubble_t = maxf(0.0, bubble_t - dt)
	pet_t = maxf(0.0, pet_t - dt)
	for h in hearts:
		h.t += dt
	hearts = hearts.filter(func(h: Dictionary) -> bool: return h.t < 1.4)
	for pp in pops:
		pp.t -= dt
	pops = pops.filter(func(pp: Dictionary) -> bool: return pp.t > 0.0)
	if phase == "cat" and cat_pose == "walk":
		cat_face = -1.0
	if not _chasing():
		return
	run_ph += dt * (speed / 330.0) * 11.0
	scroll += speed * dt
	me_y = move_toward(me_y, LANES[lane], 1300.0 * dt)
	hurt = maxf(0.0, hurt - dt)
	# Rocko lags behind (further when you're doing well) and follows your lane
	var target_x := ME_X - 150.0 - gap * 125.0
	if phase == "caught":
		target_x = ME_X - 70.0
	elif phase in ["arrive", "knock_wait", "knock", "party"]:
		target_x = 300.0
	rocko_x = move_toward(rocko_x, target_x, (260.0 if phase != "chase_intro" else 420.0) * dt)
	rocko_y = lerpf(rocko_y, LANES[1] if phase in ["knock_wait", "knock", "party"] else me_y, minf(1.0, dt * 2.5))
	for o in obstacles:
		o.x -= speed * dt
	obstacles = obstacles.filter(func(o: Dictionary) -> bool: return o.x > -200.0)
	if house_x < INF:
		house_x -= speed * dt
	if phase == "chase":
		_chase_tick(dt)
	elif phase == "arrive":
		if house_x <= ME_X + 250.0:
			speed = move_toward(speed, 0.0, 900.0 * dt)
			lane = 0
			if speed <= 0.0:
				phase = "knock_wait"
				_knock()
	_update_throws(dt)


func _chase_tick(dt: float) -> void:
	dist += dt
	var k := clampf(dist / RUN_TIME, 0.0, 1.0)
	speed = lerpf(340.0, 540.0, k)
	if k >= 0.28 and party_tile < 0:
		party_tile = floori(scroll * 0.55 / TILE.x) + 2
	for i in LINES.size():
		if k >= LINE_AT[i] and not said.has(i):
			said[i] = true
			say_bg(LINES[i][0], LINES[i][1])
	# new things in the road
	spawn_t -= dt
	if spawn_t <= 0.0 and dist < RUN_TIME - 3.0:
		spawn_t = lerpf(1.3, 0.7, k) * randf_range(0.85, 1.15)
		_spawn(k)
	throw_t -= dt
	if throw_t <= 0.0 and k > 0.2 and dist < RUN_TIME - 3.0:
		throw_t = lerpf(7.5, 4.0, k) * randf_range(0.8, 1.2)
		throws.append({"lane": lane, "t": 0.0, "dur": 1.25, "from": Vector2(rocko_x + 80, rocko_y - 160)})
		Audio.sfx("throw", -4)
		if not said.has("throw"):
			said["throw"] = true
			say_bg("Rocko is throwing cake! Move!", Narrator.DARK)
	# bumping into things
	if hurt <= 0.0 and absf(me_y - LANES[lane]) < 30.0:
		for o in obstacles:
			if o.hit or int(o.lane) != lane:
				continue
			var w := 52.0 if o.kind == "puddle" else 40.0
			if absf(float(o.x) - ME_X) < w:
				o.hit = true
				_hit(o.kind)
				break
	if hurt <= 0.0:
		safe_t += dt
		if safe_t > 8.0 and gap < 3:
			safe_t = 0.0
			gap += 1
			pops.append({"p": Vector2(rocko_x + 40, rocko_y - 230), "t": 1.2, "s": "you're getting away!", "c": Crayon.GREEN})
	if dist >= RUN_TIME:
		_arrive()


func _spawn(k: float) -> void:
	var kinds := ["can", "cone", "puddle"]
	if k > 0.25:
		kinds += ["present", "balloons"]
	if k > 0.5:
		kinds += ["guest", "guest", "guest"]
	var free := randi() % 3
	var n := 1 if k < 0.35 or randf() < 0.45 else 2
	var lanes: Array = [0, 1, 2]
	lanes.erase(free)
	lanes.shuffle()
	for i in n:
		var li: int = lanes[i]
		var kind: String = kinds[randi() % kinds.size()]
		if li == 0 and randf() < 0.35:
			kind = "hydrant"
		obstacles.append({"x": W + 90.0 + i * randf_range(0, 60), "lane": li, "kind": kind, "hit": false, "s": randi() % 997})


func _update_throws(dt: float) -> void:
	for th in throws:
		th.t += dt
		if th.t >= th.dur and not th.has("done"):
			th.done = true
			Audio.sfx("splat", -2)
			obstacles.append({"x": ME_X, "lane": th.lane, "kind": "splat", "hit": true, "s": 1})
			if phase == "chase" and int(th.lane) == lane and hurt <= 0.0:
				_hit("cake")
	throws = throws.filter(func(th: Dictionary) -> bool: return not th.has("done"))


func _hit(kind: String) -> void:
	hurt = 1.3
	safe_t = 0.0
	gap -= 1
	quake = 0.35
	Audio.sfx("splash" if kind == "puddle" else ("splat" if kind == "cake" else "bonk"), -2)
	Audio.sfx("oof", -4)
	var words := ["OOF!", "OUCH!", "WHOA!", "AAH!"]
	pops.append({"p": Vector2(ME_X, me_y - 190), "t": 1.0, "s": words[randi() % words.size()], "c": Crayon.RED})
	if kind == "guest":
		say_bg("Join us, Chumbo.", Narrator.CREEPY)
	if gap <= 0:
		_caught()


func _caught() -> void:
	phase = "caught"
	locked = true
	var tw := create_tween()
	tw.tween_property(self, "speed", 0.0, 0.6)
	Audio.sfx("meow_demon")
	quake = 0.8
	await wait(0.8)
	obstacles.clear()
	throws.clear()
	await say("Rocko caught you! He's dragging you back to the party!", Narrator.DARK)
	_tw("black", 0.85, 0.3)
	await wait(0.6)
	_tw("black", 0.0, 0.3)
	await say("Wait, you wiggled free! Run, Chumbo, run!")
	gap = 2
	hurt = 1.5
	dist = maxf(0.0, dist - RUN_TIME * 0.06)
	spawn_t = 1.5
	phase = "chase"
	locked = false


# ------------------------------------------------------------------ the end of the street


func _arrive() -> void:
	phase = "arrive"
	house_x = W + 360.0


func _house_door() -> Rect2:
	return Rect2(house_x - 48, 298, 96, 122)


func _knock() -> void:
	locked = true
	_tw("demon", 0.0, 2.0)
	_tw("grow", 1.15, 2.0)
	me_mood = "o"
	await say("You made it to a house! Quick, knock on the door!")
	phase = "knock"
	locked = false


func _party() -> void:
	phase = "party"
	locked = true
	Audio.sfx("thud", -2)
	await wait(0.35)
	Audio.sfx("thud", -2)
	await wait(0.5)
	Audio.sfx("creak")
	_tw("door_open", 1.0, 0.4)
	await wait(0.4)
	Audio.sfx("surprise")
	Audio.sfx("tada", -3)
	Audio.play_music("hub", 0.6)
	_tw("guests_out", 1.0, 0.6)
	confetti_burst(Vector2(house_x, 300), 60)
	me_mood = "o"
	await say("SURPRISE! Happy birthday, Chumbo!")
	await say("Rocko brought you back to your party. Good kitty.", Narrator.DARK)
	_meow("Meow.")
	await say("Meow.", Narrator.ROCKO)
	me_mood = "happy"
	await say("Oh hi, everyone.", Narrator.CHUMBO)
	Game.secret_done = true
	Game.save_game()
	finish_game(-1, "SECRET FOUND!")


# ------------------------------------------------------------------ drawing


func paint_back() -> void:
	if _chasing() or phase == "chase_intro":
		_street_back()
		return
	# the living room
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, 2560), Color(0.93, 0.84, 0.7))
	pen.draw_rect(Rect2(-2000, 560, W + 4000, 2000), Color(0.68, 0.48, 0.3))
	Crayon.line(pen, Vector2(-40, 560), Vector2(W + 40, 560), Crayon.INK, 5, 1)
	for i in 9:
		Crayon.line(pen, Vector2(-40 + i * 170, 560), Vector2(-90 + i * 170, 720), Color(0.55, 0.37, 0.22), 3, 2 + i)
	# wallpaper stripes
	for i in 16:
		pen.draw_rect(Rect2(i * 84 + 20, 0, 14, 556), Color(0.9, 0.8, 0.66))
	# window (night)
	var wr := Rect2(70, 110, 230, 190)
	Crayon.rect(pen, wr, Crayon.INK, 6, Color(0.1, 0.1, 0.28), 20)
	Crayon.circle(pen, wr.position + Vector2(160, 60), 24, Crayon.INK, 3, Color(1, 1, 0.85), 21)
	for i in 6:
		Crayon.star(pen, wr.position + Vector2(30 + i * 33, 40 + (i % 3) * 40), 6, Color(1, 1, 0.7), Color(1, 1, 0.7), 22 + i)
	Crayon.line(pen, wr.position + Vector2(wr.size.x * 0.5, 0), wr.position + Vector2(wr.size.x * 0.5, wr.size.y), Crayon.INK, 5, 30)
	Crayon.line(pen, wr.position + Vector2(0, wr.size.y * 0.5), wr.position + Vector2(wr.size.x, wr.size.y * 0.5), Crayon.INK, 5, 31)
	# picture of a cake (of course)
	var pr := Rect2(420, 92, 150, 112)
	Crayon.rect(pen, pr, Crayon.BROWN, 7, Crayon.WHITE, 40)
	Crayon.cake(pen, pr.position + Vector2(75, 92), 80, 40, Crayon.PINK, 3, true, 41)
	# the front door
	Crayon.rect(pen, DOOR, Crayon.INK, 6, Color(0.55, 0.32, 0.2), 50)
	Crayon.rect(pen, DOOR.grow(-22), Color(0.4, 0.22, 0.12), 3, Color(0, 0, 0, 0), 51)
	Crayon.circle(pen, Vector2(DOOR.position.x + 26, DOOR.get_center().y + 10), 9, Crayon.INK, 3, Crayon.YELLOW, 52)
	# rug
	Crayon.ellipse(pen, Vector2(570, 640), Vector2(330, 52), Crayon.INK, 4, Color(0.85, 0.35, 0.4), 60)
	Crayon.ellipse(pen, Vector2(570, 640), Vector2(250, 32), Color(0.95, 0.75, 0.4), 4, Color(0, 0, 0, 0), 61)
	# couch
	var cc := Color(0.3, 0.45, 0.75)
	Crayon.rect(pen, Rect2(285, 320, 590, 140), Crayon.INK, 6, cc, 70)
	Crayon.rect(pen, Rect2(300, 330, 280, 115), cc.darkened(0.15), 3, Color(0, 0, 0, 0), 71)
	Crayon.rect(pen, Rect2(580, 330, 280, 115), cc.darkened(0.15), 3, Color(0, 0, 0, 0), 72)
	Crayon.rect(pen, Rect2(285, 450, 590, 78), Crayon.INK, 6, cc.lightened(0.1), 73)
	Crayon.rect(pen, Rect2(235, 370, 72, 170), Crayon.INK, 6, cc.darkened(0.1), 74)
	Crayon.rect(pen, Rect2(853, 370, 72, 170), Crayon.INK, 6, cc.darkened(0.1), 75)
	Crayon.line(pen, Vector2(270, 538), Vector2(262, 562), Crayon.INK, 7, 76)
	Crayon.line(pen, Vector2(890, 538), Vector2(898, 562), Crayon.INK, 7, 77)
	# lamp pole (the shade and light are drawn on top)
	Crayon.line(pen, Vector2(960, 560), Vector2(960, 250), Crayon.INK, 6, 80)
	Crayon.ellipse(pen, Vector2(960, 560), Vector2(36, 10), Crayon.INK, 4, Crayon.GREY, 81)


func _street_back() -> void:
	var sky := Color(0.06, 0.05, 0.16)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, 2420), sky)
	for i in 5:
		pen.draw_rect(Rect2(-2000, 300 + i * 22, W + 4000, 22), sky.lerp(Color(0.25, 0.12, 0.3), (i + 1) / 6.0))
	Crayon.circle(pen, Vector2(1080, 70), 34, Crayon.INK, 3, Color(1, 1, 0.85), 3)
	for i in 14:
		Crayon.star(pen, Vector2(fmod(i * 211.0, W), 20 + fmod(i * 97.0, 160)), 5, Color(1, 1, 0.7), Color(1, 1, 0.7), 10 + i)
	# sidewalk and road
	pen.draw_rect(Rect2(-2000, 410, W + 4000, 108), Color(0.62, 0.6, 0.62))
	pen.draw_rect(Rect2(-2000, 518, W + 4000, 2000), Color(0.24, 0.23, 0.27))
	Crayon.line(pen, Vector2(-40, 410), Vector2(W + 40, 410), Crayon.INK, 4, 30)
	Crayon.line(pen, Vector2(-40, 518), Vector2(W + 40, 518), Crayon.INK, 5, 31)
	pen.draw_rect(Rect2(-2000, 518, W + 4000, 8), Color(0.78, 0.76, 0.78))


func _draw_tile(n: Node2D, variant: int) -> void:
	Crayon.freeze(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var base := 330.0
	var cols := [Color(0.9, 0.55, 0.45), Color(0.55, 0.7, 0.9), Color(0.95, 0.85, 0.5), Color(0.6, 0.82, 0.6), Color(0.8, 0.65, 0.9)]
	var x := 30.0
	for h in 4:
		var w := rng.randf_range(210, 255)
		var hh := rng.randf_range(140, 185)
		var col: Color = cols[(h + 1) % cols.size()].darkened(0.35)
		var body := Rect2(x, base - hh, w, hh)
		Crayon.rect(n, body, Crayon.INK, 5, col, 100 + h * 10)
		Crayon.poly(n, PackedVector2Array([Vector2(x - 16, base - hh), Vector2(x + w + 16, base - hh), Vector2(x + w * 0.5, base - hh - 72)]),
			Crayon.INK, 5, Color(0.45, 0.18, 0.18), 101 + h * 10)
		var door := Rect2(x + w * 0.5 - 24, base - 78, 48, 78)
		Crayon.rect(n, door, Crayon.INK, 4, Color(0.35, 0.2, 0.12), 102 + h * 10)
		for side in 2:
			var win := Rect2(x + 22 + side * (w - 92), base - hh + 30, 50, 44)
			Crayon.rect(n, win, Crayon.INK, 4, Color(1, 0.88, 0.45), 103 + h * 10 + side)
			if variant == 1 and (h + side) % 2 == 0:
				# someone at the window, watching
				var c := win.get_center() + Vector2(0, 8)
				Crayon.disc(n, c, 15, Color(0.15, 0.1, 0.12))
				Crayon.disc(n, c + Vector2(-5, -3), 3, Color(1, 1, 1))
				Crayon.disc(n, c + Vector2(5, -3), 3, Color(1, 1, 1))
				Crayon.party_hat(n, c + Vector2(0, -12), 10, Crayon.RAINBOW[(h + side) % 7], 140 + h)
		Crayon.circle(n, Vector2(x + 14, base - 14), 22, Crayon.INK, 3, Color(0.2, 0.45, 0.25), 105 + h * 10)
		if variant == 1:
			# balloons by the door and a banner on the roof
			for b in 2:
				var bp := Vector2(door.position.x - 26 + b * 100, base - 120 - b * 12)
				Crayon.balloon(n, bp, 18, Crayon.RAINBOW[(h * 2 + b) % 7], 90, 150 + h * 3 + b)
			var by := base - hh - 8
			Crayon.rect(n, Rect2(x + 10, by - 30, w - 20, 32), Crayon.INK, 3, Crayon.WHITE, 160 + h)
			Crayon.text(n, Vector2(x + w * 0.5, by - 14), "HAPPY BIRTHDAY", 20, Crayon.RED, 1, 170 + h, null, 0.3, false)
			Crayon.party_hat(n, Vector2(x + w * 0.5, base - hh - 70), 22, Crayon.PINK, 180 + h)
		# street light
		var lx := x + w + 28
		Crayon.line(n, Vector2(lx, base + 6), Vector2(lx, base - 200), Crayon.INK, 5, 190 + h)
		Crayon.line(n, Vector2(lx, base - 200), Vector2(lx + 26, base - 206), Crayon.INK, 5, 195 + h)
		Crayon.disc(n, Vector2(lx + 30, base - 196), 26, Color(1, 0.95, 0.6, 0.25))
		Crayon.circle(n, Vector2(lx + 30, base - 200), 9, Crayon.INK, 3, Color(1, 0.95, 0.6), 200 + h)
		x += w + rng.randf_range(62, 82)
	Crayon.freeze(false)


func paint() -> void:
	var q := quake * 9.0
	_q = Vector2(randf_range(-q, q), randf_range(-q, q)) if quake > 0.0 else Vector2.ZERO
	pen.draw_set_transform(_q)
	if _chasing():
		_paint_chase()
	else:
		_paint_room()
	pen.draw_set_transform(Vector2.ZERO)
	if black > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0, 0, 0, black))


func _paint_room() -> void:
	# lamp light
	var lit := lamp
	if flicker > 0.0 and fmod(t * 13.0, 1.0) < 0.5:
		lit *= 0.3
	if lit > 0.05:
		Crayon.oval(pen, Vector2(960, 300), Vector2(150, 130), Color(1, 0.95, 0.6, 0.18 * lit))
	Crayon.poly(pen, PackedVector2Array([Vector2(915, 205), Vector2(1005, 205), Vector2(1030, 262), Vector2(890, 262)]),
		Crayon.INK, 4, Color(1, 0.85, 0.45).lerp(Color(0.4, 0.3, 0.2), 1.0 - lit), 82)
	# door swings open
	if door_open > 0.0:
		var dr := DOOR
		pen.draw_rect(dr, Color(0.05, 0.04, 0.12))
		Crayon.rect(pen, Rect2(dr.position, Vector2(dr.size.x * (1.0 - door_open * 0.8), dr.size.y)), Crayon.INK, 5, Color(0.55, 0.32, 0.2), 53)
	# characters (Rocko walks in front of the couch, then sits on it)
	var cat_feet := cat_pos + Vector2(0, -cat_hop)
	var cat_front := cat_pos.y > 500.0
	if not cat_front:
		_rocko_room(cat_feet)
	if me_pose == "sit":
		_chumbo_sitting(me_pos)
	else:
		_runner(pen, me_pos, run_ph + t * 14.0, me_mood, 1.0)
	if cat_front:
		_rocko_room(cat_feet)
	for h in hearts:
		var k: float = h.t / 1.4
		Crayon.heart(pen, h.p + Vector2(sin(h.t * 6.0) * 8, -k * 90), 16 * (1.0 - k * 0.4), Crayon.INK, Crayon.PINK, int(h.s))
	if bubble_t > 0.0 and bubble != "":
		var bp := cat_feet + Vector2(-20, -150 * grow)
		var r := Rect2(bp - Vector2(80, 30), Vector2(160, 54))
		Crayon.rect(pen, r, Crayon.INK, 4, Crayon.WHITE, 90)
		Crayon.poly(pen, PackedVector2Array([r.end - Vector2(40, 2), r.end - Vector2(70, 2), cat_feet + Vector2(-6, -112 * grow)]), Crayon.INK, 3, Crayon.WHITE, 91)
		Crayon.text(pen, r.get_center(), bubble, 30, Crayon.INK, 1, 92)
	# the room goes red when Rocko turns
	if demon > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.35, 0.0, 0.05, demon * 0.35))
	if lamp < 1.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.02, 0.0, 0.06, (1.0 - lamp) * 0.4))
	if demon > 0.2:
		# eyes glow through the dark
		var head := cat_feet + Vector2(8 * cat_face, -78) * grow
		for sx in [-1.0, 1.0]:
			Crayon.disc(pen, head + Vector2(sx * 9.0, -4) * grow, 7 * grow * demon, Color(1, 0.45, 0.1, 0.6 * demon))
	if phase == "phone" or phase == "closing" or phone_k > 0.0:
		_phone()


func _rocko_room(feet: Vector2) -> void:
	var pose := cat_pose
	if pose == "sit" and pet_t > 0.0:
		pose = "pet"
	draw_cat(pen, feet, grow, cat_face, pose, demon, t, _q)


func _chumbo_sitting(hip: Vector2) -> void:
	var neck := hip + Vector2(0, -88)
	var head := hip + Vector2(0, -122)
	# legs hang over the seat
	for sx in [-1.0, 1.0]:
		Crayon.line(pen, hip + Vector2(sx * 14, 0), hip + Vector2(sx * 26, 30), Crayon.INK, 7, 300 + int(sx))
		Crayon.line(pen, hip + Vector2(sx * 26, 30), hip + Vector2(sx * 30, 86), Crayon.INK, 7, 302 + int(sx))
		Crayon.ellipse(pen, hip + Vector2(sx * 38, 88), Vector2(14, 7), Crayon.INK, 3, Crayon.INK, 304 + int(sx))
	# green shirt
	Crayon.poly(pen, PackedVector2Array([neck + Vector2(-26, 4), neck + Vector2(26, 4), hip + Vector2(22, 2), hip + Vector2(-22, 2)]),
		Crayon.INK, 5, Crayon.GREEN, 306)
	var hand_l := hip + Vector2(-18, -48)
	var hand_r := hip + Vector2(18, -48)
	if phase == "pets" or pet_t > 0.0:
		# petting Rocko
		var cat_head := cat_pos + Vector2(8 * cat_face, -86)
		hand_r = cat_head + Vector2(0, -10 + sin(t * 12.0) * 8.0 * (1.0 if pet_t > 0.0 else 0.2))
	Crayon.line(pen, neck + Vector2(-22, 8), hand_l, Crayon.INK, 6, 308)
	Crayon.line(pen, neck + Vector2(22, 8), hand_r, Crayon.INK, 6, 309)
	if phase == "intro" or phase == "phone" or phase == "closing":
		# the phone
		var ph := Rect2(hip + Vector2(-18, -78), Vector2(36, 54))
		Crayon.rect(pen, ph, Crayon.INK, 4, Color(0.15, 0.15, 0.2), 310)
		if screen_off < 1.0:
			pen.draw_rect(ph.grow(-6), Color(0.6, 0.9, 1.0, 0.9 * (1.0 - screen_off)))
			Crayon.oval(pen, head + Vector2(0, 10), Vector2(50, 40), Color(0.6, 0.9, 1.0, 0.18 * (1.0 - screen_off)))
	Crayon.circle(pen, head, 30, Crayon.INK, 5, Color(1, 0.88, 0.75), 311)
	var look := Vector2(0, 0.6) if phase == "intro" or phase == "phone" else (Vector2(1, 0.2) if phase == "pets" or phase == "cat" else Vector2.ZERO)
	Crayon.face(pen, head + Vector2(0, 3), 27, me_mood, look, 312)
	Crayon.party_hat(pen, head + Vector2(0, -24), 22, Crayon.GREEN, 313, 0.2)


## Side-on running stick figure (Chumbo).
func _runner(ci: CanvasItem, feet: Vector2, ph: float, mood: String, sc: float) -> void:
	var bob := absf(sin(ph)) * 7.0 * sc
	var hip := feet + Vector2(0, -64 * sc - bob)
	var neck := hip + Vector2(16, -54) * sc
	var head := neck + Vector2(10, -26) * sc
	for side in [0.0, PI]:
		var s := sin(ph + side)
		var c := cos(ph + side)
		var knee := hip + Vector2(s * 26, 30 - maxf(0.0, c) * 8) * sc
		var foot := knee + Vector2(s * 12 - maxf(0.0, -c) * 16, 32 - maxf(0.0, c) * 12) * sc
		Crayon.line(ci, hip, knee, Crayon.INK, 6 * sc, 400 + int(side))
		Crayon.line(ci, knee, foot, Crayon.INK, 6 * sc, 402 + int(side))
	Crayon.line(ci, hip, neck, Crayon.GREEN, 16 * sc, 404)
	Crayon.line(ci, hip, neck, Crayon.INK, 4 * sc, 405)
	for side in [0.0, PI]:
		var s := sin(ph + side)
		var elbow := neck + Vector2(-s * 20, 22) * sc
		var hand := elbow + Vector2(-s * 6 + 12, -10) * sc
		Crayon.line(ci, neck + Vector2(0, 6) * sc, elbow, Crayon.INK, 5 * sc, 406 + int(side))
		Crayon.line(ci, elbow, hand, Crayon.INK, 5 * sc, 408 + int(side))
	Crayon.circle(ci, head, 22 * sc, Crayon.INK, 4 * sc, Color(1, 0.88, 0.75), 410)
	var back := fmod(t, 3.0) < 0.9 and _chasing()
	Crayon.face(ci, head + Vector2(0, 2) * sc, 20 * sc, mood, Vector2(-1.0 if back else 1.0, 0), 411)
	Crayon.party_hat(ci, head + Vector2(-4, -18) * sc, 16 * sc, Crayon.GREEN, 412, -0.5)


func _phone() -> void:
	var k := phone_k
	if k <= 0.0:
		return
	var from := HIP + Vector2(0, -52)
	var r := PHONE
	r = Rect2(from.lerp(r.position, k), r.size * k)
	if r.size.x < 8.0:
		return
	Crayon.path(pen, PackedVector2Array([from, r.position + Vector2(0, r.size.y * 0.8)]), Color(1, 1, 1, 0.6), 3, 95)
	Crayon.rect(pen, r, Crayon.INK, 7, Color(0.15, 0.15, 0.2), 96)
	if k < 0.95:
		return
	var sc := _phone_screen()
	if screen_off >= 1.0:
		pen.draw_rect(sc, Color(0.02, 0.02, 0.04))
		return
	# the screen collapses like an old TV when the game closes
	var squash := 1.0 - screen_off
	var s := Rect2(sc.position + Vector2(0, sc.size.y * 0.5 * (1.0 - squash)), Vector2(sc.size.x, maxf(4.0, sc.size.y * squash)))
	pen.draw_rect(sc, Color(0.02, 0.02, 0.04))
	pen.draw_rect(s, Color(0.99, 0.93, 0.8))
	if squash < 0.9:
		pen.draw_rect(s, Color(1, 1, 1, 1.0 - squash))
		return
	# a tiny version of the party, of course
	Crayon.text(pen, Vector2(sc.get_center().x, sc.position.y + 92), "CHUMBO'S", 26, Crayon.RED, 1, 97, Crayon.title_font())
	Crayon.text(pen, Vector2(sc.get_center().x, sc.position.y + 124), "BIRTHDAY", 26, Crayon.RED, 1, 98, Crayon.title_font())
	Crayon.cake(pen, Vector2(sc.get_center().x, sc.position.y + 262), 140, 70, Crayon.PINK, 5, true, 99)
	for i in 3:
		Crayon.present(pen, Rect2(sc.position.x + 20 + i * 76, sc.position.y + 284, 50, 50), Crayon.RAINBOW[i * 2], Crayon.YELLOW, 120 + i)
	Crayon.balloon(pen, Vector2(sc.position.x + 34, sc.position.y + 170), 18, Crayon.RED, 50, 130)
	Crayon.balloon(pen, Vector2(sc.end.x - 34, sc.position.y + 180), 18, Crayon.BLUE, 50, 131)
	var x := _x_rect()
	var pulse := 1.0 + sin(t * 6.0) * 0.08 if phase == "phone" else 1.0
	var xr := Rect2(x.get_center() - x.size * 0.5 * pulse, x.size * pulse)
	Crayon.rect(pen, xr, Crayon.INK, 4, Crayon.RED, 140)
	Crayon.line(pen, xr.position + Vector2(12, 12), xr.end - Vector2(12, 12), Crayon.WHITE, 5, 141)
	Crayon.line(pen, Vector2(xr.end.x - 12, xr.position.y + 12), Vector2(xr.position.x + 12, xr.end.y - 12), Crayon.WHITE, 5, 142)
	if phase == "phone" and not locked:
		Crayon.text(pen, xr.get_center() + Vector2(-86, 2), "TAP ->", 30, Crayon.RED, 1, 143, Crayon.title_font())


func _paint_chase() -> void:
	# houses (two pre-drawn strips, scrolled slower than the road)
	var hs := scroll * 0.55
	var k0 := floori(hs / TILE.x)
	var dim := Color(1, 1, 1).lerp(Color(0.6, 0.55, 0.8), clampf(dist / RUN_TIME, 0.0, 1.0))
	if not _tiles.is_empty():
		for i in 2:
			var ti := k0 + i
			var tex: Texture2D = _tiles[1 if party_tile >= 0 and ti >= party_tile else 0]
			pen.draw_texture_rect(tex, Rect2(ti * TILE.x - hs, TILE_Y, TILE.x, TILE.y), false, dim)
	# road markings
	var off := fmod(scroll, 180.0)
	for i in 9:
		pen.draw_rect(Rect2(i * 180.0 - off, 609, 90, 8), Color(0.95, 0.85, 0.3, 0.8))
	var so := fmod(scroll, 120.0)
	for i in 12:
		var sx := i * 120.0 - so
		pen.draw_line(Vector2(sx, 412), Vector2(sx - 30, 516), Color(0.5, 0.48, 0.5), 2.0)
	if house_x < INF:
		_party_house()
	# warning marks where Rocko's cakes will land
	for th in throws:
		var a := 0.5 + 0.5 * sin(t * 18.0)
		var c := Vector2(ME_X, LANES[int(th.lane)])
		Crayon.ellipse(pen, c, Vector2(46, 14), Color(1, 0.15, 0.15, a), 4, Color(1, 0.1, 0.1, 0.18), 600)
	# everything on the street, back to front
	var items: Array = []
	for o in obstacles:
		items.append([LANES[int(o.lane)], 0, o])
	items.append([me_y + 1.0, 1, null])
	if rocko_x > -260.0:
		items.append([rocko_y + 0.5, 2, null])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for it in items:
		match int(it[1]):
			0:
				_obstacle(it[2])
			1:
				_chumbo_run()
			2:
				_rocko_run()
	for th in throws:
		var k: float = th.t / th.dur
		var to := Vector2(ME_X, LANES[int(th.lane)] - 20)
		var p: Vector2 = Vector2(th.from).lerp(to, k) + Vector2(0, -sin(k * PI) * 220.0)
		pen.draw_set_transform(p + _q, k * 7.0)
		Crayon.cake(pen, Vector2(0, 16), 54, 30, Crayon.PINK, 1, true, 610)
		pen.draw_set_transform(_q)
	for pp in pops:
		Crayon.text(pen, pp.p + Vector2(0, -(1.2 - pp.t) * 50.0), pp.s, 38, pp.c, 1, 620, Crayon.title_font())
	_hud()


func _chumbo_run() -> void:
	var feet := Vector2(ME_X, me_y)
	Crayon.oval(pen, feet + Vector2(0, 4), Vector2(36, 9), Color(0, 0, 0, 0.3))
	if hurt > 0.0 and fmod(hurt * 12.0, 1.0) < 0.5:
		return
	var ph := run_ph if speed > 1.0 else 0.6
	var mood := me_mood if phase != "chase" else ("x" if hurt > 0.0 else "o")
	_runner(pen, feet, ph, mood, 1.15)


func _rocko_run() -> void:
	var feet := Vector2(rocko_x, rocko_y)
	Crayon.oval(pen, feet + Vector2(0, 4), Vector2(70 * grow * 0.6, 12), Color(0, 0, 0, 0.35))
	var pose := "run" if speed > 1.0 else "sit"
	draw_cat(pen, feet, grow, 1.0, pose, demon, t, _q)


func _obstacle(o: Dictionary) -> void:
	var p := Vector2(o.x, LANES[int(o.lane)])
	var sd: int = int(o.s)
	match String(o.kind):
		"can":
			Crayon.rect(pen, Rect2(p + Vector2(-26, -70), Vector2(52, 70)), Crayon.INK, 4, Color(0.55, 0.58, 0.6), sd)
			Crayon.rect(pen, Rect2(p + Vector2(-32, -82), Vector2(64, 14)), Crayon.INK, 4, Color(0.65, 0.68, 0.7), sd + 1)
			for k in 3:
				Crayon.line(pen, p + Vector2(-14 + k * 14, -62), p + Vector2(-14 + k * 14, -8), Color(0.4, 0.42, 0.45), 3, sd + 2 + k)
		"cone":
			Crayon.poly(pen, PackedVector2Array([p + Vector2(-26, 0), p + Vector2(26, 0), p + Vector2(6, -74), p + Vector2(-6, -74)]), Crayon.INK, 4, Crayon.ORANGE, sd)
			pen.draw_rect(Rect2(p + Vector2(-16, -44), Vector2(32, 10)), Crayon.WHITE)
		"puddle":
			Crayon.ellipse(pen, p + Vector2(0, -6), Vector2(58, 16), Color(0.2, 0.35, 0.7), 3, Color(0.35, 0.55, 0.9, 0.8), sd)
			Crayon.disc(pen, p + Vector2(-20, -10), 4, Color(1, 1, 1, 0.6))
		"hydrant":
			Crayon.rect(pen, Rect2(p + Vector2(-16, -62), Vector2(32, 62)), Crayon.INK, 4, Crayon.RED, sd)
			Crayon.circle(pen, p + Vector2(0, -66), 16, Crayon.INK, 4, Crayon.RED, sd + 1)
			Crayon.rect(pen, Rect2(p + Vector2(-26, -44), Vector2(52, 12)), Crayon.INK, 3, Crayon.RED.darkened(0.2), sd + 2)
		"present":
			Crayon.present(pen, Rect2(p + Vector2(-34, -66), Vector2(68, 66)), Crayon.RAINBOW[sd % 7], Crayon.YELLOW, sd)
		"balloons":
			for b in 3:
				Crayon.balloon(pen, p + Vector2(-24 + b * 24, -120 + (b % 2) * 18), 20, Crayon.RAINBOW[(sd + b) % 7], 100, sd + b)
			Crayon.rect(pen, Rect2(p + Vector2(-14, -16), Vector2(28, 16)), Crayon.INK, 3, Crayon.GREY, sd + 5)
		"guest":
			Crayon.person(pen, p, 140, Crayon.INK, "wide", Crayon.RAINBOW[sd % 7], "up", t * 3.0 + sd, sd)
		"splat":
			Crayon.ellipse(pen, p + Vector2(0, -4), Vector2(48, 13), Crayon.INK, 3, Crayon.PINK, sd)
			Crayon.ellipse(pen, p + Vector2(10, -8), Vector2(18, 6), Color(0, 0, 0, 0), 0, Crayon.WHITE, sd + 1)


func _party_house() -> void:
	var b := 410.0
	var r := Rect2(house_x - 210, b - 250, 420, 250)
	Crayon.rect(pen, r, Crayon.INK, 6, Color(0.98, 0.6, 0.75), 700)
	Crayon.poly(pen, PackedVector2Array([Vector2(r.position.x - 24, r.position.y), Vector2(r.end.x + 24, r.position.y), Vector2(house_x, r.position.y - 110)]),
		Crayon.INK, 6, Crayon.PURPLE, 701)
	Crayon.rect(pen, Rect2(r.position.x - 10, r.position.y - 20, r.size.x + 20, 44), Crayon.INK, 4, Crayon.WHITE, 702)
	Crayon.text(pen, Vector2(house_x, r.position.y + 2), "HAPPY BIRTHDAY CHUMBO", 26, Crayon.RED, 1, 703, Crayon.title_font())
	for i in 2:
		var win := Rect2(r.position.x + 30 + i * 290, r.position.y + 60, 70, 60)
		Crayon.rect(pen, win, Crayon.INK, 4, Color(1, 0.9, 0.5), 704 + i)
		var c := win.get_center() + Vector2(0, 6)
		Crayon.disc(pen, c, 17, Color(0.15, 0.1, 0.12))
		Crayon.disc(pen, c + Vector2(-6, -3), 3.5, Crayon.WHITE)
		Crayon.disc(pen, c + Vector2(6, -3), 3.5, Crayon.WHITE)
	for i in 4:
		Crayon.balloon(pen, Vector2(r.position.x - 30 + (i % 2) * (r.size.x + 60), b - 170 - (i / 2) * 40), 22, Crayon.RAINBOW[i * 2 % 7], 120, 710 + i)
	var d := _house_door()
	pen.draw_rect(d, Color(0.08, 0.05, 0.1))
	if door_open > 0.0:
		# everyone from the party is in there
		for g in 3:
			var gp := Vector2(d.position.x + 18 + g * 30, d.end.y + 4)
			Crayon.person(pen, gp + Vector2(0, (1.0 - guests_out) * 30), 110, Crayon.INK, "wide", Crayon.RAINBOW[(g * 3) % 7], "up", t * 3.0 + g, 720 + g)
	Crayon.rect(pen, Rect2(d.position, Vector2(d.size.x * (1.0 - door_open * 0.85), d.size.y)), Crayon.INK, 5, Color(0.55, 0.32, 0.2), 730)
	if phase == "knock" and not locked:
		var bob := absf(sin(t * 5.0)) * 10.0
		Crayon.text(pen, d.get_center() + Vector2(0, -90 - bob), "KNOCK!", 40, Crayon.YELLOW, 1, 731, Crayon.title_font())


func _hud() -> void:
	if phase == "party" or phase == "knock" or phase == "knock_wait":
		return
	var y := 108.0 + (110.0 if Narrator.is_active() else 0.0)
	var x0 := 340.0
	var x1 := 940.0
	Crayon.line(pen, Vector2(x0, y), Vector2(x1, y), Crayon.WHITE, 5, 800)
	Crayon.house(pen, Vector2(x0 - 30, y - 4), 40, 801)
	Crayon.text(pen, Vector2(x1 + 34, y), "???", 34, Crayon.YELLOW, 1, 802, Crayon.title_font())
	var k := clampf(dist / RUN_TIME, 0.0, 1.0)
	var mx := lerpf(x0, x1, k)
	Crayon.circle(pen, Vector2(mx, y), 13, Crayon.INK, 3, Crayon.GREEN, 803)
	var rx := lerpf(x0, x1, maxf(0.0, k - gap * 0.045 - 0.02))
	if phase != "chase_intro":
		Crayon.circle(pen, Vector2(rx, y), 13, Crayon.INK, 3, Color(0.5, 0.05, 0.08), 804)
		Crayon.disc(pen, Vector2(rx - 4, y - 2), 3, Crayon.YELLOW)
		Crayon.disc(pen, Vector2(rx + 4, y - 2), 3, Crayon.YELLOW)
	if phase == "chase" and dist < 6.0:
		var a := Vector2(ME_X + 90, me_y - 160)
		Crayon.text(pen, a + Vector2(70, -20), "TAP ABOVE", 28, Crayon.YELLOW, 0, 805)
		Crayon.text(pen, a + Vector2(70, 150), "TAP BELOW", 28, Crayon.YELLOW, 0, 806)


## Rocko the cat: black, with long fluffy fur (also used by the party room once the secret
## is found). feet = between the paws, sc = size, f = facing (1 right, -1 left),
## pose = walk | run | sit | pet, dem = 0 (cute) .. 1 (demon), tm = time for animation.
static func draw_cat(ci: CanvasItem, feet: Vector2, sc: float, f: float, pose: String, dem: float, tm: float, base: Vector2 = Vector2.ZERO) -> void:
	var fur := Color(0.13, 0.12, 0.15).lerp(Color(0.1, 0.02, 0.03), dem)
	# grey edges and fur strokes so a black cat still shows up in the dark; red when he turns
	var edge := Color(0.46, 0.44, 0.53).lerp(Color(0.9, 0.16, 0.1), dem)
	var hi := Color(0.34, 0.33, 0.4).lerp(Color(0.55, 0.08, 0.08), dem)
	var w := 4.5 / sqrt(sc)
	var tuft := 7.0 + dem * 7.0
	ci.draw_set_transform(base + feet, 0.0, Vector2(sc * f, sc))
	var head := Vector2(8, -80)
	if dem > 0.05:
		# a red glow around him
		Crayon.oval(ci, Vector2(0, -50), Vector2(70, 62), Color(0.9, 0.1, 0.08, 0.22 * dem))
	if pose == "sit" or pose == "pet":
		var curl := sin(tm * 2.0) * 4.0
		_tail(ci, PackedVector2Array([Vector2(-20, -4), Vector2(-42, -6), Vector2(-50 + curl, -24), Vector2(-38, -36)]), edge, fur, hi, w, 900)
		_fluffy(ci, Vector2(0, -34), Vector2(29, 35), 18, tuft, edge, fur, w, 902)
		for k in 4:
			Crayon.line(ci, Vector2(-14 + k * 7, -50 + (k % 2) * 6), Vector2(-10 + k * 7, -34 + (k % 2) * 6), hi, w * 0.8, 904 + k)
		Crayon.line(ci, Vector2(2, -14), Vector2(2, 0), edge, w * 2.6, 908)
		Crayon.line(ci, Vector2(14, -14), Vector2(14, 0), edge, w * 2.6, 909)
		Crayon.line(ci, Vector2(2, -14), Vector2(2, -1), fur, w * 1.6, 910)
		Crayon.line(ci, Vector2(14, -14), Vector2(14, -1), fur, w * 1.6, 911)
		if pose == "pet":
			head.y += 4.0
	else:
		var sp := 16.0 if pose == "run" else 9.0
		var amp := 14.0 if pose == "run" else 7.0
		var sw := sin(tm * sp) * amp
		var tk := sin(tm * 3.0) * 6.0
		_tail(ci, PackedVector2Array([Vector2(-40, -36), Vector2(-60, -50), Vector2(-64 + tk, -76), Vector2(-52 + tk, -96)]), edge, fur, hi, w, 912)
		var legs := [[Vector2(-26, -20), Vector2(-30 + sw, 0)], [Vector2(-14, -18), Vector2(-12 - sw, 0)],
			[Vector2(18, -18), Vector2(16 - sw, 0)], [Vector2(30, -20), Vector2(32 + sw, 0)]]
		for k in 4:
			Crayon.line(ci, legs[k][0], legs[k][1], edge, w * 2.6, 914 + k)
			Crayon.line(ci, legs[k][0], legs[k][1] - Vector2(0, 1), fur, w * 1.6, 918 + k)
		_fluffy(ci, Vector2(0, -34), Vector2(45, 23), 22, tuft, edge, fur, w, 922)
		for k in 5:
			Crayon.line(ci, Vector2(-26 + k * 12, -48 + (k % 2) * 4), Vector2(-18 + k * 12, -36 + (k % 2) * 4), hi, w * 0.8, 924 + k)
		head = Vector2(42, -56)
	# head: ears (with tufts), a fluffy ruff, then the face
	if dem > 0.05:
		Crayon.poly(ci, PackedVector2Array([head + Vector2(-16, -14), head + Vector2(-28, -14 - 30 * dem), head + Vector2(-6, -20)]), Crayon.INK, w, Color(0.3, 0.0, 0.02), 930)
		Crayon.poly(ci, PackedVector2Array([head + Vector2(8, -20), head + Vector2(26, -16 - 30 * dem), head + Vector2(16, -12)]), Crayon.INK, w, Color(0.3, 0.0, 0.02), 931)
	Crayon.poly(ci, PackedVector2Array([head + Vector2(-21, -8), head + Vector2(-17, -34), head + Vector2(-4, -18)]), edge, w, fur, 932)
	Crayon.poly(ci, PackedVector2Array([head + Vector2(4, -18), head + Vector2(17, -34), head + Vector2(21, -8)]), edge, w, fur, 933)
	Crayon.line(ci, head + Vector2(-17, -34), head + Vector2(-19, -42), hi, w * 0.7, 934)
	Crayon.line(ci, head + Vector2(17, -34), head + Vector2(19, -42), hi, w * 0.7, 935)
	Crayon.disc(ci, head + Vector2(-13, -16), 3.5, Color(0.45, 0.25, 0.3, 1.0 - dem))
	Crayon.disc(ci, head + Vector2(13, -16), 3.5, Color(0.45, 0.25, 0.3, 1.0 - dem))
	_fluffy(ci, head, Vector2(23, 22), 16, tuft * 0.8, edge, fur, w, 936)
	var light := Color(0.85, 0.85, 0.9)
	if dem < 0.5:
		if pose == "pet":
			# happy closed eyes
			Crayon._arc(ci, head + Vector2(-8, -4), 4, PI, TAU, light, w * 0.8, 937)
			Crayon._arc(ci, head + Vector2(8, -4), 4, PI, TAU, light, w * 0.8, 938)
		else:
			for sx in [-1.0, 1.0]:
				var e: Vector2 = head + Vector2(sx * 8.0, -4)
				Crayon.oval(ci, e, Vector2(5.5, 6), Color(0.98, 0.82, 0.22))
				Crayon.oval(ci, e, Vector2(1.8, 4.6), Crayon.BLACK)
				Crayon.disc(ci, e + Vector2(1.5, -2.5), 1.4, Crayon.WHITE)
		Crayon.poly(ci, PackedVector2Array([head + Vector2(-3, 3), head + Vector2(3, 3), head + Vector2(0, 6)]), Color(0.6, 0.38, 0.45), 2, Color(0.6, 0.38, 0.45), 939)
		Crayon._arc(ci, head + Vector2(-3, 7), 3, 0, PI, light, w * 0.6, 940)
		Crayon._arc(ci, head + Vector2(3, 7), 3, 0, PI, light, w * 0.6, 941)
	else:
		# glowing eyes and far too many teeth
		for sx in [-1.0, 1.0]:
			var e: Vector2 = head + Vector2(sx * 9.0, -5)
			Crayon.oval(ci, e, Vector2(6.5, 5.5), Color(1, 0.45, 0.1))
			Crayon.oval(ci, e, Vector2(1.5, 4.5), Crayon.BLACK)
		var teeth := PackedVector2Array()
		for k in 9:
			teeth.append(head + Vector2(-14 + k * 3.5, 8 + (4.0 if k % 2 == 1 else 0.0)))
		Crayon.poly(ci, PackedVector2Array([head + Vector2(-16, 6), head + Vector2(16, 6), head + Vector2(10, 16), head + Vector2(-10, 16)]), edge, w * 0.6, Color(0.15, 0.0, 0.02), 942)
		Crayon.path(ci, teeth, Crayon.WHITE, w * 0.7, 943)
	for sy in [-1.0, 1.0]:
		Crayon.line(ci, head + Vector2(12, 4 + sy * 2), head + Vector2(32, 2 + sy * 6), light, 1.5, 944 + int(sy))
		Crayon.line(ci, head + Vector2(-12, 4 + sy * 2), head + Vector2(-32, 2 + sy * 6), light, 1.5, 946 + int(sy))
	if dem > 0.5:
		Crayon.party_hat(ci, head + Vector2(0, -22), 12, Crayon.PINK, 950, 0.25)
	ci.draw_set_transform(base)


## A big bushy tail: overlapping fluff balls along the curve, getting fluffier at the tip.
static func _tail(ci: CanvasItem, pts: PackedVector2Array, edge: Color, fur: Color, hi: Color, w: float, s: int) -> void:
	var balls := PackedVector2Array()
	for i in pts.size() - 1:
		for k in 3:
			balls.append(pts[i].lerp(pts[i + 1], k / 3.0))
	balls.append(pts[pts.size() - 1])
	var n := balls.size()
	for i in n:
		var r := lerpf(7.0, 11.5, float(i) / (n - 1))
		Crayon.disc(ci, balls[i] + Crayon.jit(s + i, 1.5), r + 2.6, edge)
	for i in n:
		var r := lerpf(7.0, 11.5, float(i) / (n - 1))
		Crayon.disc(ci, balls[i] + Crayon.jit(s + i, 1.5), r, fur)
	for i in range(2, n - 1, 3):
		var d := (balls[i + 1] - balls[i - 1]).normalized()
		Crayon.line(ci, balls[i] - d * 5.0, balls[i] + d * 5.0 + d.orthogonal() * 3.0, hi, w * 0.7, s + 40 + i)


## Long fur: an outline with tufts sticking out all the way round.
static func _fluffy(ci: CanvasItem, c: Vector2, rad: Vector2, n: int, tuft: float, edge: Color, fur: Color, w: float, s: int) -> void:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := TAU * (i + Crayon.rnd(s + i) * 0.25) / (n * 2)
		var out := tuft * (0.7 + 0.3 * Crayon.rnd(s + i * 3 + 1)) if i % 2 == 1 else 0.0
		pts.append(c + Vector2(cos(a) * (rad.x + out), sin(a) * (rad.y + out)))
	Crayon.poly(ci, pts, edge, w, fur, s)
