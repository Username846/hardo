extends Screen
## Present 5: CALL OF BIRTHDAY: MODERN PARTYFARE (foam-dart shooting gallery).
## Boot camp, capture the cake... then a bonus mode where the party guests keep coming
## back, round after round. The round counter only goes up.

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
## Zombie rounds: what the counter says, how many guests, how many at once.
const ROUNDS := [[1, 3, 2], [2, 4, 3], [3, 4, 3], [8, 5, 4], [23, 5, 4], [99, 6, 5], [-1, 999, 6]]
const CAKE_POS := Vector2(640, 492)
const PIVOT := Vector2(1172, 742)

var phase := "intro"     # intro, m1, between, m2, twist, banner, zombies, ending
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
var zombies: Array = []
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
var round_i := -1
var round_left := 0
var round_t := 0.0
var night := false
var dark := 0.0
var hug := 0.0
var hug_said := false
var no_darts := false
var loading := -1.0
var end_cake := 0.0
var aim_rot := -0.35

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
	await say("Present number five! It's CALL OF BIRTHDAY! Here's your foam dart blaster. Tap anywhere to shoot!")
	await say("Listen up, recruit! Knock down sixteen cardboard party crashers. Do NOT shoot Grandma!", Narrator.SARGE)
	_banner("MISSION 1", "BOOT CAMP", Crayon.YELLOW, 2.5)
	Audio.sfx("horn", -6)
	phase = "m1"
	goal = M1_GOAL
	downed = 0
	spawn_t = 0.8
	locked = false


# ------------------------------------------------------------------ shooting


func press(p: Vector2) -> void:
	if not _playing():
		return
	if not care.is_empty() and care.landed and p.distance_to(care.pos + Vector2(0, -30)) < 80.0:
		_open_care()
		return
	_fire(p)


func _playing() -> bool:
	return phase == "m1" or phase == "m2" or phase == "zombies"


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
	if h.is_empty():
		misses_row += 1
		if misses_row >= 6 and not failed_joke and phase != "zombies":
			failed_joke = true
			_banner("MISSION FAILED", "...just kidding!", Crayon.RED, 2.5)
			Audio.sfx("wrong", -4)
			say_bg("Mission failed. Just kidding! We'll get 'em next time!", Narrator.SARGE)
	else:
		misses_row = 0
		_on_hit(h, p)
	if ammo == 0:
		empty_t = 0.0


func _reload() -> void:
	if reloading > 0.0 or ammo >= MAG or no_darts or not _playing():
		return
	reloading = 1.0
	Audio.sfx("reload", -2)


## Front-most thing under the point: zombies (nearest first), drones, then cut-outs.
func _hit_test(p: Vector2) -> Dictionary:
	var zs := zombies.duplicate()
	zs.sort_custom(func(a, b): return a.z > b.z)
	for z in zs:
		if z.state == "walk" and _zombie_rect(z).grow(10).has_point(p):
			return {"kind": "zombie", "o": z}
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
		"zombie":
			o.hp -= 1
			o.flinch = 1.0
			o.z = maxf(0.0, o.z - 0.035)
			var fs := _zombie_feet(o)
			var hh := _zombie_h(o)
			o.darts.append((p - fs) / hh)
			_hitmarker()
			if o.hp <= 0:
				o.state = "dizzy"
				o.st = 0.0
				Audio.sfx("boing", -6, 0.7)
				Audio.sfx("giggle_low", -10)
				_score(150, p, false)


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
		if phase == "zombies":
			_banner("RANK UP!", "STILL HERE", Color(0.9, 0.2, 0.25), 2.0)
		else:
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
			say_bg("Spy balloon online!", Narrator.SARGE)
		5:
			Audio.sfx("streak")
			Audio.sfx("radio", -6)
			_banner("5 STREAK", "CARE PACKAGE", Crayon.GREEN, 2.0)
			care = {"pos": Vector2(randf_range(330, 900), -80), "landed": false, "t": 0.0}
			say_bg("Care package inbound! Tap the present!", Narrator.SARGE)
		7:
			Audio.sfx("streak")
			Audio.sfx("radio", -6)
			_banner("7 STREAK", "CAKE STRIKE", Crayon.PINK, 2.0)
			strike = 0.0
			streak = 0
			say_bg("Cake strike inbound!", Narrator.SARGE)
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
		say_bg("FRIENDLY FIRE! That's Grandma, soldier! She brought snacks!", Narrator.SARGE)
	elif grandma_hits == 3:
		say_bg("Grandma again?! She's knitting you a sweater!", Narrator.SARGE)


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
	await say("Mission complete! Outstanding work, recruit!", Narrator.SARGE)
	night = false
	refresh_back()
	await say("Mission two: capture the cake! The crashers want the birthday cake. Pop the balloon drones before they grab a slice!", Narrator.SARGE)
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
	await say("Mission complete! The cake is safe! You're a birthday hero!", Narrator.SARGE)
	loading = 0.0
	var tw := create_tween()
	tw.tween_property(self, "loading", 0.72, 2.2)
	await wait(2.4)
	Audio.sfx("glitch")
	Audio.sfx("static", -8)
	Audio.play_music("duty_dark", 2.0)
	night = true
	refresh_back()
	var tw2 := create_tween()
	tw2.tween_property(self, "dark", 1.0, 2.0)
	await wait(0.8)
	loading = -1.0
	_banner("BONUS MODE UNLOCKED", "PARTY ZOMBIES", Color(0.9, 0.2, 0.25), 4.0)
	Audio.sfx("zombie", -4, 0.8)
	await say("Bonus mode unlocked.", Narrator.DARK)
	await say("The party guests are coming back, Chumbo. They always come back. Tap them until they get dizzy.", Narrator.DARK)
	ammo = MAG
	round_i = -1
	locked = false
	_next_round()


