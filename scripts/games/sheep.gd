extends Screen
## Present 2: SHEEPY SHEPHERD (herding game). Drag the puppy to push the party sheep into
## the pen. Count them. Count them again.

const IDX := 1
const PEN := Rect2(990, 230, 240, 300)
const GATE_Y0 := 315.0
const GATE_Y1 := 445.0
const FIELD := Rect2(40, 130, 1200, 560)

var dog := Vector2(300, 420)
var dog_target := Vector2(300, 420)
var dog_moving := false
var dog_face := 1.0
var sheep: Array = []
var round_i := 0
var round_t := 0.0
var playing := false
var penned := 0
var count_shown := 0
var extra_in_pen := false
var thing := {}
var night := 0.0
var flicker := 0.0
var sleepy_said := false


func enter() -> void:
	Audio.play_music("sheep")
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await say("Present number two! A puppy! Drag the puppy around to herd the party sheep into their pen.")
	await _round(5)
	await say("Five sheep! Good puppy!")
	await say("The sun is going down. Six more sheep! Hurry!")
	var tw := create_tween()
	tw.tween_property(self, "night", 0.45, 2.0)
	await _round(6)
	await wait(0.8)
	extra_in_pen = true
	count_shown = 7
	Audio.sfx("baa_human", -2)
	Audio.play_music("sheep_dark", 2.0)
	await wait(1.2)
	await say("Wait. There were six sheep. Why are there seven?", Narrator.DARK)
	await say("That one isn't a sheep, Chumbo. Don't make eye contact.", Narrator.DARK)
	var tw2 := create_tween()
	tw2.tween_property(self, "night", 0.82, 2.0)
	await say("It's dark now. Bring the last sheep home. If something follows you, keep moving.", Narrator.DARK)
	extra_in_pen = false
	thing = {"pos": Vector2(1100, 640), "touches": 0}
	await _round(6)
	thing = {}
	extra_in_pen = true
	await wait(0.6)
	await say("All the sheep are safe. Even the one who isn't a sheep. It wants to come to your party.", Narrator.DARK)
	await say("Present number two, done! Good puppy!")
	finish_game(IDX, "SHEEP SAFE!")


func _round(n: int) -> void:
	round_i += 1
	sheep.clear()
	penned = 0
	count_shown = 0
	round_t = 0.0
	sleepy_said = false
	for i in n:
		var p := Vector2(randf_range(250, 760), randf_range(200, 640))
		sheep.append({"pos": p, "vel": Vector2.ZERO, "home": false, "seed": i * 23 + round_i * 100, "baa": randf_range(2, 8), "hat": Crayon.RAINBOW[i % 7]})
	dog = Vector2(150, 420)
	dog_target = dog
	playing = true
	locked = false
	while penned < n:
		await wait(0.2)
	playing = false
	locked = true
	Audio.sfx("cheer", -6)


func press(p: Vector2) -> void:
	dog_target = p
	dog_moving = true
	if randf() < 0.3:
		Audio.sfx("bark", -6, randf_range(0.9, 1.2))


func drag(p: Vector2) -> void:
	dog_target = p


func release(_p: Vector2) -> void:
	dog_moving = false


