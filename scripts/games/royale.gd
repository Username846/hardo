extends Screen
## Present 6: FORTNIGHT - BIRTHDAY ROYALE (battle-royale build defence).
## Jump off the party bus, build walls against water balloons, throw cake at the others.
## Be the last one standing. One player left. Just you. ...two players left?

const IDX := 5
const ME := Vector2(640, 410)
const SPOTS := ["Cake Castle", "Balloon Park", "Pinata Peaks", "Sprinkle Springs"]
## One voiced line per landing spot (same order as SPOTS).
var LANDED := [
	"you_landed_at_cake",
	"you_landed_at_balloon",
	"you_landed_at_pinata",
	"you_landed_at_sprinkle",
]
const NAMES := ["xX_CakeLord_Xx", "BalloonBoi99", "sprinkle_queen", "PinataSlayer", "DefaultDancer", "LlamaLover",
	"Frosting_Fiend", "GiftWrapGamer", "CandleCrusher", "PartyHat_Pro", "NoScopeNapkin", "ConfettiKid"]

var phase := "intro"     # intro, bus, drop, fight, final, win
var bus_x := -300.0
var drop_t := 0.0
var spot := ""
var hp := 100
var left := 99
var storm_r := 720.0
var foes: Array = []
var shots: Array = []
var cakes: Array = []
var walls: Array = []
var feed: Array = []
var spawn_t := 1.0
var tick_t := 0.0
var fight_t := 0.0
var twisted := false
var eyes := 0.0
var dance := false
var hurt := 0.0
## The loot llama pinata (tap it for full health and fixed walls).
var llama := {}
var llama_done := false
## (poke yourself three times quick: emote! Everyone else stops throwing and dances too)
var me_taps := 0
var me_tap_t := -9.0
var emote_t := 0.0
const STILL_THERE := [" is still in the storm", " can't find the exit", " joined again", " has been here for 300 years",
	" is waiting for you", " forgot their name", " is still dancing"]


var _baked_key := ""
var _ring_idx := PackedInt32Array()


func enter() -> void:
	Narrator.top = true
	use_back_layer()
	Audio.play_music("royale")
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await line("welcome")
	phase = "bus"
	locked = false
	Audio.sfx("horn")


func press(p: Vector2) -> void:
	match phase:
		"bus":
			_jump()
		"fight":
			if not llama.is_empty() and p.distance_to(llama.pos) < 70.0:
				_smash_llama()
				return
			for f in foes:
				if p.distance_to(f.pos) < 48.0 and not f.hit:
					cakes.append({"pos": ME, "target": f})
					Audio.sfx("throw", -4)
					return
			if p.distance_to(ME + Vector2(0, -10)) < 44.0:
				_poke_me()
				return
			_build(p)


func _jump() -> void:
	phase = "drop"
	drop_t = 0.0
	spot = SPOTS[clampi(int((bus_x + 100.0) / 380.0), 0, 3)]
	Audio.sfx("whoosh")
	await wait(1.6)
	Audio.sfx("thud")
	phase = "fight"
	line_bg(LANDED[SPOTS.find(spot)])


func _poke_me() -> void:
	if t - me_tap_t > 0.8:
		me_taps = 0
	me_tap_t = t
	me_taps += 1
	Audio.sfx("blip", -8, 1.0 + me_taps * 0.15)
	if me_taps >= 3 and emote_t <= 0.0:
		me_taps = 0
		_emote()


## Default dance! The whole lobby stops for a dance-off (no water balloons while it lasts).
func _emote() -> void:
	emote_t = 5.0
	shots.clear()
	Audio.sfx("yay_small", -2)
	Audio.sfx("cheer", -10)
	confetti_burst(ME + Vector2(0, -90), 40)
	_feed("Emote: DEFAULT DANCE")
	_feed("Everyone stopped to dance!")
	if Game.found_egg("royale"):
		line_bg("dance_off_nobody")


func _build(p: Vector2) -> void:
	var ang := (p - ME).angle()
	for w in walls:
		if absf(wrapf(ang - w.ang, -PI, PI)) < 0.35:
			w.hp = 3
			Audio.sfx("build", -2, 1.2)
			return
	if walls.size() >= 8:
		walls.pop_front()
	walls.append({"ang": ang, "hp": 3})
	Audio.sfx("build")


