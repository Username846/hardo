extends Screen
## Present 7: ROBLOCKS - BIRTHDAY OBBY (obstacle course auto-runner). Tap to jump, tap again
## to double jump. The other players leave one by one. Someone else with your name joins.

const IDX := 6
const RUN := 270.0
const JUMP := 760.0
const GRAV := 2100.0
const SCREEN_X := 330.0
const STAGES := ["STAGE 1: BIRTHDAY HILLS", "STAGE 2: CAKE CLIMB", "STAGE 3: LIGHTS OUT", "STAGE 4: THE VOID"]
const RUNNERS := [["xX_CakeLover_Xx", Color(1.0, 0.5, 0.7)], ["guest_1337", Color(0.6, 0.6, 0.65)], ["builderman_jr", Color(1.0, 0.6, 0.2)]]

var plats: Array = []       # Rect2
var lava: Array = []        # Rect2
var flags: Array = []       # Vector2 (checkpoint positions, feet)
var stage_x: Array = []     # start x of each stage
var chat_at: Array = []     # [x, text, action]
var chat: Array = []
var pad := Rect2()
var other_pos := Vector2.ZERO
var pos := Vector2(100, 560)
var vy := 0.0
var grounded := true
var jumps := 0
var cp := 0
var deaths := 0
var deaths_here := 0
var dead_t := 0.0
var running := false
var stage := 0
var banner_t := 0.0
var mercy_until := -1.0
var runners_on := [true, true, true]
var ended := false
var badge := 0.0
var cam := 0.0


var _baked_stage := -1


func enter() -> void:
	Narrator.top = true
	use_back_layer()
	Audio.play_music("obby")
	_build_level()
	pos = flags[0]
	cam = pos.x - SCREEN_X
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await say("Present number seven! Welcome to ROBLOCKS! Beat the Birthday Obby! Tap to jump. Tap again in the air to double jump!")
	running = true
	banner_t = 2.5
	locked = false


func _build_level() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	var x := 0.0
	var y := 560.0
	for s in 4:
		stage_x.append(x)
		# long start platform with a checkpoint flag
		plats.append(Rect2(x, y, 560, 60))
		flags.append(Vector2(x + 80, y))
		x += 560 + 120
		var segs: int = [6, 7, 7, 6][s]
		for i in segs:
			var ny := clampf(y + rng.randf_range(-90, 80), 380, 600)
			var plen := rng.randf_range(240, 460) if s < 3 else rng.randf_range(160, 300)
			plats.append(Rect2(x, ny, plen, 60 if s < 3 else 36))
			if s >= 1 and rng.randf() < 0.55 and plen > 260:
				lava.append(Rect2(x + plen * 0.5 - 35, ny - 22, 70, 22))
			if s == 3 and i % 2 == 1:
				lava.append(Rect2(x + plen - 60, ny - 22, 50, 22))
			y = ny
			x += plen + rng.randf_range(100, 165) + s * 6
	# the end: the other Chumbo waits on a platform before the badge pad
	plats.append(Rect2(x, 520, 420, 60))
	other_pos = Vector2(x + 300, 520)
	x += 420 + 130
	pad = Rect2(x, 520, 300, 60)
	plats.append(pad)
	chat_at = [
		[200, "xX_CakeLover_Xx: happy bday chumbo!!", ""], [700, "guest_1337: gg", ""],
		[1500, "builderman_jr: nice obby lol", ""], [2200, "xX_CakeLover_Xx: race u to the end", ""],
		[stage_x[1] + 300, "guest_1337: the lava is cake flavored", ""], [stage_x[1] + 1400, "builderman_jr: wait for me", ""],
		[stage_x[2] + 200, "[guest_1337 left the game]", "leave1"], [stage_x[2] + 900, "[builderman_jr left the game]", "leave2"],
		[stage_x[2] + 1500, "xX_CakeLover_Xx: chumbo its getting dark", ""], [stage_x[2] + 2100, "[xX_CakeLover_Xx left the game]", "leave0"],
		[stage_x[3] - 200, "[chumbo joined the game]", ""], [stage_x[3] + 400, "chumbo: hi", ""],
		[stage_x[3] + 1200, "chumbo: you took my name", ""], [stage_x[3] + 1900, "chumbo: its my birthday too", ""],
		[other_pos.x - 600, "chumbo: wait for me at the end", ""],
	]


