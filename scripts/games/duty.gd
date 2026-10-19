extends Screen
## Present 5: CALL OF BIRTHDAY: MODERN PARTYFARE (foam-dart shooting gallery).
## Boot camp, capture the cake... and then the next mission loads, and it isn't a game any more:
## the yard is a muddy battlefield in the rain, shells come whistling down, and Chumbo's friends
## are pinned down out there. Tap them to pull them back to the trench. Letters home between the
## days. Then the order comes to go over the top, and it goes very quiet. (No gore: the ones who
## don't come back leave only a helmet, and poppies grow there.)

const IDX := 4
const MAG := 12
const HORIZON := 330.0
const M1_GOAL := 16
const M2_GOAL := 20
## Pop-up target spots: [crate, scale]. Targets flip up from behind the crates.
const SPOTS := [
	[Rect2(110, 455, 170, 95), 0.95],
	[Rect2(400, 405, 130, 72), 0.72],
	[Rect2(750, 405, 130, 72), 0.72],
	[Rect2(985, 455, 165, 92), 0.92],
	[Rect2(250, 560, 190, 100), 1.08],
	[Rect2(800, 570, 180, 95), 1.04],
]
const CRATE_COLS := [Color(0.98, 0.5, 0.7), Color(0.22, 0.48, 0.9), Color(0.3, 0.72, 0.3), Color(0.58, 0.32, 0.78), Color(1.0, 0.85, 0.2), Color(0.98, 0.55, 0.16)]
const RANKS := ["RECRUIT", "PRIVATE PARTY", "CORPORAL CUPCAKE", "SERGEANT SPRINKLES", "LIEUTENANT LOLLIPOP",
	"CAPTAIN CANDLES", "MAJOR MUFFIN", "COLONEL CONFETTI", "GENERAL GIFTWRAP"]
## The squad at the front: Chumbo's friends from the party, in helmets that are too big for them.
const SQUAD := ["MAX", "LULU", "BEN", "OLLIE", "SAM", "RUBY"]
## Days at the front: [day, friends pinned down, shells, seconds of warning before each lands]
const WAVES := [[1, 2, 3, 2.6], [40, 3, 4, 2.2], [365, 4, 5, 1.9]]
const LETTERS := [
	"Dear Mom,\nIt's my birthday today. We had mud instead of cake. I'll be home soon.",
	"Dear Mom,\nSome of the guys aren't here any more. Nobody talks about it.",
	"Dear Mom,\nI can't remember what cake tastes like. Please don't forget me.",
]
const SHELL_R := 95.0
const CAKE_POS := Vector2(640, 492)
## Three little teddy bears hiding in the yard: on the bouncy castle, on the roof, and
## dangling from the bunting (the bunting one hangs from its string). [spot, hanging]
const TEDDIES := [[Vector2(300, 207), false], [Vector2(1040, 147), false], [Vector2(470, 214), true]]
const PIVOT := Vector2(1172, 742)

var phase := "intro"     # intro, m1, between, m2, twist, front, lull, charge, ending
var ammo := MAG
var reloading := 0.0
var empty_t := 0.0
var xp := 0
var rank := 0
var streak := 0
var misses_row := 0
var failed_joke := false
var grandma_hits := 0
var downed := 0
var goal := 0
var targets: Array = []
var drones: Array = []
var darts: Array = []
var stuck: Array = []
var pops: Array = []
var banner := {}
var hitmark := 0.0
var recoil := 0.0
var spawn_t := 1.0
var next_spot := -1
var spawned := 0
var uab := 0.0
var care := {}
var confetti_gun := 0.0
var strike := -1.0
var cakes: Array = []
var slices := 8
var slice_said := false
var night := false
var dark := 0.0
var no_darts := false
var loading := -1.0
# the front
var war := false
var dawn := false
var wave := -1
var day := 0
var squad: Array = []     # {name, state: trench/pinned/run/charge/lost, x, z, t, seed, shake}
var shells: Array = []    # {x, z, t, warn, boom, whistle}
var blasts: Array = []    # {p, t, r}
var helmets: Array = []   # {x, z, name}
var flashes: Array = []   # far-off flashes on the horizon {x, t}
var flash := 0.0
var whiteout := 0.0
var letter := ""
var letter_a := 0.0
var poppies := 0.0
var lost_today := 0
var pulled_said := false
var lost_said := false
var aim_rot := -0.35
## Teddy bears shot down (all three: a secret song, and they get up and dance to it).
var teddies := [{"down": 0.0, "hit": false}, {"down": 0.0, "hit": false}, {"down": 0.0, "hit": false}]
var teddy_party := false

var _baked_key := ""


func enter() -> void:
	Narrator.top = true
	use_back_layer()
	Audio.play_music("duty")
	add_button("reload", Rect2(24, 548, 196, 70), "RELOAD", _reload, Crayon.YELLOW, 34)
	get_button("reload").visible = false
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await line("welcome")
	await line("listen_up_recruit")
	_banner("MISSION 1", "BOOT CAMP", Crayon.YELLOW, 2.5)
	Audio.sfx("horn", -6)
	phase = "m1"
	goal = M1_GOAL
	downed = 0
	spawn_t = 0.8
	locked = false


# ------------------------------------------------------------------ shooting


func press(p: Vector2) -> void:
	if phase == "front" and not locked:
		_pull(p)
		return
	if not _playing():
		return
	if not care.is_empty() and care.landed and p.distance_to(care.pos + Vector2(0, -30)) < 80.0:
		_open_care()
		return
	_fire(p)


func _playing() -> bool:
	return phase == "m1" or phase == "m2"


func _fire(p: Vector2) -> void:
	if no_darts:
		Audio.sfx("click", -2, 0.6)
		return
	if confetti_gun > 0.0:
		_confetti_shot(p)
		return
	if reloading > 0.0:
		return
	if ammo <= 0:
		Audio.sfx("click", -4, 0.7)
		_reload()
		return
	ammo -= 1
	recoil = 1.0
	Audio.sfx("dart", -3, randf_range(0.95, 1.12))
	var h := _hit_test(p)
	darts.append({"to": p, "t": 0.0, "h": h})
	if h.is_empty() and _shoot_teddy(p):
		return
	if h.is_empty():
		misses_row += 1
		if misses_row >= 6 and not failed_joke:
			failed_joke = true
			_banner("MISSION FAILED", "...just kidding!", Crayon.RED, 2.5)
			Audio.sfx("wrong", -4)
			line_bg("mission_failed_just")
	else:
		misses_row = 0
		_on_hit(h, p)
	if ammo == 0:
		empty_t = 0.0


