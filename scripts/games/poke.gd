extends Screen
## Present 8: POKeMANS (creature-catching RPG battles). Walk in the tall grass, battle the wild
## Birthday Pokemans and catch them. A wild ??? appears. It cannot be fought. It cannot be fled.

const IDX := 7
const GB0 := Color(0.88, 0.95, 0.7)
const GB1 := Color(0.6, 0.75, 0.4)
const GB2 := Color(0.3, 0.45, 0.25)
const GB3 := Color(0.1, 0.18, 0.12)
const WILD := [
	{"name": "BALLOONBASAUR", "kind": "balloon"},
	{"name": "FROSTLE", "kind": "frostle"},
	{"name": "CAKEMANDER", "kind": "cakemander"},
	{"name": "CANDLEPUFF", "kind": "puff"},
	{"name": "PRESENTOAD", "kind": "presentoad"},
	{"name": "PINYATTA", "kind": "pinyatta"},
]
## Catches before the grass grows tall, and before ??? shows up.
const DARK_AT := 4
const CATCH_ALL := 6

var mode := "intro"   # intro, walk, battle, end
var me := Vector2(640, 430)
var me_target := Vector2(640, 430)
var walks := 0
var caught: Array = []
var foe := {}
var foe_hp := 1.0
var my_hp := 1.0
var msg := ""
var msg_shown := 0.0
var menu := ""        # main, moves, none
var ball_t := -1.0
var shakes := 0
var foe_shake := 0.0
var foe_flash := 0.0
var foe_gone := false
var invert := 0.0
var dark := false
var encounter_flash := 0.0
var next_wild := 0
# (headbutt the same tree three times: a very rare MEWFFIN was hiding in it)
var tree_taps := {}
var mew := false
var mew_pos := Vector2.ZERO
var mew_a := 0.0
var gold_ball := false
var leaves: Array = []   # {p, v, t}


var _baked_key := ""


func _overworld_mode() -> bool:
	return mode in ["walk", "intro", "trans", "end"]


func enter() -> void:
	Narrator.top = true
	use_back_layer()
	lyrics_y = 34.0
	Audio.play_music("poke")
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await say("Present number eight! A POKeMANS adventure! Walk in the tall grass to find wild Birthday Pokemans, then catch them with your party ball!")
	mode = "walk"
	locked = false


# ---------------------------------------------------------------- overworld

func press(p: Vector2) -> void:
	if mode == "walk":
		if not gold_ball and not locked:
			for k in 6:
				if p.distance_to(_tree(k)) < 46.0:
					tree_taps[k] = tree_taps.get(k, 0) + 1
					_shake_tree(k, 6)
					if tree_taps[k] >= 3:
						_mewffin(k)
						return
		me_target = p.clamp(Vector2(80, 180), Vector2(W - 80, H - 60))
	elif mode == "battle" and msg_shown < msg.length():
		msg_shown = msg.length()


func tick(dt: float) -> void:
	msg_shown = minf(msg.length(), msg_shown + dt * 40.0)
	foe_shake = maxf(0.0, foe_shake - dt)
	foe_flash = maxf(0.0, foe_flash - dt)
	encounter_flash = maxf(0.0, encounter_flash - dt)
	if ball_t >= 0.0:
		ball_t += dt
	for lf in leaves:
		lf.t += dt
		lf.v.y += 160.0 * dt
		lf.p += lf.v * dt
	leaves = leaves.filter(func(lf): return lf.t < 1.6)
	if mode == "walk":
		var d := me_target - me
		if d.length() > 0.5:
			me += d.normalized() * minf(d.length(), 260.0 * dt)
			if me.distance_to(me_target) <= 0.5:
				_arrived()


func _tree(k: int) -> Vector2:
	return Vector2(70 + k * 228, 150 + (k % 2) * 30)


func _shake_tree(k: int, n: int) -> void:
	Audio.sfx("bonk", -8, randf_range(0.9, 1.1))
	for i in n:
		leaves.append({"p": _tree(k) + Vector2(randf_range(-36, 36), randf_range(-30, 20)), "v": Vector2(randf_range(-60, 60), randf_range(-80, 10)), "t": 0.0})


