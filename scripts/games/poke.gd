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
]

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
	if mode == "walk":
		var d := me_target - me
		if d.length() > 0.5:
			me += d.normalized() * minf(d.length(), 260.0 * dt)
			if me.distance_to(me_target) <= 0.5:
				_arrived()


func _arrived() -> void:
	walks += 1
	if walks % 2 == 0 or walks >= 3 and randf() < 0.7:
		_encounter()


func _encounter() -> void:
	mode = "trans"
	locked = true
	encounter_flash = 1.0
	Audio.sfx("glitch" if caught.size() >= 3 else "run", -4)
	await wait(1.0)
	if caught.size() >= 3:
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
	await _msg("Wild %s used %s!" % [foe.name, attacks[randi() % attacks.size()]], 0.3)
	Audio.sfx("boing", -6)
	my_hp = maxf(0.3, my_hp - 0.1)
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
			dark = true
			Audio.play_music("poke_dark", 2.0)
			await say("The grass is getting taller. Something is moving in it. Keep walking.", Narrator.DARK)


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
				pen.draw_circle(gp + Vector2(-6, -h * 0.6), 4, Color(1, 0.95, 0.4))
				pen.draw_circle(gp + Vector2(6, -h * 0.6), 4, Color(1, 0.95, 0.4))
	# trainer
	var p := me
	var bob := absf(sin(t * 10.0)) * 4.0 if me.distance_to(me_target) > 4.0 else 0.0
	Crayon.person(pen, p + Vector2(0, 40 - bob), 90, GB3, "happy", Color(0, 0, 0, 0), "walk" if bob > 0 else "stand", t * 10.0, 30, GB0)
	Crayon.rect(pen, Rect2(p + Vector2(-16, -52 - bob), Vector2(32, 10)), GB3, 3, Crayon.RED, 31)
	# the party ball shelf
	for k in caught.size():
		_ball(Vector2(120 + k * 50, H - 40), 0.0)


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


func _ball(p: Vector2, wob: float) -> void:
	pen.draw_set_transform(p, wob, Vector2.ONE)
	Crayon.circle(pen, Vector2.ZERO, 22, GB3, 4, Crayon.WHITE, 60)
	pen.draw_rect(Rect2(-22, -22, 44, 20), Crayon.PINK)
	Crayon.line(pen, Vector2(-22, 0), Vector2(22, 0), GB3, 4, 61)
	Crayon.circle(pen, Vector2.ZERO, 7, GB3, 3, Crayon.WHITE, 62)
	pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


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
				pen.draw_circle(e, 8, Color(0.95, 0.95, 0.9))
				pen.draw_circle(e + Vector2(-2, 1), 4, Crayon.BLACK)
			Crayon.party_hat(pen, p + Vector2(10, -80), 26, Crayon.BLACK, 106, 0.3)