func _shoot_teddy(p: Vector2) -> bool:
	if teddy_party:
		return false
	for k in TEDDIES.size():
		var td: Dictionary = teddies[k]
		if not td.hit and p.distance_to(TEDDIES[k][0] + Vector2(0, -4)) < 24.0:
			td.hit = true
			Audio.sfx("squish", -2, 1.6)
			Audio.sfx("boing", -8, 1.4)
			pops.append({"p": TEDDIES[k][0] + Vector2(0, -30), "s": "115", "t": 0.0, "col": Crayon.YELLOW})
			var tw := create_tween()
			tw.tween_method(func(v: float): td.down = v, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			if teddies.all(func(x): return x.hit):
				_teddy_song()
			return true
	return false


## Every bear found: someone put a song on. The bears get back up to dance.
func _teddy_song() -> void:
	teddy_party = true
	Game.found_egg("duty")
	await wait(0.7)
	Audio.sfx("radio", -4)
	Audio.play_music("race", 0.8)
	_banner("SECRET SONG", "TEDDY BEAR PARTY", Crayon.PINK, 2.5)
	for td in teddies:
		var tw := create_tween()
		tw.tween_method(func(v: float): td.down = v, 1.0, 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await wait(0.6)
	line_bg("soldier_who_put_the")


func _reload() -> void:
	if reloading > 0.0 or ammo >= MAG or no_darts or not _playing():
		return
	reloading = 1.0
	Audio.sfx("reload", -2)


## Front-most thing under the point: drones, then cut-outs.
func _hit_test(p: Vector2) -> Dictionary:
	for d in drones:
		if d.state != "pop" and p.distance_to(d.pos) < 46.0 * d.sc + 10.0:
			return {"kind": "drone", "o": d}
	for i in range(targets.size() - 1, -1, -1):
		var tg: Dictionary = targets[i]
		if (tg.state == "rise" or tg.state == "up") and tg.rise > 0.45 and _target_rect(tg).grow(12).has_point(p):
			return {"kind": "target", "o": tg}
	return {}


func _on_hit(h: Dictionary, p: Vector2) -> void:
	var o: Dictionary = h.o
	match h.kind:
		"target":
			if o.kind == "grandma":
				_friendly_fire(o)
				return
			o.darts.append((p - _target_base(o)) / Vector2(_target_scale(o), _target_scale(o) * maxf(o.rise, 0.2)))
			o.state = "hit"
			_score(100, p)
			_downed()
		"drone":
			_pop_drone(o, p)


func _hitmarker() -> void:
	hitmark = 1.0
	Audio.sfx("hitmarker", -2)


func _score(n: int, p: Vector2, marker: bool = true) -> void:
	if marker:
		_hitmarker()
	xp += n
	pops.append({"p": p + Vector2(0, -30), "s": "+%d" % n, "t": 0.0, "col": Crayon.YELLOW})
	var want := mini(xp / 700, RANKS.size() - 1)
	if want > rank:
		rank = want
		Audio.sfx("levelup", -4)
		_banner("RANK UP!", RANKS[rank], Crayon.YELLOW, 2.0)


func _downed() -> void:
	downed += 1
	if phase != "m1" and phase != "m2":
		return
	streak += 1
	match streak:
		3:
			uab = 10.0
			Audio.sfx("streak")
			_banner("3 STREAK", "UAB ONLINE", Crayon.SKY, 2.0)
			line_bg("spy_balloon_online")
		5:
			Audio.sfx("streak")
			Audio.sfx("radio", -6)
			_banner("5 STREAK", "CARE PACKAGE", Crayon.GREEN, 2.0)
			care = {"pos": Vector2(randf_range(330, 900), -80), "landed": false, "t": 0.0}
			line_bg("care_package_inbound")
		7:
			Audio.sfx("streak")
			Audio.sfx("radio", -6)
			_banner("7 STREAK", "CAKE STRIKE", Crayon.PINK, 2.0)
			strike = 0.0
			streak = 0
			line_bg("cake_strike_inbound")
	if downed >= goal:
		_mission_done()


func _friendly_fire(o: Dictionary) -> void:
	o.state = "hit"
	o.ff = true
	grandma_hits += 1
	streak = 0
	xp = maxi(0, xp - 50)
	pops.append({"p": _target_base(o) + Vector2(0, -150), "s": "-50", "t": 0.0, "col": Crayon.RED})
	_banner("FRIENDLY FIRE!", "that's Grandma!", Crayon.RED, 1.8)
	Audio.sfx("wrong", -4)
	Audio.sfx("oof", -8, 1.5)
	if grandma_hits == 1:
		line_bg("friendly_fire_thats")
	elif grandma_hits == 3:
		line_bg("grandma_again_shes")


func _pop_drone(d: Dictionary, p: Vector2) -> void:
	d.state = "pop"
	d.st = 0.0
	Audio.sfx("pop", -2)
	confetti_burst(d.pos, 16)
	if d.slice:
		slices = mini(8, slices + 1)
		pops.append({"p": d.pos + Vector2(0, -50), "s": "SLICE SAVED!", "t": 0.0, "col": Crayon.PINK})
	_score(50, p)
	_downed()


# ------------------------------------------------------------------ killstreaks


func _open_care() -> void:
	Audio.sfx("tada", -4)
	Audio.sfx("pop")
	confetti_burst(care.pos + Vector2(0, -30), 40)
	confetti_gun = 8.0
	_banner("CONFETTI CANNON!", "tap tap tap!", Crayon.PINK, 2.0)
	care = {}


func _confetti_shot(p: Vector2) -> void:
	recoil = 1.0
	Audio.sfx("pop", -3, randf_range(0.8, 1.2))
	confetti_burst(p, 22)
	for tg in targets:
		if (tg.state == "rise" or tg.state == "up") and tg.kind != "grandma" and _target_rect(tg).get_center().distance_to(p) < 160.0:
			tg.state = "hit"
			_score(100, _target_rect(tg).get_center())
			_downed()
	for d in drones:
		if d.state != "pop" and d.pos.distance_to(p) < 160.0:
			_pop_drone(d, d.pos)


# ------------------------------------------------------------------ flow


func _mission_done() -> void:
	if phase == "m1":
		phase = "between"
		_clear_field()
		_banner("MISSION COMPLETE", "+500 XP", Crayon.GREEN, 3.0)
		xp += 500
		Audio.sfx("tada")
		Audio.sfx("cheer", -8)
		_mission2()
	elif phase == "m2":
		phase = "twist"
		_clear_field()
		_twist()


func _clear_field() -> void:
	locked = true
	for tg in targets:
		if tg.state != "hit":
			tg.state = "drop"
	for d in drones:
		d.state = "pop"
		d.st = 0.0
	care = {}
	confetti_gun = 0.0
	uab = 0.0
	streak = 0
	get_button("reload").visible = false


func _mission2() -> void:
	await wait(1.2)
	await line("mission_complete")
	night = false
	refresh_back()
	await line("mission_two_capture")
	_banner("MISSION 2", "CAPTURE THE CAKE", Crayon.YELLOW, 2.5)
	Audio.sfx("horn", -6)
	ammo = MAG
	phase = "m2"
	goal = M2_GOAL
	downed = 0
	spawn_t = 0.6
	locked = false


func _twist() -> void:
	_banner("MISSION COMPLETE", "the cake is safe", Crayon.GREEN, 3.0)
	Audio.sfx("tada")
	Audio.sfx("cheer", -8)
	await wait(1.2)
	await line("mission_complete_cake_safe")
	loading = 0.0
	var tw := create_tween()
	tw.tween_property(self, "loading", 0.72, 2.2)
	await wait(2.4)
	Audio.sfx("glitch")
	Audio.sfx("static", -8)
	Audio.play_music("duty_dark", 2.0)
	night = true
	war = true
	refresh_back()
	var tw2 := create_tween()
	tw2.tween_property(self, "dark", 1.0, 2.0)
	await wait(0.8)
	loading = -1.0
	_banner("MISSION 3", "THE FRONT", Color(0.85, 0.8, 0.7), 4.0)
	Audio.sfx("thud", -2, 0.5)
	await line("this_isnt_a_game")
	await line("incoming_your_friends")
	squad.clear()
	for k in SQUAD.size():
		squad.append({"name": SQUAD[k], "state": "trench", "x": 640.0, "z": 0.3, "t": 0.0, "seed": 3000 + k * 37, "shake": 0.0})
	_day(0)


## A day at the front: some of the squad are pinned down in the craters, and the shells come
## down right where they're hiding, one after another.
func _day(i: int) -> void:
	wave = i
	day = WAVES[i][0]
	lost_today = 0
	var idle := squad.filter(func(f): return f.state == "trench")
	idle.shuffle()
	var n := mini(int(WAVES[i][1]), idle.size())
	var warn: float = WAVES[i][3]
	for k in n:
		var f: Dictionary = idle[k]
		f.state = "pinned"
		f.x = 250.0 + (k + 0.5) * 780.0 / n + randf_range(-40, 40)
		f.z = randf_range(0.22, 0.5)
		f.t = 0.0
	shells.clear()
	for k in int(WAVES[i][2]):
		var sh := {"t": -(1.4 + k * warn * 0.85), "warn": warn, "x": randf_range(220, 1060), "z": randf_range(0.1, 0.5), "boom": false, "whistle": false}
		if k < n:
			# this one is coming down right where somebody is hiding
			sh.x = idle[k].x + randf_range(-25, 25)
			sh.z = idle[k].z + randf_range(-0.03, 0.03)
		shells.append(sh)
	_banner("DAY %d" % day, "", Color(0.85, 0.8, 0.7), 2.2)
	match i:
		1:
			line_bg("day_forty_it_hasnt")
		2:
			line_bg("day_three_hundred")
	phase = "front"
	locked = false


func _pull(p: Vector2) -> void:
	for f in squad:
		if f.state == "pinned" and _friend_rect(f).grow(24).has_point(p):
			f.state = "run"
			f.t = 0.0
			Audio.sfx("run", -6)
			Audio.sfx("whoosh", -12)
			if not pulled_said:
				pulled_said = true
				line_bg("go_go_go_back")
			return


func _boom(sh: Dictionary) -> void:
	sh.boom = true
	var at := _field_feet(sh.x, sh.z)
	blasts.append({"p": at, "t": 0.0, "r": 70.0 + sh.z * 140.0})
	flash = 0.35
	Audio.sfx("smash", -2, randf_range(0.6, 0.75))
	Audio.sfx("thud", 0, 0.55)
	for f in squad:
		if f.state == "pinned" and _field_feet(f.x, f.z).distance_to(at) < SHELL_R + f.z * 60.0:
			_lose(f)


## Somebody doesn't come back. All that's left out there is their helmet.
func _lose(f: Dictionary) -> void:
	f.state = "lost"
	helmets.append({"x": f.x, "z": f.z, "name": f.name})
	lost_today += 1
	if phase == "front" and not lost_said:
		lost_said = true
		line_bg("no_no_no_no")


func _tick_front(dt: float) -> void:
	for f in squad:
		f.shake = maxf(0.0, f.shake - dt)
		match f.state:
			"run":
				f.t += dt
				f.z += dt * 0.42
				if f.z >= 1.02:
					f.state = "trench"
					Audio.sfx("land", -6)
					pops.append({"p": Vector2(_field_feet(f.x, 0.95).x, 600), "s": "SAFE", "t": 0.0, "col": Crayon.GREEN.lightened(0.3)})
			"charge":
				f.t += dt
				if f.t > 0.0:
					f.z = maxf(0.18, f.z - dt * 0.2)
	if phase != "front":
		return
	var falling := false
	for sh in shells:
		if sh.boom:
			continue
		falling = true
		sh.t += dt
		if sh.t >= 0.0:
			if not sh.whistle:
				sh.whistle = true
				Audio.sfx("slide_down", -4, clampf(1.4 / sh.warn, 0.5, 1.2))
			for f in squad:
				if f.state == "pinned" and _field_feet(f.x, f.z).distance_to(_field_feet(sh.x, sh.z)) < SHELL_R:
					f.shake = 0.15
		if sh.t >= sh.warn:
			_boom(sh)
	if not falling:
		# the shelling stops for today; anyone still hiding crawls back
		var out := false
		for f in squad:
			if f.state == "pinned":
				f.state = "run"
			if f.state == "run":
				out = true
		if not out:
			_end_of_day()


func _end_of_day() -> void:
	phase = "lull"
	locked = true
	await wait(1.6)
	if lost_today > 0:
		await line("we_lost_good_people")
	else:
		await line("everyone_made_it")
	letter = LETTERS[wave]
	var tw := create_tween()
	tw.tween_property(self, "letter_a", 1.0, 0.6)
	await wait(0.7)
	match wave:
		0:
			await line("dear_mom_its_my")
		1:
			await line("dear_mom_some_of")
		2:
			await line("dear_mom_i_cant")
	await wait(0.8)
	var tw2 := create_tween()
	tw2.tween_property(self, "letter_a", 0.0, 0.6)
	await wait(0.8)
	if wave + 1 < WAVES.size():
		_day(wave + 1)
	else:
		_over_the_top()


## The order nobody wanted: everyone still in the trench climbs out and walks into it.
func _over_the_top() -> void:
	phase = "charge"
	locked = true
	await line("new_orders_everyone")
	await line("nobody_asked_them")
	var going := squad.filter(func(f): return f.state == "trench")
	for k in going.size():
		var f: Dictionary = going[k]
		f.state = "charge"
		f.x = 300.0 + (k + 0.5) * 680.0 / maxi(going.size(), 1)
		f.z = 1.0
		f.t = -k * 0.25
	Audio.sfx("horn", -2, 0.6)
	await wait(1.4)
	for k in 14:
		var at := _field_feet(randf_range(150, 1130), randf_range(0.05, 0.75))
		blasts.append({"p": at, "t": 0.0, "r": randf_range(80, 170)})
		flash = 0.4
		Audio.sfx("smash", -3 - k * 0.3, randf_range(0.55, 0.75))
		if k % 3 == 0:
			Audio.sfx("thud", -1, 0.5)
		await wait(0.28)
	# then everything goes white, and rings
	var tw := create_tween()
	tw.tween_property(self, "whiteout", 1.0, 0.25)
	Audio.stop_music(0.3)
	Audio.sfx("smash", 0, 0.45)
	for f in squad:
		if f.state == "charge":
			_lose(f)
	for k in 6:
		Audio.sfx("beep", -14 - k * 2, 2.8)
		await wait(0.45)
	await wait(0.6)
	blasts.clear()
	flashes.clear()
	dawn = true
	refresh_back()
	var tw2 := create_tween()
	tw2.tween_property(self, "whiteout", 0.0, 3.0)
	await wait(2.6)
	_ending()


## Morning. It's quiet. Poppies grow where they fell, and every one of them gets a cross
## (with a party hat on it).
func _ending() -> void:
	phase = "ending"
	locked = true
	Audio.play_music("duty_dark", 4.0)
	var tw := create_tween()
	tw.tween_property(self, "poppies", 1.0, 4.0)
	await wait(1.5)
	await line("its_quiet_now_it")
	await line("they_only_came_to")
	await line("dear_mom_im_the")
	await wait(0.6)
	await line("done")
	finish_game(IDX, "REMEMBER THEM")


func _banner(text: String, sub: String, col: Color, dur: float) -> void:
	banner = {"text": text, "sub": sub, "col": col, "t": dur, "dur": dur}


# ------------------------------------------------------------------ spawning


func _free_spots() -> Array:
	var used := {}
	for tg in targets:
		if tg.type == "pop":
			used[tg.spot] = true
	var out := []
	for i in SPOTS.size():
		if not used.has(i):
			out.append(i)
	return out


func _pick_next_spot() -> void:
	var free := _free_spots()
	next_spot = free[randi() % free.size()] if free.size() > 0 else -1


func _active_count() -> int:
	var n := 0
	for tg in targets:
		if tg.state == "rise" or tg.state == "up":
			n += 1
	for d in drones:
		if d.state != "pop":
			n += 1
	return n


func _spawn_pop(kind: String, stay: float) -> void:
	if next_spot < 0 or not _free_spots().has(next_spot):
		_pick_next_spot()
	if next_spot < 0:
		return
	targets.append({"type": "pop", "kind": kind, "spot": next_spot, "rise": 0.0, "state": "rise", "t": 0.0,
		"stay": stay, "darts": [], "seed": randi() % 900, "ff": false})
	Audio.sfx("switch", -10, 0.8)
	_pick_next_spot()


func _spawn_roller(kind: String) -> void:
	var dir := 1.0 if randf() < 0.5 else -1.0
	targets.append({"type": "roll", "kind": kind, "x": -90.0 if dir > 0 else W + 90.0, "y": 640.0, "sc": 0.78,
		"dir": dir, "speed": randf_range(150, 190), "rise": 1.0, "state": "up", "t": 0.0, "darts": [],
		"seed": randi() % 900, "ff": false})
	Audio.sfx("roll", -10)


func _spawn_drone() -> void:
	var left := randf() < 0.5
	var p := Vector2(-60.0 if left else W + 60.0, randf_range(130, 270))
	drones.append({"pos": p, "state": "fly", "slice": false, "sc": randf_range(0.8, 1.0), "st": 0.0,
		"speed": randf_range(85, 105), "seed": randi() % 900, "ph": randf() * TAU})


# ------------------------------------------------------------------ update


func tick(dt: float) -> void:
	recoil = maxf(0.0, recoil - dt * 6.0)
	hitmark = maxf(0.0, hitmark - dt * 4.0)
	flash = maxf(0.0, flash - dt * 2.0)
	var want_rot := clampf((mouse - PIVOT).angle() + PI * 0.5, -0.7, 0.05)
	aim_rot = lerpf(aim_rot, want_rot, minf(1.0, dt * 14.0))
	for d in darts:
		d.t += dt
		if d.t >= 0.09 and d.h.is_empty():
			stuck.append({"p": d.to, "life": 1.6})
	darts = darts.filter(func(d): return d.t < 0.09)
	for s in stuck:
		s.life -= dt
	stuck = stuck.filter(func(s): return s.life > 0.0)
	for p in pops:
		p.t += dt
		p.p.y -= 50.0 * dt
	pops = pops.filter(func(p): return p.t < 1.0)
	if not banner.is_empty():
		banner.t -= dt
		if banner.t <= 0.0:
			banner = {}
	if reloading > 0.0:
		reloading -= dt
		if reloading <= 0.0:
			reloading = 0.0
			ammo = MAG
	elif ammo == 0 and _playing() and not no_darts:
		empty_t += dt
		if empty_t > 0.7:
			_reload()
	var rb := get_button("reload")
	if not rb.is_empty():
		rb.visible = _playing() and not no_darts and ammo < MAG and reloading <= 0.0
	_tick_targets(dt)
	_tick_drones(dt)
	_tick_streaks(dt)
	if war:
		_tick_war(dt)
	if locked or not _playing():
		return
	match phase:
		"m1":
			_tick_m1(dt)
		"m2":
			_tick_m2(dt)


func _tick_m1(dt: float) -> void:
	spawn_t -= dt
	var max_up := 2 if downed < 7 else 3
	if spawn_t <= 0.0 and _active_count() < max_up:
		spawn_t = randf_range(1.1, 1.6)
		var kind := "grandma" if spawned >= 3 and randf() < 0.22 and not _grandma_up() else "crasher"
		_spawn_pop(kind, 2.8 if downed < 8 else 2.3)
		spawned += 1


func _tick_m2(dt: float) -> void:
	spawn_t -= dt
	if spawn_t <= 0.0 and _active_count() < 4:
		spawn_t = randf_range(1.1, 1.6)
		var r := randf()
		if r < 0.4:
			_spawn_drone()
		elif r < 0.7:
			_spawn_roller("grandma" if randf() < 0.15 and not _grandma_up() else "crasher")
		else:
			_spawn_pop("grandma" if randf() < 0.18 and not _grandma_up() else "crasher", 2.4)


func _grandma_up() -> bool:
	for tg in targets:
		if tg.kind == "grandma" and tg.state != "hit":
			return true
	return false


func _tick_targets(dt: float) -> void:
	for tg in targets:
		match tg.state:
			"rise":
				tg.rise = minf(1.0, tg.rise + dt * 6.0)
				if tg.rise >= 1.0:
					tg.state = "up"
			"up":
				if not locked:
					tg.t += dt
				if tg.type == "pop" and tg.t > tg.stay:
					tg.state = "drop"
			"drop", "hit":
				tg.rise = maxf(0.0, tg.rise - dt * (3.5 if tg.state == "hit" else 5.0))
		if tg.type == "roll" and tg.state != "hit":
			tg.x += tg.dir * tg.speed * dt
			if tg.x < -140.0 or tg.x > W + 140.0:
				tg.state = "gone"
	targets = targets.filter(func(tg): return tg.state != "gone" and not ((tg.state == "drop" or tg.state == "hit") and tg.rise <= 0.0))


func _tick_drones(dt: float) -> void:
	for d in drones:
		d.ph += dt * 3.0
		match d.state:
			"fly":
				var goal_p := CAKE_POS + Vector2(0, -95)
				var to: Vector2 = goal_p - d.pos
				if to.length() < 30.0:
					d.state = "flee"
					d.slice = slices > 1
					if d.slice:
						slices -= 1
						Audio.sfx("chomp", -6)
						if not slice_said and not locked:
							slice_said = true
							line_bg("they_took_a_slice")
				else:
					d.pos += to.normalized() * d.speed * dt
				d.pos.y += sin(d.ph) * 12.0 * dt
			"flee":
				d.pos += Vector2(sign(d.pos.x - 640.0 + 0.1) * 60.0, -110.0) * dt
				if d.pos.y < -120.0:
					d.state = "pop"
					d.st = 1.0
			"pop":
				d.st += dt
	drones = drones.filter(func(d): return not (d.state == "pop" and d.st > 0.3))


## Rain, the far-off guns, smoke, and the blasts fading.
func _tick_war(dt: float) -> void:
	_tick_front(dt)
	for b in blasts:
		b.t += dt
	blasts = blasts.filter(func(b): return b.t < 1.6)
	for fl in flashes:
		fl.t += dt
	flashes = flashes.filter(func(fl): return fl.t < 0.5)
	if not dawn and randf() < dt * 0.7:
		flashes.append({"x": randf_range(0, W), "t": 0.0})
		if randf() < 0.35:
			Audio.sfx("thud", -20, randf_range(0.4, 0.6))


func _tick_streaks(dt: float) -> void:
	uab = maxf(0.0, uab - dt)
	confetti_gun = maxf(0.0, confetti_gun - dt)
	if not care.is_empty():
		care.t += dt
		if not care.landed:
			care.pos.y += 120.0 * dt
			if care.pos.y >= 590.0:
				care.pos.y = 590.0
				care.landed = true
				Audio.sfx("thud", -4)
		elif care.t > 14.0 and _playing():
			_open_care()
	if strike >= 0.0:
		strike += dt
		if strike >= 0.9 and strike - dt < 0.9:
			for tg in targets:
				if (tg.state == "rise" or tg.state == "up") and tg.kind != "grandma":
					cakes.append({"o": tg, "t": 0.0, "x": _target_rect(tg).get_center().x, "drone": false})
			for d in drones:
				if d.state != "pop":
					cakes.append({"o": d, "t": 0.0, "x": d.pos.x, "drone": true})
		if strike > 2.6:
			strike = -1.0
	for c in cakes:
		c.t += dt
		if c.t >= 0.5 and not c.has("done"):
			c.done = true
			var o: Dictionary = c.o
			Audio.sfx("splat", -4)
			if c.drone:
				if o.state != "pop":
					_pop_drone(o, o.pos)
			elif o.state == "rise" or o.state == "up":
				o.state = "hit"
				o.caked = true
				_score(100, _target_rect(o).get_center())
				if _playing():
					_downed()
	cakes = cakes.filter(func(c): return c.t < 0.8)


# ------------------------------------------------------------------ geometry


func _target_base(tg: Dictionary) -> Vector2:
	if tg.type == "pop":
		var r: Rect2 = SPOTS[tg.spot][0]
		return Vector2(r.get_center().x, r.position.y + 8)
	return Vector2(tg.x, tg.y)


func _target_scale(tg: Dictionary) -> float:
	return SPOTS[tg.spot][1] if tg.type == "pop" else tg.sc


func _target_rect(tg: Dictionary) -> Rect2:
	var b := _target_base(tg)
	var s := _target_scale(tg)
	var h: float = 175.0 * s * tg.rise
	return Rect2(b.x - 54.0 * s, b.y - h, 108.0 * s, h - 20.0 * s * tg.rise)


## The battlefield in perspective: z = 0 far away on the horizon, 1 = the trench at your feet.
func _field_feet(x: float, z: float) -> Vector2:
	return Vector2(640.0 + (x - 640.0) * (0.45 + 0.75 * z), 365.0 + z * 380.0)


func _field_h(z: float) -> float:
	return 60.0 + z * 400.0


func _friend_rect(f: Dictionary) -> Rect2:
	var p := _field_feet(f.x, f.z)
	var h := _field_h(f.z) * 0.75
	return Rect2(p.x - h * 0.35, p.y - h, h * 0.7, h)


func _muzzle() -> Vector2:
	return PIVOT + Vector2(0, -250 + recoil * 26.0).rotated(aim_rot)


# ------------------------------------------------------------------ drawing


func _table_on() -> bool:
	return (phase == "m2" or phase == "twist") and not night


func _back_key() -> String:
	return "%s/%s/%s/%s" % [night, _table_on(), war, dawn]


func paint_back() -> void:
	_baked_key = _back_key()
	if war:
		_war_back()
		return
	var top := Color(0.45, 0.72, 1.0)
	var low := Color(0.78, 0.9, 1.0)
	var grass := Color(0.48, 0.8, 0.4)
	if night:
		top = Color(0.05, 0.03, 0.12)
		low = Color(0.25, 0.08, 0.2)
		grass = Color(0.12, 0.2, 0.14)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, 2000 + HORIZON), top)
	for i in 6:
		var y := i * HORIZON / 6.0
		pen.draw_rect(Rect2(-2000, y, W + 4000, HORIZON / 6.0 + 1), top.lerp(low, (i + 0.5) / 6.0))
	pen.draw_rect(Rect2(-2000, HORIZON, W + 4000, 2000), grass)
	if night:
		for i in 26:
			var sp := Vector2(fmod(i * 197.0, W), 20 + fmod(i * 83.0, 230))
			Crayon.dot(pen, sp, 2.5 + (i % 3), Color(1, 1, 0.85, 0.8))
		Crayon.circle(pen, Vector2(800, 74), 42, Crayon.INK, 4, Color(0.95, 0.93, 0.8), 3)
		Crayon.face(pen, Vector2(800, 77), 33, "wide", Vector2.ZERO, 4)
		Crayon.party_hat(pen, Vector2(808, 34), 24, Crayon.PURPLE.darkened(0.3), 5, 0.3)
	else:
		Crayon.sun(pen, Vector2(800, 70), 34, "happy", 3)
		Crayon.cloud(pen, Vector2(440, 76), 56, Crayon.WHITE, 6)
		Crayon.cloud(pen, Vector2(1010, 50), 46, Crayon.WHITE, 7)
	# bunting across the yard
	var flags := PackedVector2Array()
	for i in 14:
		var x := 330.0 + i * 70.0
		flags.append(Vector2(x, 150.0 + sin(i * 0.45) * 8.0 + pow((i - 6.5) / 6.5, 2) * -18.0))
	Crayon.path(pen, flags, Crayon.INK, 3, 8)
	for i in 13:
		var a := flags[i]
		var b := flags[i + 1]
		var m := (a + b) * 0.5 + Vector2(0, 34)
		var col: Color = Crayon.RAINBOW[i % 7]
		if night:
			col = col.darkened(0.55)
		Crayon.poly(pen, PackedVector2Array([a + Vector2(6, 2), b - Vector2(6, -2), m]), Crayon.INK, 2.5, col, 10 + i)
		if night:
			Crayon.dot(pen, a, 5, Color(1, 0.85, 0.4))
	# bouncy castle (left) and the house (right)
	var bc := Color(0.98, 0.5, 0.7) if not night else Color(0.35, 0.18, 0.28)
	Crayon.rect(pen, Rect2(40, 222, 290, 112), Crayon.INK, 5, bc, 30)
	for k in 4:
		var tr := Rect2(40 + k * 82, 176, 44, 60)
		Crayon.rect(pen, tr, Crayon.INK, 4, Crayon.YELLOW if not night else Color(0.35, 0.3, 0.15), 31 + k)
		Crayon.poly(pen, PackedVector2Array([tr.position + Vector2(-6, 2), tr.position + Vector2(22, -36), tr.position + Vector2(50, 2)]), Crayon.INK, 3,
			Crayon.BLUE if not night else Color(0.12, 0.15, 0.3), 36 + k)
	Crayon.poly(pen, PackedVector2Array([Vector2(130, 334), Vector2(185, 262), Vector2(240, 334)]), Crayon.INK, 4, Color(0.2, 0.1, 0.15), 41)
	var hc := Color(0.98, 0.85, 0.6) if not night else Color(0.25, 0.2, 0.22)
	Crayon.rect(pen, Rect2(990, 200, 250, 134), Crayon.INK, 5, hc, 42)
	Crayon.poly(pen, PackedVector2Array([Vector2(970, 204), Vector2(1115, 112), Vector2(1260, 204)]), Crayon.INK, 5, Crayon.RED if not night else Color(0.3, 0.08, 0.1), 43)
	for k in 2:
		var wr := Rect2(1018 + k * 140, 228, 62, 50)
		Crayon.rect(pen, wr, Crayon.INK, 4, Crayon.SKY if not night else Color(1, 0.85, 0.35), 44 + k)
		if night:
			# someone is always home
			Crayon.disc(pen, wr.get_center() + Vector2(-9, 4), 4, Crayon.BLACK)
			Crayon.disc(pen, wr.get_center() + Vector2(9, 4), 4, Crayon.BLACK)
	Crayon.rect(pen, Rect2(1092, 270, 46, 64), Crayon.INK, 4, Crayon.BROWN, 46)
	# fence on the horizon
	var fc := Color(1, 1, 1) if not night else Color(0.45, 0.42, 0.5)
	Crayon.line(pen, Vector2(-30, HORIZON - 30), Vector2(W + 30, HORIZON - 30), Crayon.INK, 4, 50)
	for k in 26:
		var x := -10.0 + k * 52.0
		if (x > 30 and x < 340) or (x > 980 and x < 1250):
			continue
		Crayon.rect(pen, Rect2(x, HORIZON - 48, 24, 54), Crayon.INK, 3, fc, 51 + k)
	# tree in the middle
	Crayon.rect(pen, Rect2(625, 205, 30, 128), Crayon.INK, 4, Crayon.BROWN, 80)
	Crayon.circle(pen, Vector2(640, 182), 62, Crayon.INK, 5, Crayon.GREEN.darkened(0.15 if not night else 0.65), 81)
	# grass tufts
	for k in 22:
		var gp := Vector2(fmod(k * 157.0, W), HORIZON + 30 + fmod(k * 89.0, 300))
		Crayon.line(pen, gp, gp + Vector2(-6, -14), grass.darkened(0.3), 3, 90 + k)
		Crayon.line(pen, gp, gp + Vector2(6, -16), grass.darkened(0.3), 3, 120 + k)
	# the cake table (mission 2)
	if _table_on():
		Crayon.rect(pen, Rect2(CAKE_POS.x - 95, CAKE_POS.y, 190, 18), Crayon.INK, 4, Crayon.WHITE, 150)
		Crayon.line(pen, CAKE_POS + Vector2(-80, 18), CAKE_POS + Vector2(-80, 70), Crayon.INK, 5, 151)
		Crayon.line(pen, CAKE_POS + Vector2(80, 18), CAKE_POS + Vector2(80, 70), Crayon.INK, 5, 152)
	# sandbag pillows along the bottom
	for k in 9:
		var pc := Vector2(70 + k * 150, 712 + (k % 2) * 8)
		var pcol := Color(0.92, 0.88, 0.78) if not night else Color(0.32, 0.3, 0.3)
		Crayon.ellipse(pen, pc, Vector2(88, 34), Crayon.INK, 4, pcol, 160 + k)


