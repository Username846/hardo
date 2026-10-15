extends Screen
## Present 5: CLAW MACHINE (arcade claw sim). Tap a toy and the claw goes to get it.
## The toys like you. They would very much like to come home with you.

const IDX := 4
const GLASS := Rect2(330, 110, 620, 420)
const RAIL_Y := 135.0
const PILE_Y := 480.0
const CHUTE_X := 880.0
const HOME_X := 400.0

var prizes: Array = []
var won: Array = []
var coins := 6
var tries := 0
var claw_x := HOME_X
var claw_y := RAIL_Y + 40
var claw_open := 1.0
var state := "idle"
var target_x := HOME_X
var held: Array = []
var fog := 0.0
var handprint := 0.0
var hi_text := 0.0
var armed := false
var last_won := 0
var dark := false


var _baked_key := ""


func enter() -> void:
	use_back_layer()
	Audio.play_music("claw")
	var kinds := ["teddy", "duck", "star", "bunny", "dino", "teddy", "duck", "chumbo"]
	var cols := [Crayon.BROWN, Crayon.YELLOW, Crayon.YELLOW, Crayon.WHITE, Crayon.GREEN, Color(0.95, 0.6, 0.7), Color(0.5, 0.8, 1.0), Color(1, 0.88, 0.75)]
	for k in kinds.size():
		prizes.append({"kind": kinds[k], "col": cols[k], "x": 380.0 + k * 58.0 + randf_range(-8, 8), "y": PILE_Y - (k % 2) * 26.0, "seed": 300 + k * 13, "rot": randf_range(-0.3, 0.3)})
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await say("Present number five! A claw machine! Tap a toy, and the claw will try to grab it. You have six coins.")
	armed = true
	locked = false


func press(p: Vector2) -> void:
	if not armed or state != "idle" or coins <= 0:
		return
	if not GLASS.has_point(p):
		return
	coins -= 1
	tries += 1
	Audio.sfx("coin")
	target_x = clampf(p.x, GLASS.position.x + 40, CHUTE_X - 70)
	# from the 4th try on, the little Chumbo doll crawls under the claw
	if tries == 4:
		for pr in prizes:
			if pr.kind == "chumbo":
				pr.x = target_x
	last_won = 0
	state = "move"


func _nearest(x: float) -> Dictionary:
	var best := {}
	var bd := 9999.0
	for pr in prizes:
		var d := absf(float(pr.x) - x)
		if d < bd:
			bd = d
			best = pr
	return best


func tick(dt: float) -> void:
	match state:
		"move":
			if Engine.get_process_frames() % 20 == 0:
				Audio.sfx("motor", -14)
			var d := target_x - claw_x
			claw_x += signf(d) * minf(absf(d), 320.0 * dt)
			if dark:
				_shuffle(dt)
			if absf(d) < 1.0:
				state = "down"
		"down":
			claw_y += 300.0 * dt
			if claw_y >= PILE_Y - 60:
				claw_y = PILE_Y - 60
				state = "close"
				_grab()
		"close":
			claw_open = maxf(0.0, claw_open - dt * 3.0)
			if claw_open <= 0.0:
				state = "up"
		"up":
			claw_y -= 240.0 * dt
			_carry()
			if claw_y <= RAIL_Y + 40:
				claw_y = RAIL_Y + 40
				state = "to_chute" if held.size() > 0 else "home"
				if held.is_empty():
					Audio.sfx("music_wrong", -8)
					say_bg("So close! Try again!" if not dark else "They slipped away. They want you to try again.", Narrator.CUTE if not dark else Narrator.DARK)
		"to_chute":
			claw_x = move_toward(claw_x, CHUTE_X, 320.0 * dt)
			_carry()
			if absf(claw_x - CHUTE_X) < 1.0:
				state = "drop"
				_drop_prizes()
		"home":
			claw_open = minf(1.0, claw_open + dt * 3.0)
			claw_x = move_toward(claw_x, HOME_X, 320.0 * dt)
			if absf(claw_x - HOME_X) < 1.0 and claw_open >= 1.0:
				state = "idle"
				_after_try()


func _shuffle(dt: float) -> void:
	# when you're watching the claw, the toys quietly rearrange themselves
	for pr in prizes:
		if pr.kind != "chumbo":
			pr.x = float(pr.x) + sin(t * 3.0 + pr.seed) * 20.0 * dt


func _grab() -> void:
	Audio.sfx("clank")
	held.clear()
	if tries >= 5:
		# everything clings to the claw
		for pr in prizes:
			held.append(pr)
		return
	var pr := _nearest(claw_x)
	if pr.is_empty():
		return
	var chance := 0.9 if tries != 3 else 0.0
	if tries == 4 and pr.kind == "chumbo":
		chance = 1.0
	if absf(float(pr.x) - claw_x) < 42.0 and randf() < chance:
		held.append(pr)