func _mewffin(k: int) -> void:
	locked = true
	me_target = me
	gold_ball = true
	Game.found_egg("poke")
	_shake_tree(k, 20)
	await wait(0.4)
	Audio.sfx("sparkle")
	mew = true
	mew_pos = _tree(k)
	mew_a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "mew_pos", me + Vector2(140, -120), 1.0).set_trans(Tween.TRANS_SINE)
	await wait(1.0)
	say_bg("A wild MEWFFIN! It's super rare. It left you a golden party ball!")
	var tw2 := create_tween()
	tw2.tween_property(self, "mew_a", TAU * 1.5, 2.2)
	await wait(2.2)
	Audio.sfx("catch")
	var tw3 := create_tween()
	tw3.tween_property(self, "mew_pos", Vector2(mew_pos.x + 200, -150), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await wait(1.0)
	mew = false
	if mode == "walk":
		locked = false


func _arrived() -> void:
	walks += 1
	if walks % 2 == 0 or walks >= 3 and randf() < 0.7:
		_encounter()


func _encounter() -> void:
	mode = "trans"
	locked = true
	encounter_flash = 1.0
	Audio.sfx("glitch" if caught.size() >= CATCH_ALL else "run", -4)
	await wait(1.0)
	if caught.size() >= CATCH_ALL:
		foe = {"name": "???", "kind": "chumbmon"}
	else:
		foe = WILD[next_wild % WILD.size()]
		next_wild += 1
	foe_hp = 1.0
	foe_gone = false
	mode = "battle"
	shakes = 0
	ball_t = -1.0
	await _msg("A wild %s appeared!" % foe.name)
	if dark and foe.kind != "chumbmon":
		await _msg("It looks very tired. It has been in the grass a long time.")
	if foe.kind == "chumbmon":
		await say("That's not a Pokemans. It's smiling at you. It knows your name.", Narrator.DARK)
	_main_menu()
	locked = false


func _msg(text: String, hold: float = 0.9) -> void:
	msg = text
	msg_shown = 0.0
	await wait(text.length() / 40.0 + hold)


# ---------------------------------------------------------------- battle menus

func _clear_menu() -> void:
	for id in ["fight", "ball", "run", "m1", "m2", "m3", "back"]:
		remove_button(id)
	menu = ""


func _main_menu() -> void:
	_clear_menu()
	menu = "main"
	msg = "What will PARTYCHU do?"
	msg_shown = msg.length()
	add_button("fight", Rect2(760, 560, 230, 64), "FIGHT", _fight_menu, GB0, 36)
	add_button("ball", Rect2(1010, 560, 230, 64), "BALL", _throw, GB0, 36)
	add_button("run", Rect2(760, 636, 480, 64), "RUN", _run_away, GB0, 36)


func _fight_menu() -> void:
	_clear_menu()
	menu = "moves"
	var names := ["TICKLE", "CONFETTI", "SING"] if foe.kind != "chumbmon" else ["...", "...", "..."]
	for k in 3:
		var nm: String = names[k]
		add_button("m%d" % (k + 1), Rect2(760 + (k % 2) * 250, 560 + (k / 2) * 76, 230, 64), nm, func(): _use_move(nm), GB0, 32)
	add_button("back", Rect2(1010, 636, 230, 64), "BACK", _main_menu, GB1, 30)


func _use_move(move: String) -> void:
	_clear_menu()
	locked = true
	if foe.kind == "chumbmon":
		await _msg("PARTYCHU is too scared to move.")
		await _msg("??? is watching you.", 1.4)
		Audio.sfx("heartbeat")
		_main_menu()
		locked = false
		return
	await _msg("PARTYCHU used %s!" % move, 0.3)
	Audio.sfx("hit")
	foe_shake = 0.5
	foe_flash = 0.4
	foe_hp = maxf(0.08, foe_hp - randf_range(0.3, 0.45))
	await wait(0.6)
	if randf() < 0.5:
		await _msg("It's super effective!")
	var attacks := ["HUG", "GIGGLE", "BIRTHDAY WISH", "SPRINKLE"]
	if dark:
		attacks = ["STAY", "ONE MORE CANDLE", "FORGET", "BIRTHDAY AGAIN"]
	await _msg("Wild %s used %s!" % [foe.name, attacks[randi() % attacks.size()]], 0.3)
	Audio.sfx("boing", -6)
	my_hp = maxf(0.3, my_hp - 0.1)
	if dark:
		await _msg("It's very effective. You feel a little older.")
	else:
		await _msg("It's not very effective. It just wants to party.")
	_main_menu()
	locked = false


func _throw() -> void:
	_clear_menu()
	locked = true
	await _msg("You threw a PARTY BALL!", 0.2)
	Audio.sfx("throw")
	ball_t = 0.0
	await wait(0.7)
	foe_gone = true
	Audio.sfx("pop")
	var need := 3
	var success := randf() < 0.4 + (1.0 - foe_hp) * 0.6
	if foe.kind == "chumbmon":
		need = 1
		success = true
	for k in need:
		await wait(0.55)
		shakes += 1
		Audio.sfx("shake")
		if not success and k == 1:
			break
	await wait(0.6)
	if success:
		Audio.sfx("catch")
		if foe.kind == "chumbmon":
			await _chumbmon_caught()
			return
		caught.append(foe.name)
		await _msg("Gotcha! %s was caught!" % foe.name, 1.2)
		ball_t = -1.0
		await _after_catch()
	else:
		foe_gone = false
		ball_t = -1.0
		shakes = 0
		Audio.sfx("pop", -2, 0.8)
		await _msg("Oh no! It broke free!")
		_main_menu()
	locked = false


func _after_catch() -> void:
	mode = "walk"
	msg = ""
	me_target = me
	match caught.size():
		1:
			say_bg("You caught one! Find some more in the tall grass!")
		2:
			say_bg("Two Pokemans! You're a real Pokemans trainer!")
		3:
			say_bg("Three! Your party ball shelf is filling up!")
		DARK_AT:
			dark = true
			Audio.play_music("poke_dark", 2.0)
			await say("The grass is getting taller. Something is moving in it. Keep walking.", Narrator.DARK)
		5:
			say_bg("This route never ends. You've walked past that sign a hundred times.", Narrator.DARK)
		CATCH_ALL:
			say_bg("Six. The grass is taller than you now. Something is waiting in it.", Narrator.DARK)


func _run_away() -> void:
	_clear_menu()
	locked = true
	if foe.kind == "chumbmon":
		await _msg("Can't escape!")
		await _msg("It knows where you live.", 1.2)
		_main_menu()
		locked = false
		return
	Audio.sfx("run")
	await _msg("Got away safely!")
	mode = "walk"
	msg = ""
	locked = false


func _chumbmon_caught() -> void:
	await _msg("Gotcha! ??? was caught!", 1.0)
	Audio.sfx("glitch")
	var tw := create_tween()
	tw.tween_property(self, "invert", 1.0, 0.6)
	await _msg("...", 0.6)
	await _msg("??? caught YOU.", 1.6)
	await say("CHUMBMON. The Birthday Pokemans. It lives inside birthday cakes. It knows your name.", Narrator.DARK)
	var tw2 := create_tween()
	tw2.tween_property(self, "invert", 0.0, 1.0)
	await wait(1.0)
	mode = "end"
	msg = ""
	await say("Present number eight, done! You caught them all! Or did they catch you?")
	finish_game(IDX, "CAUGHT 'EM!")


# ---------------------------------------------------------------- drawing

func paint_back() -> void:
	_baked_key = "%s/%s" % [_overworld_mode(), dark]
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), GB0.lerp(GB2, 0.5 if dark else 0.0))
	if _overworld_mode():
		_overworld_back()
	else:
		# battle platforms
		Crayon.ellipse(pen, Vector2(940, 300), Vector2(200, 40), GB3, 4, GB1, 1)
		Crayon.ellipse(pen, Vector2(330, 520), Vector2(220, 46), GB3, 4, GB1, 2)


