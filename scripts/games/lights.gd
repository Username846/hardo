extends Screen
## Present 9: LIGHTS OUT! (flashlight hide-and-seek). Find the eight guests hiding for a
## surprise party. Then find the ninth. And the tenth. There's always one more.

const IDX := 8
const R_LIGHT := 125.0

var light := Vector2(640, 380)
var guests: Array = []
var extras: Array = []
var found := 0
var total := 8
var playing := false
var phase := "hide"      # hide, extra, final, lit
var lit := 0.0
var idle_t := 0.0
var final_fig := 0.0


var _baked_key := ""
var _hole: GradientTexture2D


func enter() -> void:
	use_back_layer()
	_hole = _make_hole_texture()
	Audio.play_music("lights")
	var spots := [
		["couch", Vector2(330, 392)], ["table", Vector2(760, 528)], ["curtain", Vector2(1080, 506)], ["closet", Vector2(128, 300)],
		["plant", Vector2(596, 420)], ["shelf", Vector2(1222, 182)], ["rug", Vector2(420, 628)], ["gift", Vector2(1062, 600)],
	]
	for k in spots.size():
		guests.append({"spot": spots[k][0], "pos": spots[k][1], "seen": 0.0, "found": false, "col": Crayon.RAINBOW[k % 7], "seed": 500 + k * 11})
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	Audio.sfx("switch")
	await say("Present number nine! Uh oh, the lights went out! Your friends are hiding for a surprise. Drag your flashlight around to find all eight of them!")
	playing = true
	locked = false


func press(p: Vector2) -> void:
	light = p
	if not playing:
		return
	Audio.sfx("switch", -12, 1.4)


func drag(p: Vector2) -> void:
	light = p


func tick(dt: float) -> void:
	if not DisplayServer.is_touchscreen_available():
		light = mouse
	if not playing:
		return
	idle_t += dt
	if phase == "hide":
		for g in guests:
			if g.found:
				continue
			if light.distance_to(g.pos) < R_LIGHT * 0.6:
				g.seen += dt
				if g.seen > 0.5:
					_found(g)
			else:
				g.seen = maxf(0.0, g.seen - dt)
		if idle_t > 18.0:
			idle_t = 0.0
			say_bg("Listen! Somebody's giggling over there.")
			Audio.sfx("giggle", -2)
	elif phase == "extra":
		for e in extras:
			if e.gone:
				continue
			if light.distance_to(e.pos) < R_LIGHT * 0.55:
				e.gone = true
				found += 1
				Audio.sfx("giggle_low", -2, randf_range(0.8, 1.0))
				Audio.sfx("heartbeat", -4)
		if extras.all(func(e): return e.gone):
			_final()


func _found(g: Dictionary) -> void:
	g.found = true
	found += 1
	idle_t = 0.0
	Audio.sfx("surprise", -2)
	Audio.sfx("pop", -6)
	confetti_burst(g.pos, 30)
	if found == 4:
		say_bg("Four more! Where could they be?")
	if found == total:
		_twist()


func _twist() -> void:
	playing = false
	locked = true
	Audio.sfx("cheer", -6)
	await say("You found everybody! Okay, lights back on!")
	Audio.sfx("switch")
	await wait(0.6)
	Audio.sfx("switch")
	await wait(0.6)
	Audio.play_music("lights_dark", 2.0)
	await say("The lights won't turn on. And somebody is still hiding.", Narrator.DARK)
	for p in [Vector2(250, 190), Vector2(720, 150), Vector2(880, 640), Vector2(1170, 650)]:
		extras.append({"pos": p, "gone": false})
	phase = "extra"
	playing = true
	locked = false


func _final() -> void:
	playing = false
	phase = "final"
	locked = true
	await wait(0.8)
	Audio.sfx("found_you", 2)
	var tw := create_tween()
	tw.tween_property(self, "final_fig", 1.0, 0.8)
	await wait(1.0)
	await say("Found you.", Narrator.WHISPER)
	Audio.sfx("switch")
	phase = "lit"
	var tw2 := create_tween()
	tw2.tween_property(self, "lit", 1.0, 0.4)
	Audio.play_music("lights", 0.5)
	Audio.sfx("surprise")
	confetti_burst(Vector2(640, 300), 90)
	await wait(0.8)
	await say("SURPRISE! Everyone is here! Even the ones who weren't invited.")
	await say("Present number nine, done! Great finding!")
	finish_game(IDX, "FOUND 'EM ALL!")