func _carry() -> void:
	for k in held.size():
		var pr: Dictionary = held[k]
		pr.x = claw_x + (k - held.size() * 0.5) * 18.0
		pr.y = claw_y + 70 + k * 6


func _drop_prizes() -> void:
	claw_open = 1.0
	Audio.sfx("thud")
	for pr in held:
		prizes.erase(pr)
		won.append(pr)
	var n := held.size()
	last_won = n
	held.clear()
	await wait(0.3)
	if n > 0:
		Audio.sfx("tada", -4)
	state = "home"


func _after_try() -> void:
	locked = true
	match tries:
		1:
			if last_won > 0:
				await say("You won a prize! Yay!")
		2:
			if last_won > 0:
				await say("Another one! You're a claw machine champion!")
		3:
			dark = true
			Audio.play_music("claw_dark", 2.0)
			await say("Did the toys just move? They're looking at the claw. They're looking at you.", Narrator.DARK)
		4:
			await say("You won... a little Chumbo? It looks just like you. It's smiling.", Narrator.DARK)
		5:
			await say("They all want to come home with you.", Narrator.DARK)
			await _ending()
			return
	locked = false
	if coins <= 0 and tries < 5:
		coins = 1


func _ending() -> void:
	var tw := create_tween()
	tw.tween_property(self, "fog", 1.0, 2.0)
	Audio.sfx("wind", -6)
	await wait(2.0)
	Audio.sfx("thud", -2, 0.7)
	handprint = 1.0
	await wait(1.0)
	Audio.sfx("scribble", -4)
	var tw2 := create_tween()
	tw2.tween_property(self, "hi_text", 1.0, 1.2)
	await wait(1.5)
	await say("They'll ride home with you. Don't check the back seat.", Narrator.DARK)
	await say("Present number five, done! You won everything!")
	finish_game(IDX, "YOU WON!")


func _name(kind: String) -> String:
	return {"teddy": "teddy bear", "duck": "ducky", "star": "star", "bunny": "bunny", "dino": "dino", "chumbo": "Chumbo"}.get(kind, "toy")


func paint_back() -> void:
	_baked_key = "%s/%d" % [dark, won.size()]
	var col := Color(0.25, 0.15, 0.35).lerp(Color(0.08, 0.04, 0.1), 1.0 if dark else 0.0)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), col)
	# cabinet
	var cab := Rect2(290, 70, 700, 640)
	Crayon.rect(pen, cab, Crayon.INK, 7, Crayon.RED.lerp(Color(0.3, 0.05, 0.1), 0.6 if dark else 0.0), 20)
	Crayon.text(pen, Vector2(640, 92), "MEGA CLAW", 34, Crayon.YELLOW, 1, 21, Crayon.title_font())
	Crayon.rect(pen, GLASS, Crayon.INK, 6, Color(0.75, 0.9, 1.0).lerp(Color(0.2, 0.25, 0.3), 0.6 if dark else 0.0), 22)
	# chute
	Crayon.rect(pen, Rect2(CHUTE_X - 50, 430, 100, 100), Crayon.INK, 5, Color(0.1, 0.1, 0.12), 23)
	# rail
	Crayon.line(pen, Vector2(GLASS.position.x + 10, RAIL_Y), Vector2(GLASS.end.x - 10, RAIL_Y), Crayon.GREY, 8, 24)
	# the shelf of toys you won
	Crayon.text(pen, Vector2(640, 566), "YOUR PRIZES:", 30, Crayon.YELLOW, 1, 50)
	for k in won.size():
		var pr: Dictionary = won[k]
		var copy := pr.duplicate()
		copy.x = 380.0 + k * 62.0
		copy.y = 636.0
		_prize(copy)


func paint() -> void:
	if _baked_key != "%s/%d" % [dark, won.size()]:
		refresh_back()
	# arcade lights (blinking)
	for k in 14:
		var lp := Vector2(80 + k * 90, 40)
		var on := int(t * 4.0 + k) % 3 == 0
		pen.draw_circle(lp, 11, Crayon.INK)
		pen.draw_circle(lp, 8, Crayon.RAINBOW[k % 7] if on else Crayon.GREY)
	# prizes
	for pr in prizes:
		if not held.has(pr):
			_prize(pr)
	_claw()
	for pr in held:
		_prize(pr)
	# fog + handprint + HI (on the inside of the glass)
	if fog > 0.0:
		pen.draw_rect(GLASS.grow(-4), Color(0.92, 0.94, 0.96, fog * 0.85))
		if handprint > 0.0:
			var h := Vector2(560, 300)
			var hc := Color(0.55, 0.6, 0.65, 0.9)
			Crayon.ellipse(pen, h, Vector2(45, 55), Color(0, 0, 0, 0), 0, hc, 30)
			for k in 5:
				var a := -2.5 + k * 0.42
				Crayon.line(pen, h + Vector2(cos(a), sin(a)) * 40, h + Vector2(cos(a), sin(a)) * (85 if k > 0 else 65), hc, 18, 31 + k)
		if hi_text > 0.0:
			Crayon.text(pen, Vector2(770, 260), "HI"  if hi_text > 0.5 else "H", 110, Color(0.5, 0.55, 0.6, 0.9), 1, 40, Crayon.title_font())