func _feed(msg: String) -> void:
	feed.push_front({"m": msg, "t": 4.0})
	if feed.size() > 4:
		feed.pop_back()


func tick(dt: float) -> void:
	hurt = maxf(0.0, hurt - dt * 2.0)
	emote_t = maxf(0.0, emote_t - dt)
	for f in feed:
		f.t -= dt
	feed = feed.filter(func(f): return f.t > 0.0)
	match phase:
		"bus":
			bus_x += 230.0 * dt
			if bus_x > 1500.0:
				_jump()
		"drop":
			drop_t += dt
		"fight":
			_fight(dt)
		"final":
			eyes = minf(1.0, eyes + dt * 0.5)
	if phase in ["fight", "final"]:
		_move_projectiles(dt)


func _fight(dt: float) -> void:
	fight_t += dt
	storm_r = maxf(170.0, storm_r - dt * 4.5)
	tick_t -= dt
	if tick_t <= 0.0 and left > 2:
		tick_t = randf_range(0.8, 1.4) if not twisted else randf_range(4.0, 5.5)
		left -= 1
		var who: String = NAMES[randi() % NAMES.size()] + str(randi() % 90 + 10)
		_feed(who + (" got caught in the storm" if not twisted else STILL_THERE[randi() % STILL_THERE.size()]))
	if left <= 60 and not llama_done and llama.is_empty():
		var a := randf() * TAU
		llama = {"pos": ME + Vector2(cos(a) * 230.0, sin(a) * 150.0), "t": 0.0}
		Audio.sfx("sparkle")
		line_bg("loot_llama_tap_it")
	if not llama.is_empty():
		llama.t += dt
		if llama.t > 18.0:
			llama = {}
			llama_done = true
	if left <= 12 and not twisted:
		_twist()
	spawn_t -= dt
	var alive := foes.filter(func(f): return not f.hit).size()
	if spawn_t <= 0.0 and alive < (4 if not twisted else 3) and left > alive + 1:
		spawn_t = randf_range(1.6, 2.6)
		var a := randf() * TAU
		var r := randf_range(260.0, minf(storm_r - 40.0, 560.0))
		var pos := ME + Vector2(cos(a), sin(a)) * Vector2(r, r * 0.6)
		pos = pos.clamp(Vector2(60, 150), Vector2(W - 60, H - 60))
		foes.append({"pos": pos, "throw": randf_range(1.2, 2.5), "hit": false, "gone": 0.0, "col": Crayon.RAINBOW[randi() % 7], "seed": randi() % 1000, "name": NAMES[randi() % NAMES.size()]})
	for f in foes:
		if f.hit:
			f.gone += dt
			continue
		if emote_t > 0.0:
			continue
		f.throw -= dt
		if f.throw <= 0.0:
			f.throw = randf_range(2.0, 3.4)
			shots.append({"pos": f.pos, "vel": (ME - f.pos).normalized() * 260.0})
			Audio.sfx("throw", -10, 1.3)
		# the storm eats people who wander outside it
		if f.pos.distance_to(ME) > storm_r + 20.0:
			f.hit = true
			left = maxi(2, left - 1)
	foes = foes.filter(func(f): return f.gone < 0.8)
	# end of the match
	if twisted and left <= 2 and foes.filter(func(f): return not f.hit).is_empty():
		_final()


func _move_projectiles(dt: float) -> void:
	for s in shots:
		s.pos += s.vel * dt
		for w in walls:
			if w.hp > 0 and s.pos.distance_to(_wall_pos(w)) < 36.0:
				w.hp -= 1
				s.dead = true
				Audio.sfx("splash", -6)
		if not s.get("dead", false) and s.pos.distance_to(ME) < 30.0:
			s.dead = true
			hp -= 10
			hurt = 1.0
			Audio.sfx("splash", -2)
			Audio.sfx("ow", -8)
			if hp <= 0:
				hp = 50
				line_bg("you_got_back_up")
	shots = shots.filter(func(s): return not s.get("dead", false) and s.pos.x > -100 and s.pos.x < W + 100)
	walls = walls.filter(func(w): return w.hp > 0)
	for c in cakes:
		var f: Dictionary = c.target
		var d: Vector2 = f.pos - c.pos
		if d.length() < 20.0:
			c.dead = true
			if not f.hit:
				f.hit = true
				left = maxi(2, left - 1)
				Audio.sfx("splat", -2)
				_feed("You caked " + String(f.name) + "!")
		else:
			c.pos += d.normalized() * minf(d.length(), 760.0 * dt)
	cakes = cakes.filter(func(c): return not c.get("dead", false))