func _next_round() -> void:
	round_i += 1
	phase = "banner"
	round_t = 0.0
	banner = {}
	var r: Array = ROUNDS[round_i]
	Audio.sfx("heartbeat", -2)
	Audio.sfx("zombie", -8, 0.7)
	match round_i:
		0:
			say_bg("Round one. They just want to sing to you.", Narrator.DARK)
		1:
			say_bg("Round two. There are always more guests.", Narrator.DARK)
		2:
			say_bg("Round three. Don't you want to stay?", Narrator.DARK)
		3:
			say_bg("Round eight. You don't remember rounds four to seven. Nobody does.", Narrator.DARK)
		4:
			say_bg("Round twenty three. The cake is still warm. It is always warm.", Narrator.DARK)
		5:
			say_bg("Round ninety nine. Nobody ever leaves this party.", Narrator.DARK)
		6:
			say_bg("Round forever.", Narrator.CREEPY)
	await wait(2.6)
	round_left = r[1]
	spawn_t = 0.3
	round_t = 0.0
	phase = "zombies"


func _ending() -> void:
	phase = "ending"
	locked = true
	no_darts = true
	ammo = 0
	get_button("reload").visible = false
	_banner("OUT OF DARTS", "", Color(0.9, 0.2, 0.25), 3.0)
	Audio.sfx("click", 0, 0.5)
	await wait(0.4)
	Audio.sfx("click", 0, 0.45)
	await wait(1.0)
	await say("Out of darts.", Narrator.DARK)
	# everyone stops being dizzy and gathers round
	zombies.clear()
	for k in 9:
		var x := 640.0 + (k - 4) * 150.0
		var goal_z := 0.5 + (1.0 - absf(k - 4) / 4.0) * 0.14
		zombies.append(_make_zombie(x, 0.05 + randf() * 0.1, goal_z))
	Audio.sfx("zombie", -4, 0.9)
	await wait(3.5)
	await say("They were never attacking, Chumbo. They just want you to come back to the party.", Narrator.DARK)
	var tw := create_tween()
	tw.tween_property(self, "end_cake", 1.0, 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.sfx("sparkle")
	Audio.sfx("cheer", -10, 0.6)
	await wait(1.6)
	await say("Happy birthday, Chumbo. There is always another round.", Narrator.CREEPY)
	await say("Present number five, done! Mission accomplished, soldier!")
	finish_game(IDX, "MISSION COMPLETE")


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


func _make_zombie(x: float, z: float, stop_z: float = 2.0) -> Dictionary:
	var shirts := [Color(0.55, 0.7, 0.55), Color(0.6, 0.55, 0.75), Color(0.75, 0.55, 0.55), Color(0.5, 0.62, 0.75), Color(0.72, 0.68, 0.5)]
	return {"x": x, "z": z, "hp": 3, "state": "walk", "flinch": 0.0, "st": 0.0, "ph": randf() * TAU,
		"seed": randi() % 900, "hat": Crayon.RAINBOW[randi() % 7], "shirt": shirts[randi() % shirts.size()],
		"darts": [], "speed": randf_range(0.075, 0.095) * (1.0 + maxi(round_i, 0) * 0.07), "stop": stop_z, "a": 1.0,
		"hat_fly": Vector2.ZERO}


# ------------------------------------------------------------------ update


func tick(dt: float) -> void:
	recoil = maxf(0.0, recoil - dt * 6.0)
	hitmark = maxf(0.0, hitmark - dt * 4.0)
	hug = maxf(0.0, hug - dt * 1.5)
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
	_tick_zombies(dt)
	_tick_streaks(dt)
	if locked or not _playing():
		return
	match phase:
		"m1":
			_tick_m1(dt)
		"m2":
			_tick_m2(dt)
		"zombies":
			_tick_round(dt)


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


func _tick_round(dt: float) -> void:
	round_t += dt
	spawn_t -= dt
	var r: Array = ROUNDS[round_i]
	var walking := 0
	for z in zombies:
		if z.state == "walk":
			walking += 1
	if round_left > 0 and spawn_t <= 0.0 and walking < r[2]:
		spawn_t = randf_range(1.0, 1.8) if round_i < 6 else randf_range(0.5, 0.9)
		round_left -= 1
		zombies.append(_make_zombie(randf_range(260, 1020), 0.0))
		if randf() < 0.4:
			Audio.sfx("zombie", -10, randf_range(0.8, 1.15))
	if round_i == 6:
		# round forever: it doesn't end. The darts do.
		if round_t > 13.0:
			_ending()
		return
	if round_left <= 0 and zombies.is_empty():
		_next_round()


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
							say_bg("They took a slice! Don't worry, there's plenty.")
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


func _tick_zombies(dt: float) -> void:
	for z in zombies:
		z.ph += dt * 4.0
		z.flinch = maxf(0.0, z.flinch - dt * 4.0)
		match z.state:
			"walk":
				if phase == "ending":
					if z.stop < 1.5:
						z.z = minf(z.stop, z.z + dt * 0.15)
				elif not locked:
					z.z += z.speed * dt * (1.0 - z.flinch * 0.8)
					if z.z >= 0.93:
						_hug(z)
			"dizzy":
				z.st += dt
				z.hat_fly += Vector2(90, -260 + z.st * 500) * dt
				if z.st > 1.4:
					z.state = "leave"
					z.st = 0.0
			"leave":
				z.st += dt
				z.z = maxf(0.0, z.z - dt * 0.12)
				z.a = 1.0 - clampf(z.st / 1.2, 0, 1)
	zombies = zombies.filter(func(z): return not (z.state == "leave" and z.a <= 0.0))
	zombies.sort_custom(func(a, b): return a.z < b.z)


func _hug(z: Dictionary) -> void:
	hug = 1.0
	z.z = 0.32
	z.hp = 3
	z.darts.clear()
	Audio.sfx("zombie", -2, 1.1)
	Audio.sfx("squish", -6)
	if not hug_said:
		hug_said = true
		say_bg("It just wanted a hug. It will come back.", Narrator.DARK)


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


func _zombie_feet(z: Dictionary) -> Vector2:
	var zz: float = z.z
	return Vector2(640.0 + (z.x - 640.0) * (0.45 + 0.75 * zz), 365.0 + zz * 380.0)


func _zombie_h(z: Dictionary) -> float:
	return 60.0 + z.z * 400.0


func _zombie_rect(z: Dictionary) -> Rect2:
	var f := _zombie_feet(z)
	var h := _zombie_h(z)
	return Rect2(f.x - h * 0.24, f.y - h, h * 0.48, h)


func _muzzle() -> Vector2:
	return PIVOT + Vector2(0, -250 + recoil * 26.0).rotated(aim_rot)


# ------------------------------------------------------------------ drawing


func _table_on() -> bool:
	return (phase == "m2" or phase == "twist") and not night


func paint_back() -> void:
	_baked_key = "%s/%s" % [night, _table_on()]
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
	if _baked_key != "%s/%s" % [night, _table_on()]:
		refresh_back()
	if dark > 0.0 and not night:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.05, 0.0, 0.1, dark * 0.6))
	if _table_on():
		_cake(CAKE_POS, slices)
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
	for z in zombies:
		_zombie(z)
	if end_cake > 0.0:
		var cb := Vector2(640, 790 - end_cake * 120)
		Crayon.cake(pen, cb, 340, 130, Crayon.PINK.lerp(Color(0.5, 0.2, 0.3), 0.5), 9, false, 500)
		Crayon.cake_flames(pen, cb, 340, 130, 9, 500)
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
	if hug > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(1.0, 0.55, 0.75, hug * 0.55))
		Crayon.text(pen, Vector2(640, 360), "HUG!", 90, Color(1, 1, 1, hug), 1, 700, Crayon.title_font())


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
	if phase == "banner" or (phase == "zombies" and round_t < 1.5):
		_round_title(Vector2(640, 250), 1.0 if phase == "banner" else 1.0 - round_t / 1.5)


