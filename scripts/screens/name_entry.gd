extends Screen
## "What's your name?" There is exactly one correct answer.

const ROWS := ["QWERTYUIOP", "ASDFGHJKL'", "ZXCVBNM"]
const KEY := Vector2(66, 60)
const GAP := 8.0
const MAX_LEN := 14

var typed := ""
var wrong := 0
var state := "typing"   # typing, punish, happy, forced
var pun_kind := 0
var pun_t := 0.0
var victim_name := ""
var hand_pos := Vector2(-200, -200)
var hand_target := Vector2(-200, -200)
var key_flash := {}
var celebrate_t := -1.0
var host_talk := false


func enter() -> void:
	show_home = false
	remove_button("home")
	Narrator.top = true
	use_back_layer()
	bake_buttons = true
	Audio.play_music("title")
	var y0 := 300.0
	for r in ROWS.size():
		var row: String = ROWS[r]
		var row_w := row.length() * (KEY.x + GAP) - GAP
		var x0 := W * 0.5 - row_w * 0.5 - (40.0 if r == 2 else 0.0)
		for i in row.length():
			var ch := row.substr(i, 1)
			add_button("k_" + ch, Rect2(Vector2(x0 + i * (KEY.x + GAP), y0 + r * (KEY.y + GAP)), KEY), ch, func(): _type(ch), Crayon.WHITE, 36)
		if r == 2:
			var bx := x0 + row.length() * (KEY.x + GAP)
			add_button("k_back", Rect2(Vector2(bx, y0 + r * (KEY.y + GAP)), Vector2(KEY.x * 2 + GAP, KEY.y)), "<- oops", _backspace, Crayon.PINK, 28)
	var y3 := y0 + 3 * (KEY.y + GAP)
	add_button("k_space", Rect2(Vector2(W * 0.5 - 370, y3), Vector2(440, KEY.y)), "space", func(): _type(" "), Crayon.WHITE, 30)
	add_button("k_ok", Rect2(Vector2(W * 0.5 + 90, y3), Vector2(280, KEY.y)), "THAT'S ME!", _submit, Crayon.GREEN, 34)
	_intro()


func _intro() -> void:
	locked = true
	host_talk = true
	await wait(0.4)
	await line("hi_there_welcome")
	host_talk = false
	locked = false


func _keys_visible(v: bool) -> void:
	for b in buttons:
		if String(b.id).begins_with("k_"):
			b.visible = v
	refresh_back()


func paint_back() -> void:
	if state == "punish":
		return
	Crayon.text(pen, Vector2(W * 0.5, 165), "MY NAME IS:", 40, Crayon.INK, 1, 11, Crayon.title_font())
	Crayon.rect(pen, Rect2(W * 0.5 - 330, 190, 660, 86), Crayon.INK, 6, Crayon.WHITE, 12)


func _type(ch: String) -> void:
	if state != "typing" or typed.length() >= MAX_LEN:
		return
	typed += ch
	Audio.sfx("key", -6, randf_range(0.9, 1.2))
	key_flash[ch] = 0.3


func _backspace() -> void:
	if state != "typing" or typed.is_empty():
		return
	typed = typed.substr(0, typed.length() - 1)
	Audio.sfx("key", -6, 0.8)


func _unhandled_input(e: InputEvent) -> void:
	super(e)
	if e is InputEventKey and e.pressed and state == "typing" and not locked:
		var k := e as InputEventKey
		if k.keycode == KEY_BACKSPACE:
			_backspace()
		elif k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
			_submit()
		elif k.unicode >= 32 and k.unicode < 0x10000:
			_type(String.chr(k.unicode))
		get_viewport().set_input_as_handled()


func _submit() -> void:
	if state != "typing":
		return
	if typed.strip_edges() == "":
		locked = true
		await line("you_have_to_type")
		locked = false
		return
	if Game.is_correct_name(typed):
		_success(false)
	else:
		_punish()


