extends Screen
## Present 4: CARD CHECKPOINT (document inspection). Check every birthday card against the
## rules and stamp it YAY or NOPE. Later, the rules change. Everyone is invited.

const IDX := 3
const CARD := Rect2(420, 110, 450, 480)

var cards: Array = []
var i := -1
var card_off := Vector2(0, -700)
var stamp := ""
var stamp_t := 0.0
var busy := true
var checked := 0
var mistakes := 0
var rule4 := false
var feedback := ""
var feedback_t := 0.0


func enter() -> void:
	Audio.play_music("cards")
	var today: String = Game.date_text(0)
	cards = [
		{"from": "Grandma", "to": "Chumbo", "date": today, "msg": "Happy birthday sweetie! Wear a sweater!", "sig": "Grandma xoxo", "ok": true, "col": Crayon.PINK, "pic": "heart"},
		{"from": "Your Dog", "to": "Chumbo", "date": today, "msg": "WOOF WOOF WOOF (happy birthday)", "sig": "paw", "ok": true, "col": Crayon.YELLOW, "pic": "bone"},
		{"from": "Uncle Steve", "to": "Chimbo", "date": today, "msg": "Happy birthday, champ! Love ya!", "sig": "Steve", "ok": false, "col": Crayon.GREEN, "pic": "cake"},
		{"from": "Best Friend", "to": "Chumbo", "date": Game.date_text(1), "msg": "HAPPY BIRTHDAY DUDE!!! Party time!", "sig": "ur best friend", "ok": false, "col": Crayon.SKY, "pic": "balloon"},
		{"from": "The Mailman", "to": "Chumbo", "date": today, "msg": "Happy birthday from the mail guy.", "sig": "", "ok": false, "col": Crayon.ORANGE, "pic": "star"},
		{"from": "Mom", "to": "Chumbo", "date": today, "msg": "Happy birthday! I can't believe you forgot your own birthday!", "sig": "Mom", "ok": true, "col": Crayon.PINK, "pic": "heart"},
		{"from": "Your Teacher", "to": "Chumbo", "date": Game.date_text(-1), "msg": "Have a wonderful birthday. Homework is due Monday.", "sig": "Mrs. B", "ok": false, "col": Crayon.PURPLE, "pic": "star"},
		{"from": "The Neighbor's Basement", "to": "Chumbo", "date": today, "msg": "We can't wait to meet you.", "sig": "hand", "ok": true, "col": Color(0.55, 0.5, 0.45), "pic": "eye"},
		{"from": "Everyone In The Walls", "to": "Chumbo", "date": today, "msg": "We sang for you last night. Did you hear us?", "sig": "us", "ok": true, "col": Color(0.6, 0.55, 0.6), "pic": "eye"},
		{"from": "You (from next year)", "to": "Chumbo", "date": today, "msg": "Don't open the last present.", "sig": "Chumbo", "ok": true, "col": Color(0.85, 0.85, 0.8), "pic": "x"},
		{"from": "", "to": "Chumbo", "date": "TODAY TODAY TODAY", "msg": "WE'RE ALREADY HERE", "sig": "smile", "ok": true, "col": Color(0.4, 0.3, 0.35), "pic": "eye"},
		{"from": "Everyone", "to": "Chumbo", "date": today, "msg": "Happy birthday, Chumbo. It's always your birthday.", "sig": "everyone", "ok": true, "col": Color(0.5, 0.15, 0.2), "pic": "cake"},
	]
	add_button("yay", Rect2(930, 200, 300, 120), "YAY!", func(): _stamp("YAY!"), Crayon.GREEN, 64)
	add_button("nope", Rect2(930, 360, 300, 120), "NOPE!", func(): _stamp("NOPE!"), Crayon.RED, 64)
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await say("Present number four! You got a job! You're the Birthday Card Inspector. Read the rules, then stamp each card YAY or NOPE.")
	locked = false
	_next()