func paint() -> void:
	if _baked_key != "%s/%s" % [_overworld_mode(), dark]:
		refresh_back()
	if _overworld_mode():
		_overworld()
	else:
		_battle()
	if encounter_flash > 0.0:
		var bars := int((1.0 - encounter_flash) * 12)
		for k in bars:
			pen.draw_rect(Rect2(-2000, k * 60, W + 4000, 30), GB3)
	if invert > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(GB3, invert * 0.85))
		if invert > 0.5:
			Crayon.face(pen, Vector2(640, 330), 220, "wide", Vector2.ZERO, 999, Color(GB0, invert))


func paint_top() -> void:
	hud("CAUGHT: %d" % caught.size(), GB3 if not dark else GB0)
	if mode == "walk" and walks == 0:
		Crayon.text(pen, Vector2(640, 160), "TAP THE GRASS TO WALK!", 44, GB3, 1, 50, Crayon.title_font())


func _overworld_back() -> void:
	var grass := GB1.lerp(GB3, 0.45 if dark else 0.0)
	# a path, some trees and a sign
	Crayon.ellipse(pen, Vector2(640, 700), Vector2(260, 60), Color(0, 0, 0, 0), 0, GB0.lerp(GB1, 0.3), 5)
	for k in 6:
		var tp := Vector2(70 + k * 228, 150 + (k % 2) * 30)
		Crayon.circle(pen, tp, 42, GB3, 4, GB2.lerp(GB3, 0.3 if dark else 0.0), 6 + k)
		Crayon.rect(pen, Rect2(tp + Vector2(-8, 36), Vector2(16, 30)), GB3, 3, Crayon.BROWN, 12 + k)
	Crayon.rect(pen, Rect2(1100, 560, 110, 60), GB3, 4, Crayon.BROWN.lightened(0.3), 20)
	Crayon.text(pen, Vector2(1155, 590), "ROUTE 1", 22, GB3, 1, 21)
	for k in 70:
		var gp := _tuft(k)
		var h := 26.0 if not dark else 26.0 + fmod(k * 13.0, 40.0)
		for j in 3:
			Crayon.line(pen, gp + Vector2(j * 9 - 9, 0), gp + Vector2(j * 9 - 9 + (j - 1) * 3, -h), grass, 4, 10 + k * 3 + j, 0.4)