func tick(dt: float) -> void:
	flicker = maxf(0.0, flicker - dt)
	if not playing:
		return
	round_t += dt
	# puppy
	var before := dog
	if dog_moving:
		var d := dog_target - dog
		var step := minf(d.length(), 420.0 * dt)
		if d.length() > 1.0:
			dog += d.normalized() * step
			if absf(d.x) > 2:
				dog_face = signf(d.x)
	dog = dog.clamp(FIELD.position, FIELD.end)
	var dog_speed := (dog - before).length() / maxf(dt, 0.001)
	# sheep
	var center := Vector2.ZERO
	var free := 0
	for s in sheep:
		if not s.home:
			center += s.pos
			free += 1
	if free > 0:
		center /= free
	var sleepy := round_t > 70.0
	if sleepy and not sleepy_said:
		sleepy_said = true
		say_bg("The sheep are getting sleepy. They're walking home by themselves.")
	for s in sheep:
		var pos: Vector2 = s.pos
		var vel: Vector2 = s.vel
		s.baa -= dt
		if s.baa <= 0:
			s.baa = randf_range(4, 10)
			Audio.sfx("baa", -14, randf_range(0.85, 1.25))
		if s.home:
			vel = vel * 0.9 + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 30.0
			pos += vel * dt
			pos = pos.clamp(PEN.position + Vector2(30, 40), PEN.end - Vector2(30, 20))
			s.pos = pos
			s.vel = vel
			continue
		var acc := Vector2.ZERO
		var to_dog := pos - dog
		var dd := to_dog.length()
		if dd < 230.0:
			acc += to_dog.normalized() * (230.0 - dd) * 9.0
		if free > 1:
			acc += (center - pos) * 0.4
		for o in sheep:
			if not is_same(o, s) and not o.home:
				var away: Vector2 = pos - o.pos
				var l := away.length()
				if l < 60.0 and l > 0.01:
					acc += away / l * (60.0 - l) * 6.0
		acc += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 60.0
		if sleepy:
			acc += (Vector2(PEN.position.x + 60, (GATE_Y0 + GATE_Y1) * 0.5) - pos).normalized() * 220.0
		# soft field walls
		if pos.x < FIELD.position.x + 40: acc.x += 400
		if pos.x > FIELD.end.x - 40: acc.x -= 400
		if pos.y < FIELD.position.y + 40: acc.y += 400
		if pos.y > FIELD.end.y - 30: acc.y -= 400
		vel = (vel + acc * dt) * 0.92
		if vel.length() > 210.0:
			vel = vel.normalized() * 210.0
		var np := pos + vel * dt
		# pen walls (only the gate is open)
		var inside_x := np.x > PEN.position.x and np.x < PEN.end.x
		if inside_x and np.y > PEN.position.y and np.y < PEN.end.y:
			var through_gate := pos.x <= PEN.position.x and np.y > GATE_Y0 and np.y < GATE_Y1
			if through_gate or pos.x > PEN.position.x:
				if np.x > PEN.position.x + 25:
					s.home = true
					penned += 1
					count_shown = penned
					Audio.sfx("baa", -4)
					Audio.sfx("ding", -6)
			else:
				np = pos
				vel = -vel * 0.3
		s.pos = np.clamp(FIELD.position, FIELD.end)
		s.vel = vel
	# the thing that follows you
	if not thing.is_empty():
		var tp: Vector2 = thing.pos
		if dog_speed > 20.0:
			tp += (dog - tp).normalized() * 75.0 * dt
		thing.pos = tp
		if tp.distance_to(dog) < 46.0:
			thing.touches += 1
			Audio.sfx("baa_human", -2)
			flicker = 0.4
			say_bg("Baaa.", Narrator.CREEPY)
			thing.pos = Vector2(60 if dog.x > 640 else 1200, 660)


