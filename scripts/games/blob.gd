extends Screen
## Present 3: BABY BLOB (virtual pet). Hatch it, feed it, play with it, love it.
## It grows. It learns your name. It likes your name. It would like to keep your name.

const IDX := 2
const CENTER := Vector2(640, 390)

var stage := 0           # 0 egg, 1 baby, 2 kid, 3 big, 4 huge
var cracks := 0
var meters := [0.3, 0.3, 0.3]   # food, fun, love
var anim := ""
var anim_t := 0.0
var squish := 0.0
var hearts: Array = []
var busy := false
var name_left := 10
var eaten_name := false
var size_k := 0.0
var choice := false
var show_name := true


var _baked_stage := -1


func enter() -> void:
	Narrator.top = true
	use_back_layer()
	lyrics_y = 96.0
	Audio.play_music("blob")
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await say("Present number three! An egg! Tap the egg to help it hatch.")
	locked = false


func _setup_buttons() -> void:
	for id in ["feed", "play", "pet"]:
		remove_button(id)
	if stage < 1:
		return
	var y := H - 104
	add_button("feed", Rect2(250, y, 240, 84), "FEED", _feed, Crayon.PINK, 40)
	add_button("play", Rect2(520, y, 240, 84), "PLAY", _play, Crayon.YELLOW, 40)
	add_button("pet", Rect2(790, y, 240, 84), "PET", _pet, Color(0.6, 0.85, 1.0), 40)
	if stage >= 4:
		var f := get_button("feed")
		f.rect = Rect2(330, y, 620, 84)
		f.label = "FEED IT... YOUR NAME?"
		f.size = 36
		remove_button("play")
		remove_button("pet")


func press(p: Vector2) -> void:
	if stage == 0:
		if p.distance_to(CENTER) < 140:
			cracks += 1
			squish = 1.0
			Audio.sfx("crack", -2, 1.0 + cracks * 0.05)
			if cracks >= 5:
				_hatch()
		return
	if p.distance_to(CENTER) < _radius() and not busy and stage < 4:
		squish = 1.0
		Audio.sfx("squish", -4, randf_range(1.0, 1.4))
		Audio.sfx("blip", -8, 1.3)
		_add(2, 0.12)


func drag(p: Vector2) -> void:
	if stage >= 1 and stage < 4 and p.distance_to(CENTER) < _radius() and not busy:
		_add(2, 0.004)
		if randf() < 0.04:
			hearts.append({"p": p, "t": 0.0})


func _hatch() -> void:
	locked = true
	stage = 1
	Audio.sfx("pop")
	Audio.sfx("sparkle")
	confetti_burst(CENTER, 50)
	await wait(0.4)
	await say("Blip!", Narrator.CRITTER)
	await say("It's a baby blob! It's so cute! Fill up all its meters so it can grow big and strong.")
	_setup_buttons()
	locked = false


func _radius() -> float:
	return [120.0, 90.0, 130.0, 190.0, 520.0][stage] * (1.0 + size_k * 0.15)


func _add(i: int, amt: float) -> void:
	meters[i] = clampf(meters[i] + amt, 0.0, 1.0)
	if meters[0] >= 0.99 and meters[1] >= 0.99 and meters[2] >= 0.99 and not busy:
		_grow()


func _feed() -> void:
	if busy:
		return
	if stage >= 4:
		_eat_name()
		return
	busy = true
	anim = "feed"
	anim_t = 0.0
	Audio.sfx("throw", -6)
	await wait(0.5)
	Audio.sfx("chomp")
	squish = 1.0
	busy = false
	_add(0, 0.5)


func _play() -> void:
	if busy:
		return
	busy = true
	anim = "play"
	anim_t = 0.0
	Audio.sfx("boing", -6)
	await wait(0.9)
	Audio.sfx("giggle" if stage < 3 else "giggle_low", -4)
	busy = false
	_add(1, 0.5)


func _pet() -> void:
	if busy:
		return
	busy = true
	anim = "pet"
	anim_t = 0.0
	for i in 4:
		Audio.sfx("squish", -8, 1.0 + i * 0.15)
		hearts.append({"p": CENTER + Vector2(randf_range(-60, 60), -40), "t": 0.0})
		await wait(0.2)
	busy = false
	_add(2, 0.5)


func _grow() -> void:
	busy = true
	locked = true
	anim = ""
	Audio.sfx("levelup")
	Audio.sfx("sparkle")
	stage += 1
	meters = [0.25, 0.25, 0.25]
	_setup_buttons()
	for b in buttons:
		if b.id in ["feed", "play", "pet"]:
			b.visible = false
	await wait(0.6)
	match stage:
		2:
			await say("Happy birthday, Chumbo!", Narrator.CRITTER)
			await say("It knows your name already! What a smart blob.")
		3:
			Audio.play_music("blob_dark", 2.5)
			await say("Is it my birthday too?", Narrator.CREEPY)
			await say("It's getting very big. It's always hungry now. Maybe don't look at its teeth.", Narrator.DARK)
		4:
			await say("More.", Narrator.CREEPY)
			await say("It ate the cake. It ate the plate. It wants something else now.", Narrator.DARK)
	for b in buttons:
		b.visible = true
	busy = false
	locked = false