func _hud() -> void:
	var ink := Crayon.INK if not night else Crayon.WHITE
	if phase in ["m1", "m2", "between"]:
		var title := "MISSION 1: BOOT CAMP" if phase != "m2" else "MISSION 2: CAPTURE THE CAKE"
		Crayon.text(pen, Vector2(110, 30), title, 30, ink, 0, 730, null, 0.5, false)
		Crayon.text(pen, Vector2(110, 64), "CRASHERS DOWN: %d / %d" % [mini(downed, goal), goal], 26, ink, 0, 731, null, 0.5, false)
	elif phase in ["zombies", "banner", "ending"] and round_i >= 0:
		var rr: int = ROUNDS[round_i][0]
		Crayon.text(pen, Vector2(110, 30), "PARTY ZOMBIES", 30, Color(1, 0.35, 0.4), 0, 732, null, 0.5, false)
		if rr > 0:
			Crayon.text(pen, Vector2(110, 66), "ROUND %d" % rr, 30, Color(1, 0.35, 0.4), 0, 733, null, 0.5, false)
		else:
			Crayon.text(pen, Vector2(110, 66), "ROUND", 30, Color(1, 0.35, 0.4), 0, 733, null, 0.5, false)
			_infinity(Vector2(232, 66), 22, Color(1, 0.35, 0.4), 4)
	if phase != "intro":
		hud("XP %d" % xp, ink)
		var y := 84.0 + (120.0 if Narrator.top and Narrator.is_active() else 0.0)
		Crayon.text(pen, Vector2(W - 24, y), RANKS[rank] if phase not in ["zombies", "banner", "ending"] or rank == 0 else "STILL HERE", 22, ink, 2, 734, null, 0.4, false)
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