func paint_top() -> void:
	hud("COINS: %d" % coins, Crayon.YELLOW)
	if armed and state == "idle" and tries == 0:
		Crayon.text(pen, Vector2(640, 300), "TAP A TOY!", 56, Crayon.RED, 1, 60, Crayon.title_font())


func _claw() -> void:
	var top := Vector2(claw_x, RAIL_Y)
	var c := Vector2(claw_x, claw_y)
	Crayon.rect(pen, Rect2(top - Vector2(24, 12), Vector2(48, 24)), Crayon.INK, 4, Crayon.GREY, 70)
	Crayon.line(pen, top, c, Crayon.INK, 4, 71)
	Crayon.circle(pen, c, 16, Crayon.INK, 4, Crayon.GREY, 72)
	var spread := 20.0 + claw_open * 22.0
	for sx in [-1.0, 1.0]:
		var mid := c + Vector2(sx * spread, 30)
		var tip := c + Vector2(sx * (spread - 14), 62)
		Crayon.line(pen, c, mid, Crayon.INK, 7, 73 + int(sx))
		Crayon.line(pen, mid, tip, Crayon.INK, 7, 76 + int(sx))


func _prize(pr: Dictionary) -> void:
	var p := Vector2(pr.x, pr.y)
	var sd: int = pr.seed
	var col: Color = pr.col
	var look := Vector2.ZERO
	var mood := "happy"
	if dark:
		look = (Vector2(claw_x, claw_y) - p).normalized()
		mood = "wide" if tries >= 4 else "flat"
	match String(pr.kind):
		"teddy":
			Crayon.circle(pen, p, 26, Crayon.INK, 3, col, sd)
			Crayon.circle(pen, p + Vector2(0, -36), 20, Crayon.INK, 3, col, sd + 1)
			Crayon.circle(pen, p + Vector2(-15, -52), 7, Crayon.INK, 2, col, sd + 2)
			Crayon.circle(pen, p + Vector2(15, -52), 7, Crayon.INK, 2, col, sd + 3)
			Crayon.face(pen, p + Vector2(0, -36), 16, mood, look, sd + 4)
		"duck":
			Crayon.ellipse(pen, p, Vector2(30, 22), Crayon.INK, 3, col, sd)
			Crayon.circle(pen, p + Vector2(14, -26), 16, Crayon.INK, 3, col, sd + 1)
			Crayon.poly(pen, PackedVector2Array([p + Vector2(28, -28), p + Vector2(44, -22), p + Vector2(28, -18)]), Crayon.INK, 2, Crayon.ORANGE, sd + 2)
			Crayon.face(pen, p + Vector2(12, -28), 12, mood, look, sd + 3)
		"star":
			Crayon.star(pen, p + Vector2(0, -14), 34, Crayon.INK, col, sd)
			Crayon.face(pen, p + Vector2(0, -12), 14, mood, look, sd + 1)
		"bunny":
			Crayon.ellipse(pen, p + Vector2(-9, -60), Vector2(7, 22), Crayon.INK, 3, col, sd + 1)
			Crayon.ellipse(pen, p + Vector2(9, -60), Vector2(7, 22), Crayon.INK, 3, col, sd + 2)
			Crayon.circle(pen, p, 24, Crayon.INK, 3, col, sd)
			Crayon.circle(pen, p + Vector2(0, -32), 18, Crayon.INK, 3, col, sd + 3)
			Crayon.face(pen, p + Vector2(0, -32), 15, mood, look, sd + 4)
		"dino":
			Crayon.ellipse(pen, p, Vector2(32, 22), Crayon.INK, 3, col, sd)
			for k in 3:
				Crayon.poly(pen, PackedVector2Array([p + Vector2(-20 + k * 14, -18), p + Vector2(-13 + k * 14, -32), p + Vector2(-6 + k * 14, -18)]), Crayon.INK, 2, Crayon.ORANGE, sd + 1 + k)
			Crayon.circle(pen, p + Vector2(28, -20), 15, Crayon.INK, 3, col, sd + 5)
			Crayon.face(pen, p + Vector2(28, -20), 12, mood, look, sd + 6)
		"chumbo":
			Crayon.ellipse(pen, p + Vector2(0, -4), Vector2(16, 24), Crayon.INK, 3, Crayon.GREEN, sd)
			Crayon.circle(pen, p + Vector2(0, -42), 18, Crayon.INK, 3, col, sd + 1)
			Crayon.face(pen, p + Vector2(0, -42), 15, "wide" if dark else "happy", look, sd + 2)
			Crayon.party_hat(pen, p + Vector2(0, -58), 12, Crayon.GREEN, sd + 3)