func press(_p: Vector2) -> void:
	if not running or dead_t > 0.0 or ended:
		return
	if grounded or jumps < 2:
		vy = -JUMP * (1.0 if grounded else 0.85)
		jumps += 1
		grounded = false
		Audio.sfx("jump", -4, 1.0 + jumps * 0.1)


func _die() -> void:
	if dead_t > 0.0:
		return
	dead_t = 0.8
	deaths += 1
	deaths_here += 1
	Audio.sfx("oof")
	if deaths == 1:
		say_bg("Oof! Don't worry, you go back to the last flag.")
	if deaths_here == 3:
		mercy_until = stage_x[cp + 1] if cp + 1 < stage_x.size() else pad.position.x
		say_bg("The obby feels sorry for you. Here's a bridge!")


func _respawn() -> void:
	pos = flags[cp]
	vy = 0.0
	grounded = true
	jumps = 0
	cam = pos.x - SCREEN_X


func tick(dt: float) -> void:
	banner_t = maxf(0.0, banner_t - dt)
	if ended:
		badge = minf(1.0, badge + dt * 2.0)
		return
	if not running:
		return
	if dead_t > 0.0:
		dead_t -= dt
		if dead_t <= 0.0:
			_respawn()
		return
	# horizontal movement (blocked by walls)
	var nx := pos.x + RUN * dt
	var blocked := false
	for r in plats:
		if nx + 15 > r.position.x and nx - 15 < r.end.x and pos.y > r.position.y + 10 and pos.y - 60 < r.end.y:
			if pos.x + 15 <= r.position.x + 2:
				blocked = true
	if not blocked:
		pos.x = nx
	# vertical
	var old_y := pos.y
	vy += GRAV * dt
	pos.y += vy * dt
	grounded = false
	var floors := plats.duplicate()
	if mercy_until > pos.x:
		floors.append(Rect2(flags[cp].x, 560, mercy_until - flags[cp].x, 40))
	for r in floors:
		if pos.x + 12 > r.position.x and pos.x - 12 < r.end.x and old_y <= r.position.y + 1 and pos.y >= r.position.y and vy >= 0:
			pos.y = r.position.y
			vy = 0.0
			grounded = true
			jumps = 0
	if mercy_until < pos.x:
		for r in lava:
			if Rect2(pos.x - 13, pos.y - 58, 26, 56).intersects(r):
				_die()
	if pos.y > 900:
		_die()
	# checkpoints / stages
	for i in range(cp + 1, flags.size()):
		if pos.x >= flags[i].x:
			cp = i
			deaths_here = 0
			stage = i
			banner_t = 2.5
			Audio.sfx("checkpoint")
			match i:
				2:
					Audio.play_music("obby_dark", 2.0)
					say_bg("Where did everybody go?", Narrator.DARK)
				3:
					say_bg("There's another player up ahead. It has your name.", Narrator.DARK)
	# chat
	while chat_at.size() > 0 and pos.x >= float(chat_at[0][0]):
		var c: Array = chat_at.pop_front()
		chat.append(c[1])
		if chat.size() > 5:
			chat.pop_front()
		Audio.sfx("blip", -10, 1.6)
		match String(c[2]):
			"leave0":
				runners_on[0] = false
			"leave1":
				runners_on[1] = false
			"leave2":
				runners_on[2] = false
	if pos.x > pad.position.x + 40 and grounded:
		_end()
	cam = pos.x - SCREEN_X


func _end() -> void:
	ended = true
	locked = true
	Audio.sfx("levelup")
	Audio.sfx("cheer", -6)
	await wait(1.6)
	await say("Only one Chumbo can leave the obby.", Narrator.DARK)
	await say("Just kidding! Probably.", Narrator.DARK)
	await say("Present number seven, done! You beat the obby!")
	finish_game(IDX, "OBBY BEATEN!")


func _ground_at(x: float) -> float:
	for r in plats:
		if x >= r.position.x and x <= r.end.x:
			return r.position.y
	return INF


const SKIES := [Color(0.55, 0.82, 1.0), Color(1.0, 0.68, 0.45), Color(0.18, 0.12, 0.28), Color(0.02, 0.02, 0.04)]