func _eat_name() -> void:
	busy = true
	locked = true
	for b in buttons:
		if b.id == "feed":
			b.visible = false
	await say("Okay. Just a little bite.", Narrator.DARK)
	for i in 10:
		name_left -= 1
		Audio.sfx("chomp", -2, 0.7 + i * 0.03)
		squish = 1.0
		await wait(0.28)
	eaten_name = true
	await wait(0.6)
	await say("I'm Chumbo.", Narrator.CREEPY)
	await say("That's not right. You are Chumbo.", Narrator.DARK)
	await say("No. I'm Chumbo.", Narrator.CREEPY)
	await say("Which one of you is the real Chumbo?", Narrator.DARK)
	choice = true
	add_button("c1", Rect2(220, H - 110, 380, 86), "I'm Chumbo", _choose, Crayon.WHITE, 40)
	add_button("c2", Rect2(680, H - 110, 380, 86), "I'm Chumbo", _choose, Crayon.WHITE, 40)
	locked = false


func _choose() -> void:
	if not choice:
		return
	choice = false
	locked = true
	remove_button("c1")
	remove_button("c2")
	await say("See? We are both Chumbo now.", Narrator.CREEPY)
	Audio.sfx("gulp", 0, 0.5)
	name_left = 10
	eaten_name = false
	var tw := create_tween()
	tw.tween_property(self, "size_k", -6.0, 1.2)
	await wait(1.3)
	stage = 1
	size_k = 0.0
	Audio.play_music("blob", 1.5)
	Audio.sfx("pop")
	await say("Blip!", Narrator.CRITTER)
	await say("Aww, it's a baby again! Present number three, done! Feed it again next year. It will be hungry.")
	finish_game(IDX, "BLOB RAISED!")


func tick(dt: float) -> void:
	anim_t += dt
	squish = maxf(0.0, squish - dt * 3.0)
	if stage >= 1 and stage < 4 and not busy:
		for i in 3:
			meters[i] = maxf(0.05, meters[i] - dt * 0.006)
	for h in hearts:
		h.t += dt
		h.p.y -= 60.0 * dt
	hearts = hearts.filter(func(h): return h.t < 1.5)
	Crayon.shake = 1.0 + maxf(0, stage - 2) * 0.5


func paint_back() -> void:
	_baked_stage = stage
	var dark := clampf((stage - 2) / 2.0, 0.0, 1.0)
	var col := Color(0.98, 0.9, 0.95).lerp(Color(0.16, 0.08, 0.18), dark)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), col)
	# a little crib rug + wallpaper hearts
	if stage < 4:
		for i in 12:
			var hp := Vector2(fmod(i * 211.0, W), 140 + fmod(i * 97.0, 300))
			Crayon.heart(pen, hp, 12, Color(0, 0, 0, 0), Crayon.PINK.lerp(col, 0.6 + dark * 0.3), 20 + i)
		Crayon.ellipse(pen, CENTER + Vector2(0, 150), Vector2(330, 50), Crayon.INK, 4, Crayon.BLUE.lerp(col, 0.5), 5)


func paint() -> void:
	if stage != _baked_stage:
		refresh_back()
	if stage == 0:
		_egg()
	else:
		_blob()
	for h in hearts:
		Crayon.heart(pen, h.p, 14, Crayon.INK, Color(Crayon.RED, 1.0 - h.t / 1.5), 60)
	# animation props
	match anim:
		"feed":
			if anim_t < 0.5:
				var from := Vector2(370, H - 110)
				var to := CENTER + Vector2(0, 20)
				var f := anim_t / 0.5
				var p := from.lerp(to, f) + Vector2(0, -sin(f * PI) * 120)
				Crayon.poly(pen, PackedVector2Array([p + Vector2(-26, 18), p + Vector2(26, 18), p + Vector2(0, -22)]), Crayon.INK, 3, Crayon.PINK, 70)
		"play":
			if anim_t < 0.9:
				var f := anim_t / 0.9
				var p := CENTER + Vector2(cos(f * TAU) * (_radius() + 60), -absf(sin(f * TAU * 2)) * 120 - 40)
				Crayon.circle(pen, p, 24, Crayon.INK, 3, Crayon.RED, 71)
				Crayon.line(pen, p + Vector2(-24, 0), p + Vector2(24, 0), Crayon.WHITE, 3, 72)
		"pet":
			if anim_t < 0.8:
				var p := CENTER + Vector2(sin(anim_t * 12.0) * 50, -_radius() * 0.7)
				Crayon.poly(pen, PackedVector2Array([p + Vector2(-30, 0), p + Vector2(30, 0), p + Vector2(34, -30), p + Vector2(-34, -30)]), Crayon.INK, 3, Color(1, 0.85, 0.7), 73)


