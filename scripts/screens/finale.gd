extends Screen
## Everyone came. Everyone will come back.

const CFG := preload("res://scripts/config.gd")

var light := 0.0
var credits := false
var roll := 0.0
var cheer := false


func enter() -> void:
	show_home = false
	remove_button("home")
	Narrator.top = true
	bg = Color(0.06, 0.04, 0.1)
	lyrics_y = -1.0
	Audio.stop_music(0.5)
	_run()


func _run() -> void:
	locked = true
	await wait(1.0)
	await say("Shh. Everyone is here.", Narrator.WHISPER)
	var tw := create_tween()
	tw.tween_property(self, "light", 1.0, 2.5)
	Audio.sfx("switch")
	await wait(2.0)
	await say("Everyone came, Chumbo. Everyone from every present.", Narrator.DARK)
	await say("And they will all come back. Next year. And the year after. And the year after that.", Narrator.DARK)
	cheer = true
	Audio.play_music("karaoke", 0.5)
	Audio.sfx("cheer")
	Audio.sfx("tada")
	for i in 5:
		confetti_burst(Vector2(200 + i * 220, 300), 50)
	await say("HAPPY BIRTHDAY, CHUMBO!")
	Game.finale_seen = true
	Game.save_game()
	credits = true
	await wait(1.0)
	add_button("back", Rect2(W * 0.5 - 200, H - 92, 400, 72), "back to the party", func(): Game.goto("hub"), Crayon.GREEN, 36)
	locked = false


func tick(dt: float) -> void:
	if credits:
		roll += dt


func paint() -> void:
	var room := Color(0.06, 0.04, 0.1).lerp(Color(0.98, 0.9, 0.75), light * (0.9 if cheer else 0.55))
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), room)
	if light < 0.05:
		# only eyes in the dark
		for i in 14:
			var e := Vector2(80 + i * 85, 260 + sin(i * 2.3) * 120)
			if fmod(t + i * 0.7, 3.5) > 0.2:
				Crayon.disc(pen, e, 6, Color(1, 0.95, 0.5))
				Crayon.disc(pen, e + Vector2(18, 0), 6, Color(1, 0.95, 0.5))
		return
	var a := clampf(light, 0, 1)
	var floor_y := 560.0
	Crayon.line(pen, Vector2(-40, floor_y), Vector2(W + 40, floor_y), Color(Crayon.INK, a), 5, 1)
	# the whole cast
	var mood := "wide" if not cheer else "happy"
	Crayon.cake(pen, Vector2(640, floor_y), 260, 130, Crayon.PINK, 10, true, 2)
	Host.draw(pen, Vector2(640, 250), 80, 0.5 if not cheer else 0.0, Narrator.is_active(), Vector2.ZERO, 3)
	# sheep (standing up)
	_sheep(Vector2(140, floor_y), true)
	_sheep(Vector2(250, floor_y), false)
	# blob
	Crayon.ellipse(pen, Vector2(380, floor_y - 60), Vector2(70, 60), Crayon.INK, 5, Crayon.PURPLE, 10)
	Crayon.face(pen, Vector2(380, floor_y - 70), 50, mood, Vector2.ZERO, 11)
	# teddy plush
	Crayon.circle(pen, Vector2(880, floor_y - 50), 46, Crayon.INK, 4, Crayon.BROWN, 20)
	Crayon.circle(pen, Vector2(880, floor_y - 125), 36, Crayon.INK, 4, Crayon.BROWN, 21)
	Crayon.circle(pen, Vector2(852, floor_y - 155), 13, Crayon.INK, 3, Crayon.BROWN, 22)
	Crayon.circle(pen, Vector2(908, floor_y - 155), 13, Crayon.INK, 3, Crayon.BROWN, 23)
	Crayon.face(pen, Vector2(880, floor_y - 125), 30, mood, Vector2.ZERO, 24)
	# Chumbmon
	Crayon.ellipse(pen, Vector2(1010, floor_y - 70), Vector2(60, 70), Crayon.INK, 5, Color(0.15, 0.1, 0.2), 30)
	Crayon.face(pen, Vector2(1010, floor_y - 80), 50, "wide", Vector2.ZERO, 31, Crayon.WHITE)
	# the other Chumbo
	Crayon.person(pen, Vector2(1160, floor_y), 170, Crayon.INK, mood, Crayon.GREEN, "wave", t * 2.0, 40)
	Crayon.text(pen, Vector2(1160, floor_y - 205), "chumbo", 22, Crayon.GREY, 1, 41, null, 0.5, false)
	Crayon.person(pen, Vector2(500, floor_y), 160, Crayon.INK, mood, Crayon.RED, "up" if cheer else "stand", t * 2.0, 42)
	Crayon.person(pen, Vector2(770, floor_y), 150, Crayon.INK, mood, Crayon.BLUE, "up" if cheer else "stand", t * 2.0, 43)
	if credits:
		_credits()


func _sheep(feet: Vector2, standing: bool) -> void:
	if standing:
		Crayon.line(pen, feet + Vector2(-12, 0), feet + Vector2(-8, -60), Crayon.INK, 6, 50)
		Crayon.line(pen, feet + Vector2(12, 0), feet + Vector2(8, -60), Crayon.INK, 6, 51)
		Crayon.ellipse(pen, feet + Vector2(0, -105), Vector2(42, 55), Crayon.INK, 4, Crayon.WHITE, 52)
		Crayon.circle(pen, feet + Vector2(0, -175), 26, Crayon.INK, 4, Color(0.25, 0.22, 0.25), 53)
		Crayon.face(pen, feet + Vector2(0, -175), 22, "wide", Vector2.ZERO, 54, Crayon.WHITE)
	else:
		for k in 4:
			Crayon.line(pen, feet + Vector2(-30 + k * 20, 0), feet + Vector2(-30 + k * 20, -30), Crayon.INK, 5, 55 + k)
		Crayon.ellipse(pen, feet + Vector2(0, -50), Vector2(55, 34), Crayon.INK, 4, Crayon.WHITE, 60)
		Crayon.circle(pen, feet + Vector2(50, -66), 20, Crayon.INK, 4, Color(0.25, 0.22, 0.25), 61)
		Crayon.party_hat(pen, feet + Vector2(50, -84), 16, Crayon.PINK, 62)


func _credits() -> void:
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0, 0, 0, clampf(roll * 0.4, 0, 0.55)))
	var lines := [
		["CHUMBO'S BIRTHDAY", 64],
		["starring: I'm Chumbo", 36],
		["and everyone who came", 30],
		["", 20],
		["made with love by", 30],
		[CFG.GIFT_FROM, 44],
		["", 20],
		[CFG.GIFT_MESSAGE, 40],
		["", 20],
		["see you on your next birthday", 30],
		["(it's tomorrow)", 26],
	]
	var y := H + 40 - roll * 70.0
	y = maxf(y, 70.0)
	for ln in lines:
		var s: String = ln[0]
		var sz: int = ln[1]
		if s != "":
			var f := Crayon.title_font() if sz >= 44 else null
			Crayon.text(pen, Vector2(W * 0.5, y), s, sz, Crayon.WHITE, 1, int(y) % 7 + sz, f)
		y += sz * 1.25