func _next() -> void:
	i += 1
	stamp = ""
	if i >= cards.size():
		_end()
		return
	card_off = Vector2(0, -700)
	Audio.sfx("paper", -2)
	var tw := create_tween()
	tw.tween_property(self, "card_off", Vector2.ZERO, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	busy = false
	match i:
		2:
			say_bg("Hmm. Look very closely at the name.")
		9:
			say_bg("That's your handwriting, isn't it?", Narrator.DARK)


func _stamp(kind: String) -> void:
	if busy or i < 0 or i >= cards.size():
		return
	busy = true
	if rule4 and kind == "NOPE!":
		kind = "YAY!"
		Audio.sfx("glitch", -4)
	stamp = kind
	stamp_t = 0.0
	Audio.sfx("stamp")
	var c: Dictionary = cards[i]
	var correct := (kind == "YAY!") == bool(c.ok)
	checked += 1
	if correct:
		feedback = "CORRECT!"
		Audio.sfx("ding", -4)
	else:
		feedback = "OOPS!"
		mistakes += 1
		Audio.sfx("wrong", -6)
	feedback_t = 1.2
	await wait(0.8)
	var tw := create_tween()
	var dest := Vector2(900, -100) if kind == "YAY!" else Vector2(-700, 400)
	tw.tween_property(self, "card_off", dest, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	Audio.sfx("whoosh", -6)
	await tw.finished
	if i == 0 and correct:
		say_bg("Good job! Grandma would be proud.")
	if i == 6:
		locked = true
		Audio.play_music("cards_dark", 2.0)
		await say("Uh oh. The mail is coming from... strange places now.", Narrator.DARK)
		locked = false
	if i == 7:
		locked = true
		rule4 = true
		Audio.sfx("scribble")
		var nb := get_button("nope")
		nb.label = "YAY!"
		nb.col = Crayon.GREEN
		await say("New rule. All cards are approved. Everyone is invited.", Narrator.DARK)
		locked = false
	_next()


func _end() -> void:
	locked = true
	busy = true
	await wait(0.4)
	await say("Good work, Inspector. Everyone has been invited now.", Narrator.DARK)
	await say("Present number four, done! So much birthday mail!")
	finish_game(IDX, "ALL STAMPED!")


func tick(dt: float) -> void:
	stamp_t += dt
	feedback_t = maxf(0.0, feedback_t - dt)
	Crayon.shake = 1.0 + (0.6 if i >= 7 else 0.0)


func paint() -> void:
	var dark := 0.0 if i < 7 else clampf((i - 6) / 4.0, 0.0, 1.0)
	bg = Color(0.75, 0.55, 0.38).lerp(Color(0.22, 0.14, 0.12), dark)
	draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), bg)
	for k in 9:
		Crayon.line(self, Vector2(-40, 80 + k * 80), Vector2(W + 40, 80 + k * 80 + 6), bg.darkened(0.15), 3, 10 + k)
	_rules()
	if i >= 0 and i < cards.size():
		_card(cards[i])
	Crayon.text(self, Vector2(1080, 540), "checked: %d" % checked, 30, Crayon.WHITE, 1, 50)
	Crayon.text(self, Vector2(1080, 580), "oopsies: %d" % mistakes, 30, Crayon.WHITE, 1, 51)
	if feedback_t > 0.0:
		var col := Crayon.GREEN if feedback == "CORRECT!" else Crayon.RED
		Crayon.text(self, Vector2(645, 650), feedback, 52, col.lightened(0.3), 1, 52, Crayon.title_font())


func paint_top() -> void:
	if rule4:
		var nb := get_button("nope")
		Crayon.line(self, nb.rect.position + Vector2(10, 10), nb.rect.end - Vector2(10, 10), Crayon.INK, 6, 60)


func _rules() -> void:
	var r := Rect2(30, 100, 360, 480)
	Crayon.rect(self, r, Crayon.INK, 5, Crayon.BROWN.lightened(0.2), 20)
	var paper := Rect2(r.position + Vector2(20, 40), r.size - Vector2(40, 60))
	Crayon.rect(self, paper, Crayon.INK, 3, Crayon.WHITE, 21)
	Crayon.rect(self, Rect2(r.position + Vector2(120, -14), Vector2(120, 34)), Crayon.INK, 4, Crayon.GREY, 22)
	Crayon.text(self, paper.position + Vector2(paper.size.x * 0.5, 34), "THE RULES", 40, Crayon.RED, 1, 23, Crayon.title_font())
	var rules := ["1. Must say TO: CHUMBO", "2. Must be dated TODAY", "   (" + Game.today_text() + ")", "3. Must be signed"]
	for k in rules.size():
		Crayon.text(self, paper.position + Vector2(18, 92 + k * 46), rules[k], 28, Crayon.INK, 0, 24 + k, null, 0.7, false)
	if rule4:
		Crayon.text(self, paper.position + Vector2(18, 300), "4. ALL CARDS", 34, Crayon.RED, 0, 30, null, 1.6, false)
		Crayon.text(self, paper.position + Vector2(18, 342), "   ARE APPROVED", 34, Crayon.RED, 0, 31, null, 1.6, false)


