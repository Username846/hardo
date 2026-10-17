extends Screen
## Present 3: DIJIMON (digital monster V-pet). Hatch it, feed it, train it, pet it, clean up
## after it, and it dijivolves. It learns your name. It likes your name. It would like to keep it.

const IDX := 2
const DEVICE := Vector2(640, 372)        # centre of the egg-shaped Dijivice
const DEV_R := Vector2(272, 238)
const LCD := Rect2(478, 222, 324, 236)   # its little screen
const FLOOR_Y := 444.0                   # where the monster stands on the screen
const CENTER := Vector2(640, 345)        # the egg
const SIZES := [92.0, 58.0, 64.0, 78.0, 100.0, 128.0, 150.0]
const STAGES := [
	{"name": "DIJIEGG", "level": "EGG", "atk": ""},
	{"name": "BLOBMON", "level": "BABY", "atk": "BUBBLE BLOW!"},
	{"name": "FROSTMON", "level": "IN-TRAINING", "atk": "FROSTING BUBBLES!"},
	{"name": "PARTYMON", "level": "ROOKIE", "atk": "PARTY BREATH!"},
	{"name": "GRRTHDAYMON", "level": "CHAMPION", "atk": "CANDLE BLASTER!"},
	{"name": "METAL CAKEMON", "level": "ULTIMATE", "atk": ""},
	{"name": "CHUMBOMON", "level": "MEGA", "atk": ""},
]
const FEED_DARK := 6

var stage := 0           # index into STAGES
var cracks := 0
var meters := [0.2, 0.2, 0.2]   # food, power, love
var anim := ""
var anim_t := 0.0
var squish := 0.0
var hearts: Array = []
var busy := false
var name_left := 10
var eaten_name := false
var shrink := 1.0
var choice := false
var poops: Array = []    # x positions on the screen floor
var poop_t := 7.0
var flush_t := -1.0
var training := false
var train_t := 0.0
var train_zone := 0.5
var train_w := 0.2
var train_msg := ""
var train_msg_t := 0.0
var attack_t := -1.0
var evo_t := -1.0
var evo_from := 0
var evo_to := 0
var evo_word := "DIJIVOLVE"
var age := 0.0
var age_spin := false
var feeds_dark := 0
var clean_said := false
var said := {}


var _baked_key := ""


func enter() -> void:
	Narrator.top = true
	use_back_layer()
	lyrics_y = 96.0
	Audio.play_music("digi")
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await say("Present number three! A Dijivice! There's a Dijiegg inside. Tap the egg to help it hatch!")
	locked = false


func _setup_buttons() -> void:
	for id in ["feed", "train", "pet", "clean"]:
		remove_button(id)
	if stage < 1:
		return
	var y := H - 104
	if stage <= 4:
		add_button("feed", Rect2(170, y, 220, 84), "FEED", _feed, Crayon.PINK, 40)
		add_button("train", Rect2(410, y, 220, 84), "TRAIN", _train, Crayon.YELLOW, 40)
		add_button("pet", Rect2(650, y, 220, 84), "PET", _pet, Color(0.6, 0.85, 1.0), 40)
		add_button("clean", Rect2(890, y, 220, 84), "CLEAN", _clean, Color(0.65, 0.92, 0.7), 40)
	elif stage == 5:
		add_button("feed", Rect2(390, y, 500, 84), "FEED IT MORE", _feed, Crayon.PINK, 40)
	else:
		add_button("feed", Rect2(330, y, 620, 84), "FEED IT... YOUR NAME?", _feed, Crayon.PINK, 36)


func _show_buttons(on: bool) -> void:
	for b in buttons:
		if b.id in ["feed", "train", "pet", "clean"]:
			b.visible = on


func _radius() -> float:
	return SIZES[stage] * (shrink if stage == 6 else 1.0)


func _mon_center() -> Vector2:
	var r := _radius()
	match stage:
		0:
			return CENTER
		1, 2:
			return Vector2(640, FLOOR_Y - r * 0.82)
		6:
			return Vector2(640, 604)
	return Vector2(640, FLOOR_Y - r * 1.05)


## Where food goes in.
func _mouth() -> Vector2:
	var c := _mon_center()
	var r := _radius()
	match stage:
		1, 2:
			return c + Vector2(0, r * 0.2)
		6:
			return c + Vector2(0, -r * 2.1)
	return c + Vector2(r * 0.5, -r * 0.3)


func _hit_test(p: Vector2) -> bool:
	if stage == 6:
		return p.distance_to(_mon_center() + Vector2(0, -_radius() * 1.4)) < _radius()
	return p.distance_to(_mon_center()) < _radius() * 1.15


func press(p: Vector2) -> void:
	if stage == 0:
		if p.distance_to(CENTER) < 130:
			cracks += 1
			squish = 1.0
			Audio.sfx("crack", -2, 1.0 + cracks * 0.05)
			Audio.sfx("beep", -12, 1.0 + cracks * 0.1)
			if cracks >= 6:
				_hatch()
		return
	if training:
		_train_hit()
		return
	if _hit_test(p) and not busy and stage <= 4:
		squish = 1.0
		Audio.sfx("squish", -4, randf_range(1.0, 1.4))
		Audio.sfx("beep", -14, 1.3)
		hearts.append({"p": p, "t": 0.0})
		_add(2, 0.06)


func drag(p: Vector2) -> void:
	if stage >= 1 and stage <= 4 and not busy and not training and _hit_test(p):
		_add(2, 0.004)
		if randf() < 0.04:
			hearts.append({"p": p, "t": 0.0})


func _hatch() -> void:
	locked = true
	stage = 1
	age = 1.0
	poop_t = 7.0
	Audio.sfx("pop")
	Audio.sfx("beep2")
	Audio.sfx("sparkle")
	confetti_burst(CENTER, 50)
	await wait(0.4)
	await say("Blip blip!", Narrator.CRITTER)
	await say("It's a baby Dijimon! Its name is Blobmon! Feed it, train it and pet it, and it will dijivolve!")
	_setup_buttons()
	locked = false


func _add(i: int, amt: float) -> void:
	meters[i] = clampf(meters[i] + amt, 0.0, 1.0)
	_check_grow()


func _check_grow() -> void:
	if busy or stage < 1 or stage > 4:
		return
	if meters[0] < 0.99 or meters[1] < 0.99 or meters[2] < 0.99:
		return
	if not poops.is_empty():
		if not clean_said:
			clean_said = true
			say_bg("It's ready to dijivolve! But first, clean up that poop.")
		return
	_grow()


func _feed() -> void:
	if busy:
		return
	if stage >= 6:
		_eat_name()
		return
	busy = true
	anim = "feed"
	anim_t = 0.0
	Audio.sfx("throw", -6)
	Audio.sfx("beep", -12)
	await wait(0.5)
	Audio.sfx("chomp", 0, 0.8 if stage >= 4 else 1.0)
	squish = 1.0
	busy = false
	if stage == 5:
		_feed_dark()
		return
	_add(0, 0.3)