func paint() -> void:
	if _baked_key != _back_key():
		refresh_back()
	if war:
		_war()
		return
	if dark > 0.0 and not night:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.05, 0.0, 0.1, dark * 0.6))
	if _table_on():
		_cake(CAKE_POS, slices)
	for k in TEDDIES.size():
		_teddy(k)
	for tg in targets:
		if tg.type == "pop":
			_cutout(tg)
	for i in SPOTS.size():
		_crate(i)
	for tg in targets:
		if tg.type == "roll":
			_cutout(tg)
	for d in drones:
		_drone(d)
	for s in stuck:
		_dart_stub(s.p, 1.0, clampf(s.life * 2.0, 0, 1))
	if not care.is_empty():
		_care()
	for c in cakes:
		var f := clampf(c.t / 0.5, 0, 1)
		var to_y: float = (_target_rect(c.o).position.y if not c.drone else c.o.pos.y)
		var cp := Vector2(c.x, lerpf(-60, to_y, f * f))
		if c.t < 0.5:
			Crayon.rect(pen, Rect2(cp + Vector2(-26, -20), Vector2(52, 34)), Crayon.INK, 3, Crayon.PINK, 600)
			Crayon.rect(pen, Rect2(cp + Vector2(-28, -26), Vector2(56, 10)), Crayon.INK, 2, Crayon.WHITE, 601)
		else:
			Crayon.ellipse(pen, Vector2(c.x, to_y + 20), Vector2(60, 26), Crayon.INK, 3, Crayon.PINK.lightened(0.3), 602)
	if strike >= 0.0:
		_plane(Vector2(-200 + strike * 640, 100))
	if uab > 0.0:
		_uab()
	for d in darts:
		var from := _muzzle()
		var f: float = clampf(d.t / 0.09, 0, 1)
		var p: Vector2 = from.lerp(d.to, f)
		_dart_fly(p, (d.to - from).normalized(), lerpf(1.6, 0.8, f))
	_blaster()