func _tuft(k: int) -> Vector2:
	return Vector2(60 + (Crayon.rnd(k * 31) * 0.5 + 0.5) * (W - 120), 240 + (Crayon.rnd(k * 57 + 9) * 0.5 + 0.5) * 420)


func _overworld() -> void:
	if dark:
		for k in range(0, 70, 9):
			var gp := _tuft(k)
			var h := 26.0 + fmod(k * 13.0, 40.0)
			if fmod(t + k, 5.0) > 4.4:
				Crayon.disc(pen, gp + Vector2(-6, -h * 0.6), 4, Color(1, 0.95, 0.4))
				Crayon.disc(pen, gp + Vector2(6, -h * 0.6), 4, Color(1, 0.95, 0.4))
	# trainer
	var p := me
	var bob := absf(sin(t * 10.0)) * 4.0 if me.distance_to(me_target) > 4.0 else 0.0
	Crayon.person(pen, p + Vector2(0, 40 - bob), 90, GB3, "happy", Color(0, 0, 0, 0), "walk" if bob > 0 else "stand", t * 10.0, 30, GB0)
	Crayon.rect(pen, Rect2(p + Vector2(-16, -52 - bob), Vector2(32, 10)), GB3, 3, Crayon.RED, 31)
	# the party ball shelf
	for k in caught.size():
		_ball(Vector2(120 + k * 50, H - 40), 0.0)
	if gold_ball and not mew:
		_ball(Vector2(60, H - 40), 0.0, Crayon.YELLOW)
	for lf in leaves:
		Crayon.disc(pen, lf.p, 6, Color(GB2, clampf(1.6 - lf.t, 0.0, 1.0)))
	if mew:
		_mewffin_draw(me + (mew_pos - me).rotated(mew_a) if mew_a > 0.0 else mew_pos)