func _feed_dark() -> void:
	feeds_dark += 1
	meters[0] = feeds_dark / float(FEED_DARK)
	Audio.sfx("crack", -4, 0.7)
	match feeds_dark:
		2:
			say_bg("It's too big for the screen now.", Narrator.DARK)
		4:
			say_bg("The screen is cracking. It wants to come out and play. Forever.", Narrator.DARK)
	if feeds_dark >= FEED_DARK:
		_grow()


func _train() -> void:
	if training:
		_train_hit()
		return
	if busy:
		return
	busy = true
	training = true
	train_t = 0.0
	train_zone = randf_range(0.3, 0.75)
	train_w = 0.26 - stage * 0.025
	Audio.sfx("beep2", -6)
	if not said.has("train"):
		said["train"] = true
		say_bg("Training time! Tap when the arrow is in the green part!")


func _marker() -> float:
	return 0.5 - 0.5 * cos(train_t * (2.4 + stage * 0.3))


func _train_hit(timeout: bool = false) -> void:
	if not training:
		return
	training = false
	var hit := not timeout and absf(_marker() - train_zone) <= train_w * 0.5
	train_msg_t = 1.4
	if hit:
		train_msg = STAGES[stage].atk
		attack_t = 0.0
		squish = 1.0
		Audio.sfx("laser", -6, 1.5)
		await wait(0.55)
		Audio.sfx("pop", -2)
		Audio.sfx("beep2", -10)
	else:
		train_msg = "MISS!"
		Audio.sfx("wrong", -8)
		await wait(0.4)
	busy = false
	_add(1, 0.45 if hit else 0.15)


func _pet() -> void:
	if busy:
		return
	busy = true
	anim = "pet"
	anim_t = 0.0
	for i in 4:
		Audio.sfx("squish", -8, 1.0 + i * 0.15)
		hearts.append({"p": _mon_center() + Vector2(randf_range(-60, 60), -_radius() * 0.6), "t": 0.0})
		await wait(0.2)
	Audio.sfx("giggle" if stage < 4 else "giggle_low", -8)
	busy = false
	_add(2, 0.3)


func _clean() -> void:
	if busy:
		return
	if poops.is_empty():
		Audio.sfx("beep", -8)
		train_msg = "ALL CLEAN!"
		train_msg_t = 1.0
		return
	busy = true
	flush_t = 0.0
	Audio.sfx("flush")
	await wait(0.9)
	poops.clear()
	flush_t = -1.0
	Audio.sfx("sparkle", -6)
	busy = false
	_check_grow()


## The classic evolution sequence: flashing silhouettes, then the new monster and its name.
func _dijivolve(to: int, word: String = "DIJIVOLVE") -> void:
	evo_from = stage
	evo_to = to
	evo_word = word
	evo_t = 0.0
	Audio.sfx("digivolve")
	Audio.sfx("sparkle", -4)
	await wait(2.6)
	stage = to
	Audio.sfx("levelup")
	Audio.sfx("beep2", -4)
	confetti_burst(LCD.get_center(), 40)
	await wait(1.4)
	evo_t = -1.0


func _grow() -> void:
	busy = true
	locked = true
	anim = ""
	training = false
	clean_said = false
	_show_buttons(false)
	if stage == 3:
		Audio.play_music("digi_dark", 2.5)
	await _dijivolve(stage + 1)
	if stage <= 4:
		age += 1.0
	meters = [0.2, 0.2, 0.2]
	if stage == 5:
		poops.clear()
		meters = [0.0, 1.0, 1.0]
	_setup_buttons()
	_show_buttons(false)
	await wait(0.3)
	match stage:
		2:
			await say("Happy birthday, Chumbo!", Narrator.CRITTER)
			await say("It knows your name already! What a smart Dijimon.")
		3:
			await say("Partymon! Party party!", Narrator.CRITTER)
			await say("A rookie! Look at its little party hat! Keep going and it will become a champion!")
		4:
			age_spin = true
			await say("Grrr. Is it my birthday too?", Narrator.MONSTER)
			await say("Champion level. It's so big now, and it's always hungry. Try not to look at its candle teeth.", Narrator.DARK)
		5:
			await say("MORE.", Narrator.MONSTER)
			await say("It ate the cake. It ate the plate. It ate the calendar, so now it's always today.", Narrator.DARK)
			await say("The other buttons don't work anymore. Just feed it.", Narrator.DARK)
		6:
			Audio.sfx("im_chumbo", -2)
			await say("I'm Chumbo.", Narrator.MONSTER)
			await say("That's not a Dijimon anymore. It still wants something else.", Narrator.DARK)
	_show_buttons(true)
	busy = false
	locked = false


func _eat_name() -> void:
	busy = true
	locked = true
	_show_buttons(false)
	await say("Okay. Just a little bite.", Narrator.DARK)
	for i in 10:
		name_left -= 1
		Audio.sfx("chomp", -2, 0.7 + i * 0.03)
		squish = 1.0
		await wait(0.28)
	eaten_name = true
	await wait(0.6)
	await say("I'm Chumbo.", Narrator.MONSTER)
	await say("That's not right. You are Chumbo.", Narrator.DARK)
	await say("No. I'm Chumbo.", Narrator.MONSTER)
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
	remove_button("feed")
	meters = [0.3, 0.3, 0.3]
	await say("See? We are both Chumbo now.", Narrator.MONSTER)
	await say("And we will both have a birthday. Every day. Forever and ever.", Narrator.MONSTER)
	Audio.sfx("gulp", 0, 0.5)
	name_left = 10
	eaten_name = false
	var tw := create_tween()
	tw.tween_property(self, "shrink", 0.15, 1.2)
	await wait(1.3)
	age_spin = false
	age = 1.0
	await _dijivolve(1, "DE-DIJIVOLVE")
	shrink = 1.0
	age = 1.0
	feeds_dark = 0
	_baked_key = ""
	Audio.play_music("digi", 1.5)
	Audio.sfx("pop")
	await say("Blip!", Narrator.CRITTER)
	await say("Aww, it's a baby again! Present number three, done! Feed it again next birthday. It will be hungry.")
	finish_game(IDX, "DIJIMON RAISED!")