func paint_top() -> void:
	# crosshair
	if _playing() and not locked:
		var c := mouse
		var col := Crayon.WHITE if confetti_gun <= 0.0 else Crayon.PINK
		var gap := 10.0 + recoil * 8.0
		for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			pen.draw_line(c + d * gap, c + d * (gap + 18), Crayon.BLACK, 7.0)
			pen.draw_line(c + d * gap, c + d * (gap + 18), col, 3.5)
		Crayon.disc(pen, c, 3, col)
		if confetti_gun > 0.0:
			Crayon.circle(pen, c, 150, Color(1, 0.6, 0.8, 0.6), 3, Color(0, 0, 0, 0), 701)
		if hitmark > 0.0:
			var a := hitmark
			for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				pen.draw_line(c + d * 9.0, c + d * 22.0, Color(1, 1, 1, a), 4.0)
	for p in pops:
		var a: float = 1.0 - p.t
		Crayon.text(pen, p.p, p.s, 34, Color(p.col, a), 1, 710, Crayon.title_font(), 0.4, false)
	_hud()
	if loading >= 0.0:
		var r := Rect2(340, 330, 600, 50)
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0, 0, 0, 0.5))
		Crayon.text(pen, Vector2(640, 300), "LOADING NEXT MISSION...", 40, Crayon.WHITE, 1, 720)
		Crayon.rect(pen, r, Crayon.WHITE, 4, Color(0, 0, 0, 0.4), 721)
		pen.draw_rect(Rect2(r.position + Vector2(6, 6), Vector2((r.size.x - 12) * loading, r.size.y - 12)), Crayon.GREEN if dark < 0.1 else Crayon.RED)
	if not banner.is_empty():
		_draw_banner()
	if letter_a > 0.0:
		_letter()
	if whiteout > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.97, 0.96, 0.93, whiteout))