func _battle() -> void:
	# foe
	if not foe_gone:
		var fp := Vector2(940, 230) + Vector2(sin(foe_shake * 60.0) * 14.0 * foe_shake, 0)
		if foe_flash <= 0.0 or int(foe_flash * 20.0) % 2 == 0:
			_creature(String(foe.kind), fp, 1.0)
	# my partychu (from behind)
	_partychu(Vector2(330, 450))
	# info boxes
	_info(Rect2(90, 90, 420, 110), String(foe.name), foe_hp)
	_info(Rect2(770, 380, 420, 110), "PARTYCHU", my_hp)
	# ball
	if ball_t >= 0.0:
		var f := clampf(ball_t / 0.7, 0, 1)
		var bp := Vector2(330, 420).lerp(Vector2(940, 280), f) + Vector2(0, -sin(f * PI) * 220)
		var wob := 0.0
		if f >= 1.0 and shakes > 0:
			wob = sin(ball_t * 18.0) * 0.4
		_ball(bp, wob)
	# message box
	var box := Rect2(40, 540, 700 if menu != "" else 1200, 170)
	Crayon.rect(pen, box, GB3, 6, GB0, 40)
	Crayon.text_block(pen, Vector2(box.position.x + 30, box.position.y + 50), msg.substr(0, int(msg_shown)), 36, box.size.x - 60, GB3, 0, 41)


func _info(r: Rect2, name: String, hp: float) -> void:
	Crayon.rect(pen, r, GB3, 5, GB0, int(r.position.x))
	Crayon.text(pen, r.position + Vector2(24, 34), name, 32, GB3, 0, int(r.position.x) + 1, null, 0.4, false)
	Crayon.text(pen, r.position + Vector2(24, 80), "HP", 26, GB3, 0, int(r.position.x) + 2, null, 0.3, false)
	var bar := Rect2(r.position + Vector2(70, 68), Vector2(r.size.x - 100, 22))
	Crayon.rect(pen, bar, GB3, 3, GB1.lightened(0.3), int(r.position.x) + 3)
	var col := Color(0.3, 0.75, 0.3) if hp > 0.5 else (Crayon.YELLOW if hp > 0.2 else Crayon.RED)
	if name == "???":
		col = Color(0.15, 0.05, 0.15)
		hp = 1.0
	pen.draw_rect(Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * hp, bar.size.y - 6)), col)


func _ball(p: Vector2, wob: float, top: Color = Crayon.PINK) -> void:
	pen.draw_set_transform(p, wob, Vector2.ONE)
	Crayon.circle(pen, Vector2.ZERO, 22, GB3, 4, Crayon.WHITE, 60)
	pen.draw_rect(Rect2(-22, -22, 44, 20), top)
	Crayon.line(pen, Vector2(-22, 0), Vector2(22, 0), GB3, 4, 61)
	Crayon.circle(pen, Vector2.ZERO, 7, GB3, 3, Crayon.WHITE, 62)
	pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## MEWFFIN: a little pink cat that is also a birthday muffin. Floats. Sparkles. Very rare.