func _smash_llama() -> void:
	confetti_burst(llama.pos, 60)
	Audio.sfx("pop")
	Audio.sfx("levelup", -4)
	llama = {}
	llama_done = true
	hp = 100
	for w in walls:
		w.hp = 3
	_feed("You smashed the Birthday Llama! Full health!")


func _twist() -> void:
	twisted = true
	Audio.play_music("royale_dark", 2.0)
	line_bg("storm_is_getting")


func _final() -> void:
	phase = "final"
	locked = true
	shots.clear()
	left = 1
	Audio.sfx("levelup")
	await wait(1.5)
	await line("one_player_left_just")
	await wait(0.6)
	Audio.sfx("glitch")
	left = 2
	_feed("??? joined the party")
	await wait(1.0)
	await line("wait_two_players")
	Audio.sfx("giggle_low")
	await wait(1.5)
	phase = "win"
	dance = true
	Audio.play_music("royale", 1.0)
	Audio.sfx("cheer")
	confetti_burst(ME + Vector2(0, -80), 80)
	await wait(1.5)
	await line("you_won_chumbo_everyone")
	await line("done")
	finish_game(IDX, "#1 ...OF 2")


func _wall_pos(w: Dictionary) -> Vector2:
	return ME + Vector2(cos(w.ang), sin(w.ang)) * 95.0


func _map_phase() -> bool:
	return phase == "bus" or phase == "drop" or phase == "intro"


func paint_back() -> void:
	_baked_key = "%s/%s" % [_map_phase(), twisted]
	if _map_phase():
		_map_back()
		return
	var grass := Color(0.5, 0.82, 0.42).lerp(Color(0.2, 0.3, 0.22), 0.6 if twisted else 0.0)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), grass)
	for k in 14:
		var tp := Vector2(fmod(k * 263.0, W), 140 + fmod(k * 131.0, 560))
		if tp.distance_to(ME) > 140:
			Crayon.circle(pen, tp, 26, Crayon.INK, 3, Crayon.GREEN.darkened(0.25), 20 + k)


func paint() -> void:
	if _baked_key != "%s/%s" % [_map_phase(), twisted]:
		refresh_back()
	if _map_phase():
		_map()
		return
	# the storm: everything outside storm_r
	var storm := Color(0.55, 0.25, 0.85, 0.55).lerp(Color(0.1, 0.0, 0.15, 0.85), 1.0 if twisted else 0.0)
	_storm(storm)
	for w in walls:
		var p := _wall_pos(w)
		pen.draw_set_transform(p, w.ang + PI / 2, Vector2.ONE)
		Crayon.rect(pen, Rect2(-44, -12, 88, 24), Crayon.INK, 4, Crayon.BROWN.lightened(0.15 * w.hp), 40)
		pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if not llama.is_empty():
		_llama(llama.pos + Vector2(0, sin(t * 4.0) * 6.0))
	for f in foes:
		var a := 1.0 - clampf(f.gone / 0.8, 0, 1)
		var col := Color(Crayon.INK, a) if not twisted else Color(0.05, 0.02, 0.08, a)
		var mood := "happy" if not twisted else "blank"
		if f.hit:
			mood = "x"
		var pose := "wave"
		if emote_t > 0.0 and not f.hit:
			pose = "up" if int(t * 4.0 + f.seed) % 2 == 0 else "wave"
			Crayon.note(pen, f.pos + Vector2(30, -60 - fmod(t * 40.0 + f.seed, 30.0)), 20, Color(Crayon.RAINBOW[int(f.seed) % 7], 0.9))
		Crayon.person(pen, f.pos + Vector2(0, 50), 100, col, mood, f.col if not twisted else Color(0, 0, 0, 0), pose, t * 3.0, f.seed)
		if f.hit:
			Crayon.circle(pen, f.pos + Vector2(0, -26), 30 * a + 4, Crayon.INK, 3, Color(Crayon.PINK, a), f.seed + 5)
	_me()
	for s in shots:
		Crayon.circle(pen, s.pos, 13, Crayon.INK, 3, Crayon.SKY, 60)
	for c in cakes:
		Crayon.poly(pen, PackedVector2Array([c.pos + Vector2(-16, 10), c.pos + Vector2(16, 10), c.pos + Vector2(0, -16)]), Crayon.INK, 3, Crayon.PINK, 61)
	if phase == "final" or (phase == "win" and eyes > 0):
		var e := Vector2(1090, 210)
		var a := eyes
		Crayon.disc(pen, e, 10, Color(1, 0.95, 0.4, a))
		Crayon.disc(pen, e + Vector2(36, 0), 10, Color(1, 0.95, 0.4, a))
		Crayon.face(pen, e + Vector2(18, 26), 34, "wide", Vector2.ZERO, 62, Color(1, 1, 1, a))
	if hurt > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.3, 0.6, 1.0, hurt * 0.25))