func _hud() -> void:
	var ink := Crayon.INK if not night else Crayon.WHITE
	if phase in ["m1", "m2", "between"]:
		var title := "MISSION 1: BOOT CAMP" if phase != "m2" else "MISSION 2: CAPTURE THE CAKE"
		Crayon.text(pen, Vector2(110, 30), title, 30, ink, 0, 730, null, 0.5, false)
		Crayon.text(pen, Vector2(110, 64), "CRASHERS DOWN: %d / %d" % [mini(downed, goal), goal], 26, ink, 0, 731, null, 0.5, false)
	elif war:
		_war_hud()
		return
	if phase != "intro":
		hud("XP %d" % xp, ink)
		var y := 84.0 + (120.0 if Narrator.top and Narrator.is_active() else 0.0)
		Crayon.text(pen, Vector2(W - 24, y), RANKS[rank], 22, ink, 2, 734, null, 0.4, false)
		if phase == "m1" or phase == "m2":
			var nxt := "UAB" if streak < 3 else ("CARE PACKAGE" if streak < 5 else "CAKE STRIKE")
			var need := 3 if streak < 3 else (5 if streak < 5 else 7)
			Crayon.text(pen, Vector2(W - 24, y + 30), "STREAK %d  (%s at %d)" % [streak, nxt, need], 22, ink, 2, 735, null, 0.4, false)
	# ammo
	if _playing() or phase == "ending" or phase == "banner":
		var ac := Crayon.WHITE if night else Crayon.INK
		var at := "%d / %d" % [ammo, MAG]
		if confetti_gun > 0.0:
			at = "CONFETTI!"
		elif reloading > 0.0:
			at = "RELOADING..."
		elif no_darts:
			at = "0 / 0"
		Crayon.text(pen, Vector2(30, 660), at, 40, ac if ammo > 3 or reloading > 0.0 else Crayon.RED, 0, 740, Crayon.title_font(), 0.4, false)
		for k in MAG:
			var dp := Vector2(34 + k * 16, 700)
			var full := k < ammo and reloading <= 0.0
			Crayon.disc(pen, dp, 6, Crayon.ORANGE if full else Color(0.5, 0.5, 0.5, 0.4))
		if confetti_gun > 0.0:
			pen.draw_rect(Rect2(30, 620, 190 * confetti_gun / 8.0, 8), Crayon.PINK)
		if reloading > 0.0:
			pen.draw_rect(Rect2(30, 620, 190 * (1.0 - reloading), 8), Crayon.YELLOW)


func _draw_banner() -> void:
	var k := clampf((banner.dur - banner.t) * 6.0, 0, 1) * clampf(banner.t * 3.0, 0, 1)
	var y := 250.0 - (1.0 - k) * 40.0
	pen.draw_rect(Rect2(-2000, y - 62, W + 4000, 124 if banner.sub != "" else 90), Color(0, 0, 0, 0.45 * k))
	var col: Color = banner.col
	col.a = k
	Crayon.text(pen, Vector2(643, y - 14 + 3), banner.text, 58, Color(0, 0, 0, 0.6 * k), 1, 750, Crayon.title_font(), 0.5, false)
	Crayon.text(pen, Vector2(640, y - 14), banner.text, 58, col, 1, 751, Crayon.title_font(), 0.6)
	if banner.sub != "":
		Crayon.text(pen, Vector2(640, y + 38), banner.sub, 34, Color(1, 1, 1, k), 1, 752, null, 0.6)


func _crate(i: int) -> void:
	var r: Rect2 = SPOTS[i][0]
	var col: Color = CRATE_COLS[i]
	if night:
		col = col.darkened(0.6)
	Crayon.present(pen, r, col, Crayon.WHITE if not night else Color(0.5, 0.5, 0.55), 200 + i * 30)
	if uab > 0.0 and i == next_spot:
		var a := 0.5 + 0.5 * sin(t * 10.0)
		Crayon.circle(pen, r.get_center() + Vector2(0, -50), 26, Color(1, 0.15, 0.2, a), 4, Color(1, 0.2, 0.2, a * 0.3), 260 + i)
		Crayon.text(pen, r.get_center() + Vector2(0, -50), "!", 36, Color(1, 0.15, 0.2, a), 1, 270 + i, Crayon.title_font(), 0.3, false)


