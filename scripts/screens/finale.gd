extends Screen
## Everyone came. Everyone will come back.

const CFG := preload("res://scripts/config.gd")
const Race := preload("res://scripts/games/race.gd")
const Skate := preload("res://scripts/games/skate.gd")
const Digi := preload("res://scripts/games/digi.gd")
const Duty := preload("res://scripts/games/duty.gd")
const Repo := preload("res://scripts/games/repo.gd")
const Karaoke := preload("res://scripts/games/karaoke.gd")

## In the dark, before the lights go on: where everyone's eyes are.
## [between the eyes, half the gap, eye size, colour]
const EYES := [
	[Vector2(116, 497), 5.0, 3.5, Color(1, 0.95, 0.55)],     # the street racer
	[Vector2(307, 397), 6.0, 4.0, Color(1, 0.95, 0.55)],     # Tony Honk
	[Vector2(431, 487), 7.0, 4.5, Color(0.6, 1.0, 0.5)],     # Partymon
	[Vector2(499, 410), 7.0, 4.5, Color(1, 0.95, 0.55)],     # a guest
	[Vector2(638, 231), 26.0, 9.0, Color(1, 0.95, 0.55)],    # the party host
	[Vector2(812, 449), 9.0, 4.5, Color(0.45, 1.0, 0.95)],   # Mikake (flickering)
	[Vector2(890, 414), 7.0, 4.5, Color(1, 0.95, 0.55)],     # the soldier
	[Vector2(985, 470), 16.0, 7.0, Color(1, 1, 1)],          # Chumbmon
	[Vector2(1077, 513), 9.0, 5.0, Color(0.4, 0.95, 1.0)],   # the gnome-catching robot
	[Vector2(1195, 405), 7.0, 4.5, Color(1, 0.95, 0.55)],    # the other Chumbo
]
## The order their eyes open in (the host's first).
const EYE_ORDER := [4, 0, 9, 2, 6, 1, 8, 3, 7, 5]

var light := 0.0
## How many of the eyes are open (0..1).
var eyes_k := 0.0
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
	# it stays dark: one by one, eyes open where everyone is standing
	var tw := create_tween()
	tw.tween_property(self, "eyes_k", 1.0, 4.0)
	await line("shh_everyone_is_here")
	await line("everyone_came_chumbo")
	await line("and_they_will_all")
	# the lights go on, and there they all are
	eyes_k = 1.0
	cheer = true
	Audio.sfx("switch")
	var tl := create_tween()
	tl.tween_property(self, "light", 1.0, 0.35)
	Audio.play_music("karaoke", 0.5)
	Audio.sfx("cheer")
	Audio.sfx("tada")
	for i in 5:
		confetti_burst(Vector2(200 + i * 220, 300), 50)
	await line("happy_birthday_chumbo")
	Game.finale_seen = true
	Game.save_game()
	credits = true
	# sing along: the lyric bar sits between the rolling credits and the button
	lyrics_y = 590.0
	await wait(1.0)
	if not Game.secret_started:
		# the first time, the party was a game on Chumbo's phone all along: the secret game starts
		add_button("back", Rect2(W * 0.5 - 200, H - 92, 400, 72), "Continue", _continue, Crayon.GREEN, 36)
	else:
		add_button("back", Rect2(W * 0.5 - 200, H - 92, 400, 72), "back to the party", Game.back_to_party, Crayon.GREEN, 36)
	locked = false


func _continue() -> void:
	Game.secret_started = true
	Game.save_game()
	Game.goto("rocko")


func tick(dt: float) -> void:
	if credits:
		roll += dt


func paint() -> void:
	var room := Color(0.06, 0.04, 0.1).lerp(Color(0.98, 0.9, 0.75), light * (0.9 if cheer else 0.55))
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), room)
	if light < 0.05:
		# only their eyes in the dark
		var open := int(eyes_k * EYES.size() + 0.5)
		for n in open:
			var i: int = EYE_ORDER[n]
			var e: Array = EYES[i]
			if fmod(t * 0.9 + i * 0.37, 3.7) < 0.14:
				continue
			var col: Color = e[3]
			if i == 5 and fmod(t * 7.0 + sin(t * 3.0), 1.0) < 0.3:
				# hers flicker
				col = Color(col, 0.35)
			for side in [-1.0, 1.0]:
				var p: Vector2 = e[0] + Vector2(side * float(e[1]), 0)
				Crayon.disc(pen, p, float(e[2]) * 2.4, Color(col, 0.15))
				Crayon.disc(pen, p, float(e[2]), col)
		return
	var a := clampf(light, 0, 1)
	var floor_y := 560.0
	Crayon.line(pen, Vector2(-40, floor_y), Vector2(W + 40, floor_y), Color(Crayon.INK, a), 5, 1)
	# the whole cast
	var mood := "wide" if not cheer else "happy"
	Crayon.cake(pen, Vector2(640, floor_y), 260, 130, Crayon.PINK, 10, true, 2)
	Host.draw(pen, Vector2(640, 250), 80, 0.5 if not cheer else 0.0, Narrator.is_active(), Vector2.ZERO, 3)
	# the street racer, Tony Honk, Partymon and one of the friends from the front
	Race.draw_mascot(pen, Vector2(120, floor_y), 0.75, t)
	Skate.draw_mascot(pen, Vector2(272, floor_y), 1.0, t, true)
	Digi.draw_mascot(pen, Vector2(418, floor_y), 0.55, t)
	Duty.draw_mascot(pen, Vector2(890, floor_y), 0.95, t)
	Repo.draw_mascot(pen, Vector2(1080, floor_y), 0.8, t)
	# Chumbmon
	Crayon.ellipse(pen, Vector2(985, floor_y - 70), Vector2(55, 66), Crayon.INK, 5, Color(0.15, 0.1, 0.2), 30)
	Crayon.face(pen, Vector2(985, floor_y - 80), 46, "wide", Vector2.ZERO, 31, Crayon.WHITE)
	# the other Chumbo
	Crayon.person(pen, Vector2(1195, floor_y), 170, Crayon.INK, mood, Crayon.GREEN, "wave", t * 2.0, 40)
	Crayon.text(pen, Vector2(1195, floor_y - 205), "chumbo", 22, Crayon.GREY, 1, 41, null, 0.5, false)
	Crayon.person(pen, Vector2(500, floor_y), 160, Crayon.INK, mood, Crayon.RED, "up" if cheer else "stand", t * 2.0, 42)
	Karaoke.draw_mascot(pen, Vector2(775, floor_y), 0.78, t)
	if credits:
		_credits()


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
	for i in lines.size():
		var s: String = lines[i][0]
		var sz: int = lines[i][1]
		if s != "":
			var f := Crayon.title_font() if sz >= 44 else null
			# (the crayon look is seeded by the line, not where it is, or it jitters as it scrolls)
			Crayon.text(pen, Vector2(W * 0.5, y), s, sz, Crayon.WHITE, 1, 40 + i * 13, f)
		y += sz * 1.25