## A stripy pinata llama (Fortnite's loot llama, birthday edition).
func _llama(p: Vector2) -> void:
	var body := Rect2(p + Vector2(-46, -20), Vector2(92, 46))
	for k in 4:
		Crayon.line(pen, p + Vector2(-34 + k * 22, 24), p + Vector2(-34 + k * 22, 54), Crayon.INK, 7, 960 + k)
	Crayon.rect(pen, body, Crayon.INK, 4, Crayon.PINK, 964)
	for k in 3:
		pen.draw_rect(Rect2(body.position + Vector2(8 + k * 28, 4), Vector2(12, body.size.y - 8)), Crayon.RAINBOW[(k * 2 + 1) % 7])
	Crayon.rect(pen, Rect2(p + Vector2(28, -74), Vector2(26, 60)), Crayon.INK, 4, Crayon.PURPLE.lightened(0.3), 965)
	Crayon.rect(pen, Rect2(p + Vector2(28, -92), Vector2(44, 26)), Crayon.INK, 4, Crayon.PURPLE.lightened(0.3), 966)
	Crayon.disc(pen, p + Vector2(58, -82), 4, Crayon.INK)
	Crayon.line(pen, p + Vector2(34, -92), p + Vector2(30, -110), Crayon.INK, 5, 967)
	Crayon.text(pen, p + Vector2(0, -120), "TAP!", 30, Crayon.YELLOW, 1, 968, Crayon.title_font())


func _storm(col: Color) -> void:
	# one triangle mesh for the whole ring from storm_r out to far away
	var n := 48
	if _ring_idx.is_empty():
		for i in n:
			var j := (i + 1) % n
			_ring_idx.append_array([i, n + i, n + j, i, n + j, j])
	var pts := PackedVector2Array()
	pts.resize(n * 2)
	var inner := PackedVector2Array()
	inner.resize(n + 1)
	for i in n:
		var d := Vector2(cos(TAU * i / n), sin(TAU * i / n))
		pts[i] = ME + d * storm_r
		pts[n + i] = ME + d * 2600.0
		inner[i] = pts[i]
	inner[n] = pts[0]
	var cols := PackedColorArray()
	cols.resize(n * 2)
	cols.fill(col)
	RenderingServer.canvas_item_add_triangle_array(pen.get_canvas_item(), _ring_idx, pts, cols)
	Crayon.path(pen, inner, Color(0.85, 0.6, 1.0), 6, 30)


func _me() -> void:
	var pose := "stand"
	var dancing := dance or emote_t > 0.0
	if dancing:
		pose = "up" if int(t * 4.0) % 2 == 0 else "wave"
	var feet := ME + Vector2(0, 55)
	if dancing:
		# floss-ish dance
		var sw := sin(t * 10.0) * 30.0
		Crayon.line(pen, feet + Vector2(0, -62), feet + Vector2(-20, 0), Crayon.INK, 5, 70)
		Crayon.line(pen, feet + Vector2(0, -62), feet + Vector2(20, 0), Crayon.INK, 5, 71)
		Crayon.line(pen, feet + Vector2(0, -62), feet + Vector2(0, -112), Crayon.INK, 5, 72)
		Crayon.line(pen, feet + Vector2(0, -105), feet + Vector2(-35 + sw, -70), Crayon.INK, 5, 73)
		Crayon.line(pen, feet + Vector2(0, -105), feet + Vector2(35 + sw, -80), Crayon.INK, 5, 74)
		Crayon.circle(pen, feet + Vector2(0, -130), 18, Crayon.INK, 4, Color(1, 0.9, 0.78), 75)
		Crayon.face(pen, feet + Vector2(0, -128), 16, "happy", Vector2.ZERO, 76)
		Crayon.party_hat(pen, feet + Vector2(0, -148), 15, Crayon.GREEN, 77)
	else:
		Crayon.person(pen, feet, 120, Crayon.INK, "o" if hurt > 0.3 else "happy", Crayon.GREEN, pose, t * 2.0, 78)
	Crayon.text(pen, ME + Vector2(0, 86), "YOU", 24, Crayon.WHITE, 1, 79)
	if emote_t > 0.0:
		for k in 2:
			var ph := fmod(t * 0.8 + k * 0.5, 1.0)
			Crayon.note(pen, ME + Vector2(-50 + k * 100 + sin(ph * 6.0) * 8.0, -90 - ph * 60.0), 26, Color(Crayon.RAINBOW[k * 3], 1.0 - ph))