func paint() -> void:
	var grass := Color(0.55, 0.85, 0.45).lerp(Color(0.1, 0.18, 0.15), night)
	bg = grass
	draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), grass)
	var sky := Crayon.SKY.lerp(Color(0.95, 0.5, 0.35), clampf(night * 2.2, 0, 1)).lerp(Color(0.05, 0.03, 0.12), clampf((night - 0.45) * 2.8, 0, 1))
	draw_rect(Rect2(-2000, -2000, W + 4000, 2110), sky)
	Crayon.line(self, Vector2(-40, 110), Vector2(W + 40, 110), Crayon.INK, 4, 1)
	# hills + sun/moon
	if night < 0.6:
		Crayon.sun(self, Vector2(640, 110 - night * 160), 40, "happy" if night < 0.3 else "flat", 2)
	else:
		Crayon.circle(self, Vector2(200, 60), 30, Crayon.INK, 3, Color(1, 1, 0.85), 3)
	for i in 3:
		Crayon.ellipse(self, Vector2(200 + i * 450, 112), Vector2(260, 50), Crayon.INK, 4, grass.darkened(0.12), 4 + i)
	# flowers
	for i in 16:
		var fp := Vector2(fmod(i * 233.0, 900) + 60, 160 + fmod(i * 157.0, 500))
		Crayon.circle(self, fp, 7, Crayon.INK.lerp(grass, 0.4), 2, Crayon.RAINBOW[i % 7].lerp(grass, night), 10 + i)
	_pen()
	# sheep sorted by y for fake depth
	var draw_list: Array = []
	for s in sheep:
		draw_list.append({"y": s.pos.y, "kind": "sheep", "s": s})
	draw_list.append({"y": dog.y, "kind": "dog"})
	if not thing.is_empty():
		draw_list.append({"y": thing.pos.y, "kind": "thing"})
	if extra_in_pen:
		draw_list.append({"y": PEN.position.y + 120, "kind": "standing"})
	draw_list.sort_custom(func(a, b): return a.y < b.y)
	for it in draw_list:
		match it.kind:
			"sheep":
				_sheep(it.s.pos, it.s.seed, it.s.hat, it.s.vel.x)
			"dog":
				_dog()
			"thing":
				_standing(thing.pos, true)
			"standing":
				_standing(Vector2(PEN.end.x - 50, PEN.position.y + 120), false)
	if night > 0.0:
		draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.02, 0.0, 0.08, night * 0.45))
		# eyes still glow in the dark
		if extra_in_pen:
			_glow_eyes(Vector2(PEN.end.x - 50, PEN.position.y + 120 - 175))
		if not thing.is_empty():
			_glow_eyes(thing.pos + Vector2(0, -175))
	if flicker > 0.0:
		draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0, 0, 0, flicker * 1.5))


func paint_top() -> void:
	var ink := Crayon.INK if night < 0.5 else Crayon.WHITE
	if round_i > 0:
		var total: int = [0, 5, 6, 6][mini(round_i, 3)]
		hud("SHEEP: %d / %d" % [count_shown, total], ink if count_shown <= total else Crayon.RED)
	if playing and penned == 0 and round_t < 4.0:
		Crayon.text(self, Vector2(W * 0.5, 160), "DRAG THE PUPPY!", 46, Crayon.RED, 1, 4300, Crayon.title_font())


func _glow_eyes(c: Vector2) -> void:
	draw_circle(c + Vector2(-9, 0), 5, Color(1, 0.9, 0.3))
	draw_circle(c + Vector2(9, 0), 5, Color(1, 0.9, 0.3))


func _pen() -> void:
	var c := Crayon.BROWN.lerp(Crayon.INK, night * 0.5)
	var r := PEN
	Crayon.line(self, r.position, Vector2(r.end.x, r.position.y), c, 8, 30)
	Crayon.line(self, Vector2(r.position.x, r.end.y), r.end, c, 8, 31)
	Crayon.line(self, Vector2(r.end.x, r.position.y), r.end, c, 8, 32)
	Crayon.line(self, r.position, Vector2(r.position.x, GATE_Y0), c, 8, 33)
	Crayon.line(self, Vector2(r.position.x, GATE_Y1), Vector2(r.position.x, r.end.y), c, 8, 34)
	for k in 6:
		var x := r.position.x + k * r.size.x / 5.0
		Crayon.line(self, Vector2(x, r.position.y - 20), Vector2(x, r.position.y + 10), c, 6, 40 + k)
		Crayon.line(self, Vector2(x, r.end.y - 10), Vector2(x, r.end.y + 20), c, 6, 50 + k)
	Crayon.text(self, Vector2(r.get_center().x, r.position.y - 40), "PEN", 34, Crayon.WHITE if night > 0.5 else Crayon.INK, 1, 60, Crayon.title_font())
	# gate arrow
	if playing:
		var a := Vector2(r.position.x - 70 + sin(t * 4) * 8, (GATE_Y0 + GATE_Y1) * 0.5)
		Crayon.line(self, a, a + Vector2(50, 0), Crayon.YELLOW, 6, 61)
		Crayon.poly(self, PackedVector2Array([a + Vector2(56, 0), a + Vector2(38, -14), a + Vector2(38, 14)]), Crayon.YELLOW, 4, Crayon.YELLOW, 62)