func tick(dt: float) -> void:
	anim_t += dt
	squish = maxf(0.0, squish - dt * 3.0)
	train_msg_t = maxf(0.0, train_msg_t - dt)
	if evo_t >= 0.0:
		evo_t += dt
	if attack_t >= 0.0:
		attack_t += dt
		if attack_t > 0.6:
			attack_t = -1.0
	if flush_t >= 0.0:
		flush_t += dt
	if training:
		train_t += dt
		if train_t > 6.0:
			_train_hit(true)
	if age_spin:
		age += dt * (1.0 + age * 0.17)
		if stage == 4 and age > 40.0 and not locked and not said.has("age") and not Narrator.is_active():
			said["age"] = true
			say_bg("Look at its age, Chumbo. So many birthdays. It can't remember the first one. Neither can you.", Narrator.DARK)
	var playing := stage >= 1 and stage <= 4 and evo_t < 0.0 and not locked
	if playing and not busy:
		var drain := 0.005 * (1.0 + poops.size() * 1.5) * (1.6 if stage == 4 else 1.0)
		for i in 3:
			meters[i] = maxf(0.05, meters[i] - dt * drain)
	if playing:
		poop_t -= dt
		if poop_t <= 0.0:
			poop_t = randf_range(15.0, 21.0)
			if poops.size() < 3 and flush_t < 0.0:
				var side := -1.0 if randf() < 0.5 else 1.0
				for x in poops:
					if signf(x - 640.0) == side:
						side = -side
				poops.append(640.0 + side * randf_range(105, 135) + poops.size() * 6.0)
				Audio.sfx("poop", -2)
				if not said.has("poop"):
					said["poop"] = true
					say_bg("Uh oh. Blobmon made a poop! Tap CLEAN. Dijimon get grumpy when it's messy.")
	for h in hearts:
		h.t += dt
		h.p.y -= 60.0 * dt
	hearts = hearts.filter(func(h): return h.t < 1.5)
	Crayon.shake = 1.0 + maxf(0, stage - 3) * 0.45


# ------------------------------------------------------------------ drawing


func _darkness() -> float:
	if stage <= 3:
		return 0.0
	return clampf((stage - 3) / 3.0, 0.0, 1.0)


func _cracks() -> int:
	match stage:
		4:
			return 1
		5:
			return 1 + feeds_dark
		6:
			return 9
	return 0


func paint_back() -> void:
	_baked_key = "%d/%d" % [stage, _cracks()]
	var dark := _darkness()
	var col := Color(0.86, 0.93, 1.0).lerp(Color(0.13, 0.06, 0.15), dark)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), col)
	# the digital world: floating pixels (and, later, the same words over and over)
	for i in 26:
		var p := Vector2(fmod(i * 211.0 + 40, W), 120 + fmod(i * 97.0, 520))
		var s := 6.0 + (i % 4) * 4.0
		var pc: Color = Crayon.RAINBOW[i % 7].lerp(col, 0.55 + dark * 0.25)
		pen.draw_rect(Rect2(p, Vector2(s, s)), pc)
	if dark > 0.0:
		for i in 7:
			var p := Vector2(fmod(i * 331.0 + 90, W), 150 + i * 70)
			Crayon.text(pen, p, "HAPPY BIRTHDAY", 22, Color(0.8, 0.2, 0.3, 0.12 + dark * 0.18), 1, 40 + i, null, 0.5, false)
	_device(dark)
	_info_panel(dark)


## The egg-shaped Dijivice: rim, body, screen with chunky pixels, icons and three buttons.
func _device(dark: float) -> void:
	var rim := Crayon.ORANGE.lerp(Color(0.55, 0.05, 0.1), dark)
	var shell := Color(0.97, 0.97, 0.95).lerp(Color(0.3, 0.27, 0.3), dark)
	# key chain loop
	Crayon.circle(pen, DEVICE + Vector2(0, -DEV_R.y - 16), 26, Crayon.INK, 6, Color(0, 0, 0, 0), 501)
	pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var outer := _egg_pts(DEVICE, DEV_R, 40)
	var inner := _egg_pts(DEVICE + Vector2(0, 6), DEV_R - Vector2(26, 26), 40)
	Crayon.poly(pen, outer, Crayon.INK, 7, rim, 502)
	Crayon.poly(pen, inner, Crayon.INK, 4, shell, 503)
	# screen bezel + LCD
	Crayon.rect(pen, LCD.grow(14), Crayon.INK, 5, Color(0.45, 0.45, 0.5).lerp(Color(0.12, 0.1, 0.12), dark), 504)
	var lcd := Color(0.68, 0.78, 0.52).lerp(Color(0.42, 0.16, 0.18), dark)
	pen.draw_rect(LCD, lcd)
	var grid := PackedVector2Array()
	var x := LCD.position.x
	while x < LCD.end.x:
		grid.append(Vector2(x, LCD.position.y))
		grid.append(Vector2(x, LCD.end.y))
		x += 12.0
	var y := LCD.position.y
	while y < LCD.end.y:
		grid.append(Vector2(LCD.position.x, y))
		grid.append(Vector2(LCD.end.x, y))
		y += 12.0
	pen.draw_multiline(grid, Color(0, 0, 0, 0.06), 1.0)
	# floor line on the screen
	Crayon.line(pen, Vector2(LCD.position.x + 8, FLOOR_Y + 4), Vector2(LCD.end.x - 8, FLOOR_Y + 4), Color(0.2, 0.25, 0.15, 0.5).lerp(Color(0.1, 0, 0, 0.6), dark), 3, 505)
	# cracks (the monster is getting too big for its screen)
	for k in _cracks():
		var a := LCD.position + Vector2(fmod(k * 113.0 + 30, LCD.size.x), fmod(k * 71.0 + 10, LCD.size.y))
		var pts := PackedVector2Array([a])
		for j in 4:
			a += Vector2(cos(k * 1.7 + j) * 34, sin(k * 2.3 + j * 0.8) * 30)
			pts.append(a.clamp(LCD.position, LCD.end))
		Crayon.path(pen, pts, Color(1, 1, 1, 0.8), 3, 520 + k)
	# menu icons above the screen (V-pet style)
	for i in 4:
		_icon(i, Vector2(568 + i * 48, 190), Crayon.INK.lerp(Crayon.WHITE, dark * 0.6))
	# the three little buttons and the brand
	for i in 3:
		var bp := Vector2(586 + i * 54, 506 + (8 if i == 1 else 0))
		Crayon.circle(pen, bp, 15, Crayon.INK, 4, rim.lightened(0.25), 530 + i)
	Crayon.text(pen, Vector2(640, 566), "DIJIVICE", 34, rim.darkened(0.2), 1, 540, Crayon.title_font())


