extends Screen
## Present 2: TONY HONK'S PRO SKATER 2 (skateboarding). A two-minute session in the birthday
## skate park: ollie, flip, grab and grind, collect S-K-A-T-E and find the secret tape.
## Then one more session. There's always one more session.
## Tap = ollie, tap in the air = flip trick, hold in the air = grab, land on a rail = grind,
## hold while landing = manual (keeps the combo going). Land a flip before you touch down!

const IDX := 1
const GROUND := 560.0
const ME_X := 330.0
const LOOP := 6400.0
const SPEED := 360.0
const GRAV := 2000.0
const OLLIE := 860.0
const SESSION := 120.0
const TILE := Vector2(1280, 330)
const DUSK := Color(0.5, 0.44, 0.72)
const FUNBOX_RAMP := 110.0
const SKIN := Color(1, 0.88, 0.75)

## One lap of the park (it repeats forever). x/w along the ground, h = height of the top.
const PARK := [
	{"k": "sign", "x": 100.0, "w": 0.0, "h": 0.0},
	{"k": "kicker", "x": 520.0, "w": 170.0, "h": 62.0},
	{"k": "rail", "x": 1000.0, "w": 420.0, "h": 72.0},
	{"k": "cake", "x": 1720.0, "w": 150.0, "h": 112.0},
	{"k": "candle", "x": 2250.0, "w": 620.0, "h": 110.0},
	{"k": "funbox", "x": 3200.0, "w": 440.0, "h": 58.0},
	{"k": "mega", "x": 3950.0, "w": 300.0, "h": 128.0},
	{"k": "arch", "x": 4750.0, "w": 260.0, "h": 0.0},
	{"k": "kicker", "x": 5400.0, "w": 170.0, "h": 62.0},
]
## S over the first kicker, K over the bench rail, A over the cake, T off the end of the
## candle rail, E over the last kicker.
const LETTER_POS := [Vector2(800, 300), Vector2(1210, 425), Vector2(1795, 330), Vector2(2930, 330), Vector2(5690, 300)]
## Way up high: only an ollie off the very lip of the mega ramp gets there.
const TAPE_POS := Vector2(4480, -20)
const WATCH_X := [860.0, 1560.0, 3000.0, 4600.0, 2080.0, 5250.0, 3760.0, 5900.0]
const FLIPS := [["Kickflip", 100], ["Heelflip", 100], ["Pop Shove-It", 80], ["Impossible", 150],
	["Cake Flip", 150], ["Hardflip", 120], ["Varial Kickflip", 150], ["360 Flip", 200]]
const GRABS := ["Birthday Grab", "Melon Grab", "Frosting Grab", "Indy Grab", "Party Hat Grab"]

var phase := "title"     # title, s1, tally, twist, s2, end
var skating := false
var clock_on := false
var session := 1
var time_left := SESSION
var reset_done := false
var end_in := -1.0
# Chumbo (x is the world position of his feet; it only ever grows, the park repeats)
var x := 0.0
var y := GROUND
var vx := 0.0
var vy := 0.0
var state := "ground"    # ground, air, grind, bail
var rail := {}
var lip_pop := false
var pressing := false
var press_t := 0.0
var air_press := false
var flip_t := 0.0
var flip_i := 0
var board_ph := 0.0
var spinning := false
var spin := 0.0
var grab := false
var grab_i := 0
var manual := false
var manual_t := 0.0
var bail_t := 0.0
var bail_rot := 0.0
var bail_vx := 0.0
var land_squash := 0.0
var splat := 0.0
var cam_x := -ME_X
var cam_y := 0.0
# scoring
var score := 0
var special := 0.0
var combo: Array = []
var combo_pts := 0.0
var combo_show := 0.0
var last_combo := ""
var last_mult := 0
var pops: Array = []
var word := "SKATE"
var got: Array = [false, false, false, false, false]
var tape_got := false
var goals: Array = []
var banner := ""
var banner_t := 0.0
var honk_t := 0.0
var honk_txt := ""
var goose_k := 0.0
# looks
var night := 0.0
var tally := 0.0
var title_k := 1.0
var visits := 364
var sparks: Array = []
var roll_t := 0.0
var grind_snd := 0.0
var said := {}
var line_q: Array = []
var _tiles: Array[Texture2D] = []
var _tex := {}
var _sky_step := -1


func enter() -> void:
	# narration goes at the bottom, over the empty concrete; the HUD lives at the top
	Narrator.top = false
	use_back_layer()
	_bake_all()
	_set_goals(1)
	Audio.play_music("skate")
	_run()