## The zombie round number in drippy red crayon.
func _round_title(c: Vector2, a: float) -> void:
	if round_i < 0:
		return
	var rr: int = ROUNDS[round_i][0]
	var red := Color(0.85, 0.08, 0.12, a)
	pen.draw_rect(Rect2(-2000, c.y - 80, W + 4000, 160), Color(0, 0, 0, 0.5 * a))
	var s := "ROUND %d" % rr if rr > 0 else "ROUND"
	var w := Crayon.text(pen, c + Vector2(-60 if rr < 0 else 0, 0), s, 96, red, 1, 760, Crayon.title_font())
	if rr < 0:
		_infinity(c + Vector2(w * 0.5 + 40, 6), 52, red, 10)
	# drips
	var x0 := c.x - w * 0.5 - (60 if rr < 0 else 0)
	for k in 9:
		var x := x0 + fmod(k * 73.0 + 17.0, w)
		var ln := 18.0 + fmod(k * 37.0, 40.0) + sin(t * 1.5 + k) * 6.0
		var y0 := c.y + 34
		Crayon.line(pen, Vector2(x, y0), Vector2(x, y0 + ln), red, 6, 770 + k, 0.3)
		Crayon.disc(pen, Vector2(x, y0 + ln + 3), 6, red)


func _infinity(c: Vector2, sz: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		var d := 1.0 + sin(a) * sin(a)
		pts.append(c + Vector2(cos(a) / d, sin(a) * cos(a) / d) * sz * 1.3)
	Crayon.path(pen, pts, col, w, 780)


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


func _zombie(z: Dictionary) -> void:
	var feet := _zombie_feet(z)
	var h := _zombie_h(z)
	var shove := Vector2(sin(z.ph * 7.0) * 8.0 * z.flinch, -z.flinch * 6.0)
	var sitting: bool = z.state == "dizzy" or z.state == "leave"
	draw_guest(pen, feet + shove, h, z.shirt, z.hat if z.state == "walk" or phase == "ending" else Color(0, 0, 0, 0), z.ph, z.seed, z.a, sitting)
	if z.state == "walk":
		for d in z.darts:
			var dp: Vector2 = feet + shove + d * h
			_dart_stub(dp, clampf(h / 260.0, 0.4, 1.6), 1.0)
	if z.state == "dizzy":
		var head := feet + Vector2(0, -h * 0.62)
		for k in 3:
			var a := t * 5.0 + k * TAU / 3.0
			Crayon.star(pen, head + Vector2(cos(a) * h * 0.18, sin(a) * h * 0.05 - h * 0.16), maxf(6.0, h * 0.04), Crayon.INK, Crayon.YELLOW, 800 + k)
		Crayon.party_hat(pen, head + Vector2(0, -h * 0.15) + z.hat_fly, h * 0.09, z.hat, 810, z.st * 6.0)


## A party guest who has been at the party for a very long time. Arms out, holding a slice
## of cake for you. feet = ground point, h = height. Also used by the finale cast.
static func draw_guest(ci: CanvasItem, feet: Vector2, h: float, shirt: Color, hat: Color, ph: float, sd: int, a: float = 1.0, sitting: bool = false) -> void:
	var ink := Color(Crayon.INK, a)
	var w := maxf(3.0, h * 0.035)
	var skin := Color(0.78, 0.86, 0.74, a)
	var hip := feet + Vector2(0, -h * 0.42)
	if sitting:
		hip = feet + Vector2(0, -h * 0.12)
		Crayon.line(ci, hip, hip + Vector2(-h * 0.22, h * 0.02), ink, w, sd)
		Crayon.line(ci, hip, hip + Vector2(h * 0.22, h * 0.02), ink, w, sd + 1)
	else:
		var sway := sin(ph) * h * 0.06
		Crayon.line(ci, hip, feet + Vector2(-h * 0.12 + sway, 0), ink, w, sd)
		Crayon.line(ci, hip, feet + Vector2(h * 0.12 + sway, 0), ink, w, sd + 1)
	var neck := hip + Vector2(sin(ph * 0.5) * h * 0.02, -h * 0.33)
	Crayon.rect(ci, Rect2(neck + Vector2(-h * 0.11, h * 0.02), Vector2(h * 0.22, h * 0.31)), ink, w, Color(shirt, a), sd + 2)
	var head := neck + Vector2(0, -h * 0.12)
	var hr := h * 0.11
	if sitting:
		Crayon.line(ci, neck + Vector2(-h * 0.1, h * 0.06), neck + Vector2(-h * 0.2, h * 0.25), ink, w, sd + 3)
		Crayon.line(ci, neck + Vector2(h * 0.1, h * 0.06), neck + Vector2(h * 0.2, h * 0.25), ink, w, sd + 4)
	else:
		# arms out in front, holding a slice of cake on a plate
		var reach := Vector2(0, -h * 0.02 + sin(ph * 0.8) * h * 0.02)
		var hl := neck + Vector2(-h * 0.16, h * 0.1) + reach
		var hrp := neck + Vector2(h * 0.16, h * 0.1) + reach
		Crayon.line(ci, neck + Vector2(-h * 0.1, h * 0.05), hl, ink, w, sd + 3)
		Crayon.line(ci, neck + Vector2(h * 0.1, h * 0.05), hrp, ink, w, sd + 4)
		var plate := (hl + hrp) * 0.5 + Vector2(0, -h * 0.01)
		Crayon.ellipse(ci, plate, Vector2(h * 0.13, h * 0.025), ink, maxf(2.0, w * 0.6), Color(1, 1, 1, a), sd + 5)
		Crayon.poly(ci, PackedVector2Array([plate + Vector2(-h * 0.07, -h * 0.01), plate + Vector2(h * 0.07, -h * 0.01), plate + Vector2(-h * 0.03, -h * 0.08)]),
			ink, maxf(2.0, w * 0.6), Color(0.98, 0.6, 0.75, a), sd + 6)
		Crayon.disc(ci, hl, w * 1.2, skin)
		Crayon.disc(ci, hrp, w * 1.2, skin)
	Crayon.circle(ci, head, hr, ink, w, skin, sd + 7)
	if sitting:
		Crayon.face(ci, head + Vector2(0, hr * 0.1), hr * 0.9, "sleep", Vector2.ZERO, sd + 8, ink)
	else:
		Crayon.face(ci, head + Vector2(0, hr * 0.1), hr * 0.9, "wide", Vector2.ZERO, sd + 8, ink)
	if hat.a > 0.0:
		Crayon.party_hat(ci, head + Vector2(0, -hr * 0.8), hr * 0.9, Color(hat, a), sd + 9, 0.2)


static func draw_mascot(ci: CanvasItem, feet: Vector2, sc: float, tm: float) -> void:
	draw_guest(ci, feet, 170.0 * sc, Color(0.55, 0.7, 0.55), Crayon.PINK, tm * 3.0, 4321)


func _blaster() -> void:
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