func _egg_pts(c: Vector2, r: Vector2, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		var s := sin(a)
		var taper := 1.0 - 0.1 * maxf(0.0, -s)
		pts.append(c + Vector2(cos(a) * r.x * taper, s * r.y))
	return pts


## Little menu icons: food, training, love, clean.
func _icon(i: int, p: Vector2, ink: Color) -> void:
	match i:
		0:
			Crayon.ellipse(pen, p + Vector2(4, 0), Vector2(13, 10), ink, 3, Color(0, 0, 0, 0), 550)
			Crayon.line(pen, p + Vector2(-6, 4), p + Vector2(-16, 10), ink, 4, 551)
		1:
			Crayon.line(pen, p + Vector2(-14, 0), p + Vector2(14, 0), ink, 4, 552)
			Crayon.line(pen, p + Vector2(-12, -9), p + Vector2(-12, 9), ink, 6, 553)
			Crayon.line(pen, p + Vector2(12, -9), p + Vector2(12, 9), ink, 6, 554)
		2:
			Crayon.heart(pen, p, 11, ink, Color(0, 0, 0, 0), 555)
		3:
			Crayon.path(pen, PackedVector2Array([p + Vector2(-15, 4), p + Vector2(-7, -4), p + Vector2(0, 4), p + Vector2(7, -4), p + Vector2(15, 4)]), ink, 4, 556)


func _info_panel(dark: float) -> void:
	var r := Rect2(28, 200, 316, 166)
	Crayon.rect(pen, r, Crayon.INK, 5, Color(1, 0.98, 0.9).lerp(Color(0.25, 0.15, 0.22), dark), 560)
	Crayon.text(pen, Vector2(r.position.x + r.size.x * 0.5, r.position.y - 2), "STATUS", 28, Crayon.INK if dark < 0.5 else Crayon.WHITE, 1, 561, Crayon.title_font())


func paint() -> void:
	if _baked_key != "%d/%d" % [stage, _cracks()]:
		refresh_back()
	if evo_t >= 0.0:
		_evo_rays()
	var look := (mouse - _mon_center()).normalized()
	# the training dummy
	if training or attack_t >= 0.0:
		var dp := Vector2(LCD.end.x - 30, FLOOR_Y - 34)
		Crayon.line(pen, dp + Vector2(0, -46), dp + Vector2(0, -30), Crayon.INK, 3, 600)
		Crayon.ellipse(pen, dp, Vector2(16, 32), Crayon.INK, 4, Color(0.85, 0.75, 0.5), 601)
	# poops
	for i in poops.size():
		var x: float = poops[i]
		if flush_t >= 0.0 and x < _flush_x():
			continue
		_poop(pen, Vector2(x, FLOOR_Y), 1.0, t, 610 + i * 7)
	# the monster (flashing silhouettes while it dijivolves)
	if evo_t >= 0.0 and evo_t < 2.6:
		var rate := 2.0 + evo_t * 5.0
		var which := evo_from if fmod(evo_t * rate, 1.0) < 0.5 else evo_to
		var keep := stage
		stage = which
		draw_mon(pen, which, _mon_center(), _radius(), t, Vector2.ZERO, 0.0, true, cracks)
		stage = keep
	else:
		draw_mon(pen, stage, _mon_center(), _radius(), t, look, squish, false, cracks)
		if stage >= 5:
			_extra_eyes(look)
	for h in hearts:
		Crayon.heart(pen, h.p, 14, Crayon.INK, Color(Crayon.RED, 1.0 - h.t / 1.5), 60)
	if attack_t >= 0.0:
		var from := _mouth()
		var to := Vector2(LCD.end.x - 30, FLOOR_Y - 40)
		var f := clampf(attack_t / 0.45, 0.0, 1.0)
		var p := from.lerp(to, f)
		if f < 1.0:
			Crayon.disc(pen, p, 18, Crayon.ORANGE)
			Crayon.disc(pen, p, 10, Crayon.YELLOW)
		else:
			Crayon.star(pen, to, 30, Crayon.INK, Crayon.YELLOW, 620)
	if flush_t >= 0.0:
		var x := _flush_x()
		Crayon.line(pen, Vector2(x, LCD.position.y + 6), Vector2(x, LCD.end.y - 6), Color(0.3, 0.6, 1.0), 16, 630)
		for k in 5:
			Crayon.disc(pen, Vector2(x - 14, LCD.position.y + 30 + k * 44 + sin(t * 12.0 + k) * 6), 7, Crayon.WHITE)
	match anim:
		"feed":
			if anim_t < 0.5:
				var from := Vector2(280, H - 110)
				var to := _mouth()
				var f := anim_t / 0.5
				var p := from.lerp(to, f) + Vector2(0, -sin(f * PI) * 140)
				if stage == 5:
					Crayon.poly(pen, PackedVector2Array([p + Vector2(-26, 18), p + Vector2(26, 18), p + Vector2(0, -22)]), Crayon.INK, 3, Crayon.PINK, 70)
				else:
					_meat(p)
		"pet":
			if anim_t < 0.8:
				var top := _mon_center() + Vector2(sin(anim_t * 12.0) * 40, -_radius() * (0.9 if stage <= 2 else 1.25))
				Crayon.poly(pen, PackedVector2Array([top + Vector2(-30, 0), top + Vector2(30, 0), top + Vector2(34, -30), top + Vector2(-34, -30)]), Crayon.INK, 3, Color(1, 0.85, 0.7), 73)
	if training:
		_train_bar()


## Text on a little white card so it reads over the monster.
func _label(c: Vector2, s: String, size: int, col: Color, font: Font, sd: int) -> void:
	var f := font if font != null else Crayon.body()
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	Crayon.rect(pen, Rect2(c - Vector2(w * 0.5 + 14, size * 0.7), Vector2(w + 28, size * 1.4)), Crayon.INK, 3, Color(1, 1, 1, 0.92), sd + 1)
	Crayon.text(pen, c, s, size, col, 1, sd, font, 0.5, false)


func _flush_x() -> float:
	return LCD.position.x + LCD.size.x * clampf(flush_t / 0.85, 0.0, 1.0)


func _meat(p: Vector2) -> void:
	Crayon.line(pen, p + Vector2(-8, 8), p + Vector2(-26, 22), Crayon.WHITE, 8, 71)
	Crayon.dot(pen, p + Vector2(-28, 20), 6, Crayon.WHITE)
	Crayon.ellipse(pen, p + Vector2(6, -4), Vector2(22, 17), Crayon.INK, 3, Color(0.7, 0.35, 0.2), 72)


func _extra_eyes(look: Vector2) -> void:
	var c := _mon_center()
	var r := _radius()
	var n := 3 if stage == 5 else 5
	for i in n:
		var e := c + Vector2(-r * 0.7 + i * r * 1.4 / maxf(1, n - 1), -r * (1.6 if stage == 6 else 0.05) + (i % 2) * r * 0.12)
		if stage == 5:
			e = c + Vector2(-r * 0.35 + i * r * 0.2, r * 0.25 + (i % 2) * r * 0.1)
		if fmod(t * 0.6 + i * 1.3, 4.0) < 0.12:
			continue
		Crayon.disc(pen, e, r * 0.06, Crayon.WHITE)
		Crayon.disc(pen, e + look * r * 0.02, r * 0.03, Crayon.BLACK)


func _evo_rays() -> void:
	var c := LCD.get_center()
	var segs := PackedVector2Array()
	var cols := PackedColorArray()
	var a0 := evo_t * 1.6
	for i in 18:
		var a := a0 + TAU * i / 18.0
		segs.append(c)
		segs.append(c + Vector2(cos(a), sin(a)) * 1400.0)
		var col: Color = Crayon.RAINBOW[i % 7]
		col.a = 0.35
		cols.append(col)
	pen.draw_multiline_colors(segs, cols, 70.0)
	if evo_t < 2.6:
		var flash := 0.5 + 0.5 * sin(evo_t * (8.0 + evo_t * 10.0))
		pen.draw_rect(LCD, Color(1, 1, 1, 0.5 + flash * 0.4))


func _train_bar() -> void:
	var bar := Rect2(LCD.position.x + 24, LCD.position.y + 12, LCD.size.x - 48, 30)
	pen.draw_rect(bar, Color(1, 1, 1, 0.85))
	var z0 := bar.position.x + bar.size.x * (train_zone - train_w * 0.5)
	pen.draw_rect(Rect2(z0, bar.position.y, bar.size.x * train_w, bar.size.y), Crayon.GREEN)
	Crayon.rect(pen, bar, Crayon.INK, 4, Color(0, 0, 0, 0), 640)
	var mx := bar.position.x + bar.size.x * _marker()
	var tip := Vector2(mx, bar.end.y - 6)
	Crayon.poly(pen, PackedVector2Array([tip, tip + Vector2(-13, 26), tip + Vector2(13, 26)]), Crayon.INK, 3, Crayon.RED, 641)
	_label(Vector2(bar.get_center().x, bar.end.y + 40), "TAP IN THE GREEN!", 24, Crayon.INK, null, 642)


func paint_top() -> void:
	var ink := Crayon.INK if stage < 4 else Crayon.WHITE
	# the player's name, which may get eaten
	var nm: String = Game.CANON_NAME.substr(0, name_left)
	Crayon.text(pen, Vector2(W * 0.5, 40), "YOUR NAME: " + nm + ("_".repeat(10 - name_left)), 36, ink, 1, 801, null, 1.0, false)
	# status readout
	var st: Dictionary = STAGES[stage]
	var tc := Crayon.INK if _darkness() < 0.5 else Color(0.95, 0.9, 0.95)
	Crayon.text(pen, Vector2(46, 240), "NAME: " + (String(st.name) if stage > 0 else "???"), 26, tc, 0, 805, null, 0.6, false)
	Crayon.text(pen, Vector2(46, 288), "LEVEL: " + String(st.level), 26, tc, 0, 806, null, 0.6, false)
	var age_s := "TOO MANY" if age >= 99999.0 else str(int(age))
	var unit := " birthday" if int(age) == 1 else " birthdays"
	Crayon.text(pen, Vector2(46, 336), "AGE: " + age_s + ("" if age >= 99999.0 else unit), 26, Crayon.RED if age_spin else tc, 0, 807, null, 0.6 + (0.7 if age_spin else 0.0), false)
	# meters
	if stage >= 1 and stage <= 5 and evo_t < 0.0:
		var labels := ["FOOD", "POWER", "LOVE"]
		var cols := [Crayon.PINK, Crayon.YELLOW, Crayon.RED]
		var rows := 3 if stage <= 4 else 1
		for i in rows:
			var r := Rect2(1074, 214 + i * 58, 170, 34)
			var lab: String = labels[i] if stage <= 4 else "MORE"
			Crayon.text(pen, Vector2(r.position.x - 10, r.get_center().y), lab, 26, ink, 2, 810 + i)
			Crayon.rect(pen, r, ink, 4, Color(1, 1, 1, 0.3), 820 + i)
			pen.draw_rect(Rect2(r.position + Vector2(4, 4), Vector2((r.size.x - 8) * meters[i], r.size.y - 8)), cols[i])
	# CLEAN blinks when there's poop
	if not poops.is_empty() and stage <= 4 and not busy:
		var b := get_button("clean")
		if not b.is_empty() and b.visible and fmod(t, 0.8) < 0.45:
			Crayon.rect(pen, b.rect.grow(8), Crayon.RED, 5, Color(0, 0, 0, 0), 830)
	if train_msg_t > 0.0 and train_msg != "":
		var col := Crayon.RED if train_msg == "MISS!" else Crayon.ORANGE.darkened(0.15)
		_label(Vector2(640, LCD.position.y + 96 - (1.4 - train_msg_t) * 20), train_msg, 34, col, Crayon.title_font(), 835)
	if stage == 0:
		Crayon.text(pen, Vector2(W * 0.5, H - 70), "TAP THE EGG!", 48, Crayon.PURPLE, 1, 840, Crayon.title_font())
	if evo_t >= 0.0:
		var r := Rect2(170, 500, 940, 150)
		Crayon.rect(pen, r, Crayon.INK, 6, Color(0.1, 0.08, 0.2, 0.92), 850)
		var from_name: String = STAGES[evo_from].name
		Crayon.text(pen, Vector2(640, r.position.y + 42), "%s %s TO..." % [from_name, evo_word], 40, Crayon.WHITE, 1, 851, Crayon.title_font())
		if evo_t >= 2.6:
			var k := clampf((evo_t - 2.6) * 5.0, 0.0, 1.0)
			Crayon.text(pen, Vector2(640, r.position.y + 106), String(STAGES[evo_to].name) + "!", int(lerpf(30, 66, k)), Crayon.YELLOW, 1, 852, Crayon.title_font())


# ------------------------------------------------------------------ the monsters


## Draws monster `kind` (0 egg ... 6 Chumbomon) around centre c with size r.
## sil = plain silhouette (for the dijivolve flashes).
static func draw_mon(ci: CanvasItem, kind: int, c: Vector2, r: float, tm: float, look: Vector2, sq: float, sil: bool, egg_cracks: int = 0) -> void:
	match kind:
		0:
			_egg(ci, c, r, tm, sq, sil, egg_cracks)
		1:
			_blobmon(ci, c, r, tm, look, sq, sil)
		2:
			_frostmon(ci, c, r, tm, look, sq, sil)
		3, 4, 5:
			_dino(ci, c, r, tm, look, sq, sil, kind - 3)
		6:
			_chumbomon(ci, c, r, tm, look, sq, sil)


## Partymon standing at `feet` (for the finale cast).
static func draw_mascot(ci: CanvasItem, feet: Vector2, sc: float, tm: float) -> void:
	var r := 80.0 * sc
	_dino(ci, feet - Vector2(0, r * 1.05), r, tm, Vector2.ZERO, 0.0, false, 0)


static func _blink(tm: float, off: float = 0.0) -> bool:
	return fmod(tm + off, 3.3) < 0.12


## Chunky LCD-pixel eye: square, a pupil square that looks around and a white pixel shine.
static func _pix_eye(ci: CanvasItem, p: Vector2, s: float, look: Vector2, blink: bool, iris: Color = Crayon.BLACK) -> void:
	if blink:
		ci.draw_rect(Rect2(p.x - s, p.y - s * 0.2, s * 2.0, s * 0.4), Crayon.BLACK)
		return
	ci.draw_rect(Rect2(p.x - s, p.y - s, s * 2.0, s * 2.0), iris)
	var pp := p + look * s * 0.3
	if iris != Crayon.BLACK:
		ci.draw_rect(Rect2(pp.x - s * 0.5, pp.y - s * 0.5, s, s), Crayon.BLACK)
	ci.draw_rect(Rect2(pp.x - s * 0.7, pp.y - s * 0.75, s * 0.5, s * 0.5), Crayon.WHITE)


static func _smile(ci: CanvasItem, m: Vector2, w: float, lw: float, s: int) -> void:
	Crayon.path(ci, PackedVector2Array([m + Vector2(-w, -w * 0.25), m + Vector2(-w * 0.5, w * 0.2), m + Vector2(0, w * 0.32), m + Vector2(w * 0.5, w * 0.2), m + Vector2(w, -w * 0.25)]), Crayon.INK, lw, s)


static func _egg(ci: CanvasItem, c: Vector2, r: float, tm: float, sq: float, sil: bool, n_cracks: int) -> void:
	var wob := sin(tm * 10.0) * 0.05 * (1.0 if n_cracks > 0 else 0.3) + sq * 0.1
	ci.draw_set_transform(c, wob, Vector2.ONE)
	Crayon.ellipse(ci, Vector2.ZERO, Vector2(r * 0.78, r), Crayon.INK, 6, Crayon.INK if sil else Color(0.98, 0.95, 0.85), 30)
	if not sil:
		var z := PackedVector2Array()
		for i in 9:
			z.append(Vector2(-r * 0.72 + i * r * 0.18, r * 0.05 if i % 2 == 0 else -r * 0.12))
		Crayon.path(ci, z, Crayon.PURPLE, 6, 35)
		for i in 5:
			Crayon.dot(ci, Vector2(-r * 0.4 + i * r * 0.2, r * 0.35 + (i % 2) * r * 0.18), r * 0.07, Crayon.RAINBOW[i])
		for k in n_cracks:
			var y := -r * 0.65 + k * r * 0.24
			var pts := PackedVector2Array([Vector2(-r * 0.6, y), Vector2(-r * 0.35, y + 12), Vector2(-r * 0.1, y - 6), Vector2(r * 0.15, y + 10), Vector2(r * 0.4, y - 4), Vector2(r * 0.6, y + 8)])
			Crayon.path(ci, pts, Crayon.INK, 4, 40 + k)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func _blobmon(ci: CanvasItem, c: Vector2, r: float, tm: float, look: Vector2, sq: float, sil: bool) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var wob := 1.0 + sin(a * 3.0 + tm * 3.0) * 0.04 + sin(a * 5.0 - tm * 2.0) * 0.03
		pts.append(c + Vector2(cos(a) * r * (1.0 + sq * 0.15) * wob, sin(a) * r * (0.85 - sq * 0.15) * wob))
	Crayon.poly(ci, pts, Crayon.INK, maxf(4.0, r * 0.07), Crayon.INK if sil else Crayon.PURPLE, 100)
	if sil:
		return
	Crayon.disc(ci, c + Vector2(-r * 0.42, -r * 0.42), r * 0.13, Color(1, 1, 1, 0.35))
	var bl := _blink(tm)
	_pix_eye(ci, c + Vector2(-r * 0.32, -r * 0.12), r * 0.13, look, bl)
	_pix_eye(ci, c + Vector2(r * 0.32, -r * 0.12), r * 0.13, look, bl)
	_smile(ci, c + Vector2(0, r * 0.22), r * 0.2, 4, 104)
	Crayon.disc(ci, c + Vector2(-r * 0.55, r * 0.12), r * 0.13, Color(1, 0.5, 0.6, 0.5))
	Crayon.disc(ci, c + Vector2(r * 0.55, r * 0.12), r * 0.13, Color(1, 0.5, 0.6, 0.5))
	Crayon.party_hat(ci, c + Vector2(r * 0.15, -r * 0.78), r * 0.38, Crayon.YELLOW, 102, 0.25)


static func _frostmon(ci: CanvasItem, c: Vector2, r: float, tm: float, look: Vector2, sq: float, sil: bool) -> void:
	var body := Crayon.INK if sil else Crayon.PINK
	var cream := Crayon.INK if sil else Color(1.0, 0.96, 0.86)
	# two long floppy frosting ears
	for sx in [-1.0, 1.0]:
		var ang: float = sx * (0.55 + sin(tm * 2.2 + sx) * 0.12)
		var base := c + Vector2(sx * r * 0.3, -r * 0.62)
		var mid := base + Vector2(sin(ang), -cos(ang)) * r * 0.48
		ci.draw_set_transform(mid, ang, Vector2.ONE)
		Crayon.ellipse(ci, Vector2.ZERO, Vector2(r * 0.17, r * 0.52), Crayon.INK, maxf(3.0, r * 0.05), cream, 110 + int(sx))
		if not sil:
			Crayon.dot(ci, Vector2(0, -r * 0.2), r * 0.05, Crayon.BLUE)
			Crayon.dot(ci, Vector2(r * 0.04, r * 0.12), r * 0.05, Crayon.GREEN)
		ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	Crayon.ellipse(ci, c, Vector2(r * (1.0 + sq * 0.15), r * (0.82 - sq * 0.12)), Crayon.INK, maxf(4.0, r * 0.07), body, 114)
	if sil:
		return
	# frosting cap with drips
	Crayon.ellipse(ci, c + Vector2(0, -r * 0.5), Vector2(r * 0.62, r * 0.25), Color(0, 0, 0, 0), 0, cream, 115)
	for k in 3:
		Crayon.oval(ci, c + Vector2(-r * 0.4 + k * r * 0.4, -r * 0.3), Vector2(r * 0.09, r * 0.15), cream)
	for k in 5:
		var sp := c + Vector2(-r * 0.4 + k * r * 0.2, -r * 0.55 + (k % 2) * r * 0.08)
		Crayon.line(ci, sp, sp + Vector2(r * 0.07, r * 0.03), Crayon.RAINBOW[k], 4, 116 + k, 0.2)
	var bl := _blink(tm, 0.7)
	_pix_eye(ci, c + Vector2(-r * 0.3, -r * 0.02), r * 0.12, look, bl)
	_pix_eye(ci, c + Vector2(r * 0.3, -r * 0.02), r * 0.12, look, bl)
	_smile(ci, c + Vector2(0, r * 0.3), r * 0.18, 4, 121)
	Crayon.disc(ci, c + Vector2(-r * 0.6, r * 0.22), r * 0.12, Color(1, 0.4, 0.5, 0.5))
	Crayon.disc(ci, c + Vector2(r * 0.6, r * 0.22), r * 0.12, Color(1, 0.4, 0.5, 0.5))


## Partymon (form 0), Grrthdaymon (1) and Metal Cakemon (2): the dino line.
static func _dino(ci: CanvasItem, c: Vector2, r: float, tm: float, look: Vector2, sq: float, sil: bool, form: int) -> void:
	var ink := Crayon.INK
	var skin: Color = [Crayon.ORANGE, Color(0.96, 0.5, 0.12), Color(0.8, 0.42, 0.2)][form]
	var belly := Color(1.0, 0.86, 0.58)
	var metal := Color(0.62, 0.64, 0.7)
	if sil:
		skin = ink
		belly = ink
		metal = ink
	var w := maxf(3.0, r * 0.055)
	var cc := c + Vector2(0, sin(tm * 3.0) * r * 0.03 - sq * r * 0.05)
	# tail
	var sway := sin(tm * 2.0) * r * 0.06
	Crayon.poly(ci, PackedVector2Array([cc + Vector2(-r * 0.4, r * 0.15), cc + Vector2(-r * 1.1, r * 0.78 + sway), cc + Vector2(-r * 0.3, r * 0.7)]), ink, w, skin, 200)
	# candles all along its back (Metal Cakemon)
	if form == 2:
		for k in 7:
			var a := PI * (1.05 + k * 0.12)
			var b := cc + Vector2(cos(a) * r * 0.62, r * 0.25 + sin(a) * r * 0.72)
			var top := b + Vector2(cos(a), sin(a)) * r * 0.3
			Crayon.line(ci, b, top, ink if sil else Crayon.RAINBOW[k], r * 0.07, 202 + k)
			if not sil:
				Crayon.flame(ci, top + Vector2(cos(a), sin(a)) * r * 0.06, r * 0.07, 210 + k)
	# legs
	for sx in [-1.0, 1.0]:
		var foot := cc + Vector2(sx * r * 0.32, r * 0.9)
		Crayon.ellipse(ci, foot, Vector2(r * 0.22, r * 0.15), ink, w, skin, 220 + int(sx))
		if not sil:
			for k in 2:
				Crayon.line(ci, foot + Vector2(r * (0.1 + k * 0.08), r * 0.08), foot + Vector2(r * (0.14 + k * 0.08), r * 0.15), Crayon.WHITE, maxf(2.0, r * 0.03), 224 + k, 0.2)
	# body + belly
	Crayon.ellipse(ci, cc + Vector2(0, r * 0.3), Vector2(r * 0.58, r * 0.62), ink, w, skin, 230)
	if not sil:
		Crayon.oval(ci, cc + Vector2(r * 0.08, r * 0.4), Vector2(r * 0.32, r * 0.42), belly)
		if form >= 1:
			for k in 3:
				var sp := cc + Vector2(-r * 0.45, r * (0.05 + k * 0.2))
				Crayon.line(ci, sp, sp + Vector2(r * 0.16, r * 0.04), Crayon.BLUE, maxf(3.0, r * 0.06), 232 + k, 0.4)
		if form == 2:
			Crayon.rect(ci, Rect2(cc + Vector2(-r * 0.2, r * 0.05), Vector2(r * 0.5, r * 0.32)), ink, w * 0.7, metal, 236)
			Crayon.dot(ci, cc + Vector2(r * 0.05, r * 0.21), r * 0.06, Crayon.RED)
	# arms (Metal Cakemon has one big metal claw)
	var wave := sin(tm * 4.0) * r * 0.06
	Crayon.line(ci, cc + Vector2(-r * 0.45, r * 0.15), cc + Vector2(-r * 0.72, r * 0.38 + wave), ink, maxf(4.0, r * 0.13), 240)
	if form == 2:
		var hand := cc + Vector2(r * 0.85, r * 0.2)
		Crayon.rect(ci, Rect2(cc + Vector2(r * 0.35, r * 0.05), Vector2(r * 0.45, r * 0.24)), ink, w * 0.7, metal, 241)
		for k in 3:
			var a := -0.5 + k * 0.5
			Crayon.line(ci, hand, hand + Vector2(cos(a), sin(a)) * r * 0.32, ink if sil else metal.darkened(0.3), maxf(4.0, r * 0.08), 242 + k)
	else:
		Crayon.line(ci, cc + Vector2(r * 0.45, r * 0.15), cc + Vector2(r * 0.72, r * 0.36 - wave), ink, maxf(4.0, r * 0.13), 245)
	# head + snout
	var hc := cc + Vector2(r * 0.1, -r * 0.48)
	Crayon.ellipse(ci, hc, Vector2(r * 0.55, r * 0.45), ink, w, skin, 250)
	Crayon.ellipse(ci, hc + Vector2(r * 0.38, r * 0.14), Vector2(r * 0.34, r * 0.22), ink, w, skin, 251)
	if sil:
		return
	# mouth and teeth
	var m0 := hc + Vector2(r * 0.12, r * 0.24)
	var m1 := hc + Vector2(r * 0.7, r * 0.2)
	Crayon.line(ci, m0, m1, ink, maxf(3.0, r * 0.04), 252)
	var nt := 2 if form == 0 else 5
	for k in nt:
		var tp := m0.lerp(m1, (k + 0.6) / (nt + 0.5))
		Crayon.poly(ci, PackedVector2Array([tp + Vector2(-r * 0.04, -r * 0.01), tp + Vector2(r * 0.04, -r * 0.01), tp + Vector2(0, r * 0.07)]), ink, 2, Crayon.WHITE, 254 + k)
	# eyes: green like a good rookie, then one red robot eye
	var bl := _blink(tm, 1.3)
	var eye_s := r * 0.1
	_pix_eye(ci, hc + Vector2(-r * 0.12, -r * 0.1), eye_s, look, bl, Color(0.25, 0.6, 0.25) if form < 2 else Color(0.85, 0.15, 0.1))
	if form == 2:
		var ep := hc + Vector2(r * 0.22, -r * 0.12)
		Crayon.disc(ci, ep, eye_s * 2.2, Color(1, 0.1, 0.1, 0.25 + 0.15 * sin(tm * 6.0)))
		ci.draw_rect(Rect2(ep - Vector2(eye_s, eye_s), Vector2(eye_s, eye_s) * 2.0), Color(1, 0.15, 0.1))
	else:
		_pix_eye(ci, hc + Vector2(r * 0.22, -r * 0.12), eye_s, look, bl, Color(0.25, 0.6, 0.25))
	match form:
		0:
			Crayon.party_hat(ci, hc + Vector2(-r * 0.12, -r * 0.36), r * 0.3, Crayon.BLUE, 260, -0.2)
		1:
			# a cake helmet with candle horns
			Crayon.ellipse(ci, hc + Vector2(-r * 0.05, -r * 0.3), Vector2(r * 0.5, r * 0.22), ink, w * 0.8, Color(0.55, 0.32, 0.2), 261)
			Crayon.ellipse(ci, hc + Vector2(-r * 0.05, -r * 0.38), Vector2(r * 0.42, r * 0.12), Color(0, 0, 0, 0), 0, Crayon.PINK, 262)
			for k in 3:
				var b := hc + Vector2(-r * 0.32 + k * r * 0.27, -r * 0.45)
				Crayon.line(ci, b, b + Vector2(0, -r * 0.3), Crayon.RAINBOW[k * 2], maxf(4.0, r * 0.08), 263 + k)
				Crayon.flame(ci, b + Vector2(0, -r * 0.36), r * 0.08, 266 + k)
		2:
			Crayon.ellipse(ci, hc + Vector2(-r * 0.05, -r * 0.3), Vector2(r * 0.52, r * 0.22), ink, w * 0.8, metal, 270)
			for k in 3:
				Crayon.dot(ci, hc + Vector2(-r * 0.35 + k * r * 0.3, -r * 0.32), r * 0.035, ink)


## Chumbomon: it looks just like you. Mostly. c = where its feet are.
static func _chumbomon(ci: CanvasItem, feet: Vector2, r: float, tm: float, look: Vector2, sq: float, sil: bool) -> void:
	var ink := Crayon.INK
	var shirt := ink if sil else Crayon.GREEN
	var dino := ink if sil else Color(0.96, 0.5, 0.12)
	var skin := ink if sil else Color(1, 0.88, 0.75)
	var w := maxf(4.0, r * 0.05)
	var bob := sin(tm * 2.5) * r * 0.03 + sq * r * 0.05
	var hip := feet + Vector2(0, -r * 0.95 + bob)
	var neck := hip + Vector2(0, -r * 0.85)
	var head := neck + Vector2(0, -r * 0.5)
	# dino tail
	Crayon.poly(ci, PackedVector2Array([hip + Vector2(-r * 0.2, -r * 0.1), hip + Vector2(-r * 0.95, r * 0.6 + sin(tm * 2.0) * r * 0.08), hip + Vector2(-r * 0.1, r * 0.3)]), ink, w, dino, 300)
	# legs with dino feet
	for sx in [-1.0, 1.0]:
		Crayon.line(ci, hip + Vector2(sx * r * 0.18, 0), feet + Vector2(sx * r * 0.3, -r * 0.1), ink, w * 1.4, 302 + int(sx))
		Crayon.ellipse(ci, feet + Vector2(sx * r * 0.35, -r * 0.06), Vector2(r * 0.2, r * 0.1), ink, w, dino, 304 + int(sx))
	# shirt (with a name sticker)
	Crayon.poly(ci, PackedVector2Array([neck + Vector2(-r * 0.42, r * 0.05), neck + Vector2(r * 0.42, r * 0.05), hip + Vector2(r * 0.36, r * 0.05), hip + Vector2(-r * 0.36, r * 0.05)]), ink, w, shirt, 306)
	# arms with claws, one holding a fork
	var hand_l := neck + Vector2(-r * 0.7, r * 0.55 + sin(tm * 3.0) * r * 0.05)
	var hand_r := neck + Vector2(r * 0.72, r * 0.4)
	Crayon.line(ci, neck + Vector2(-r * 0.38, r * 0.1), hand_l, ink, w * 1.3, 308)
	Crayon.line(ci, neck + Vector2(r * 0.38, r * 0.1), hand_r, ink, w * 1.3, 309)
	if not sil:
		for k in 3:
			var a := PI * 0.5 + (k - 1) * 0.5
			Crayon.line(ci, hand_l, hand_l + Vector2(cos(a), sin(a)) * r * 0.14, Crayon.WHITE, maxf(2.0, r * 0.03), 310 + k, 0.2)
		Crayon.line(ci, hand_r, hand_r + Vector2(r * 0.05, -r * 0.55), Color(0.75, 0.75, 0.8), maxf(3.0, r * 0.04), 314)
		for k in 3:
			var tip := hand_r + Vector2(r * (0.0 + k * 0.05), -r * 0.55)
			Crayon.line(ci, tip, tip + Vector2(0, -r * 0.14), Color(0.75, 0.75, 0.8), maxf(2.0, r * 0.025), 315 + k, 0.2)
		var tag := Rect2(neck + Vector2(-r * 0.36, r * 0.3), Vector2(r * 0.72, r * 0.26))
		Crayon.rect(ci, tag, ink, 3, Crayon.WHITE, 318)
		Crayon.text(ci, tag.get_center(), "I'M CHUMBO", maxi(12, int(r * 0.11)), Crayon.RED, 1, 319, null, 0.4, false)
	# head
	Crayon.circle(ci, head, r * 0.42, ink, w, skin, 320)
	if sil:
		return
	# messy hair
	for k in 6:
		var a := PI * (1.1 + k * 0.16)
		var b := head + Vector2(cos(a), sin(a)) * r * 0.38
		Crayon.line(ci, b, b + Vector2(cos(a), sin(a)) * r * 0.14, Crayon.BROWN, maxf(3.0, r * 0.05), 322 + k)
	Crayon.face(ci, head + Vector2(0, r * 0.03), r * 0.38, "wide", look, 330)
	Crayon.party_hat(ci, head + Vector2(r * 0.05, -r * 0.36), r * 0.28, Crayon.GREEN, 340, 0.2)


static func _poop(ci: CanvasItem, base: Vector2, sc: float, tm: float, s: int) -> void:
	var col := Color(0.5, 0.3, 0.16)
	Crayon.ellipse(ci, base + Vector2(0, -10) * sc, Vector2(22, 10) * sc, Crayon.INK, 3, col, s)
	Crayon.ellipse(ci, base + Vector2(0, -24) * sc, Vector2(15, 8) * sc, Crayon.INK, 3, col, s + 1)
	Crayon.ellipse(ci, base + Vector2(2, -35) * sc, Vector2(8, 6) * sc, Crayon.INK, 3, col, s + 2)
	for k in 2:
		var x := base.x + (k * 20 - 10) * sc
		var y0 := base.y - 46 * sc
		var off := sin(tm * 3.0 + k) * 4.0
		Crayon.path(ci, PackedVector2Array([Vector2(x + off, y0), Vector2(x - 4 - off, y0 - 10), Vector2(x + 4 + off, y0 - 20)]), Color(0.3, 0.45, 0.2), 3, s + 3 + k)