func _success(forced: bool) -> void:
	state = "happy"
	locked = true
	_keys_visible(false)
	celebrate_t = 0.0
	Audio.sfx("cheer")
	Audio.sfx("tada", -3)
	confetti_burst(Vector2(W * 0.5, 230), 80)
	Game.player_name = Game.CANON_NAME
	Game.save_game()
	host_talk = true
	if forced:
		await line("there_your_name_is")
	else:
		await line("i_knew_it_hi")
	host_talk = false
	await wait(0.3)
	Game.goto("hub" if Game.intro_done else "intro")


func _punish() -> void:
	wrong += 1
	victim_name = typed
	state = "punish"
	locked = true
	_keys_visible(false)
	pun_kind = wrong
	pun_t = 0.0
	Audio.sfx("wrong")
	await wait(3.2)
	host_talk = true
	match wrong:
		1:
			await line("wrong_thats_not_your")
		2:
			await line("nope_think_really")
		_:
			await line("okay_thats_enough")
	host_talk = false
	typed = ""
	if wrong >= 3:
		_force()
		return
	state = "typing"
	_keys_visible(true)
	locked = false


func _force() -> void:
	state = "forced"
	_keys_visible(true)
	var seq := ["I", "'", "M", " ", "C", "H", "U", "M", "B", "O"]
	hand_pos = Vector2(W + 100, H + 100)
	for ch in seq:
		var id: String = "k_space" if ch == " " else "k_" + ch
		var b := get_button(id)
		hand_target = b.rect.get_center() + Vector2(10, 18)
		await wait(0.32)
		b.pop = 1.0
		typed += ch
		key_flash[ch] = 0.3
		Audio.sfx("key", -3, 0.9)
	hand_target = get_button("k_ok").rect.get_center() + Vector2(10, 18)
	await wait(0.5)
	get_button("k_ok").pop = 1.0
	Audio.sfx("stamp")
	await wait(0.4)
	hand_target = Vector2(W + 200, H + 200)
	_success(true)


func tick(dt: float) -> void:
	pun_t += dt
	hand_pos = hand_pos.lerp(hand_target, minf(1.0, dt * 9.0))
	for k in key_flash.keys():
		key_flash[k] -= dt
		if key_flash[k] <= 0:
			key_flash.erase(k)
	if state == "punish":
		_pun_sfx(dt)


var _fired := {}


func _once(key: String, at: float) -> bool:
	if pun_t >= at and not _fired.has(str(pun_kind) + key):
		_fired[str(pun_kind) + key] = true
		return true
	return false


func _pun_sfx(_dt: float) -> void:
	match pun_kind:
		1:
			if _once("boing", 0.6):
				Audio.sfx("boing")
			if _once("bonk", 0.78):
				Audio.sfx("bonk")
				Audio.sfx("ow", -2)
			if _once("thud", 1.6):
				Audio.sfx("thud")
		2:
			if _once("whistle", 0.05):
				Audio.sfx("slide_down")
			if _once("splat", 0.9):
				Audio.sfx("splat")
				Audio.sfx("thud", -4)
			if _once("boing", 2.3):
				Audio.sfx("boing", -4)
		_:
			if _once("hole", 0.1):
				Audio.sfx("whoosh")
			if _once("fall", 0.55):
				Audio.sfx("slide_down")
			if _once("far", 1.6):
				Audio.sfx("thud", -14)
			if _once("drop", 2.15):
				Audio.sfx("slide_down", -6, 1.4)
			if _once("land", 2.6):
				Audio.sfx("thud")
				Audio.sfx("ow")


# ------------------------------------------------------------------ drawing