## Cardboard cut-out on a stick. Local origin = bottom of the stick; flips up/down by y-scale.
func _cutout(tg: Dictionary) -> void:
	if tg.rise <= 0.01:
		return
	var b := _target_base(tg)
	var s := _target_scale(tg)
	var sd: int = tg.seed
	pen.draw_set_transform(b, 0.0, Vector2(s, s * tg.rise))
	var card := Color(0.86, 0.7, 0.5)
	if night:
		card = card.darkened(0.4)
	if tg.type == "roll":
		Crayon.line(pen, Vector2(-60, 6), Vector2(60, 6), Crayon.INK, 9, sd)
		Crayon.disc(pen, Vector2(-40, 16), 9, Crayon.BLACK)
		Crayon.disc(pen, Vector2(40, 16), 9, Crayon.BLACK)
	Crayon.line(pen, Vector2(0, 0), Vector2(0, -34), Crayon.BROWN, 8, sd + 1)
	Crayon.rect(pen, Rect2(-54, -175, 108, 145), Crayon.INK, 4, card, sd + 2)
	if tg.kind == "grandma":
		Crayon.rect(pen, Rect2(-34, -104, 68, 46), Crayon.INK, 3, Crayon.PINK, sd + 3)
		Crayon.heart(pen, Vector2(0, -81), 12, Crayon.INK, Crayon.RED, sd + 4)
		Crayon.circle(pen, Vector2(0, -150), 9, Crayon.INK, 2, Color(0.85, 0.85, 0.88), sd + 5)
		Crayon.circle(pen, Vector2(0, -128), 24, Crayon.INK, 3, Color(1, 0.88, 0.78), sd + 6)
		Crayon.circle(pen, Vector2(-9, -130), 7, Crayon.INK, 2, Color(0, 0, 0, 0), sd + 7)
		Crayon.circle(pen, Vector2(9, -130), 7, Crayon.INK, 2, Color(0, 0, 0, 0), sd + 8)
		Crayon._arc(pen, Vector2(0, -122), 8, 0.2 * PI, 0.8 * PI, Crayon.INK, 2.5, sd + 9)
		Crayon.text(pen, Vector2(0, -43), "GRANDMA", 19, Crayon.RED.darkened(0.2), 1, sd + 10, null, 0.2, false)
	else:
		Crayon.rect(pen, Rect2(-34, -104, 68, 64), Crayon.INK, 3, Crayon.RED, sd + 3)
		Crayon.poly(pen, PackedVector2Array([Vector2(4, -98), Vector2(-10, -72), Vector2(2, -72), Vector2(-6, -46), Vector2(12, -78), Vector2(0, -78)]),
			Crayon.INK, 2, Crayon.YELLOW, sd + 4)
		for k in 3:
			Crayon.line(pen, Vector2(-14 + k * 14, -150), Vector2(-18 + k * 18, -166), Crayon.INK, 4, sd + 5 + k)
		Crayon.circle(pen, Vector2(0, -128), 24, Crayon.INK, 3, Color(1, 0.86, 0.7), sd + 8)
		pen.draw_rect(Rect2(-20, -138, 17, 10), Crayon.BLACK)
		pen.draw_rect(Rect2(3, -138, 17, 10), Crayon.BLACK)
		pen.draw_line(Vector2(-4, -134), Vector2(4, -134), Crayon.BLACK, 2.0)
		var mood_x: bool = tg.state == "hit"
		if mood_x:
			Crayon.line(pen, Vector2(-8, -116), Vector2(8, -116), Crayon.INK, 3, sd + 9)
		else:
			Crayon.line(pen, Vector2(-9, -117), Vector2(9, -121), Crayon.INK, 3, sd + 9)
	if tg.get("caked", false):
		Crayon.ellipse(pen, Vector2(0, -150), Vector2(46, 22), Crayon.INK, 3, Color(1, 0.75, 0.85), sd + 11)
	for d in tg.darts:
		_dart_stub(d, 1.0 / s, 1.0)
	pen.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A tiny crayon teddy bear. Shot ones tumble off out of sight; after the secret they dance
## (with sunglasses on).
func _teddy(k: int) -> void:
	var td: Dictionary = teddies[k]
	var spot: Vector2 = TEDDIES[k][0]
	var hanging: bool = TEDDIES[k][1]
	if td.down >= 1.0:
		return
	var down: float = td.down
	var a := 1.0 - down
	var p := spot + Vector2(down * 24.0, down * down * 90.0)
	var rot := down * 2.5
	if teddy_party:
		p.y -= absf(sin(t * 8.0 + k)) * 10.0
		rot = sin(t * 8.0 + k) * 0.25
	if hanging and not td.hit:
		Crayon.line(pen, spot + Vector2(0, -66), spot + Vector2(0, -16), Color(Crayon.INK, a), 2, 2400 + k, 0.3)
	var fur := Color(0.72, 0.5, 0.3) if not night else Color(0.42, 0.3, 0.2)
	var ink := Color(Crayon.INK, a)
	pen.draw_set_transform(p, rot, Vector2.ONE)
	for sx in [-1.0, 1.0]:
		Crayon.disc(pen, Vector2(sx * 9, 10), 4.5, Color(fur, a))
		Crayon.disc(pen, Vector2(sx * 7, -21), 3.5, Color(fur, a))
	Crayon.circle(pen, Vector2(0, 4), 9, ink, 2, Color(fur, a), 2410 + k)
	Crayon.circle(pen, Vector2(0, -12), 8, ink, 2, Color(fur, a), 2420 + k)
	Crayon.disc(pen, Vector2(0, -9), 3.5, Color(fur.lightened(0.35), a))
	Crayon.disc(pen, Vector2(0, -10), 1.4, ink)
	if teddy_party:
		pen.draw_rect(Rect2(-8, -16, 16, 4), ink)
	else:
		Crayon.disc(pen, Vector2(-3, -14), 1.3, ink)
		Crayon.disc(pen, Vector2(3, -14), 1.3, ink)
	pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if teddy_party and k == 0:
		for j in 3:
			var ph := fmod(t * 0.7 + j / 3.0, 1.0)
			Crayon.note(pen, TEDDIES[j][0] + Vector2(14 + sin(ph * 6.0) * 6.0, -30 - ph * 40), 18, Color(Crayon.RAINBOW[(j * 2) % 7], 1.0 - ph))


func _dart_stub(p: Vector2, sc: float, a: float) -> void:
	Crayon.disc(pen, p, 8.0 * sc, Color(0.2, 0.45, 0.95, a))
	Crayon.disc(pen, p + Vector2(2, -2) * sc, 3.0 * sc, Color(1, 1, 1, a * 0.6))


func _dart_fly(p: Vector2, dir: Vector2, sc: float) -> void:
	pen.draw_line(p - dir * 26.0 * sc, p, Crayon.ORANGE, 10.0 * sc)
	Crayon.disc(pen, p, 7.0 * sc, Crayon.BLUE)


func _drone(d: Dictionary) -> void:
	if d.state == "pop":
		var r: float = 30.0 + d.st * 120.0
		Crayon.star(pen, d.pos, r, Crayon.INK, Color(1, 0.85, 0.3, 1.0 - d.st / 0.3), d.seed)
		return
	var c: Vector2 = d.pos
	var s: float = d.sc
	var col: Color = Crayon.RAINBOW[d.seed % 7]
	if night:
		col = col.darkened(0.4)
	# propeller
	var spin := sin(t * 30.0 + d.seed) * 30.0 * s
	Crayon.line(pen, c + Vector2(0, -46 * s), c + Vector2(0, -60 * s), Crayon.INK, 3, d.seed + 1)
	pen.draw_line(c + Vector2(-spin, -60 * s), c + Vector2(spin, -60 * s), Crayon.INK, 4.0)
	Crayon.ellipse(pen, c, Vector2(38, 44) * s, Crayon.INK, 3, col, d.seed + 2)
	Crayon.disc(pen, c + Vector2(-12, -16) * s, 7 * s, Color(1, 1, 1, 0.6))
	Crayon.face(pen, c + Vector2(0, 6 * s), 18 * s, "smirk", Vector2.ZERO, d.seed + 3)
	Crayon.line(pen, c + Vector2(0, 44 * s), c + Vector2(0, 62 * s), Crayon.INK, 2, d.seed + 4)
	Crayon.rect(pen, Rect2(c + Vector2(-16, 62) * s, Vector2(32, 18) * s), Crayon.INK, 3, Crayon.BROWN, d.seed + 5)
	if d.slice:
		Crayon.poly(pen, PackedVector2Array([c + Vector2(-12, 62) * s, c + Vector2(14, 62) * s, c + Vector2(-4, 44) * s]), Crayon.INK, 2, Crayon.PINK, d.seed + 6)
	else:
		Crayon.line(pen, c + Vector2(10, 64) * s, c + Vector2(22, 40) * s, Crayon.GREY, 3, d.seed + 7)
	if uab > 0.0:
		Crayon.circle(pen, c, 58 * s, Color(1, 0.2, 0.2, 0.7), 3, Color(0, 0, 0, 0), d.seed + 8)


func _cake(base: Vector2, n: int) -> void:
	var w := 40.0 + n * 14.0
	Crayon.cake(pen, base, w, 64, Crayon.PINK, mini(n, 5), true, 400)


func _care() -> void:
	var p: Vector2 = care.pos
	if not care.landed:
		Crayon._arc(pen, p + Vector2(0, -90), 70, PI, TAU, Crayon.INK, 4, 410)
		pen.draw_rect(Rect2(p + Vector2(-70, -92), Vector2(140, 6)), Crayon.WHITE)
		Crayon.line(pen, p + Vector2(-68, -90), p + Vector2(-26, -40), Crayon.INK, 2, 411)
		Crayon.line(pen, p + Vector2(68, -90), p + Vector2(26, -40), Crayon.INK, 2, 412)
	Crayon.present(pen, Rect2(p + Vector2(-42, -70), Vector2(84, 70)), Crayon.GREEN, Crayon.YELLOW, 413)
	if care.landed:
		var bob := absf(sin(t * 5.0)) * 8.0
		Crayon.text(pen, p + Vector2(0, -110 - bob), "TAP!", 36, Crayon.YELLOW, 1, 414, Crayon.title_font(), 0.5, false)


func _plane(p: Vector2) -> void:
	Crayon.ellipse(pen, p, Vector2(70, 18), Crayon.INK, 4, Crayon.GREY.lightened(0.3), 420)
	Crayon.poly(pen, PackedVector2Array([p + Vector2(-10, 0), p + Vector2(20, 0), p + Vector2(-20, 46)]), Crayon.INK, 3, Crayon.GREY, 421)
	Crayon.poly(pen, PackedVector2Array([p + Vector2(-10, 0), p + Vector2(20, 0), p + Vector2(-20, -40)]), Crayon.INK, 3, Crayon.GREY, 422)
	Crayon.text(pen, p + Vector2(0, 2), "CAKE AIR", 16, Crayon.RED, 1, 423, null, 0.2, false)