func _sheep(p: Vector2, sd: int, hat: Color, vx: float) -> void:
	var f := -1.0 if vx < 0 else 1.0
	var legs := sin(t * 12.0 + sd) * 4.0
	for k in 4:
		var lx := p.x - 22 + k * 15
		Crayon.line(self, Vector2(lx, p.y), Vector2(lx + (legs if k % 2 == 0 else -legs), p.y + 22), Crayon.INK, 5, sd + k)
	for k in 5:
		var o := Vector2(-22 + k * 11, -6 + (k % 2) * -8)
		Crayon.circle(self, p + o + Vector2(0, -6), 18, Crayon.INK.lerp(Crayon.GREY, 0.3), 3, Crayon.WHITE, sd + 10 + k)
	var head := p + Vector2(f * 34, -14)
	Crayon.ellipse(self, head, Vector2(14, 12), Crayon.INK, 3, Color(0.2, 0.18, 0.2), sd + 20)
	draw_circle(head + Vector2(f * 5, -3), 3, Crayon.WHITE)
	Crayon.party_hat(self, head + Vector2(0, -10), 12, hat, sd + 30, f * 0.3)


func _dog() -> void:
	var p := dog
	var f := dog_face
	var bounce := absf(sin(t * 14.0)) * 4.0 if dog_moving else 0.0
	p.y -= bounce
	var fur := Color(0.8, 0.55, 0.3)
	for k in 4:
		Crayon.line(self, p + Vector2(-20 + k * 13, 0), p + Vector2(-20 + k * 13, 20), Crayon.INK, 5, 300 + k)
	Crayon.ellipse(self, p + Vector2(0, -6), Vector2(32, 18), Crayon.INK, 4, fur, 310)
	var tail := p + Vector2(-f * 30, -14)
	Crayon.line(self, tail, tail + Vector2(-f * 16, -18 + sin(t * 20.0) * 8), Crayon.INK, 5, 311)
	var head := p + Vector2(f * 30, -24)
	Crayon.circle(self, head, 17, Crayon.INK, 4, fur, 312)
	Crayon.ellipse(self, head + Vector2(-f * 10, 6), Vector2(6, 12), Crayon.INK, 3, Crayon.BROWN, 313)
	Crayon.face(self, head + Vector2(f * 3, 0), 14, "happy", Vector2(f, 0), 314)
	Crayon.party_hat(self, head + Vector2(0, -14), 13, Crayon.BLUE, 315, f * 0.2)


func _standing(feet: Vector2, moving: bool) -> void:
	var sway := sin(t * 2.0) * 3.0 if moving else 0.0
	Crayon.line(self, feet + Vector2(-12, 0), feet + Vector2(-8 + sway, -70), Crayon.INK, 6, 400)
	Crayon.line(self, feet + Vector2(12, 0), feet + Vector2(8 + sway, -70), Crayon.INK, 6, 401)
	Crayon.line(self, feet + Vector2(-30, -110), feet + Vector2(-42, -70), Crayon.INK, 5, 402)
	Crayon.line(self, feet + Vector2(30, -110), feet + Vector2(42, -70), Crayon.INK, 5, 403)
	for k in 5:
		Crayon.circle(self, feet + Vector2(-16 + (k % 2) * 32, -125 + k * 14 - 30), 22, Crayon.INK.lerp(Crayon.GREY, 0.3), 3, Crayon.WHITE, 404 + k)
	Crayon.circle(self, feet + Vector2(sway, -175), 22, Crayon.INK, 4, Color(0.2, 0.18, 0.2), 410)
	Crayon.face(self, feet + Vector2(sway, -170), 18, "wide", Vector2.ZERO, 411, Crayon.WHITE)