func paint() -> void:
	var creep := 0.0
	if state == "punish" and pun_kind >= 3:
		creep = 0.25
	Host.draw(pen, Vector2(150, 360), 78, creep, host_talk or Narrator.is_active(), (mouse - Vector2(150, 360)).normalized(), 3)
	if state == "punish":
		_paint_punish()
		return
	# name field (the box itself is in the static layer)
	var field := Rect2(W * 0.5 - 330, 190, 660, 86)
	var shown := typed
	var tw := Crayon.text(pen, Vector2(field.position.x + 24, field.get_center().y), shown, 54, Crayon.BLUE.darkened(0.2), 0, 13, null, 1.0, false)
	if state == "typing" and fmod(t, 1.0) < 0.55:
		var cx := field.position.x + 30 + tw
		Crayon.line(pen, Vector2(cx, field.position.y + 16), Vector2(cx, field.end.y - 16), Crayon.INK, 4, 14, 0.3)
	# keyboard flash
	for b in buttons:
		var id: String = b.id
		if id.begins_with("k_") and b.visible:
			var ch := " " if id == "k_space" else id.substr(2)
			if key_flash.has(ch):
				pen.draw_rect(b.rect.grow(-4), Color(1, 0.9, 0.2, 0.5))
	# the player, waving with a question mark
	if state != "punish":
		var mood := "happy" if state != "happy" else "o"
		Crayon.person(pen, Vector2(1140, 520), 170, Crayon.INK, mood, Crayon.GREEN, "up" if state == "happy" else "wave", t * 2.0, 21)
		if state == "typing":
			Crayon.text(pen, Vector2(1200, 300 + sin(t * 3) * 5), "?", 70, Crayon.PURPLE, 1, 22, Crayon.title_font())
		elif state == "happy":
			Crayon.text(pen, Vector2(1140, 300), "CHUMBO!", 44, Crayon.RED, 1, 23, Crayon.title_font())
	if state == "forced":
		_draw_hand(hand_pos)


func _draw_hand(p: Vector2) -> void:
	var skin := Color(1, 0.85, 0.7)
	Crayon.poly(pen, PackedVector2Array([p, p + Vector2(-14, 40), p + Vector2(40, 120), p + Vector2(110, 110), p + Vector2(70, 30), p + Vector2(18, 26), p + Vector2(10, -8)]), Crayon.INK, 4, skin, 61)
	Crayon.line(pen, p + Vector2(70, 110), p + Vector2(160, 200), Crayon.INK, 8, 62)