func _mewffin_draw(p: Vector2) -> void:
	p += Vector2(0, sin(t * 3.0) * 8.0)
	# long thin tail with a round tip
	Crayon.path(pen, PackedVector2Array([p + Vector2(22, 14), p + Vector2(54, 4), p + Vector2(62, -26), p + Vector2(48, -44)]), GB3, 4, 130)
	Crayon.circle(pen, p + Vector2(48, -48), 8, GB3, 3, Crayon.PINK.lightened(0.3), 131)
	# muffin cup
	Crayon.poly(pen, PackedVector2Array([p + Vector2(-26, 2), p + Vector2(26, 2), p + Vector2(18, 34), p + Vector2(-18, 34)]), GB3, 4, Crayon.SKY, 132)
	for k in 3:
		Crayon.line(pen, p + Vector2(-12 + k * 12, 6), p + Vector2(-10 + k * 10, 30), GB3, 2, 133 + k)
	# frosting head with cat ears
	Crayon.poly(pen, PackedVector2Array([p + Vector2(-26, -24), p + Vector2(-20, -50), p + Vector2(-6, -32)]), GB3, 3, Crayon.PINK.lightened(0.3), 136)
	Crayon.poly(pen, PackedVector2Array([p + Vector2(26, -24), p + Vector2(20, -50), p + Vector2(6, -32)]), GB3, 3, Crayon.PINK.lightened(0.3), 137)
	Crayon.ellipse(pen, p + Vector2(0, -12), Vector2(32, 24), GB3, 4, Crayon.PINK.lightened(0.3), 138)
	Crayon.face(pen, p + Vector2(0, -10), 18, "happy", Vector2.ZERO, 139)
	for k in 4:
		var a := t * 2.5 + k * TAU / 4.0
		Crayon.star(pen, p + Vector2(cos(a) * 52, sin(a) * 40 - 8), 7, GB3, Crayon.YELLOW, 140 + k)


func _partychu(p: Vector2) -> void:
	var y := Crayon.YELLOW
	Crayon.poly(pen, PackedVector2Array([p + Vector2(-40, -60), p + Vector2(-70, -150), p + Vector2(-20, -80)]), GB3, 4, y, 70)
	Crayon.poly(pen, PackedVector2Array([p + Vector2(40, -60), p + Vector2(70, -150), p + Vector2(20, -80)]), GB3, 4, y, 71)
	Crayon.poly(pen, PackedVector2Array([p + Vector2(-72, -145), p + Vector2(-62, -120), p + Vector2(-56, -135)]), GB3, 2, GB3, 72)
	Crayon.poly(pen, PackedVector2Array([p + Vector2(72, -145), p + Vector2(62, -120), p + Vector2(56, -135)]), GB3, 2, GB3, 73)
	Crayon.ellipse(pen, p + Vector2(0, -10), Vector2(80, 70), GB3, 5, y, 74)
	Crayon.path(pen, PackedVector2Array([p + Vector2(70, 10), p + Vector2(110, -20), p + Vector2(95, -40), p + Vector2(140, -80)]), Crayon.BROWN, 12, 75)
	Crayon.party_hat(pen, p + Vector2(0, -70), 26, Crayon.PINK, 76, -0.1)