func paint_back() -> void:
	_baked_stage = stage
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), SKIES[stage])
	if stage < 2:
		Crayon.sun(pen, Vector2(1100, 110), 45, "happy", 2)


func paint() -> void:
	if stage != _baked_stage:
		refresh_back()
	bg = SKIES[stage]
	if stage == 3:
		for k in 40:
			Crayon.disc(pen, Vector2(fmod(k * 197.0 - cam * 0.1, W + 40), fmod(k * 113.0, H)), 2, Color(1, 1, 1, 0.5))
	# distant blocky hills (parallax)
	if stage < 3:
		for k in 8:
			var hx := fmod(k * 260.0 - cam * 0.3, W + 300) - 150
			Crayon.rect(pen, Rect2(hx, 380 - (k % 3) * 60, 200, 400), Crayon.INK.lerp(bg, 0.5), 3, bg.darkened(0.15), 10 + k)
	var off := Vector2(-cam, 0)
	var block_col: Color = [Color(0.35, 0.75, 0.35), Color(0.85, 0.6, 0.4), Color(0.35, 0.3, 0.45), Color(0.85, 0.85, 0.9)][stage]
	for r in plats:
		if r.end.x + off.x < -50 or r.position.x + off.x > W + 50:
			continue
		var col: Color = block_col
		if r == pad:
			col = Crayon.YELLOW
		Crayon.rect(pen, Rect2(r.position + off, r.size), Crayon.INK, 4, col, int(r.position.x) % 997)
		# studs on top like toy bricks
		var k := 0
		var sx: float = r.position.x + 20
		while sx < r.end.x - 10:
			pen.draw_rect(Rect2(Vector2(sx, r.position.y - 6) + off, Vector2(18, 6)), col.darkened(0.15))
			sx += 46
			k += 1
	if mercy_until > pos.x:
		Crayon.rect(pen, Rect2(Vector2(flags[cp].x, 560) + off, Vector2(mercy_until - flags[cp].x, 16)), Crayon.INK, 3, Color(1, 0.85, 0.3, 0.9), 900)
	for r in lava:
		if r.end.x + off.x < -50 or r.position.x + off.x > W + 50:
			continue
		var glow := 0.8 + sin(t * 6.0 + r.position.x) * 0.2
		Crayon.rect(pen, Rect2(r.position + off, r.size), Crayon.INK, 3, Color(1.0, 0.25 * glow, 0.1), int(r.position.x) % 991)
	for i in flags.size():
		var f: Vector2 = flags[i] + off
		Crayon.line(pen, f, f + Vector2(0, -90), Crayon.INK, 5, 50 + i)
		Crayon.poly(pen, PackedVector2Array([f + Vector2(0, -90), f + Vector2(44, -76), f + Vector2(0, -62)]), Crayon.INK, 3, Crayon.GREEN if i <= cp else Crayon.RED, 60 + i)
	# badge pad sign
	Crayon.text(pen, pad.get_center() + off + Vector2(0, -90), "BADGE!", 40, Crayon.YELLOW, 1, 70, Crayon.title_font())
	# the other Chumbo
	if stage >= 3:
		var facing := -1.0
		_noob(other_pos + off, Crayon.YELLOW, Color(0.2, 0.4, 0.9), Crayon.GREEN, 0.0, "wide", facing, 80)
		Crayon.text(pen, other_pos + off + Vector2(0, -100), "chumbo", 24, Crayon.WHITE, 1, 81, null, 0.5, false)
	# ghost runners
	for k in 3:
		if not runners_on[k] or stage >= 3:
			continue
		var rx: float = pos.x + [-160.0, 120.0, -60.0][k] + sin(t * 0.7 + k * 2.0) * 50.0
		var gy := _ground_at(rx)
		var ry := gy if gy != INF else pos.y
		ry -= absf(sin(t * 5.0 + k)) * 30.0
		var rc: Color = RUNNERS[k][1]
		_noob(Vector2(rx, ry) + off, Crayon.YELLOW.lerp(rc, 0.4), rc, rc.darkened(0.3), t * 10.0 + k, "happy", 1.0, 90 + k * 5, 0.75)
		Crayon.text(pen, Vector2(rx, ry - 96) + off, String(RUNNERS[k][0]), 18, Crayon.WHITE, 1, 91 + k, null, 0.4, false)
	# player
	if dead_t > 0.0:
		var f := 1.0 - dead_t / 0.8
		for k in 6:
			var a := TAU * k / 6.0
			Crayon.rect(pen, Rect2(pos + off + Vector2(cos(a), sin(a) - 1.0) * (30 + f * 80) - Vector2(10, 10), Vector2(20, 20)), Crayon.INK, 2, [Crayon.YELLOW, Crayon.BLUE, Crayon.GREEN][k % 3], 100 + k)
		Crayon.text(pen, pos + off + Vector2(0, -110), "OOF!", 46, Crayon.RED, 1, 110, Crayon.title_font())
	else:
		_noob(pos + off, Crayon.YELLOW, Color(0.2, 0.4, 0.9), Crayon.GREEN, t * 12.0 if grounded else 0.0, "happy", 1.0, 120)
		Crayon.text(pen, pos + off + Vector2(0, -100), "I'm Chumbo", 20, Crayon.WHITE, 1, 121, null, 0.5, false)