func _map_back() -> void:
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.4, 0.7, 1.0))
	var island := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var r := 330.0 + sin(a * 3.0) * 40.0 + cos(a * 5.0) * 25.0
		island.append(Vector2(640, 420) + Vector2(cos(a) * r * 1.6, sin(a) * r * 0.8))
	Crayon.poly(pen, island, Crayon.INK, 6, Color(0.5, 0.82, 0.42), 1)
	var marks := [Vector2(240, 400), Vector2(500, 320), Vector2(800, 480), Vector2(1060, 380)]
	for k in 4:
		Crayon.circle(pen, marks[k], 30, Crayon.INK, 4, Crayon.RAINBOW[k * 2], 2 + k)
		Crayon.text(pen, marks[k] + Vector2(0, 52), SPOTS[k], 28, Crayon.INK, 1, 10 + k)


func _map() -> void:
	# party bus
	var bp := Vector2(bus_x, 160 + sin(t * 2.0) * 8.0)
	if phase == "bus" or phase == "intro":
		Crayon.balloon(pen, bp + Vector2(-40, -70), 22, Crayon.RED, 40, 20)
		Crayon.balloon(pen, bp + Vector2(30, -76), 22, Crayon.YELLOW, 46, 21)
		Crayon.rect(pen, Rect2(bp + Vector2(-110, -30), Vector2(220, 70)), Crayon.INK, 5, Crayon.BLUE, 22)
		for k in 4:
			Crayon.rect(pen, Rect2(bp + Vector2(-95 + k * 50, -20), Vector2(36, 26)), Crayon.INK, 3, Crayon.SKY, 23 + k)
		Crayon.text(pen, bp + Vector2(0, 26), "PARTY BUS", 22, Crayon.WHITE, 1, 30)
	if phase == "bus":
		Crayon.text(pen, Vector2(640, 640), "TAP TO JUMP!", 60, Crayon.RED, 1, 31, Crayon.title_font())
	if phase == "drop":
		var f := clampf(drop_t / 1.6, 0, 1)
		var p := Vector2(bus_x - 230.0 * drop_t, lerpf(180, 420, f))
		Crayon._arc(pen, p + Vector2(0, -40), 50, PI, TAU, Crayon.INK, 4, 40)
		Crayon.line(pen, p + Vector2(-50, -40), p + Vector2(0, 0), Crayon.INK, 2, 41)
		Crayon.line(pen, p + Vector2(50, -40), p + Vector2(0, 0), Crayon.INK, 2, 42)
		Crayon.person(pen, p + Vector2(0, 70), 70, Crayon.INK, "o", Crayon.GREEN, "up", t, 43)


func paint_top() -> void:
	if phase in ["fight", "final", "win"]:
		hud("PLAYERS LEFT: %d" % left, Crayon.WHITE)
		var hy := 88.0 + (120.0 if Narrator.is_active() else 0.0)
		Crayon.text(pen, Vector2(W - 24, hy), "HP: %d" % hp, 30, Crayon.WHITE, 2, 4250)
		for k in feed.size():
			Crayon.text(pen, Vector2(110, 110 + k * 32), String(feed[k].m), 22, Color(1, 1, 1, clampf(feed[k].t, 0, 1)), 0, 4260 + k, null, 0.5, false)
		if fight_t < 5.0 and phase == "fight":
			Crayon.text(pen, Vector2(640, 250), "TAP = BUILD   TAP A PLAYER = CAKE", 34, Crayon.YELLOW, 1, 4270)