func _uab() -> void:
	var x := W + 120 - (10.0 - uab) / 10.0 * (W + 240)
	var p := Vector2(x, 70 + sin(t * 2.0) * 6.0)
	Crayon.balloon(pen, p, 26, Crayon.SKY, 20, 430)
	Crayon.ellipse(pen, p + Vector2(0, 50), Vector2(16, 6), Crayon.INK, 2, Crayon.WHITE, 431)
	Crayon.line(pen, p + Vector2(0, 50), p + Vector2(10, 38), Crayon.INK, 2, 432)
	Crayon.text(pen, p + Vector2(0, -50), "UAB", 20, Crayon.RED, 1, 433, null, 0.2, false)


# ------------------------------------------------------------------ the front: drawing


func _war_back() -> void:
	var top := Color(0.2, 0.18, 0.2) if not dawn else Color(0.62, 0.62, 0.66)
	var low := Color(0.5, 0.36, 0.28) if not dawn else Color(0.86, 0.83, 0.78)
	var mud := Color(0.5, 0.41, 0.32) if not dawn else Color(0.56, 0.5, 0.42)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, 2000 + HORIZON), top)
	for i in 6:
		pen.draw_rect(Rect2(-2000, i * HORIZON / 6.0, W + 4000, HORIZON / 6.0 + 1), top.lerp(low, (i + 0.5) / 6.0))
	pen.draw_rect(Rect2(-2000, HORIZON, W + 4000, 2000), mud)
	# smoke columns far away
	if not dawn:
		for k in 3:
			var x := 180.0 + k * 430.0
			for j in 5:
				Crayon.disc(pen, Vector2(x + sin(j * 1.7 + k) * 24.0, HORIZON - 30 - j * 46.0), 30.0 + j * 9.0, Color(0.12, 0.1, 0.11, 0.35 - j * 0.05))
	# what's left of the bouncy castle: flat on the ground, in the mud
	var bc := Color(0.5, 0.36, 0.42)
	Crayon.poly(pen, PackedVector2Array([Vector2(40, 334), Vector2(70, 300), Vector2(130, 312), Vector2(180, 290), Vector2(250, 316), Vector2(320, 306), Vector2(340, 334)]), Crayon.INK, 4, bc, 30)
	Crayon.poly(pen, PackedVector2Array([Vector2(150, 300), Vector2(172, 270), Vector2(190, 296)]), Crayon.INK, 3, Color(0.38, 0.34, 0.22), 31)
	# the house, without its roof
	var hc := Color(0.42, 0.38, 0.36)
	Crayon.poly(pen, PackedVector2Array([Vector2(990, 334), Vector2(990, 214), Vector2(1030, 196), Vector2(1060, 230), Vector2(1100, 186), Vector2(1150, 222), Vector2(1190, 200), Vector2(1240, 232), Vector2(1240, 334)]), Crayon.INK, 5, hc, 42)
	for k in 2:
		Crayon.rect(pen, Rect2(1018 + k * 140, 236, 62, 46), Crayon.INK, 4, Color(0.08, 0.07, 0.08), 44 + k)
		Crayon.line(pen, Vector2(1018 + k * 140, 236), Vector2(1080 + k * 140, 282), Crayon.BROWN, 6, 46 + k)
		Crayon.line(pen, Vector2(1080 + k * 140, 236), Vector2(1018 + k * 140, 282), Crayon.BROWN, 6, 48 + k)
	# the tree, burnt down to a stump with two branches
	Crayon.line(pen, Vector2(640, 334), Vector2(636, 230), Color(0.15, 0.12, 0.12), 14, 80)
	Crayon.line(pen, Vector2(638, 262), Vector2(600, 226), Color(0.15, 0.12, 0.12), 7, 81)
	Crayon.line(pen, Vector2(637, 248), Vector2(672, 214), Color(0.15, 0.12, 0.12), 6, 82)
	# the fence, broken, and torn bunting hanging off one post
	for k in 26:
		var x := -10.0 + k * 52.0
		if (x > 30 and x < 340) or (x > 980 and x < 1250) or k % 3 == 1:
			continue
		var lean := (fmod(k * 37.0, 7.0) - 3.0) * 0.06
		Crayon.line(pen, Vector2(x + 12, HORIZON + 6), Vector2(x + 12 + lean * 50.0, HORIZON - 44), Color(0.3, 0.27, 0.27), 8, 51 + k)
	for k in 3:
		var a := Vector2(400 + k * 40, 150 + k * 22)
		Crayon.poly(pen, PackedVector2Array([a, a + Vector2(26, 6), a + Vector2(8, 34)]), Crayon.INK, 2, Color(0.4, 0.38, 0.36), 70 + k)
	# craters
	for k in 9:
		var cp := _field_feet(140.0 + fmod(k * 397.0, 1000.0), 0.08 + fmod(k * 0.23, 0.6))
		var r := 40.0 + fmod(k * 13.0, 30.0) + cp.y * 0.08
		Crayon.ellipse(pen, cp, Vector2(r, r * 0.3), Crayon.INK, 3, mud.darkened(0.3), 120 + k)
	# barbed wire, two rows
	for row in 2:
		var y := HORIZON + 40.0 + row * 120.0
		var posts := 9 if row == 0 else 7
		for k in posts:
			var x := 60.0 + k * (1160.0 / (posts - 1))
			Crayon.line(pen, Vector2(x, y + 10), Vector2(x + 4, y - 24 - row * 8), Color(0.28, 0.22, 0.18), 5, 140 + k + row * 10)
		var pts := PackedVector2Array()
		for k in 60:
			pts.append(Vector2(40.0 + k * 20.0, y - 14 - row * 4 + (6.0 if k % 2 == 0 else -6.0)))
		Crayon.path(pen, pts, Color(0.2, 0.2, 0.22), 2, 160 + row)
	# our trench: sandbags along the bottom
	for k in 9:
		var pc := Vector2(70 + k * 150, 712 + (k % 2) * 8)
		Crayon.ellipse(pen, pc, Vector2(88, 34), Crayon.INK, 4, Color(0.5, 0.45, 0.36), 170 + k)


func _war() -> void:
	# far-off guns
	for fl in flashes:
		var a: float = 1.0 - fl.t / 0.5
		Crayon.disc(pen, Vector2(fl.x, HORIZON - 10), 60.0, Color(1.0, 0.75, 0.4, 0.25 * a))
	# where they fell: just their helmets
	for hm in helmets:
		var p := _field_feet(hm.x, hm.z)
		var sc := _field_h(hm.z) / 300.0
		_helmet_at(pen, p + Vector2(0, -8 * sc), 20.0 * sc, 1.0, 2500 + int(hm.x) % 50, 0.5)
	if poppies > 0.0:
		# in the morning, poppies all over the field, and a cross for every one of them
		for k in 46:
			var z := 0.08 + fmod(k * 0.137, 0.8)
			var p := _field_feet(60.0 + fmod(k * 263.0, 1160.0), z)
			_poppy(p, (4.0 + z * 9.0) * clampf(poppies * 2.0 - fmod(k * 0.31, 1.0), 0.0, 1.0))
		var n := helmets.size()
		for k in n:
			var x := 640.0 + (k - (n - 1) * 0.5) * minf(170.0, 1000.0 / maxf(n, 1))
			_cross(Vector2(x, 640), clampf(poppies * 1.6 - k * 0.1, 0.0, 1.0), helmets[k].name)
	# incoming: a shadow on the ground that grows until it lands
	for sh in shells:
		if sh.boom or sh.t < 0.0:
			continue
		var p := _field_feet(sh.x, sh.z)
		var f: float = clampf(sh.t / sh.warn, 0.0, 1.0)
		var r: float = (30.0 + f * 60.0) * (0.6 + float(sh.z))
		Crayon.ellipse(pen, p, Vector2(r, r * 0.3), Color(0.8, 0.15, 0.1, 0.5 + 0.4 * f), 3, Color(0, 0, 0, 0.15 + 0.3 * f), 2600)
		Crayon.text(pen, p + Vector2(0, -r * 0.3 - 30), "!", 40, Color(1, 0.3, 0.2, 0.5 + 0.5 * sin(t * 14.0)), 1, 2601, Crayon.title_font(), 0.3, false)
	# the squad, far ones first
	var order := squad.filter(func(f): return f.state in ["pinned", "run", "charge"])
	order.sort_custom(func(a, b): return a.z < b.z)
	for f in order:
		_friend(f)
	for b in blasts:
		var k: float = b.t / 1.6
		var r: float = b.r * (0.5 + k)
		if b.t < 0.25:
			Crayon.star(pen, b.p + Vector2(0, -r * 0.3), r, Crayon.INK, Color(1, 0.75, 0.3, 1.0 - b.t * 3.0), 2610)
		for j in 5:
			var d := Vector2(cos(j * 1.3), -absf(sin(j * 1.3 + 0.5))) * r * 0.8
			Crayon.disc(pen, b.p + d * k + Vector2(0, -k * 40.0), r * 0.35 * (1.0 - k * 0.5), Color(0.3, 0.27, 0.26, 0.6 * (1.0 - k)))
	# rain (not at dawn)
	if not dawn:
		for i in 70:
			var x := fmod(i * 137.0 + t * 260.0, W + 200.0) - 100.0
			var y := fmod(i * 89.0 + t * 720.0, H)
			pen.draw_line(Vector2(x, y), Vector2(x - 8, y + 22), Color(0.75, 0.8, 0.9, 0.3), 2.0)
	if flash > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(1, 0.95, 0.85, flash * 0.5))
	if phase == "front" and wave == 0 and not pulled_said:
		Crayon.text(pen, Vector2(640, 668), "TAP YOUR FRIENDS TO PULL THEM BACK!", 30, Crayon.WHITE, 1, 2620, Crayon.title_font())