func _paint_punish() -> void:
	var ground := 600.0
	Crayon.line(pen, Vector2(260, ground), Vector2(1240, ground), Crayon.GREEN, 6, 70)
	var p := Vector2(760, ground)
	var mood := "o"
	var pose := "stand"
	var rot := 0.0
	var scale_k := 1.0
	var tt := pun_t
	match pun_kind:
		1:
			# boxing glove from a present
			var box := Rect2(330, ground - 120, 140, 120)
			var lid := 0.0 if tt < 0.6 else 60.0
			var wob := sin(tt * 40.0) * 4.0 if tt < 0.6 else 0.0
			Crayon.present(pen, Rect2(box.position + Vector2(wob, 0), box.size), Crayon.BLUE, Crayon.YELLOW, 71, lid)
			var ext := 0.0
			if tt >= 0.6 and tt < 0.78:
				ext = (tt - 0.6) / 0.18
			elif tt >= 0.78 and tt < 0.95:
				ext = 1.0
			elif tt >= 0.95:
				ext = clampf(1.0 - (tt - 0.95) / 0.4, 0.0, 1.0)
			if ext > 0.0:
				var start := Vector2(400, ground - 140)
				var end := start.lerp(Vector2(700, ground - 110), ext)
				var zig := PackedVector2Array()
				for i in 13:
					var f := i / 12.0
					zig.append(start.lerp(end, f) + Vector2(0, 14 if i % 2 == 0 else -14))
				Crayon.path(pen, zig, Crayon.GREY, 5, 72)
				Crayon.circle(pen, end + Vector2(18, 0), 34, Crayon.INK, 5, Crayon.RED, 73)
				Crayon.text(pen, end + Vector2(18, -60), "BONK!", 40, Crayon.RED, 1, 74, Crayon.title_font())
			if tt >= 0.78:
				var f := clampf((tt - 0.78) / 0.8, 0.0, 1.0)
				p = Vector2(lerpf(760, 1060, f), ground - sin(f * PI) * 260)
				rot = f * TAU * 1.5
				pose = "fall"
				mood = "x"
		2:
			# giant cake from the sky
			var fall := clampf(tt / 0.9, 0.0, 1.0)
			var shadow := fall * 1.0
			pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			Crayon.ellipse(pen, Vector2(760, ground + 4), Vector2(150 * shadow, 22 * shadow), Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0.25), 80)
			if tt < 0.9:
				var y := lerpf(-300, ground - 40, fall * fall)
				Crayon.cake(pen, Vector2(760, y + 130), 320, 150, Crayon.PINK, 6, true, 81)
				mood = "o"
				pose = "up"
			else:
				pose = "flat" if tt < 2.3 else "stand"
				mood = "x"
				for i in 9:
					var a := TAU * i / 9.0
					Crayon.circle(pen, Vector2(760, ground - 20) + Vector2(cos(a) * 230, sin(a) * 70 - 30), 18 + i % 3 * 6, Crayon.INK, 3, Crayon.PINK if i % 2 == 0 else Crayon.WHITE, 82 + i)
				if tt < 2.3:
					Crayon.ellipse(pen, Vector2(760, ground - 22), Vector2(200, 34), Crayon.INK, 5, Crayon.PINK, 95)
					Crayon.text(pen, Vector2(760, ground - 120), "SPLAT!", 70, Crayon.PINK.darkened(0.3), 1, 96, Crayon.title_font())
				else:
					p.y -= sin(clampf((tt - 2.3) / 0.4, 0, 1) * PI) * 60
		_:
			# a hole opens up...
			var hole_r := clampf(tt / 0.4, 0.0, 1.0) * (1.0 - clampf((tt - 1.8) / 0.4, 0.0, 1.0))
			Crayon.ellipse(pen, Vector2(760, ground + 6), Vector2(170 * hole_r, 34 * hole_r), Crayon.INK, 4, Crayon.BLACK, 100)
			if tt >= 0.55 and tt < 1.6:
				var f := clampf((tt - 0.55) / 0.6, 0.0, 1.0)
				p.y += f * 40
				scale_k = 1.0 - f
				pose = "up"
			elif tt >= 1.6 and tt < 2.15:
				scale_k = 0.0
			elif tt >= 2.15:
				var f := clampf((tt - 2.15) / 0.45, 0.0, 1.0)
				p.y = lerpf(-200, ground, f * f)
				pose = "fall" if f < 1.0 else "stand"
				mood = "x" if f >= 1.0 else "o"
			if tt >= 1.6 and tt < 2.1:
				Crayon.text(pen, Vector2(760, ground + 70), "...thud", 34, Crayon.GREY, 1, 101)
	if scale_k > 0.01:
		var h := 170.0 * scale_k
		var c := p + Vector2(0, -h * 0.5)
		pen.draw_set_transform(c, rot, Vector2.ONE)
		Crayon.person(pen, Vector2(0, h * 0.5), h, Crayon.INK, mood, Color(0, 0, 0, 0), pose, t * 6.0, 110)
		pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if pose != "flat":
			var tag_y := p.y - h - 40
			if not (pun_kind == 1 and tt > 0.78 and tt < 1.6):
				Crayon.text(pen, Vector2(p.x, tag_y), "\"" + victim_name + "\"", 40, Crayon.BLUE, 1, 111, null, 1.0, false)
				var tw := Crayon.body().get_string_size(victim_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
				Crayon.line(pen, Vector2(p.x - tw * 0.6 - 10, tag_y + 4), Vector2(p.x + tw * 0.6 + 10, tag_y - 6), Crayon.RED, 6, 112)
		if mood == "x" and pose != "flat":
			for i in 3:
				var a := t * 4.0 + TAU * i / 3.0
				Crayon.star(pen, p + Vector2(cos(a) * 50, -h - 6 + sin(a) * 14), 12, Crayon.INK, Crayon.YELLOW, 120 + i)
	Crayon.text(pen, Vector2(W * 0.5 + 60, 190), ["", "WRONG!", "WRONG AGAIN!", "NOPE!!!"][mini(pun_kind, 3)], 80, Crayon.RED, 1, 130, Crayon.title_font())