func _key() -> String:
	var f := 0
	for g in guests:
		if g.found:
			f += 1
	return "%d/%s" % [f, lit > 0.5]


func paint_back() -> void:
	_baked_key = _key()
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.95, 0.88, 0.75))
	pen.draw_rect(Rect2(-2000, 560, W + 4000, 2000), Color(0.75, 0.55, 0.4))
	Crayon.line(pen, Vector2(-40, 560), Vector2(W + 40, 560), Crayon.INK, 5, 1)
	_room()
	for g in guests:
		if not g.found:
			_guest(g)


func paint() -> void:
	if _baked_key != _key():
		refresh_back()
	for g in guests:
		if g.found:
			_guest(g)
	if phase == "lit":
		# everyone (and some extra party hats on the table)
		for k in 4:
			Crayon.person(pen, Vector2(300 + k * 230, 560), 150, Crayon.INK.lerp(Color(0.3, 0.2, 0.4), 0.5), "wide", Color(0, 0, 0, 0), "wave", t * 2.0, 700 + k)
	# darkness with a flashlight hole: one soft-edged gradient + four rectangles
	if lit < 1.0:
		var a := 0.975 * (1.0 - lit)
		var ro := R_LIGHT + 50.0
		var sq := Rect2(light - Vector2(ro, ro), Vector2(ro, ro) * 2.0)
		var big := Rect2(-2000, -2000, W + 4000, H + 4000)
		var dark := Color(0.02, 0.01, 0.05, a)
		pen.draw_rect(Rect2(big.position.x, big.position.y, big.size.x, sq.position.y - big.position.y), dark)
		pen.draw_rect(Rect2(big.position.x, sq.end.y, big.size.x, big.end.y - sq.end.y), dark)
		pen.draw_rect(Rect2(big.position.x, sq.position.y, sq.position.x - big.position.x, sq.size.y), dark)
		pen.draw_rect(Rect2(sq.end.x, sq.position.y, big.end.x - sq.end.x, sq.size.y), dark)
		pen.draw_texture_rect(_hole, sq, false, Color(1, 1, 1, a))
		Crayon.circle(pen, light, R_LIGHT + 4, Color(1, 0.95, 0.6, 0.35 * (1.0 - lit)), 4, Color(0, 0, 0, 0), 2)
	# found markers + glowing eyes stay visible
	if lit < 1.0:
		for g in guests:
			if g.found:
				Crayon.star(pen, g.pos + Vector2(0, -60), 16, Crayon.INK, Crayon.YELLOW, 600 + int(g.seed))
		for e in extras:
			if not e.gone and fmod(t + e.pos.x, 3.0) > 0.15:
				Crayon.disc(pen, e.pos + Vector2(-12, 0), 7, Color(1, 0.95, 0.4))
				Crayon.disc(pen, e.pos + Vector2(12, 0), 7, Color(1, 0.95, 0.4))
	if final_fig > 0.0 and phase == "final":
		var fp := Vector2(640, 600)
		Crayon.person(pen, fp, 300 * final_fig, Color(0.9, 0.9, 0.95), "wide", Crayon.GREEN, "stand", 0.0, 800, Color(0.15, 0.1, 0.15))


func paint_top() -> void:
	var col := Crayon.WHITE if lit < 0.5 else Crayon.INK
	if found > 0 or playing:
		hud("FOUND: %d / %d" % [found, total], col if found <= total else Crayon.RED)
	if playing and found == 0 and t < 25.0:
		Crayon.text(pen, Vector2(640, 120), "DRAG THE FLASHLIGHT!", 44, Crayon.YELLOW, 1, 20, Crayon.title_font())