func _creature(kind: String, p: Vector2, s: float) -> void:
	match kind:
		"balloon":
			Crayon.ellipse(pen, p + Vector2(0, 20), Vector2(70, 45), GB3, 4, Color(0.45, 0.75, 0.55), 80)
			Crayon.balloon(pen, p + Vector2(0, -60), 40, Crayon.RED, 20, 81)
			Crayon.face(pen, p + Vector2(-30, 20), 30, "happy", Vector2(-1, 0), 82)
		"frostle":
			Crayon.circle(pen, p + Vector2(-50, 10), 26, GB3, 4, Crayon.SKY, 83)
			Crayon.ellipse(pen, p + Vector2(10, 10), Vector2(65, 45), GB3, 4, Crayon.WHITE, 84)
			for k in 3:
				Crayon.circle(pen, p + Vector2(10, 0) + Vector2(cos(k * 2.1), sin(k * 2.1)) * 18, 16, Crayon.PINK, 3, Color(0, 0, 0, 0), 85 + k)
			Crayon.face(pen, p + Vector2(-50, 10), 22, "happy", Vector2(-1, 0), 88)
		"cakemander":
			Crayon.ellipse(pen, p + Vector2(0, 20), Vector2(50, 55), GB3, 4, Crayon.ORANGE, 89)
			Crayon.circle(pen, p + Vector2(-10, -50), 32, GB3, 4, Crayon.ORANGE, 90)
			Crayon.line(pen, p + Vector2(40, 40), p + Vector2(80, 0), GB3, 8, 91)
			Crayon.flame(pen, p + Vector2(84, -14), 16, 92)
			Crayon.face(pen, p + Vector2(-14, -50), 26, "happy", Vector2(-1, 0), 93)
		"puff":
			for k in 7:
				Crayon.circle(pen, p + Vector2(cos(k * 0.9) * 40, sin(k * 0.9) * 30), 30, GB3, 3, Crayon.PINK.lightened(0.3), 94 + k)
			Crayon.rect(pen, Rect2(p + Vector2(-6, -90), Vector2(12, 40)), GB3, 3, Crayon.BLUE, 101)
			Crayon.flame(pen, p + Vector2(0, -100), 12, 102)
			Crayon.face(pen, p, 34, "happy", Vector2(-1, 0), 103)
		"presentoad":
			Crayon.rect(pen, Rect2(p + Vector2(-60, -20), Vector2(120, 80)), GB3, 4, Crayon.GREEN, 107)
			Crayon.line(pen, p + Vector2(0, -20), p + Vector2(0, 60), Crayon.YELLOW, 10, 108)
			Crayon.circle(pen, p + Vector2(-26, -40), 20, GB3, 4, Crayon.GREEN.lightened(0.2), 109)
			Crayon.circle(pen, p + Vector2(26, -40), 20, GB3, 4, Crayon.GREEN.lightened(0.2), 110)
			Crayon.disc(pen, p + Vector2(-26, -40), 8, GB3)
			Crayon.disc(pen, p + Vector2(26, -40), 8, GB3)
			Crayon.line(pen, p + Vector2(-34, 6), p + Vector2(34, 6), GB3, 4, 111)
			Crayon.ellipse(pen, p + Vector2(-20, -66), Vector2(18, 10), GB3, 3, Crayon.YELLOW, 112)
			Crayon.ellipse(pen, p + Vector2(20, -66), Vector2(18, 10), GB3, 3, Crayon.YELLOW, 113)
		"pinyatta":
			for k in 4:
				Crayon.line(pen, p + Vector2(-44 + k * 26, 30), p + Vector2(-44 + k * 26, 76), GB3, 8, 114 + k)
			Crayon.rect(pen, Rect2(p + Vector2(-64, -20), Vector2(120, 56)), GB3, 4, Crayon.PINK, 118)
			for k in 4:
				pen.draw_rect(Rect2(p + Vector2(-54 + k * 28, -14), Vector2(12, 44)), Crayon.RAINBOW[(k * 2) % 7])
			Crayon.rect(pen, Rect2(p + Vector2(-90, -84), Vector2(34, 70)), GB3, 4, Crayon.YELLOW, 119)
			Crayon.rect(pen, Rect2(p + Vector2(-120, -100), Vector2(64, 34)), GB3, 4, Crayon.YELLOW, 120)
			Crayon.face(pen, p + Vector2(-92, -84), 20, "happy", Vector2(-1, 0), 121)
			Crayon.line(pen, p + Vector2(-70, -100), p + Vector2(-66, -124), GB3, 5, 122)
		"chumbmon":
			var pts := PackedVector2Array()
			for k in 30:
				var a := TAU * k / 30.0
				var r := 85.0 + sin(a * 7.0 + t * 4.0) * 10.0 + Crayon.rnd(Crayon.boil() + k) * 8.0
				pts.append(p + Vector2(cos(a) * r, sin(a) * r * 0.9))
			Crayon.poly(pen, pts, GB3, 5, Color(0.1, 0.03, 0.12), 104)
			Crayon.face(pen, p + Vector2(0, 10), 70, "wide", Vector2(-1, 0.2), 105, Color(0.95, 0.95, 0.9))
			for k in 4:
				var e := p + Vector2(-50 + k * 33, -50 - (k % 2) * 14)
				Crayon.disc(pen, e, 8, Color(0.95, 0.95, 0.9))
				Crayon.disc(pen, e + Vector2(-2, 1), 4, Crayon.BLACK)
			Crayon.party_hat(pen, p + Vector2(10, -80), 26, Crayon.BLACK, 106, 0.3)