func paint_top() -> void:
	var ink := Crayon.INK if stage < 3 else Crayon.WHITE
	# the player's name, which may get eaten
	var nm: String = Game.CANON_NAME.substr(0, name_left)
	Crayon.text(pen, Vector2(W * 0.5, 40), "YOUR NAME: " + nm + ("_".repeat(10 - name_left)), 36, ink, 1, 801, null, 1.0, false)
	if stage >= 1 and stage < 4:
		var labels := ["FOOD", "FUN", "LOVE"]
		var cols := [Crayon.PINK, Crayon.YELLOW, Crayon.RED]
		for i in 3:
			var r := Rect2(W - 260, 110 + i * 56, 220, 34)
			Crayon.text(pen, Vector2(r.position.x - 12, r.get_center().y), labels[i], 26, ink, 2, 810 + i)
			Crayon.rect(pen, r, ink, 4, Color(1, 1, 1, 0.3), 820 + i)
			pen.draw_rect(Rect2(r.position + Vector2(4, 4), Vector2((r.size.x - 8) * meters[i], r.size.y - 8)), cols[i])
		Crayon.text(pen, Vector2(W - 150, 290), ["", "baby", "kid", "BIG", ""][stage], 30, ink, 1, 830)
	if stage == 0:
		Crayon.text(pen, Vector2(W * 0.5, H - 70), "TAP THE EGG!", 48, Crayon.PURPLE, 1, 840, Crayon.title_font())


func _egg() -> void:
	var wob := sin(t * 10.0) * 0.05 * (1.0 if cracks > 0 else 0.3) + squish * 0.1
	pen.draw_set_transform(CENTER, wob, Vector2.ONE)
	Crayon.ellipse(pen, Vector2.ZERO, Vector2(95, 125), Crayon.INK, 6, Color(0.98, 0.95, 0.85), 30)
	for i in 6:
		Crayon.dot(pen, Vector2(-50 + i * 20, -40 + (i % 3) * 30), 8, Crayon.RAINBOW[i])
	for k in cracks:
		var y := -60.0 + k * 28
		var pts := PackedVector2Array([Vector2(-70, y), Vector2(-40, y + 14), Vector2(-15, y - 6), Vector2(15, y + 12), Vector2(40, y - 4), Vector2(70, y + 10)])
		Crayon.path(pen, pts, Crayon.INK, 4, 40 + k)
	pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _blob() -> void:
	var r := _radius()
	var c := CENTER
	if stage >= 4:
		c = Vector2(640, 560)
	var col := Crayon.PURPLE.lerp(Color(0.3, 0.12, 0.35), clampf((stage - 1) / 3.0, 0, 1))
	var sq := squish * 0.15
	var pts := PackedVector2Array()
	var n := 36
	for i in n:
		var a := TAU * i / n
		var wob := 1.0 + sin(a * 3.0 + t * 3.0) * 0.04 + sin(a * 5.0 - t * 2.0) * 0.03
		pts.append(c + Vector2(cos(a) * r * (1.0 + sq) * wob, sin(a) * r * (0.85 - sq) * wob))
	Crayon.poly(pen, pts, Crayon.INK, maxf(5.0, r * 0.03), col, 100)
	Crayon.disc(pen, c + Vector2(-r * 0.4, -r * 0.45), r * 0.12, Color(1, 1, 1, 0.35))
	var look := (mouse - c).normalized()
	var mood := "happy"
	if stage == 3:
		mood = "wide"
	elif stage >= 4:
		mood = "wide"
	Crayon.face(pen, c + Vector2(0, -r * 0.05), r * 0.6, mood, look, 101, Crayon.INK if stage < 3 else Crayon.BLACK)
	if stage >= 3:
		# extra eyes
		for i in (2 if stage == 3 else 6):
			var e := c + Vector2(-r * 0.55 + i * r * 0.22, -r * 0.6 + (i % 2) * r * 0.1)
			if stage == 3:
				e = c + Vector2(-r * 0.6 + i * r * 1.2, -r * 0.55)
			Crayon.disc(pen, e, r * 0.07, Crayon.WHITE)
			Crayon.disc(pen, e + look * r * 0.025, r * 0.035, Crayon.BLACK)
	if stage >= 1 and stage <= 2:
		Crayon.party_hat(pen, c + Vector2(r * 0.1, -r * 0.8), r * 0.4, Crayon.YELLOW, 102, 0.2)
	if stage == 1:
		ci_blush(c, r)


func ci_blush(c: Vector2, r: float) -> void:
	Crayon.disc(pen, c + Vector2(-r * 0.45, r * 0.1), r * 0.12, Color(1, 0.5, 0.6, 0.5))
	Crayon.disc(pen, c + Vector2(r * 0.45, r * 0.1), r * 0.12, Color(1, 0.5, 0.6, 0.5))