func paint_top() -> void:
	# chat box
	var r := Rect2(100, 14, 470, 36 + chat.size() * 28)
	pen.draw_rect(r, Color(0, 0, 0, 0.45))
	for k in chat.size():
		var line: String = chat[k]
		var col := Crayon.WHITE
		if line.begins_with("["):
			col = Color(1, 0.9, 0.4)
		elif line.begins_with("chumbo:"):
			col = Color(1, 0.4, 0.4)
		Crayon.text(pen, Vector2(114, 34 + k * 28), line, 20, col, 0, 200 + k, null, 0.3, false)
	hud("OOFS: %d" % deaths, Crayon.WHITE)
	if banner_t > 0.0 and running:
		Crayon.text(pen, Vector2(W * 0.5, 200), STAGES[stage], 52, Crayon.WHITE, 1, 210, Crayon.title_font())
	if running and pos.x < 400 and stage == 0:
		Crayon.text(pen, Vector2(W * 0.5, 280), "TAP TO JUMP!", 46, Crayon.YELLOW, 1, 211, Crayon.title_font())
	if ended:
		var b := Rect2(W * 0.5 - 300, 120 - (1.0 - badge) * 200, 600, 130)
		Crayon.rect(pen, b, Crayon.INK, 6, Crayon.YELLOW, 220)
		Crayon.text(pen, b.get_center() + Vector2(0, -26), "BADGE EARNED!", 40, Crayon.INK, 1, 221, Crayon.title_font())
		Crayon.text(pen, b.get_center() + Vector2(0, 26), "You Met The Other Chumbo", 30, Crayon.INK, 1, 222)


func _noob(feet: Vector2, head: Color, body: Color, legs: Color, run: float, mood: String, facing: float, sd: int, alpha: float = 1.0) -> void:
	var ink := Color(Crayon.INK, alpha)
	var sw := sin(run) * 8.0
	Crayon.rect(pen, Rect2(feet + Vector2(-13 + sw * 0.5, -26), Vector2(12, 26)), ink, 3, Color(legs, alpha), sd)
	Crayon.rect(pen, Rect2(feet + Vector2(1 - sw * 0.5, -26), Vector2(12, 26)), ink, 3, Color(legs, alpha), sd + 1)
	Crayon.rect(pen, Rect2(feet + Vector2(-15, -56), Vector2(30, 30)), ink, 3, Color(body, alpha), sd + 2)
	Crayon.rect(pen, Rect2(feet + Vector2(-26, -56 + sw * 0.3), Vector2(11, 26)), ink, 3, Color(head, alpha), sd + 3)
	Crayon.rect(pen, Rect2(feet + Vector2(15, -56 - sw * 0.3), Vector2(11, 26)), ink, 3, Color(head, alpha), sd + 4)
	Crayon.rect(pen, Rect2(feet + Vector2(-13, -82), Vector2(26, 26)), ink, 3, Color(head, alpha), sd + 5)
	Crayon.face(pen, feet + Vector2(facing * 2, -69), 12, mood, Vector2(facing, 0), sd + 6, ink)