func _make_hole_texture() -> GradientTexture2D:
	var ro := R_LIGHT + 50.0
	var g := Gradient.new()
	var clear := R_LIGHT / ro
	g.offsets = PackedFloat32Array([0.0, clear, 1.0])
	g.colors = PackedColorArray([Color(0.02, 0.01, 0.05, 0.0), Color(0.02, 0.01, 0.05, 0.0), Color(0.02, 0.01, 0.05, 1.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func _room() -> void:
	# window + curtains
	Crayon.rect(pen, Rect2(990, 110, 180, 200), Crayon.INK, 5, Color(0.1, 0.1, 0.25), 10)
	Crayon.circle(pen, Vector2(1100, 170), 18, Crayon.INK, 2, Color(1, 1, 0.85), 11)
	for k in 2:
		var cx := 960.0 + k * 220.0
		var pts := PackedVector2Array()
		for j in 9:
			pts.append(Vector2(cx + sin(j * 1.3 + k) * 14, 100 + j * 52))
		pts.append(Vector2(cx + 60 - k * 120, 520))
		pts.append(Vector2(cx + 60 - k * 120, 100))
		Crayon.poly(pen, pts, Crayon.INK, 4, Color(0.75, 0.25, 0.3), 12 + k)
	# closet
	Crayon.rect(pen, Rect2(50, 140, 130, 420), Crayon.INK, 5, Crayon.BROWN, 20)
	Crayon.circle(pen, Vector2(160, 360), 7, Crayon.INK, 2, Crayon.YELLOW, 21)
	# couch
	Crayon.rect(pen, Rect2(200, 420, 320, 140), Crayon.INK, 5, Crayon.BLUE, 30)
	Crayon.rect(pen, Rect2(180, 400, 50, 160), Crayon.INK, 5, Crayon.BLUE.darkened(0.2), 31)
	Crayon.rect(pen, Rect2(490, 400, 50, 160), Crayon.INK, 5, Crayon.BLUE.darkened(0.2), 32)
	# plant
	Crayon.rect(pen, Rect2(570, 480, 60, 80), Crayon.INK, 4, Crayon.ORANGE, 40)
	for k in 5:
		var a := -PI * 0.5 + (k - 2) * 0.4
		Crayon.ellipse(pen, Vector2(600, 470) + Vector2(cos(a), sin(a)) * 50, Vector2(14, 34), Crayon.INK, 3, Crayon.GREEN, 41 + k)
	# table
	Crayon.rect(pen, Rect2(640, 440, 260, 24), Crayon.INK, 5, Crayon.BROWN, 50)
	Crayon.line(pen, Vector2(660, 464), Vector2(660, 560), Crayon.INK, 6, 51)
	Crayon.line(pen, Vector2(880, 464), Vector2(880, 560), Crayon.INK, 6, 52)
	Crayon.cake(pen, Vector2(770, 440), 110, 50, Crayon.PINK, 3, lit > 0.5, 53)
	# shelf
	Crayon.rect(pen, Rect2(1190, 200, 80, 360), Crayon.INK, 5, Crayon.BROWN.lightened(0.1), 60)
	for k in 4:
		Crayon.line(pen, Vector2(1190, 280 + k * 70), Vector2(1270, 280 + k * 70), Crayon.INK, 4, 61 + k)
	# rug
	Crayon.ellipse(pen, Vector2(420, 640), Vector2(170, 40), Crayon.INK, 4, Crayon.PURPLE.lightened(0.2), 70)
	# gift box
	Crayon.present(pen, Rect2(1000, 600, 130, 100), Crayon.GREEN, Crayon.YELLOW, 80, 18.0)


func _guest(g: Dictionary) -> void:
	var p: Vector2 = g.pos
	var sd: int = g.seed
	var col: Color = g.col
	if g.found:
		Crayon.person(pen, p + Vector2(0, 70), 120, Crayon.INK, "happy", col, "up", t * 3.0, sd)
		return
	match String(g.spot):
		"couch", "plant", "shelf":
			Crayon.circle(pen, p, 22, Crayon.INK, 4, Color(1, 0.9, 0.78), sd)
			Crayon.face(pen, p + Vector2(0, -2), 18, "happy", Vector2.ZERO, sd + 1)
			Crayon.party_hat(pen, p + Vector2(0, -18), 16, col, sd + 2)
		"table", "gift", "closet":
			Crayon.disc(pen, p + Vector2(-9, 0), 5, Crayon.WHITE)
			Crayon.disc(pen, p + Vector2(9, 0), 5, Crayon.WHITE)
			Crayon.disc(pen, p + Vector2(-8, 1), 2.5, Crayon.INK)
			Crayon.disc(pen, p + Vector2(10, 1), 2.5, Crayon.INK)
			Crayon.party_hat(pen, p + Vector2(0, -12), 14, col, sd + 2)
		"curtain":
			Crayon.ellipse(pen, p + Vector2(-14, 0), Vector2(14, 7), Crayon.INK, 3, Crayon.RED, sd)
			Crayon.ellipse(pen, p + Vector2(14, 0), Vector2(14, 7), Crayon.INK, 3, Crayon.RED, sd + 1)
		"rug":
			Crayon.ellipse(pen, p, Vector2(50, 22), Crayon.INK, 3, Crayon.PURPLE.lightened(0.1), sd)
			Crayon.party_hat(pen, p + Vector2(0, -18), 14, col, sd + 2)