func _run() -> void:
	locked = true
	await wait(0.6)
	Audio.sfx("honk")
	await say("Present number two! It's TONY HONK'S PRO SKATER 2! The birthday skate park is open!")
	honk_t = 4.0
	honk_txt = "HONK!"
	Audio.sfx("honk", 0, 1.1)
	await say("HONK! I'm Tony Honk! Show me your sickest birthday tricks!", Narrator.HYPE)
	var tw := create_tween()
	tw.tween_property(self, "title_k", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await say("Tap to ollie. Tap again in the air to flip. Hold to grab. Land on a rail to grind!")
	await say("You have two minutes. Finish your tricks before you land, or you'll bail!")
	_start_session(1)


func _start_session(n: int) -> void:
	session = n
	phase = "s%d" % n
	time_left = SESSION
	skating = true
	clock_on = true
	locked = false
	_banner("GO!" if n == 1 else "SESSION TWO")
	Audio.sfx("horn", -6)


func _set_goals(n: int) -> void:
	if n == 1:
		word = "SKATE"
		goals = [
			{"id": "score", "t": "Score 8,000 points", "done": false},
			{"id": "letters", "t": "Collect S-K-A-T-E", "done": false},
			{"id": "cake", "t": "Ollie the birthday cake", "done": false},
			{"id": "candle", "t": "Grind the candle rail", "done": false},
			{"id": "tape", "t": "Find the secret tape", "done": false},
		]
	else:
		word = "STAY"
		goals = [
			{"id": "score", "t": "Score 8,000 points. Again.", "done": false},
			{"id": "letters", "t": "Collect S-T-A-Y", "done": false},
			{"id": "cake", "t": "Ollie the cake. Again.", "done": false},
			{"id": "candle", "t": "Grind the candle rail. Again.", "done": false},
			{"id": "stay", "t": "Don't leave.", "done": true},
		]
	got = [false, false, false, false, false]
	tape_got = false


func _goals_done() -> int:
	var n := 0
	for g in goals:
		if g.done:
			n += 1
	return n


func _goal(id: String) -> void:
	for g in goals:
		if g.id == id and not g.done:
			g.done = true
			honk_t = 3.0
			if session == 1:
				honk_txt = "HONK!"
				_banner("GOAL!  " + String(g.t))
				Audio.sfx("levelup", -2)
				Audio.sfx("honk", -2, 1.15)
				_line(["HONK! Goal complete!", Narrator.HYPE], true)
			else:
				honk_txt = "honk."
				_banner("GOAL. AGAIN.")
				Audio.sfx("glitch", -6)
				Audio.sfx("honk", -4, 0.7)


func _banner(s: String) -> void:
	banner = s
	banner_t = 2.4


## Queue a background line so lines don't cut each other off (pairs keep them voiced).
func _line(pair: Array, again: bool = false) -> void:
	if said.has(pair[0]) and not again:
		return
	said[pair[0]] = true
	if line_q.size() < 3:
		line_q.append(pair)


# ------------------------------------------------------------------ input


func press(_p: Vector2) -> void:
	if not skating:
		return
	pressing = true
	press_t = 0.0
	air_press = false
	match state:
		"ground":
			if manual:
				manual = false
				_ollie()
			elif _on_ramp():
				lip_pop = true
			else:
				_ollie()
		"grind":
			state = "air"
			vy = -760.0
			Audio.sfx("ollie", -2)
			_trick("Ollie", 50)
		"air":
			air_press = true


func release(_p: Vector2) -> void:
	if not pressing:
		return
	pressing = false
	if state == "air":
		if grab:
			grab = false
		elif air_press and press_t < 0.22:
			_flip()
	elif state == "ground" and manual:
		manual = false
		_bank()
	air_press = false


func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or e.echo or locked or not skating:
		return
	if e.keycode in [KEY_SPACE, KEY_UP, KEY_W]:
		if e.pressed:
			press(Vector2.ZERO)
		else:
			release(Vector2.ZERO)
		get_viewport().set_input_as_handled()


func _ollie() -> void:
	state = "air"
	vy = -OLLIE
	y -= 1.0
	Audio.sfx("ollie", -2)
	_trick("Ollie", 50)


func _flip() -> void:
	if special >= 1.0 and flip_t <= 0.0 and _time_to_land() > 0.8:
		spinning = true
		spin = 0.0
		flip_t = 0.75
		special = 0.4
		_trick("THE 900!", 1200)
		Audio.sfx("levelup", -4, 1.2)
		Audio.sfx("cheer", -10)
		return
	flip_t += 0.4
	var f: Array = FLIPS[flip_i % FLIPS.size()]
	flip_i += 1
	_trick(f[0], f[1])
	Audio.sfx("whoosh", -8, 1.4)


func _trick(name: String, pts: int) -> void:
	combo.append(name)
	combo_pts += pts
	combo_show = 2.0
	if special < 1.0:
		special = minf(1.0, special + pts / 1400.0)
		if special >= 1.0 and session == 1:
			_line(["Special meter full! Tap in the air for a 900!", Narrator.HYPE])


func _bank() -> void:
	if combo.is_empty():
		return
	var mult := mini(combo.size(), 10)
	var total := int(combo_pts) * mult
	score += total
	last_combo = " + ".join(combo.slice(maxi(0, combo.size() - 4)))
	last_mult = mult
	combo_show = 1.6
	_pop("+" + _fmt(total), Crayon.GREEN if session == 1 else Color(0.75, 0.6, 1.0), 46 if mult < 4 else 60)
	Audio.sfx("ding" if mult >= 3 else "coin", -8)
	combo.clear()
	combo_pts = 0.0
	if score >= 8000:
		_goal("score")


func _bail(cake: bool) -> void:
	state = "bail"
	bail_t = 0.0
	bail_rot = 0.0
	combo.clear()
	combo_pts = 0.0
	manual = false
	grab = false
	flip_t = 0.0
	spinning = false
	lip_pop = false
	special = 0.0
	Audio.sfx("oof", -2)
	Audio.sfx("thud", -2)
	if cake:
		vy = -800.0
		bail_vx = 230.0
		splat = 4.0
		Audio.sfx("splat", -2)
		if session == 1:
			_line(["Splat! Tap before the cake to jump over it!", Narrator.CUTE])
	else:
		vy = -260.0
		bail_vx = maxf(vx * 0.7, 120.0)
		if session == 1:
			_line(["Ouch! Finish your trick before you land!", Narrator.CUTE])
	if session == 2:
		_line(["Get up, Chumbo. They're still watching.", Narrator.DARK])
	_pop("BAIL!", Crayon.RED, 64)


func _pop(s: String, col: Color, size: int) -> void:
	var fresh := 0
	for p in pops:
		if p.t < 0.5:
			fresh += 1
	pops.append({"s": s, "c": col, "t": 0.0, "size": size, "x": randf_range(-20, 20), "dy": fresh * 54.0})


func _fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


# ------------------------------------------------------------------ the park


func _surface(wx: float) -> float:
	var m := fposmod(wx, LOOP)
	for f: Dictionary in PARK:
		var fx: float = f.x
		var fw: float = f.w
		if m < fx or m >= fx + fw:
			continue
		var fh: float = f.h
		match String(f.k):
			"kicker", "mega":
				return GROUND - fh * (m - fx) / fw
			"cake":
				return GROUND - fh
			"funbox":
				if m < fx + FUNBOX_RAMP:
					return GROUND - fh * (m - fx) / FUNBOX_RAMP
				return GROUND - fh
	return GROUND


func _feature_at(wx: float, kinds: Array) -> Dictionary:
	var m := fposmod(wx, LOOP)
	for f: Dictionary in PARK:
		if String(f.k) in kinds and m >= float(f.x) and m < float(f.x) + float(f.w):
			return f
	return {}


func _on_ramp() -> bool:
	return state == "ground" and not _feature_at(x, ["kicker", "mega"]).is_empty()


func _crossed(old: float, new: float, edge: float) -> bool:
	var a := fposmod(old, LOOP)
	return a < edge and a + (new - old) >= edge


## How long until Chumbo touches down (ground, ramp, cake or rail) if nothing changes.
func _time_to_land() -> float:
	var px := x
	var py := y
	var pv := vy
	var h := 1.0 / 60.0
	for i in 180:
		pv += GRAV * h
		var nx := px + vx * h
		var ny := py + pv * h
		if pv > 0.0:
			var r := _feature_at(nx, ["rail", "candle"])
			if not r.is_empty() and py <= GROUND - float(r.h) + 2.0 and ny >= GROUND - float(r.h):
				return i * h
		if ny >= _surface(nx):
			return i * h
		px = nx
		py = ny
	return 3.0


# ------------------------------------------------------------------ update


func tick(dt: float) -> void:
	Crayon.shake = 1.0 if session == 1 else 1.35
	if not line_q.is_empty() and not Narrator.is_active() and phase != "end":
		var p: Array = line_q.pop_front()
		say_bg(p[0], p[1])
	banner_t = maxf(0.0, banner_t - dt)
	honk_t = maxf(0.0, honk_t - dt)
	goose_k = move_toward(goose_k, 1.0 if honk_t > 0.4 else 0.0, dt * 3.0)
	combo_show = maxf(0.0, combo_show - dt)
	splat = maxf(0.0, splat - dt)
	land_squash = maxf(0.0, land_squash - dt * 5.0)
	for p in pops:
		p.t += dt
	pops = pops.filter(func(p): return p.t < 1.4)
	for s in sparks:
		s.t += dt
		s.p += s.v * dt
		s.v.y += 900.0 * dt
	sparks = sparks.filter(func(s): return s.t < 0.35)
	if pressing:
		press_t += dt
	if clock_on:
		time_left -= dt
		_clock_events()
	if phase in ["s1", "s2", "tally", "twist", "end"]:
		var steps := maxi(1, ceili(dt / 0.017))
		for i in steps:
			_step(dt / steps)
	cam_x = x - ME_X
	cam_y = lerpf(cam_y, minf(0.0, y - 330.0), minf(1.0, dt * 9.0))
	if end_in > 0.0:
		end_in -= dt
		if end_in <= 0.0:
			_ending()


func _clock_events() -> void:
	var el := SESSION - time_left
	if session == 1:
		if time_left <= 60.0:
			_line(["One minute left!", Narrator.HYPE])
		if time_left <= 10.0:
			_line(["Ten seconds! Big finish!", Narrator.HYPE])
		if time_left <= 0.0 and phase == "s1":
			_end_session_1()
		return
	night = clampf(0.45 + el / SESSION * 0.55, 0.0, 1.0) if not reset_done else 1.0
	if el > 14.0:
		_line(["They don't clap. They just watch.", Narrator.DARK])
	if el > 66.0:
		_line(["It's the same cake again. It's always the same cake.", Narrator.DARK])
	if time_left <= 15.0 and not reset_done:
		_line(["Almost over. Almost.", Narrator.DARK])
	if time_left <= 0.0 and not reset_done:
		reset_done = true
		time_left = SESSION
		Audio.sfx("glitch")
		Audio.sfx("honk", -4, 0.6)
		_banner("ONE MORE SESSION!")
		banner_t = 6.0
		line_q.clear()
		_line(["One more session. There's always one more session.", Narrator.DARK])
		end_in = 9.0


func _step(h: float) -> void:
	var ox := x
	if state != "bail":
		var target := 0.0
		if skating:
			target = SPEED * (1.08 if special >= 1.0 else 1.0)
		vx = move_toward(vx, target, (420.0 if skating else 300.0) * h)
	match state:
		"ground":
			_step_ground(h)
		"air":
			_step_air(h)
		"grind":
			_step_grind(h)
		"bail":
			_step_bail(h)
	if state == "air":
		if flip_t > 0.0:
			flip_t = maxf(0.0, flip_t - h)
			if spinning:
				spin += h * TAU * 2.5 / 0.75
			else:
				board_ph += h / 0.4
		if pressing and press_t >= 0.22 and not grab and flip_t <= 0.0:
			grab = true
			_trick(GRABS[grab_i % GRABS.size()], 100)
			grab_i += 1
			Audio.sfx("whoosh", -12, 0.8)
		if grab:
			combo_pts += 160.0 * h
	if flip_t <= 0.0:
		board_ph = 0.0
	_pickups(ox)


func _step_ground(h: float) -> void:
	var nx := x + vx * h
	for f: Dictionary in PARK:
		if (f.k == "kicker" or f.k == "mega") and _crossed(x, nx, float(f.x) + float(f.w)):
			x = nx
			y = GROUND - float(f.h)
			var up := 620.0 if f.k == "kicker" else 1000.0
			if lip_pop:
				up = 1000.0 if f.k == "kicker" else 1300.0
				Audio.sfx("ollie", -2)
				_trick("Ollie" if f.k == "kicker" else "Mega Ollie", 50 if f.k == "kicker" else 150)
			state = "air"
			vy = -up
			lip_pop = false
			manual = false
			Audio.sfx("whoosh", -10)
			return
	var s := _surface(nx)
	if s < y - 16.0:
		_bail(true)
		return
	x = nx
	if s > y + 3.0:
		state = "air"
		vy = 0.0
		return
	y = s
	if manual:
		manual_t += h
		combo_pts += 140.0 * h
		if manual_t > 4.0:
			manual = false
			_bank()
	if skating and vx > 100.0:
		roll_t -= h
		if roll_t <= 0.0:
			roll_t = 1.0
			Audio.sfx("roll", -18)


func _step_air(h: float) -> void:
	vy += GRAV * h
	var nx := x + vx * h
	var ny := y + vy * h
	if vy > 0.0:
		var r := _feature_at(nx, ["rail", "candle"])
		if not r.is_empty():
			var top := GROUND - float(r.h)
			if y <= top + 2.0 and ny >= top:
				x = nx
				y = top
				_land_rail(r)
				return
	var s := _surface(nx)
	if ny >= s:
		if y > s + 12.0:
			x = nx
			_bail(true)
			return
		x = nx
		y = s
		_land()
		return
	x = nx
	y = ny


func _land() -> void:
	state = "ground"
	vy = 0.0
	if flip_t > 0.1:
		_bail(false)
		return
	if flip_t > 0.0:
		_pop("SKETCHY!", Crayon.ORANGE, 40)
	flip_t = 0.0
	spinning = false
	spin = 0.0
	grab = false
	land_squash = 1.0
	Audio.sfx("land", -4)
	if pressing and not combo.is_empty():
		manual = true
		manual_t = 0.0
		_trick("Frosting Manual", 60)
	else:
		_bank()


func _land_rail(r: Dictionary) -> void:
	if flip_t > 0.1:
		_bail(false)
		return
	flip_t = 0.0
	spinning = false
	spin = 0.0
	grab = false
	state = "grind"
	rail = r
	if r.k == "candle":
		_trick("Candle Grind", 120)
		_goal("candle")
	else:
		_trick(["50-50 Grind", "Boardslide", "Crooked Grind", "Smith Grind"][randi() % 4], 100)
	Audio.sfx("grind", -2)
	grind_snd = 0.7
	if session == 1:
		_line(["Grinding! Sick!", Narrator.HYPE])


func _step_grind(h: float) -> void:
	x += vx * h
	combo_pts += 200.0 * h
	grind_snd -= h
	if grind_snd <= 0.0:
		grind_snd = 0.7
		Audio.sfx("grind", -5)
	if randf() < h * 30.0:
		sparks.append({"p": Vector2(x - 20, y), "v": Vector2(randf_range(-260, -80), randf_range(-220, -40)), "t": 0.0})
	if fposmod(x, LOOP) >= float(rail.x) + float(rail.w) or vx < 30.0:
		state = "air"
		vy = -150.0


func _step_bail(h: float) -> void:
	bail_t += h
	vy += GRAV * h
	x += bail_vx * h
	y += vy * h
	var s := _surface(x)
	if y >= s and vy >= 0.0:
		y = s
		vy = 0.0
		bail_vx = move_toward(bail_vx, 0.0, 300.0 * h)
	else:
		bail_rot += h * 9.0
	if bail_t > 1.5 and y >= s - 0.5:
		state = "ground"
		bail_rot = 0.0
		vx = 40.0


func _pickups(ox: float) -> void:
	var m := fposmod(x, LOOP)
	var body := Vector2(m, y - 55.0)
	for i in word.length():
		if got[i]:
			continue
		var lp: Vector2 = LETTER_POS[i]
		if absf(body.x - lp.x) < 46.0 and absf(body.y - lp.y) < 74.0:
			got[i] = true
			Audio.sfx("coin", -2)
			Audio.sfx("sparkle", -8)
			_pop(word[i], Crayon.YELLOW, 70)
			if session == 2:
				_line(["S. T. A. Y. The letters spell stay.", Narrator.DARK])
			if not got.slice(0, word.length()).has(false):
				_goal("letters")
	if not tape_got and absf(body.x - TAPE_POS.x) < 70.0 and absf(body.y - TAPE_POS.y) < 90.0:
		tape_got = true
		Audio.sfx("tada", -4)
		_pop("SECRET TAPE!", Crayon.PINK, 56)
		if session == 1:
			_goal("tape")
			_line(["You found the secret tape! Radical!", Narrator.HYPE])
		else:
			_line(["It's a tape of you. Skating here. Yesterday. And the day before.", Narrator.DARK])
	if state == "bail":
		return
	for f: Dictionary in PARK:
		match String(f.k):
			"cake":
				if _crossed(ox, x, float(f.x) + float(f.w)):
					_trick("CAKE GAP", 250)
					_pop("CAKE GAP!", Crayon.PINK, 48)
					_goal("cake")
					if session == 1:
						_line(["You jumped the cake! Happy birthday, cake!", Narrator.HYPE])
			"arch":
				if state == "air" and _crossed(ox, x, float(f.x) + float(f.w) * 0.5):
					_trick("BALLOON GAP", 300)
					_pop("BALLOON GAP!", Crayon.SKY, 48)
			"sign":
				if _crossed(ox, x, float(f.x)) and session == 2:
					visits += 1


# ------------------------------------------------------------------ the sessions


func _wait_landed(limit: float) -> void:
	var waited := 0.0
	while (state == "air" or state == "bail") and waited < limit:
		await wait(0.1)
		waited += 0.1


func _end_session_1() -> void:
	phase = "tally"
	skating = false
	clock_on = false
	locked = true
	time_left = 0.0
	pressing = false
	lip_pop = false
	line_q.clear()
	Narrator.cancel()
	Audio.sfx("horn", -4)
	_banner("TIME'S UP!")
	await _wait_landed(3.0)
	_bank()
	await wait(0.8)
	var tw := create_tween()
	tw.tween_property(self, "tally", 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.sfx("tada")
	honk_t = 6.0
	honk_txt = "HONK HONK!"
	await say("Time's up! What a session! Look at all those tricks!", Narrator.HYPE)
	await wait(0.6)
	_twist()


func _twist() -> void:
	phase = "twist"
	Audio.play_music("skate_dark", 2.0)
	var tw := create_tween()
	tw.tween_property(self, "night", 0.45, 3.0)
	await say("Wait. Where are you going, Chumbo? The session isn't over.", Narrator.DARK)
	var tw2 := create_tween()
	tw2.tween_property(self, "tally", 0.0, 0.4)
	await wait(0.45)
	# back to the start of the park. It's the same park. It's always the same park.
	session = 2
	_set_goals(2)
	score = 0
	special = 0.0
	x = ceilf((x + 200.0) / LOOP) * LOOP
	y = GROUND
	vx = 0.0
	state = "ground"
	cam_x = x - ME_X
	visits += 1
	await say("One more session, Chumbo. Everyone came to watch you skate.", Narrator.DARK)
	_start_session(2)


func _ending() -> void:
	phase = "end"
	skating = false
	locked = true
	pressing = false
	lip_pop = false
	line_q.clear()
	await _wait_landed(3.0)
	_bank()
	honk_t = 99.0
	honk_txt = "HONK."
	Audio.sfx("honk", -2, 0.75)
	await wait(0.8)
	await say("HONK.", Narrator.CREEPY)
	await say("The session never ends, Chumbo. The park will be right here tomorrow. On your birthday.", Narrator.DARK)
	await say("Present number two, done! Sick tricks, Chumbo!")
	finish_game(IDX, "SICK TRICKS!")


# ------------------------------------------------------------------ baked pictures


func _bake_all() -> void:
	var px := Vector2(get_window().size)
	var sc := clampf(px.x / maxf(get_viewport_rect().size.x, 1.0), 1.0, 2.0)
	for v in 2:
		_tiles.append(_bake_pic(TILE, Vector2.ZERO, sc, _draw_tile.bind(v)))
	var specs := {
		"kicker": [Vector2(220, 110), Vector2(25, 95)],
		"mega": [Vector2(400, 250), Vector2(30, 230)],
		"rail": [Vector2(460, 110), Vector2(20, 100)],
		"candle": [Vector2(680, 180), Vector2(20, 160)],
		"cake": [Vector2(200, 230), Vector2(25, 205)],
		"funbox": [Vector2(480, 130), Vector2(20, 110)],
		"arch": [Vector2(320, 400), Vector2(30, 380)],
		"sign": [Vector2(380, 280), Vector2(40, 265)],
		"sign2": [Vector2(380, 280), Vector2(40, 265)],
	}
	for k in specs:
		var sz: Vector2 = specs[k][0]
		var org: Vector2 = specs[k][1]
		_tex[k] = {"tex": _bake_pic(sz, org, sc, _draw_feature.bind(k)), "org": org, "size": sz}


func _bake_pic(size: Vector2, origin: Vector2, sc: float, painter: Callable) -> Texture2D:
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(ceili(size.x * sc), ceili(size.y * sc))
	vp.size_2d_override = Vector2i(size)
	vp.size_2d_override_stretch = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var n := Node2D.new()
	n.position = origin
	vp.add_child(n)
	n.draw.connect(_paint_baked.bind(n, painter))
	add_child(vp)
	return vp.get_texture()


func _paint_baked(n: Node2D, painter: Callable) -> void:
	Crayon.freeze(true)
	painter.call(n)
	Crayon.freeze(false)


func _draw_feature(n: Node2D, k: String) -> void:
	var wood := Color(0.86, 0.64, 0.4)
	match k:
		"kicker", "mega":
			var w := 170.0 if k == "kicker" else 300.0
			var hh := 62.0 if k == "kicker" else 128.0
			if k == "mega":
				for i in 4:
					var sx := 40.0 + i * 70.0
					Crayon.line(n, Vector2(sx, 0), Vector2(sx, -hh * sx / w + 6), Crayon.GREY, 4, 40 + i)
				Crayon.line(n, Vector2(30, -10), Vector2(w - 10, -hh + 20), Crayon.GREY, 3, 48)
			Crayon.poly(n, PackedVector2Array([Vector2(0, 0), Vector2(w, -hh), Vector2(w, 0)]), Crayon.INK, 5, wood, 10 if k == "kicker" else 20)
			for i in 3:
				var f := 0.25 + i * 0.25
				Crayon.line(n, Vector2(w * f, -hh * f), Vector2(w * f, 0), wood.darkened(0.25), 3, 30 + i)
			Crayon.rect(n, Rect2(w - 12, -hh, 12, hh), Crayon.INK, 4, wood.darkened(0.3), 35)
			Crayon.line(n, Vector2(w - 26, -hh + 9), Vector2(w + 2, -hh - 1), Crayon.GREY, 7, 36)
			if k == "mega":
				Crayon.line(n, Vector2(w + 6, -hh), Vector2(w + 6, -hh - 90), Crayon.INK, 4, 50)
				Crayon.poly(n, PackedVector2Array([Vector2(w + 6, -hh - 90), Vector2(w + 58, -hh - 74), Vector2(w + 6, -hh - 58)]), Crayon.INK, 3, Crayon.RED, 51)
				Crayon.text(n, Vector2(w * 0.62, -24), "MEGA RAMP", 26, Crayon.INK, 1, 52, Crayon.title_font(), 0.3, false)
		"rail":
			for sx in [30.0, 210.0, 390.0]:
				Crayon.line(n, Vector2(sx, 2), Vector2(sx, -72), Crayon.INK, 6, 60 + int(sx))
			Crayon.line(n, Vector2(-6, -72), Vector2(426, -72), Crayon.INK, 13, 70)
			Crayon.line(n, Vector2(-4, -72), Vector2(424, -72), Color(0.7, 0.72, 0.78), 7, 71)
			Crayon.line(n, Vector2(0, -75), Vector2(420, -75), Crayon.WHITE, 2, 72)
		"candle":
			for sx in [70.0, 320.0, 560.0]:
				Crayon.line(n, Vector2(sx, 2), Vector2(sx, -90), Crayon.INK, 6, 80 + int(sx))
			var body := Rect2(0, -110, 590, 26)
			Crayon.rect(n, body, Crayon.INK, 5, Color(1, 0.96, 0.9), 90)
			for i in 15:
				var sx := 14.0 + i * 39.0
				Crayon.line(n, Vector2(sx, -84), Vector2(sx + 22, -110), Crayon.RAINBOW[i % 7], 8, 100 + i, 0.4)
			Crayon.line(n, Vector2(592, -98), Vector2(606, -98), Crayon.INK, 3, 120)
			Crayon.flame(n, Vector2(618, -100), 16.0, 121)
			Crayon.text(n, Vector2(300, -48), "CANDLE RAIL", 24, Crayon.INK, 1, 122, Crayon.title_font(), 0.3, false)
		"cake":
			Crayon.cake(n, Vector2(75, 0), 150, 112, Crayon.PINK, 4, true, 130)
			Crayon.text(n, Vector2(75, -40), "HAPPY", 26, Crayon.RED, 1, 131, Crayon.title_font(), 0.3, false)
			Crayon.text(n, Vector2(75, -14), "B-DAY", 24, Crayon.BLUE, 1, 132, Crayon.title_font(), 0.3, false)
		"funbox":
			Crayon.poly(n, PackedVector2Array([Vector2(0, 0), Vector2(FUNBOX_RAMP, -58), Vector2(FUNBOX_RAMP, 0)]), Crayon.INK, 5, wood, 140)
			var box := Rect2(FUNBOX_RAMP, -58, 330, 58)
			Crayon.rect(n, box, Crayon.INK, 5, Crayon.RED, 141)
			n.draw_rect(Rect2(FUNBOX_RAMP + 140, -58, 40, 58), Crayon.YELLOW)
			n.draw_rect(Rect2(FUNBOX_RAMP, -36, 330, 14), Crayon.YELLOW)
			Crayon.line(n, Vector2(FUNBOX_RAMP, -60), Vector2(FUNBOX_RAMP + 330, -60), Crayon.INK, 5, 142)
			Crayon.text(n, Vector2(FUNBOX_RAMP + 260, -28), "FUNBOX", 22, Crayon.INK, 1, 143, Crayon.title_font(), 0.3, false)
		"arch":
			var pts: Array = []
			for i in 6:
				pts.append(Vector2(0, -24 - i * 48.0))
				pts.append(Vector2(260, -24 - i * 48.0))
			for i in range(1, 6):
				var a := PI + PI * i / 6.0
				pts.append(Vector2(130, -264) + Vector2(cos(a) * 130, sin(a) * 78))
			for i in pts.size():
				var c: Vector2 = pts[i]
				Crayon.circle(n, c, 26, Crayon.INK, 3, Crayon.RAINBOW[i % 7], 150 + i)
				Crayon.disc(n, c + Vector2(-8, -9), 6, Color(1, 1, 1, 0.6))
		"sign", "sign2":
			Crayon.line(n, Vector2(0, 4), Vector2(0, -170), Crayon.INK, 7, 170)
			Crayon.line(n, Vector2(300, 4), Vector2(300, -170), Crayon.INK, 7, 171)
			var r := Rect2(-30, -255, 360, 100)
			Crayon.rect(n, r, Crayon.INK, 5, Crayon.YELLOW if k == "sign" else Color(0.85, 0.82, 0.9), 172)
			if k == "sign":
				Crayon.text(n, Vector2(150, -226), "BIRTHDAY", 38, Crayon.RED, 1, 173, Crayon.title_font(), 0.3, false)
				Crayon.text(n, Vector2(150, -184), "SKATE PARK", 32, Crayon.BLUE, 1, 174, Crayon.title_font(), 0.3, false)
			else:
				Crayon.text(n, Vector2(150, -226), "WELCOME BACK", 34, Crayon.RED, 1, 175, Crayon.title_font(), 0.3, false)
				Crayon.text(n, Vector2(150, -184), "CHUMBO", 36, Crayon.INK, 1, 176, Crayon.title_font(), 0.3, false)
			# Tony Honk himself, painted on the sign
			draw_mascot(n, Vector2(150, 0), 0.7, 0.0, k == "sign2")


## The park in the distance: trees, a fence, bleachers. Variant 1 has the guests.
func _draw_tile(n: Node2D, variant: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var base := TILE.y
	n.draw_rect(Rect2(0, base - 70, TILE.x, 70), Color(0.45, 0.75, 0.4))
	Crayon.line(n, Vector2(-10, base - 70), Vector2(TILE.x + 10, base - 70), Crayon.INK, 4, 1)
	# far trees
	for i in 7:
		var tx := 60.0 + i * 185.0 + rng.randf_range(-30, 30)
		var th := rng.randf_range(120, 180)
		Crayon.line(n, Vector2(tx, base - 60), Vector2(tx, base - 60 - th * 0.55), Crayon.BROWN, 12, 10 + i)
		Crayon.circle(n, Vector2(tx, base - 60 - th * 0.7), th * 0.33, Crayon.INK, 4, Color(0.25, 0.6, 0.3), 20 + i)
	# bleachers
	var bl := Rect2(470, base - 150, 300, 90)
	for r in 3:
		Crayon.rect(n, Rect2(bl.position.x + r * 20, bl.position.y + r * 30, bl.size.x - r * 40, 30), Crayon.INK, 4, Color(0.75, 0.75, 0.8), 30 + r)
	if variant == 0:
		for k in 3:
			var p := Vector2(530 + k * 90, base - 150)
			Crayon.person(n, p, 70, Crayon.INK, "happy", Crayon.RAINBOW[k * 2], "up", k * 1.3, 40 + k * 5)
	else:
		for k in 6:
			var p := Vector2(500 + k * 46, base - 150 + (k % 2) * 30)
			Crayon.person(n, p, 70, Crayon.INK, "blank", Crayon.RAINBOW[k % 7], "stand", 0.0, 40 + k * 5)
	# chain-link fence
	var fy := base - 110
	for i in 15:
		var fx := 20.0 + i * 90.0
		Crayon.line(n, Vector2(fx, base - 56), Vector2(fx, fy), Crayon.GREY, 5, 60 + i)
	Crayon.line(n, Vector2(0, fy), Vector2(TILE.x, fy), Crayon.GREY, 5, 80)
	for i in 30:
		var fx := i * 45.0
		n.draw_line(Vector2(fx, fy), Vector2(fx + 45, base - 58), Color(0.6, 0.6, 0.65, 0.6), 2.0)
		n.draw_line(Vector2(fx + 45, fy), Vector2(fx, base - 58), Color(0.6, 0.6, 0.65, 0.6), 2.0)
	if variant == 1:
		# the guests, along the fence. Watching.
		for i in 18:
			var gx := 30.0 + i * 70.0 + rng.randf_range(-12, 12)
			if gx > 450 and gx < 800:
				continue
			var feet := Vector2(gx, base - 62)
			Crayon.person(n, feet, rng.randf_range(80, 100), Crayon.INK, "blank", Crayon.RAINBOW[i % 7], "stand", 0.0, 200 + i, Color(0.85, 0.78, 0.75))
		for i in 5:
			Crayon.balloon(n, Vector2(100 + i * 260, base - 170), 18, Crayon.RAINBOW[(i * 3) % 7], 60, 300 + i, 0.6)
	else:
		for i in 4:
			Crayon.balloon(n, Vector2(150 + i * 330, base - 190), 20, Crayon.RAINBOW[(i * 2) % 7], 80, 300 + i)


func paint_back() -> void:
	var n := _sky_step / 4.0
	var top := Color(0.45, 0.72, 0.98).lerp(Color(0.08, 0.06, 0.22), n)
	var low := Color(0.78, 0.92, 1.0).lerp(Color(0.85, 0.42, 0.42), n)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, 2000), top)
	for i in 10:
		pen.draw_rect(Rect2(-2000, i * 60.0, W + 4000, 61), top.lerp(low, i / 9.0))
	pen.draw_rect(Rect2(-2000, 600, W + 4000, 2000), low)
	if _sky_step <= 0:
		Crayon.sun(pen, Vector2(1080, 270), 46, "happy", 5)
		Crayon.cloud(pen, Vector2(250, 210), 70, Crayon.WHITE, 6)
		Crayon.cloud(pen, Vector2(1120, 300), 60, Crayon.WHITE, 7)
	else:
		for i in 20:
			var sp := Vector2(fmod(i * 233.0, W), 40 + fmod(i * 97.0, 300.0))
			var a := clampf(n * 1.4 - 0.2, 0.0, 1.0)
			Crayon.star(pen, sp, 6 + (i % 3) * 2, Color(1, 1, 0.8, a), Color(1, 0.95, 0.5, a), 900 + i)
		Crayon.circle(pen, Vector2(1080, 250 + 60 * (1.0 - n)), 44, Crayon.INK, 4, Color(1, 0.96, 0.8), 8)
		Crayon.face(pen, Vector2(1080, 250 + 60 * (1.0 - n)), 38, "flat", Vector2(-0.6, 0.5), 9)


# ------------------------------------------------------------------ drawing


func paint() -> void:
	var step := 0 if session == 1 and night < 0.1 else clampi(int(night * 4.0 + 0.5), 1, 4)
	if step != _sky_step:
		_sky_step = step
		refresh_back()
	var tint := Color(1, 1, 1).lerp(DUSK, night)
	var gy := GROUND - cam_y
	# the park in the distance (slower)
	var px := cam_x * 0.5
	var ty := GROUND - TILE.y - cam_y * 0.6
	var k0 := floori(px / TILE.x)
	var tile: Texture2D = _tiles[1 if session == 2 else 0]
	for i in range(-1, 3):
		pen.draw_texture_rect(tile, Rect2((k0 + i) * TILE.x - px, ty, TILE.x, TILE.y), false, tint)
	if gy > ty + TILE.y:
		pen.draw_rect(Rect2(-2000, ty + TILE.y - 2, W + 4000, gy - ty - TILE.y + 4), Color(0.45, 0.75, 0.4) * tint)
	# the concrete
	pen.draw_rect(Rect2(-2000, gy, W + 4000, 2000), Color(0.78, 0.77, 0.74) * tint)
	pen.draw_rect(Rect2(-2000, gy - 2, W + 4000, 7), Color(0.35, 0.33, 0.36) * tint)
	var off := fposmod(cam_x, 160.0)
	for i in range(-2, 11):
		var jx := i * 160.0 - off
		pen.draw_line(Vector2(jx, gy + 6), Vector2(jx - 50, gy + 170), Color(0.55, 0.54, 0.52) * tint, 2.0)
	var lap := floori(cam_x / LOOP)
	_chalk(lap, gy, tint)
	if session == 2:
		_watchers(lap, gy)
	for L in range(lap - 1, lap + 2):
		for f: Dictionary in PARK:
			var k := String(f.k)
			if k == "sign" and session == 2:
				k = "sign2"
			var sx: float = float(f.x) + L * LOOP - cam_x
			if sx > W + 500 or sx + float(f.w) < -500:
				continue
			var e: Dictionary = _tex[k]
			var org: Vector2 = e.org
			pen.draw_texture_rect(e.tex, Rect2(Vector2(sx, gy) - org, e.size), false, tint)
			if k == "sign2":
				Crayon.text(pen, Vector2(sx + 150, gy - 40), "VISIT #%d" % visits, 26, Crayon.WHITE, 1, 177, Crayon.title_font(), 0.3, false)
	_paint_pickups(lap)
	if session == 1 and phase == "s1":
		_hints(lap, gy)
	for s in sparks:
		var sp: Vector2 = s.p - Vector2(cam_x, cam_y)
		pen.draw_line(sp, sp - s.v * 0.03, Color(1, 0.85, 0.3, 1.0 - s.t / 0.35), 3.0)
	_paint_chumbo()
	if goose_k > 0.0 or phase == "title":
		_paint_goose(gy)


const CHALK := [[300.0, "HAPPY BIRTHDAY!", "STAY"], [1550.0, "SK8 OR DIE", "AGAIN"], [2100.0, "*", "*"],
	[3000.0, "CHUMBO WAS HERE", "CHUMBO WAS HERE"], [3800.0, "<3", "AGAIN"], [4500.0, "TONY HONK RULES", "CHUMBO IS HERE"],
	[5200.0, "*", "STAY"], [6000.0, "RAD!", "CHUMBO WILL BE HERE"]]


## Chalk scribbles on the concrete (they change in the second session).
func _chalk(lap: int, gy: float, tint: Color) -> void:
	for L in range(lap - 1, lap + 2):
		for c: Array in CHALK:
			var sx: float = float(c[0]) + L * LOOP - cam_x
			if sx < -400 or sx > W + 400:
				continue
			var txt: String = c[1] if session == 1 else c[2]
			var col := Color(1, 1, 1, 0.55) * tint if session == 1 else Color(1, 0.75, 0.8, 0.5)
			if txt == "*":
				Crayon.star(pen, Vector2(sx, gy + 62), 22, col, Color(0, 0, 0, 0), 1100 + int(c[0]))
			else:
				Crayon.text(pen, Vector2(sx, gy + 58), txt, 34, col, 1, 1100 + int(c[0]), null, 0.3, false)


## Big friendly arrows over the things that make goals (first session, until done).
func _hints(lap: int, gy: float) -> void:
	var bob := absf(sin(t * 5.0)) * 10.0
	for L in range(lap, lap + 2):
		for f: Dictionary in PARK:
			var sx: float = float(f.x) + L * LOOP - cam_x
			var label := ""
			match String(f.k):
				"cake":
					if not _is_done("cake"):
						label = "TAP TO JUMP!"
				"candle":
					if not _is_done("candle"):
						label = "GRIND ME!"
				"mega":
					if not _is_done("tape"):
						label = "TAP ON THE RAMP!"
			if label == "" or sx < -200 or sx > W + 200:
				continue
			var cx := sx + float(f.w) * 0.5
			var ty := gy - float(f.h) - 120.0 - bob
			Crayon.text(pen, Vector2(cx, ty - 34), label, 30, Crayon.RED, 1, 1200, Crayon.title_font())
			Crayon.line(pen, Vector2(cx, ty - 12), Vector2(cx, ty + 40), Crayon.RED, 6, 1201)
			Crayon.line(pen, Vector2(cx - 16, ty + 22), Vector2(cx, ty + 42), Crayon.RED, 6, 1202)
			Crayon.line(pen, Vector2(cx + 16, ty + 22), Vector2(cx, ty + 42), Crayon.RED, 6, 1203)


func _is_done(id: String) -> bool:
	for g in goals:
		if g.id == id:
			return g.done
	return true


func _watchers(lap: int, gy: float) -> void:
	var el := SESSION - time_left if not reset_done else SESSION
	var shown := mini(WATCH_X.size(), 2 + int(el / 12.0))
	if phase in ["twist"]:
		shown = 2
	var me := Vector2(ME_X, y - cam_y - 100)
	for L in range(lap - 1, lap + 2):
		for i in shown:
			var sx: float = WATCH_X[i] + L * LOOP - cam_x
			if sx < -300 or sx > W + 300:
				continue
			var feet := Vector2(sx, gy - 2)
			var col := Color(0.2, 0.17, 0.25)
			var head := feet + Vector2(0, -106)
			Crayon.line(pen, feet + Vector2(-12, 0), feet + Vector2(0, -48), col, 5, 1000 + i)
			Crayon.line(pen, feet + Vector2(12, 0), feet + Vector2(0, -48), col, 5, 1010 + i)
			Crayon.line(pen, feet + Vector2(0, -48), feet + Vector2(0, -88), col, 5, 1020 + i)
			Crayon.line(pen, feet + Vector2(0, -84), feet + Vector2(-18, -50), col, 5, 1030 + i)
			Crayon.line(pen, feet + Vector2(0, -84), feet + Vector2(18, -50), col, 5, 1040 + i)
			Crayon.circle(pen, head, 18, col, 4, Color(0.8, 0.74, 0.74), 1050 + i)
			var look := (me - head).normalized()
			for ex in [-6.0, 6.0]:
				var e := head + Vector2(ex, -2)
				Crayon.disc(pen, e, 4.5, Crayon.WHITE)
				Crayon.disc(pen, e + look * 2.0, 2.4, Crayon.BLACK)
			Crayon.party_hat(pen, head + Vector2(0, -14), 13, Crayon.RAINBOW[i % 7], 1060 + i)


func _paint_pickups(lap: int) -> void:
	for L in range(lap - 1, lap + 2):
		var ox := L * LOOP - cam_x
		for i in word.length():
			if got[i]:
				continue
			var p: Vector2 = LETTER_POS[i] + Vector2(ox, -cam_y + sin(t * 3.0 + i) * 6.0)
			if p.x < -100 or p.x > W + 100:
				continue
			Crayon.disc(pen, p, 38, Color(1, 0.95, 0.4, 0.35) if session == 1 else Color(0.6, 0.3, 0.7, 0.4))
			Crayon.text(pen, p, word[i], 62, Crayon.RED if session == 1 else Color(0.85, 0.75, 1.0), 1, 600 + i, Crayon.title_font())
		if not tape_got:
			var tp := TAPE_POS + Vector2(ox, -cam_y + sin(t * 2.0) * 8.0)
			if tp.x > -100 and tp.x < W + 100 and tp.y > -100:
				_tape(tp)


func _tape(c: Vector2) -> void:
	var r := Rect2(c - Vector2(44, 28), Vector2(88, 56))
	Crayon.rect(pen, r, Crayon.INK, 4, Crayon.BLACK, 620)
	pen.draw_rect(Rect2(c - Vector2(32, 22), Vector2(64, 18)), Color(1, 0.95, 0.85))
	Crayon.disc(pen, c + Vector2(-18, 10), 9, Crayon.WHITE)
	Crayon.disc(pen, c + Vector2(18, 10), 9, Crayon.WHITE)
	Crayon.text(pen, c + Vector2(0, -13), "SECRET", 16, Crayon.RED, 1, 621, null, 0.2, false)
	if fmod(t, 0.6) < 0.3:
		Crayon.star(pen, c + Vector2(48, -30), 12, Crayon.INK, Crayon.YELLOW, 622)


func _paint_chumbo() -> void:
	var feet := Vector2(ME_X, y - cam_y)
	var ground := _surface(x) - cam_y
	if state == "grind":
		ground = feet.y
	var hgt := clampf((ground - feet.y) / 300.0, 0.0, 1.0)
	Crayon.oval(pen, Vector2(ME_X, ground + 2), Vector2(34 * (1.0 - hgt * 0.5), 7), Color(0, 0, 0, 0.25))
	var mood := "happy"
	if state == "air":
		mood = "o" if flip_t > 0.0 or vy < -300.0 else "happy"
	if state == "bail":
		mood = "x"
	elif session == 2 and phase != "s1":
		mood = "flat"
	if state == "bail":
		# tumbling; the board skids off on its own
		var bx := feet + Vector2(70 + minf(bail_t, 0.8) * 90.0, 0)
		bx.y = _surface(x + 70.0 + minf(bail_t, 0.8) * 90.0) - cam_y
		_board(bx + Vector2(0, -6), 0.0, 0.0)
		var pivot := feet + Vector2(0, -60)
		pen.draw_set_transform_matrix(Transform2D(bail_rot, pivot) * Transform2D(0.0, Vector2(0, 60)))
		_body(Vector2.ZERO, 0.5, mood, false, "flail")
		pen.draw_set_transform(Vector2.ZERO)
		return
	var rot := 0.0
	if manual:
		rot = -0.2 + sin(t * 9.0) * 0.04
	elif state == "grind":
		rot = sin(t * 14.0) * 0.03
	elif state == "ground":
		var s0 := _surface(x - 20.0)
		var s1 := _surface(x + 20.0)
		rot = atan2(s1 - s0, 40.0) * 0.8
	var crouch := 0.25 + land_squash * 0.5
	if lip_pop:
		crouch = 0.9
	if state == "air":
		crouch = 0.15 if not grab else 0.95
		if flip_t > 0.0:
			crouch = 0.6
	if spinning:
		rot = spin
	var pivot := feet + Vector2(0, -60)
	pen.draw_set_transform_matrix(Transform2D(rot, pivot) * Transform2D(0.0, Vector2(0, 60)))
	var lift := 0.0
	if flip_t > 0.0 and not spinning:
		lift = sin(fposmod(board_ph, 1.0) * PI) * 22.0
	_board(Vector2(0, -6 - lift), board_ph, 0.0)
	_body(Vector2.ZERO, crouch, mood, grab, "air" if state == "air" else "ride")
	pen.draw_set_transform(Vector2.ZERO)


## Skateboard; ph = flip progress (1.0 = one full kickflip).
func _board(c: Vector2, ph: float, tilt: float) -> void:
	var sq := cos(ph * TAU)
	var dir := Vector2(cos(tilt), sin(tilt))
	var nrm := Vector2(-dir.y, dir.x)
	var th := 2.0 + 5.0 * absf(sq)
	var a := c - dir * 40.0
	var b := c + dir * 40.0
	var col := Color(0.25, 0.25, 0.28) if sq >= 0.0 else Color(0.9, 0.3, 0.25)
	if absf(sq) > 0.25:
		var wy := 9.0 * sq
		Crayon.disc(pen, c - dir * 24.0 + nrm * wy, 7.0, Crayon.INK)
		Crayon.disc(pen, c + dir * 24.0 + nrm * wy, 7.0, Crayon.INK)
		Crayon.disc(pen, c - dir * 24.0 + nrm * wy, 3.0, Crayon.YELLOW)
		Crayon.disc(pen, c + dir * 24.0 + nrm * wy, 3.0, Crayon.YELLOW)
	Crayon.line(pen, a, b, Crayon.INK, th + 4.0, 500)
	Crayon.line(pen, a, b, col, th, 501, 0.5)
	Crayon.line(pen, a, a - dir * 10.0 - nrm * 8.0 * sq, Crayon.INK, th + 2.0, 502, 0.3)
	Crayon.line(pen, b, b + dir * 10.0 - nrm * 8.0 * sq, Crayon.INK, th + 2.0, 503, 0.3)


## Chumbo from the feet up (feet at o, facing right).
func _body(o: Vector2, crouch: float, mood: String, grabbing: bool, pose: String) -> void:
	var hip := o + Vector2(-4, -66 + crouch * 22)
	var fb := o + Vector2(-20, -12)
	var ff := o + Vector2(20, -12)
	var kb := (hip + fb) * 0.5 + Vector2(-10 - crouch * 8, -crouch * 2)
	var kf := (hip + ff) * 0.5 + Vector2(10 + crouch * 10, -crouch * 6)
	var jeans := Color(0.25, 0.4, 0.75)
	if pose == "flail":
		kb = hip + Vector2(-26, 14)
		kf = hip + Vector2(24, 18)
		fb = kb + Vector2(-14, 26)
		ff = kf + Vector2(22, 10)
	for leg in [[kb, fb], [kf, ff]]:
		Crayon.line(pen, hip, leg[0], jeans, 9, 510)
		Crayon.line(pen, leg[0], leg[1], jeans, 9, 511)
		Crayon.oval(pen, leg[1] + Vector2(3, -2), Vector2(11, 6), Crayon.INK)
	var neck := hip + Vector2(10, -48 + crouch * 8)
	Crayon.line(pen, hip, neck, Crayon.GREEN, 18, 512)
	Crayon.line(pen, hip, neck, Crayon.INK, 3, 513, 0.5)
	var sw := sin(t * 3.0) * 5.0
	var hl := neck + Vector2(-36, 6 + sw)
	var hr := neck + Vector2(38, -2 - sw)
	if pose == "air":
		hl = neck + Vector2(-34, -22)
		hr = neck + Vector2(36, -26)
	if pose == "flail":
		hl = neck + Vector2(-30, -34 + sw * 2.0)
		hr = neck + Vector2(34, -30 - sw * 2.0)
	if grabbing:
		hr = o + Vector2(18, -18)
	Crayon.line(pen, neck + Vector2(0, 4), (neck + hl) * 0.5 + Vector2(0, 8), Crayon.INK, 5, 514)
	Crayon.line(pen, (neck + hl) * 0.5 + Vector2(0, 8), hl, Crayon.INK, 5, 515)
	Crayon.line(pen, neck + Vector2(0, 4), (neck + hr) * 0.5 + Vector2(0, 8), Crayon.INK, 5, 516)
	Crayon.line(pen, (neck + hr) * 0.5 + Vector2(0, 8), hr, Crayon.INK, 5, 517)
	var head := neck + Vector2(8, -26)
	Crayon.circle(pen, head, 22, Crayon.INK, 4, SKIN, 518)
	Crayon.face(pen, head + Vector2(0, 2), 20, mood, Vector2(0.6, 0.1), 519)
	if splat > 0.0:
		Crayon.disc(pen, head + Vector2(-6, 4), 10, Color(1, 0.6, 0.75, minf(1.0, splat)))
		Crayon.disc(pen, head + Vector2(9, -6), 8, Color(1, 1, 1, minf(1.0, splat)))
		Crayon.disc(pen, head + Vector2(6, 10), 7, Color(1, 0.6, 0.75, minf(1.0, splat)))
	Crayon.party_hat(pen, head + Vector2(-4, -18), 16, Crayon.GREEN, 520, -0.4)


func _paint_goose(gy: float) -> void:
	var k := ease(goose_k, -2.0)
	var feet := Vector2(lerpf(-140.0, 150.0, k), gy)
	if phase == "title":
		feet = Vector2(1110, gy)
	draw_mascot(pen, feet, 1.0, t, session == 2)
	if honk_t > 0.4 and honk_txt != "":
		var bp := feet + Vector2(80, -210)
		if bp.x > W - 90:
			bp.x = W - 90
		Crayon.rect(pen, Rect2(bp - Vector2(80, 30), Vector2(160, 56)), Crayon.INK, 4, Crayon.WHITE, 640)
		Crayon.line(pen, bp + Vector2(-50, 26), feet + Vector2(40, -140), Crayon.INK, 4, 641)
		Crayon.text(pen, bp, honk_txt, 32, Crayon.INK, 1, 642, Crayon.title_font())


## Tony Honk: a goose in a helmet on a skateboard (party=true: a party hat instead).
static func draw_mascot(ci: CanvasItem, feet: Vector2, sc: float, tm: float, party: bool = false) -> void:
	var bob := sin(tm * 6.0) * 2.0
	# board
	Crayon.disc(ci, feet + Vector2(-26, -7) * sc, 7 * sc, Crayon.INK)
	Crayon.disc(ci, feet + Vector2(26, -7) * sc, 7 * sc, Crayon.INK)
	Crayon.line(ci, feet + Vector2(-44, -16) * sc, feet + Vector2(44, -16) * sc, Crayon.INK, 12 * sc, 9000)
	Crayon.line(ci, feet + Vector2(-44, -16) * sc, feet + Vector2(44, -16) * sc, Color(0.9, 0.3, 0.25), 6 * sc, 9001, 0.4)
	Crayon.line(ci, feet + Vector2(-44, -16) * sc, feet + Vector2(-54, -26) * sc, Crayon.INK, 8 * sc, 9002, 0.3)
	Crayon.line(ci, feet + Vector2(44, -16) * sc, feet + Vector2(54, -26) * sc, Crayon.INK, 8 * sc, 9003, 0.3)
	var body := feet + Vector2(-4, -72 + bob) * sc
	# orange legs and big flat feet
	for lx in [-12.0, 14.0]:
		Crayon.line(ci, body + Vector2(lx * 0.6, 22) * sc, feet + Vector2(lx, -22) * sc, Crayon.ORANGE, 6 * sc, 9004 + int(lx))
		Crayon.oval(ci, feet + Vector2(lx + 6, -22) * sc, Vector2(12, 5) * sc, Crayon.ORANGE)
	# tail, body, wing
	Crayon.poly(ci, PackedVector2Array([body + Vector2(-40, -6) * sc, body + Vector2(-66, -24) * sc, body + Vector2(-44, 12) * sc]),
		Crayon.INK, 3 * sc, Crayon.WHITE, 9010)
	Crayon.ellipse(ci, body, Vector2(48, 30) * sc, Crayon.INK, 4 * sc, Crayon.WHITE, 9011)
	Crayon.ellipse(ci, body + Vector2(-8, -2) * sc, Vector2(26, 14) * sc, Crayon.INK, 3 * sc, Color(0.85, 0.85, 0.9), 9012)
	# long neck
	var nb := body + Vector2(30, -14) * sc
	var nt := body + Vector2(38, -78 + sin(tm * 3.0) * 3.0) * sc
	Crayon.line(ci, nb, nt, Crayon.INK, 22 * sc, 9013)
	Crayon.line(ci, nb, nt, Crayon.WHITE, 15 * sc, 9014, 0.4)
	var head := nt + Vector2(4, -8) * sc
	Crayon.circle(ci, head, 19 * sc, Crayon.INK, 4 * sc, Crayon.WHITE, 9015)
	var open := 6.0 if fmod(tm, 1.2) < 0.25 else 1.0
	Crayon.poly(ci, PackedVector2Array([head + Vector2(13, -6) * sc, head + Vector2(44, -2 - open * 0.5) * sc, head + Vector2(13, 4) * sc]),
		Crayon.INK, 3 * sc, Crayon.ORANGE, 9016)
	Crayon.poly(ci, PackedVector2Array([head + Vector2(13, 5) * sc, head + Vector2(38, 4 + open) * sc, head + Vector2(13, 10) * sc]),
		Crayon.INK, 3 * sc, Crayon.ORANGE, 9017)
	Crayon.disc(ci, head + Vector2(6, -6) * sc, 4.5 * sc, Crayon.INK)
	Crayon.disc(ci, head + Vector2(7, -7.5) * sc, 1.5 * sc, Crayon.WHITE)
	if party:
		Crayon.party_hat(ci, head + Vector2(-2, -15) * sc, 15 * sc, Crayon.PURPLE, 9018, -0.2)
	else:
		# helmet with a star
		var hp := PackedVector2Array()
		for i in 8:
			var a := PI + PI * i / 7.0
			hp.append(head + Vector2(cos(a) * 23, sin(a) * 21 - 3) * sc)
		Crayon.poly(ci, hp, Crayon.INK, 4 * sc, Crayon.RED, 9019)
		Crayon.star(ci, head + Vector2(0, -14) * sc, 8 * sc, Crayon.INK, Crayon.YELLOW, 9020)


func paint_top() -> void:
	var hy := 0.0
	if phase == "title" or title_k > 0.0:
		_title_card()
	if phase in ["s1", "s2", "tally", "twist", "end"] and tally <= 0.05:
		_hud(hy)
	if tally > 0.0:
		_tally_panel()
	var head_y := y - cam_y - 210.0
	for p in pops:
		var k: float = p.t / 1.4
		var c: Color = p.c
		c.a = 1.0 - k * k
		var py := maxf(head_y, 250.0 + hy) - k * 80.0 - float(p.dy)
		Crayon.text(pen, Vector2(ME_X + 190 + p.x, py), p.s, p.size, c, 1, 700, Crayon.title_font())
	if banner_t > 0.0 and tally <= 0.05:
		var flash := banner == "ONE MORE SESSION!" and fmod(t, 0.5) < 0.2
		var col := Crayon.RED if session == 2 else Crayon.ORANGE
		var by := 262.0 + hy * 0.6
		pen.draw_rect(Rect2(-2000, by - 40, W + 4000, 80), Color(0, 0, 0, 0.35 * minf(1.0, banner_t * 3.0)))
		Crayon.text(pen, Vector2(640, by), banner, 50 if banner.length() > 18 else 64,
			Crayon.WHITE if flash else col.lightened(0.2), 1, 710, Crayon.title_font())


func _hud(hy: float) -> void:
	var ink := Crayon.INK if night < 0.5 else Crayon.WHITE
	# score + letters + special
	Crayon.text(pen, Vector2(104, 34 + hy), _fmt(score), 42, ink, 0, 720, Crayon.title_font(), 0.3, false)
	for i in word.length():
		var r := Rect2(104 + i * 40, 66 + hy, 34, 36)
		Crayon.rect(pen, r, ink, 3, Crayon.YELLOW if got[i] else Color(1, 1, 1, 0.25), 730 + i)
		Crayon.text(pen, r.get_center(), word[i], 26, Crayon.INK if got[i] else Color(ink, 0.35), 1, 740 + i, Crayon.title_font(), 0.3, false)
	var sr := Rect2(104, 112 + hy, 200, 16)
	pen.draw_rect(sr, Color(0, 0, 0, 0.25))
	var full := special >= 1.0
	pen.draw_rect(Rect2(sr.position, Vector2(sr.size.x * special, sr.size.y)), Crayon.YELLOW if not full or fmod(t, 0.3) < 0.15 else Crayon.ORANGE)
	Crayon.rect(pen, sr, ink, 3, Color(0, 0, 0, 0), 750)
	Crayon.text(pen, Vector2(sr.end.x + 10, sr.get_center().y), "SPECIAL!" if full else "special", 20, ink, 0, 751, null, 0.2, false)
	# the clock
	var tl := maxf(0.0, time_left)
	var secs := int(ceilf(tl))
	var clock := "%d:%02d" % [floori(secs / 60.0), secs % 60]
	var ccol := ink
	if tl <= 10.0 and clock_on:
		ccol = Crayon.RED
	Crayon.text(pen, Vector2(640, 42 + hy), clock, 60, ccol, 1, 760, Crayon.title_font())
	# goals
	Crayon.text(pen, Vector2(W - 24, 30 + hy), "GOALS %d/%d" % [_goals_done(), goals.size()], 28, ink, 2, 770, Crayon.title_font(), 0.3, false)
	for i in goals.size():
		var g: Dictionary = goals[i]
		var gyy := 64.0 + hy + i * 26.0
		var w := Crayon.text(pen, Vector2(W - 24, gyy), g.t, 21, Color(ink, 0.55 if g.done else 1.0), 2, 780 + i, null, 0.2, false)
		var bx := Vector2(W - 44 - w, gyy)
		pen.draw_rect(Rect2(bx - Vector2(9, 9), Vector2(18, 18)), Color(ink, 0.9), false, 2.0)
		if g.done:
			pen.draw_line(bx + Vector2(-7, 0), bx + Vector2(-2, 6), Crayon.GREEN, 4.0)
			pen.draw_line(bx + Vector2(-2, 6), bx + Vector2(9, -9), Crayon.GREEN, 4.0)
	# the combo in progress (or the one just landed)
	if not combo.is_empty() or combo_show > 0.0:
		var names := " + ".join(combo.slice(maxi(0, combo.size() - 4))) if not combo.is_empty() else last_combo
		var pts := "%s x %d" % [_fmt(int(combo_pts)), mini(combo.size(), 10)] if not combo.is_empty() else ""
		var cy := 150.0 + hy
		Crayon.text(pen, Vector2(640, cy), names, 30, ink, 1, 790, null, 0.6, false)
		if pts != "":
			Crayon.text(pen, Vector2(640, cy + 42), pts, 38, Crayon.ORANGE if session == 1 else Color(0.8, 0.6, 1.0), 1, 791, Crayon.title_font())
	if manual:
		var mr := Rect2(ME_X - 50, GROUND - cam_y - 230, 100, 14)
		pen.draw_rect(mr, Color(0, 0, 0, 0.3))
		var b := 0.5 + sin(manual_t * 4.0) * 0.4
		pen.draw_rect(Rect2(mr.position.x + mr.size.x * b - 4, mr.position.y - 4, 8, 22), Crayon.RED)
	if phase == "s1" and SESSION - time_left < 14.0 and not Narrator.is_active():
		# down on the concrete, out of the way
		var r := Rect2(150, 584, 980, 62)
		Crayon.rect(pen, r, Crayon.INK, 4, Color(1, 1, 1, 0.9), 794)
		Crayon.text(pen, Vector2(330, r.get_center().y), "TAP = OLLIE", 30, Crayon.RED, 1, 795, Crayon.title_font())
		Crayon.text(pen, Vector2(660, r.get_center().y), "TAP IN THE AIR = FLIP", 30, Crayon.BLUE, 1, 796, Crayon.title_font())
		Crayon.text(pen, Vector2(985, r.get_center().y), "HOLD = GRAB", 30, Crayon.GREEN.darkened(0.2), 1, 797, Crayon.title_font())


func _title_card() -> void:
	var off := (1.0 - title_k) * -700.0
	var r := Rect2(260, 175 + off, 760, 290)
	Crayon.rect(pen, r, Crayon.INK, 7, Color(0.15, 0.15, 0.2), 800)
	Crayon.text(pen, Vector2(640, r.position.y + 58), "TONY HONK'S", 54, Crayon.YELLOW, 1, 801, Crayon.title_font())
	Crayon.text(pen, Vector2(643, r.position.y + 143), "PRO SKATER 2", 84, Crayon.BLACK, 1, 802, Crayon.title_font())
	Crayon.text(pen, Vector2(640, r.position.y + 138), "PRO SKATER 2", 84, Crayon.RED, 1, 803, Crayon.title_font())
	Crayon.text(pen, Vector2(640, r.position.y + 218), "BIRTHDAY EDITION", 34, Crayon.WHITE, 1, 804, Crayon.title_font())
	Crayon.text(pen, Vector2(640, r.position.y + 262), "(not the real one)", 22, Color(1, 1, 1, 0.6), 1, 805, null, 0.2, false)


func _tally_panel() -> void:
	var off := (1.0 - tally) * 600.0
	var r := Rect2(300, 190 + off, 680, 330)
	var dark := session == 2
	Crayon.rect(pen, r, Crayon.INK, 7, Color(1, 0.97, 0.75) if not dark else Color(0.15, 0.1, 0.2), 820)
	var ink := Crayon.INK if not dark else Crayon.WHITE
	Crayon.text(pen, Vector2(640, r.position.y + 50), "SESSION OVER!", 54, Crayon.RED, 1, 821, Crayon.title_font())
	for i in goals.size():
		var g: Dictionary = goals[i]
		var gy := r.position.y + 112 + i * 36
		Crayon.text(pen, Vector2(r.position.x + 90, gy), g.t, 28, ink, 0, 822 + i, null, 0.3, false)
		var bx := Vector2(r.position.x + 60, gy)
		pen.draw_rect(Rect2(bx - Vector2(12, 12), Vector2(24, 24)), ink, false, 3.0)
		if g.done:
			pen.draw_line(bx + Vector2(-9, 0), bx + Vector2(-2, 8), Crayon.GREEN, 5.0)
			pen.draw_line(bx + Vector2(-2, 8), bx + Vector2(12, -12), Crayon.GREEN, 5.0)
	Crayon.text(pen, Vector2(640, r.end.y - 34), "SCORE: " + _fmt(score), 40, Crayon.BLUE if not dark else Crayon.YELLOW, 1, 830, Crayon.title_font())