## One of Chumbo's friends out on the field: hiding in a crater, running back, or walking away.
func _friend(f: Dictionary) -> void:
	var p := _field_feet(f.x, f.z) + Vector2(sin(t * 60.0) * 3.0 * float(f.shake > 0.0), 0)
	var h := _field_h(f.z) * 0.75
	match f.state:
		"pinned":
			Crayon.ellipse(pen, p, Vector2(h * 0.75, h * 0.2), Crayon.INK, 3, Color(0.22, 0.17, 0.14), int(f.seed) + 1)
			draw_soldier(pen, p + Vector2(0, h * 0.18), h * 0.85, "o", "stand", t, int(f.seed))
			# the near lip of the crater hides their legs
			Crayon.poly(pen, PackedVector2Array([p + Vector2(-h * 0.8, 0), p + Vector2(h * 0.8, 0), p + Vector2(h * 0.7, h * 0.18), p + Vector2(-h * 0.7, h * 0.18)]), Crayon.INK, 3, Color(0.36, 0.28, 0.22), int(f.seed) + 2)
		"run":
			draw_soldier(pen, p, h, "o", "walk", t * 9.0, int(f.seed))
		"charge":
			draw_soldier(pen, p, h, "flat", "walk", t * 5.0, int(f.seed))
	# name tag
	var tag := p + Vector2(0, -h * 1.12)
	var fs := int(clampf(h * 0.16, 18, 28))
	Crayon.text(pen, tag + Vector2(2, 2), f.name, fs, Color(0, 0, 0, 0.7), 1, int(f.seed) + 3, Crayon.title_font(), 0.3, false)
	Crayon.text(pen, tag, f.name, fs, Crayon.WHITE, 1, int(f.seed) + 3, Crayon.title_font(), 0.3, false)


func _poppy(p: Vector2, r: float) -> void:
	if r <= 0.5:
		return
	Crayon.line(pen, p, p + Vector2(0, r * 2.0), Color(0.25, 0.45, 0.2), maxf(1.5, r * 0.25), 2630)
	for k in 4:
		var a := k * TAU / 4.0 + 0.4
		Crayon.disc(pen, p + Vector2(cos(a), sin(a)) * r * 0.6, r * 0.7, Color(0.85, 0.12, 0.12))
	Crayon.disc(pen, p, r * 0.35, Color(0.1, 0.08, 0.08))


## A little wooden cross with their name, and a party hat on top.
func _cross(p: Vector2, sc: float, name: String) -> void:
	if sc <= 0.05:
		return
	var wood := Color(0.62, 0.5, 0.36)
	Crayon.line(pen, p, p + Vector2(0, -120 * sc), Crayon.INK, 16 * sc + 2, 2640)
	Crayon.line(pen, p, p + Vector2(0, -120 * sc), wood, 12 * sc, 2641)
	Crayon.line(pen, p + Vector2(-46 * sc, -80 * sc), p + Vector2(46 * sc, -80 * sc), Crayon.INK, 26 * sc + 2, 2642)
	Crayon.line(pen, p + Vector2(-46 * sc, -80 * sc), p + Vector2(46 * sc, -80 * sc), wood, 22 * sc, 2643)
	Crayon.party_hat(pen, p + Vector2(0, -122 * sc), 20 * sc, Crayon.RED, 2644, 0.2)
	_helmet_at(pen, p + Vector2(0, -6 * sc), 22 * sc, 1.0, 2646, 0.3)
	Crayon.text(pen, p + Vector2(0, -80 * sc), name, int(maxf(10.0, 20 * sc)), Crayon.INK, 1, 2645, Crayon.title_font(), 0.3, false)


func _letter() -> void:
	var r := Rect2(340, 230, 600, 230)
	var a := letter_a
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0, 0, 0, 0.4 * a))
	Crayon.rect(pen, r, Color(Crayon.INK, a), 4, Color(0.96, 0.93, 0.84, a), 2650)
	for k in 5:
		pen.draw_line(Vector2(r.position.x + 20, r.position.y + 70 + k * 34), Vector2(r.end.x - 20, r.position.y + 70 + k * 34), Color(0.6, 0.7, 0.9, 0.5 * a), 2.0)
	var lines := letter.split("\n")
	Crayon.text(pen, r.position + Vector2(30, 46), lines[0], 30, Color(Crayon.INK, a), 0, 2651, null, 0.5, false)
	Crayon.text_block(pen, r.position + Vector2(r.size.x * 0.5, 100), lines[1] if lines.size() > 1 else "", 28, r.size.x - 60, Color(Crayon.INK, a), 1, 2652, 1.2)
	Crayon.text(pen, r.end - Vector2(40, 26), "Love, Chumbo", 26, Color(Crayon.INK, a), 2, 2653, null, 0.5, false)
	# a muddy thumbprint
	Crayon.disc(pen, r.position + Vector2(r.size.x - 70, 40), 16, Color(0.35, 0.27, 0.2, 0.5 * a))


func _war_hud() -> void:
	Crayon.text(pen, Vector2(110, 30), "MISSION 3: THE FRONT", 30, Crayon.WHITE, 0, 736, null, 0.5, false)
	if day > 0:
		Crayon.text(pen, Vector2(110, 66), "DAY %d" % day, 30, Color(0.95, 0.85, 0.7), 0, 737, null, 0.5, false)
	# the squad: who is still here
	var y := 34.0 + (120.0 if Narrator.top and Narrator.is_active() else 0.0)
	for k in squad.size():
		var f: Dictionary = squad[k]
		var gone: bool = f.state == "lost"
		var p := Vector2(W - 30, y + k * 30)
		var col := Crayon.WHITE if not gone else Color(0.6, 0.55, 0.55)
		var w := Crayon.text(pen, p, f.name, 22, col, 2, 738 + k, Crayon.title_font(), 0.3, false)
		_helmet_at(pen, p + Vector2(-w - 20, 2), 11.0, 1.0 if not gone else 0.5, 760 + k)
		if gone:
			Crayon.line(pen, p + Vector2(-w - 4, -2), p + Vector2(4, -2), Color(0.85, 0.2, 0.2), 3, 770 + k)


## One of Chumbo's friends at the front: a kid in a helmet that is too big for them.
## Also the finale/title mascot (with a party hat stuck on the helmet).
static func draw_soldier(ci: CanvasItem, feet: Vector2, h: float, mood: String, pose: String, ph: float, sd: int, a: float = 1.0) -> void:
	Crayon.person(ci, feet, h, Color(Crayon.INK, a), mood, Color(0, 0, 0, 0), pose, ph, sd)
	_helmet_at(ci, feet + Vector2(0, -h * 0.87 - h * 0.04), h * 0.17, a, sd + 50)


static func _helmet_at(ci: CanvasItem, c: Vector2, r: float, a: float, sd: int, tilt: float = 0.0) -> void:
	var pts := PackedVector2Array()
	for k in 11:
		var ang := PI + k * PI / 10.0 + tilt
		pts.append(c + Vector2(cos(ang) * r, sin(ang) * r * 0.85))
	Crayon.poly(ci, pts, Color(Crayon.INK, a), maxf(2.0, r * 0.12), Color(0.42, 0.47, 0.3, a), sd)
	var brim := Vector2(cos(tilt), sin(tilt)) * r * 1.25
	Crayon.line(ci, c - brim, c + brim, Color(Crayon.INK, a), maxf(2.0, r * 0.15), sd + 1)


static func draw_mascot(ci: CanvasItem, feet: Vector2, sc: float, tm: float) -> void:
	var h := 170.0 * sc
	draw_soldier(ci, feet, h, "happy", "stand", tm * 3.0, 4321)
	Crayon.party_hat(ci, feet + Vector2(4, -h * 1.02), h * 0.1, Crayon.PINK, 4330, 0.25)


func _blaster() -> void:
	if war:
		return
	var back := Vector2(0, 26.0 * recoil).rotated(aim_rot)
	pen.draw_set_transform(PIVOT + back, aim_rot, Vector2.ONE)
	var sleeve := Color(0.3, 0.6, 0.3) if not night else Color(0.2, 0.35, 0.22)
	Crayon.rect(pen, Rect2(-46, 60, 92, 140), Crayon.INK, 5, sleeve, 900)
	Crayon.ellipse(pen, Vector2(0, 52), Vector2(42, 30), Crayon.INK, 4, Color(1, 0.86, 0.72), 901)
	Crayon.poly(pen, PackedVector2Array([Vector2(-46, 40), Vector2(46, 40), Vector2(40, -120), Vector2(-40, -120)]), Crayon.INK, 5, Crayon.ORANGE, 902)
	Crayon.line(pen, Vector2(-38, -10), Vector2(38, -10), Crayon.YELLOW, 8, 906)
	Crayon.line(pen, Vector2(-36, -50), Vector2(36, -50), Crayon.YELLOW, 8, 907)
	Crayon.rect(pen, Rect2(-32, -136, 64, 56), Crayon.INK, 4, Crayon.BLUE, 903)
	for k in 3:
		Crayon.disc(pen, Vector2(-17 + k * 17, -122), 7, Crayon.ORANGE.lightened(0.2))
	Crayon.rect(pen, Rect2(-18, -236, 36, 104), Crayon.INK, 4, Crayon.YELLOW, 904)
	Crayon.rect(pen, Rect2(-24, -254, 48, 22), Crayon.INK, 4, Crayon.ORANGE, 905)
	pen.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if recoil > 0.55:
		var m := _muzzle()
		Crayon.star(pen, m, 22.0 * recoil, Color(1, 1, 1, 0.0), Color(1, 1, 0.8, recoil * 0.8), 910)