func _card(c: Dictionary) -> void:
	var r := Rect2(CARD.position + card_off, CARD.size)
	var col: Color = c.col
	Crayon.rect(self, r, Crayon.INK, 6, col.lightened(0.55), 100 + i)
	Crayon.rect(self, r.grow(-14), col, 4, Color(0, 0, 0, 0), 101 + i)
	var cx := r.get_center().x
	var y := r.position.y
	_pic(c.pic, Vector2(cx, y + 70), 120 + i)
	var ink := Crayon.INK
	Crayon.text(self, Vector2(r.position.x + 30, y + 150), "TO: " + String(c.to), 34, ink, 0, 130 + i, null, 0.6, false)
	Crayon.text(self, Vector2(r.position.x + 30, y + 196), "DATE: " + String(c.date), 28, ink, 0, 131 + i, null, 0.6, false)
	Crayon.text_block(self, Vector2(cx, y + 255), String(c.msg), 30, r.size.x - 60, Crayon.BLUE.darkened(0.3), 1, 132 + i)
	var from_txt := "FROM: " + String(c.from) if String(c.from) != "" else "FROM: ???"
	Crayon.text(self, Vector2(r.position.x + 30, r.end.y - 92), from_txt, 26, ink, 0, 133 + i, null, 0.6, false)
	_signature(String(c.sig), Vector2(r.position.x + 30, r.end.y - 50), 140 + i)
	if stamp != "":
		var sc := Crayon.GREEN.darkened(0.2) if stamp == "YAY!" else Crayon.RED
		sc.a = 0.85
		var sp := r.get_center() + Vector2(40, 40)
		var k := clampf(stamp_t * 8.0, 0.0, 1.0)
		var size := int(lerpf(140, 84, k))
		Crayon.rect(self, Rect2(sp - Vector2(150, 55), Vector2(300, 110)), sc, 8, Color(0, 0, 0, 0), 150)
		Crayon.text(self, sp, stamp, size, sc, 1, 151, Crayon.title_font(), 0.5, false)


func _signature(sig: String, p: Vector2, sd: int) -> void:
	match sig:
		"":
			Crayon.text(self, p + Vector2(0, 0), "sign here: ________", 24, Crayon.GREY, 0, sd, null, 0.3, false)
		"paw":
			Crayon.circle(self, p + Vector2(40, 0), 14, Crayon.INK, 3, Crayon.BROWN, sd)
			for k in 4:
				Crayon.circle(self, p + Vector2(20 + k * 13, -22 - (0 if k % 3 == 0 else 6)), 6, Crayon.INK, 2, Crayon.BROWN, sd + k + 1)
		"hand":
			var h := p + Vector2(50, -6)
			Crayon.circle(self, h, 18, Crayon.INK, 3, Color(0.3, 0.25, 0.25), sd)
			for k in 5:
				var a := -2.6 + k * 0.38
				Crayon.line(self, h + Vector2(cos(a), sin(a)) * 16, h + Vector2(cos(a), sin(a)) * 40, Color(0.3, 0.25, 0.25), 8, sd + k + 1)
		"smile":
			Crayon.circle(self, p + Vector2(40, -8), 22, Crayon.INK, 3, Crayon.YELLOW, sd)
			Crayon.face(self, p + Vector2(40, -8), 20, "wide", Vector2.ZERO, sd + 3)
		_:
			Crayon.text(self, p, sig, 34, Crayon.BLUE.darkened(0.2), 0, sd, null, 1.4, false)
			var w := Crayon.body().get_string_size(sig, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
			Crayon.line(self, p + Vector2(-4, 18), p + Vector2(w + 10, 14), Crayon.BLUE.darkened(0.2), 3, sd + 9)


func _pic(kind: String, c: Vector2, sd: int) -> void:
	match kind:
		"heart":
			Crayon.heart(self, c, 40, Crayon.INK, Crayon.RED, sd)
		"bone":
			Crayon.line(self, c + Vector2(-40, 0), c + Vector2(40, 0), Crayon.INK, 18, sd)
			for sx in [-1, 1]:
				for sy in [-1, 1]:
					Crayon.circle(self, c + Vector2(sx * 44, sy * 10), 12, Crayon.INK, 3, Crayon.WHITE, sd + 2)
		"cake":
			Crayon.cake(self, c + Vector2(0, 40), 100, 50, Crayon.PINK, 3, true, sd)
		"balloon":
			Crayon.balloon(self, c + Vector2(-25, -10), 26, Crayon.RED, 30, sd)
			Crayon.balloon(self, c + Vector2(25, -14), 26, Crayon.BLUE, 30, sd + 5)
		"star":
			Crayon.star(self, c, 44, Crayon.INK, Crayon.YELLOW, sd)
		"eye":
			Crayon.ellipse(self, c, Vector2(60, 32), Crayon.INK, 4, Crayon.WHITE, sd)
			Crayon.circle(self, c + (mouse - c).normalized() * 10, 18, Crayon.INK, 3, Color(0.4, 0.1, 0.1), sd + 1)
			Crayon.dot(self, c + (mouse - c).normalized() * 12, 7, Crayon.BLACK)
		"x":
			Crayon.line(self, c + Vector2(-35, -35), c + Vector2(35, 35), Crayon.RED, 9, sd)
			Crayon.line(self, c + Vector2(35, -35), c + Vector2(-35, 35), Crayon.RED, 9, sd + 1)
