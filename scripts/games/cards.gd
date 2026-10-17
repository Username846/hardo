extends Screen
## Present 4: CARD CHECKPOINT (document inspection). Check every birthday card against the
## rules and stamp it YAY or NOPE. Later, the rules change. Everyone is invited.
## Everyone except Pip, your best friend, whose cards keep fading... and so does Pip.

const IDX := 3
const CARD := Rect2(420, 110, 450, 480)
const PHOTO := Rect2(948, 14, 290, 172)
## How much of Pip is left in the photo after each of Pip's sad cards.
const PIP_LEFT := [1.0, 0.62, 0.36, 0.14, 0.0]

var cards: Array = []
var i := -1
var card_off := Vector2(0, -700)
var card_alpha := 1.0
var stamp := ""
var stamp_t := 0.0
var busy := true
var checked := 0
var mistakes := 0
var rule4 := false
var feedback := ""
var feedback_t := 0.0
## Pip fades from the photo one step per lost card; pip_shown animates towards it.
var pip_lost := 0
var pip_shown := 1.0
var lost_note := ""
var lost_t := 0.0
var photo_zoom := 0.0
var bits: Array = []

var _baked_key := ""
var _a := 1.0


func enter() -> void:
	use_back_layer()
	Audio.play_music("cards")
	var today: String = Game.date_text(0)
	var long_ago: String = Game.date_text(-365)
	var cream := Color(0.85, 0.85, 0.8)
	cards = [
		{"from": "Grandma", "to": "Chumbo", "date": today, "msg": "Happy birthday sweetie! Wear a sweater!", "sig": "Grandma xoxo", "ok": true, "col": Crayon.PINK, "pic": "heart"},
		{"from": "Your Dog", "to": "Chumbo", "date": today, "msg": "WOOF WOOF WOOF (happy birthday)", "sig": "paw", "ok": true, "col": Crayon.YELLOW, "pic": "bone"},
		{"from": "Pip", "to": "Chumbo", "date": today, "msg": "HAPPY BIRTHDAY!!! Race you to the cake! Best friends forever!", "sig": "Pip :)", "ok": true, "col": Crayon.GREEN, "pic": "friends", "pip": true},
		{"from": "Uncle Steve", "to": "Chimbo", "date": today, "msg": "Happy birthday, champ! Love ya!", "sig": "Steve", "ok": false, "col": Crayon.ORANGE, "pic": "cake"},
		{"from": "Cousin Max", "to": "Chumbo", "date": Game.date_text(1), "msg": "HAPPY BIRTHDAY DUDE!!! Party time!", "sig": "Max", "ok": false, "col": Crayon.SKY, "pic": "balloon"},
		{"from": "The Mailman", "to": "Chumbo", "date": today, "msg": "Happy birthday from the mail guy.", "sig": "", "ok": false, "col": Crayon.ORANGE, "pic": "star"},
		{"from": "Mom", "to": "Chumbo", "date": today, "msg": "Happy birthday! I can't believe you forgot your own birthday!", "sig": "Mom", "ok": true, "col": Crayon.PINK, "pic": "heart"},
		{"from": "Aunt Lulu", "to": "Chumbo", "date": today, "msg": "Happy birthday! I put a sticker in here. Don't eat it.", "sig": "Lulu", "ok": true, "col": Crayon.PURPLE, "pic": "star"},
		{"from": "Pip", "to": "Chumbo", "date": today, "msg": "Remember our treehouse? I saved you the best seat!", "sig": "Pip :)", "ok": true, "col": Crayon.GREEN, "pic": "tree", "pip": true},
		{"from": "Pizza Palace", "to": "Valued Customer", "date": today, "msg": "Happy birthday! Enjoy 10% off one (1) breadstick.", "sig": "The Manager", "ok": false, "col": Crayon.RED, "pic": "star"},
		{"from": "Your Teacher", "to": "Chumbo", "date": Game.date_text(-1), "msg": "Have a wonderful birthday. Homework is due Monday.", "sig": "Mrs. B", "ok": false, "col": Crayon.BLUE, "pic": "star"},
		{"from": "The Dentist", "to": "Chumbo", "date": today, "msg": "Happy birthday! Brush after the cake! And floss!", "sig": "Dr. Molar", "ok": true, "col": Crayon.SKY, "pic": "star"},
		# ---- the mail comes from strange places now
		{"from": "The Neighbor's Basement", "to": "Chumbo", "date": today, "msg": "We can't wait to meet you.", "sig": "hand", "ok": true, "col": Color(0.55, 0.5, 0.45), "pic": "eye"},
		{"from": "Pip", "to": "Chumbo", "date": long_ago, "msg": "Is it still your birthday? It's been your birthday for so long.", "sig": "Pip", "ok": false, "col": Crayon.GREEN.lerp(cream, 0.4), "pic": "friends", "pip": true, "lost": true},
		{"from": "Everyone In The Walls", "to": "Chumbo", "date": today, "msg": "We sang for you last night. Did you hear us?", "sig": "us", "ok": true, "col": Color(0.6, 0.55, 0.6), "pic": "eye"},
		{"from": "The Moon", "to": "Chumbo", "date": today, "msg": "I can see your party from here. It never stops.", "sig": "moon", "ok": true, "col": Color(0.85, 0.82, 0.55), "pic": "moon"},
		{"from": "P_p", "to": "Chumbo", "date": long_ago, "msg": "I knocked and knocked. Nobody opened the door.", "sig": "P", "ok": true, "col": Crayon.GREEN.lerp(cream, 0.65), "pic": "tree", "pip": true, "lost": true},
		{"from": "Your Shadow", "to": "Chumbo", "date": today, "msg": "I'll be right behind you. At every party. Forever.", "sig": "smudge", "ok": true, "col": Color(0.35, 0.33, 0.4), "pic": "x"},
		{"from": "You (from next year)", "to": "Chumbo", "date": today, "msg": "Don't open the last present.", "sig": "Chumbo", "ok": true, "col": cream, "pic": "x"},
		{"from": "P", "to": "Chumbo", "date": "", "msg": "do you rem", "sig": "", "ok": true, "col": Crayon.GREEN.lerp(cream, 0.85), "pic": "", "pip": true, "lost": true},
		{"from": "", "to": "Chumbo", "date": "TODAY TODAY TODAY", "msg": "WE'RE ALREADY HERE", "sig": "smile", "ok": true, "col": Color(0.4, 0.3, 0.35), "pic": "eye"},
		{"from": "The Clock", "to": "Chumbo", "date": today, "msg": "I stopped. Now it can be your birthday forever. You're welcome.", "sig": "clock", "ok": true, "col": Color(0.7, 0.6, 0.5), "pic": "clock"},
		{"from": "", "to": "Chumbo", "date": "", "msg": "", "sig": "", "ok": true, "col": cream, "pic": "", "pip": true, "lost": true},
		{"from": "Everyone", "to": "Chumbo", "date": today, "msg": "Happy birthday, Chumbo. It's always your birthday.", "sig": "everyone", "ok": true, "col": Color(0.5, 0.15, 0.2), "pic": "cake"},
	]
	add_button("yay", Rect2(930, 220, 300, 120), "YAY!", func(): _stamp("YAY!"), Crayon.GREEN, 64)
	add_button("nope", Rect2(930, 370, 300, 120), "NOPE!", func(): _stamp("NOPE!"), Crayon.RED, 64)
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await say("Present number four! You got a job! You're the Birthday Card Inspector. Read the rules, then stamp each card YAY or NOPE.")
	await say("That's you and Pip in the picture. Best friends forever!")
	locked = false
	_next()


func _next() -> void:
	i += 1
	stamp = ""
	card_alpha = 1.0
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
			say_bg("A card from Pip! Pip is your best friend in the whole world.")
		3:
			say_bg("Hmm. Look very closely at the name.")
		13:
			say_bg("This card from Pip is from a long time ago. Rules are rules.", Narrator.DARK)
		16:
			say_bg("P... p? Somebody forgot how to spell their own name.", Narrator.DARK)
		18:
			say_bg("That's your handwriting, isn't it?", Narrator.DARK)
		19:
			say_bg("Another one. You almost remember who sends these.", Narrator.DARK)
		22:
			say_bg("This one is empty. It's still warm, like someone was holding it.", Narrator.DARK)


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
	if c.has("lost"):
		await _lose(c)
	else:
		var tw := create_tween()
		var dest := Vector2(900, -100) if kind == "YAY!" else Vector2(-700, 400)
		tw.tween_property(self, "card_off", dest, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		Audio.sfx("whoosh", -6)
		await tw.finished
	if i == 0 and correct:
		say_bg("Good job! Grandma would be proud.")
	elif i == 8:
		say_bg("Pip saved you a seat. That's what best friends do.")
	if i == 11:
		locked = true
		Audio.play_music("cards_dark", 2.0)
		await say("Uh oh. The mail is coming from... strange places now.", Narrator.DARK)
		locked = false
	if i == 14:
		locked = true
		rule4 = true
		Audio.sfx("scribble")
		var nb := get_button("nope")
		nb.label = "YAY!"
		nb.col = Crayon.GREEN
		await say("New rule. All cards are approved. Everyone is invited.", Narrator.DARK)
		locked = false
	_next()


## Pip's card can't be delivered, whatever the stamp says. It crumbles away, and a little
## more of Pip goes with it.
func _lose(c: Dictionary) -> void:
	pip_lost = mini(pip_lost + 1, PIP_LEFT.size() - 1)
	lost_note = "RETURN TO SENDER" if pip_lost < 3 else "NO SUCH PERSON"
	lost_t = 2.4
	Audio.sfx("paper", -6, 0.7)
	Audio.sfx("wind", -10)
	for k in 26:
		var p := CARD.position + Vector2(randf() * CARD.size.x, randf() * CARD.size.y)
		bits.append({"p": p, "v": Vector2(randf_range(-30, 50), randf_range(-90, -30)), "t": randf_range(1.2, 2.2), "col": (c.col as Color).lightened(0.4)})
	var tw := create_tween()
	tw.tween_property(self, "card_alpha", 0.0, 1.6)
	var tw2 := create_tween()
	tw2.tween_property(self, "pip_shown", PIP_LEFT[pip_lost], 2.2)
	await tw.finished
	match pip_lost:
		1:
			say_bg("Huh. The picture looks a little different.", Narrator.DARK)
		2:
			say_bg("Return to sender. No such address.", Narrator.DARK)
		4:
			Audio.sfx("whisper_chumbo", -8, 1.15)
			await wait(0.4)
			say_bg("bye, Chumbo.", Narrator.WHISPER)
	await wait(0.4)


func _end() -> void:
	locked = true
	busy = true
	await wait(0.4)
	await say("Good work, Inspector. Everyone has been invited now.", Narrator.DARK)
	var tw := create_tween()
	tw.tween_property(self, "photo_zoom", 1.0, 1.4).set_trans(Tween.TRANS_SINE)
	await tw.finished
	await say("Who's that in your picture? Oh. Just you. It was always just you.", Narrator.DARK)
	await say("Wasn't it?", Narrator.WHISPER)
	var tw2 := create_tween()
	tw2.tween_property(self, "photo_zoom", 0.0, 0.8)
	await say("Present number four, done! So much birthday mail!")
	finish_game(IDX, "ALL STAMPED!")


func tick(dt: float) -> void:
	stamp_t += dt
	feedback_t = maxf(0.0, feedback_t - dt)
	lost_t = maxf(0.0, lost_t - dt)
	for b in bits:
		b.t -= dt
		b.p += b.v * dt
		b.v.y -= 20.0 * dt
	bits = bits.filter(func(b): return b.t > 0.0)
	Crayon.shake = 1.0 + (0.6 if i >= 15 else 0.0)


func paint_back() -> void:
	_baked_key = "%d/%s" % [i, rule4]
	var dark := 0.0 if i < 12 else clampf((i - 11) / 6.0, 0.0, 1.0)
	var desk := Color(0.75, 0.55, 0.38).lerp(Color(0.22, 0.14, 0.12), dark)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), desk)
	for k in 9:
		Crayon.line(pen, Vector2(-40, 80 + k * 80), Vector2(W + 40, 80 + k * 80 + 6), desk.darkened(0.15), 3, 10 + k)
	_rules()


func paint() -> void:
	if _baked_key != "%d/%s" % [i, rule4]:
		refresh_back()
	if photo_zoom <= 0.0:
		_photo(PHOTO)
	if i >= 0 and i < cards.size() and card_alpha > 0.0:
		_a = card_alpha
		_card(cards[i])
		_a = 1.0
	for b in bits:
		var a := clampf(b.t, 0.0, 1.0)
		pen.draw_rect(Rect2(b.p, Vector2(9, 7)), Color(b.col, a))
	Crayon.text(pen, Vector2(1080, 545), "checked: %d / %d" % [checked, cards.size()], 30, Crayon.WHITE, 1, 50)
	Crayon.text(pen, Vector2(1080, 585), "oopsies: %d" % mistakes, 30, Crayon.WHITE, 1, 51)
	if feedback_t > 0.0:
		var col := Crayon.GREEN if feedback == "CORRECT!" else Crayon.RED
		Crayon.text(pen, Vector2(645, 622), feedback, 52, col.lightened(0.3), 1, 52, Crayon.title_font())
	if lost_t > 0.0:
		var la := clampf(lost_t, 0.0, 1.0)
		Crayon.text(pen, CARD.get_center() + Vector2(0, -20), lost_note, 44, Color(0.85, 0.85, 0.85, la), 1, 53, Crayon.title_font())


func paint_top() -> void:
	if rule4:
		var nb := get_button("nope")
		Crayon.line(pen, nb.rect.position + Vector2(10, 10), nb.rect.end - Vector2(10, 10), Crayon.INK, 6, 60)
	if photo_zoom > 0.0:
		# the photo comes up close at the end: just Chumbo, one arm around nobody
		var big := Rect2(W * 0.5 - 330, 110, 660, 392)
		var r := Rect2(PHOTO.position.lerp(big.position, photo_zoom), PHOTO.size.lerp(big.size, photo_zoom))
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0, 0, 0, 0.45 * photo_zoom))
		_photo(r)


## Chumbo and Pip under a crayon sun. Pip fades out as pip_shown drops.
func _photo(r: Rect2) -> void:
	var k := r.size.x / PHOTO.size.x
	Crayon.rect(pen, r, Crayon.INK, 5, Color(0.95, 0.85, 0.55), 70)
	var pic := r.grow(-12 * k)
	pic.size.y -= 26 * k
	pen.draw_rect(pic, Crayon.SKY.lerp(Color(0.6, 0.6, 0.65), 1.0 - pip_shown))
	pen.draw_rect(Rect2(pic.position + Vector2(0, pic.size.y * 0.72), Vector2(pic.size.x, pic.size.y * 0.28)), Color(0.5, 0.78, 0.42))
	Crayon.disc(pen, pic.position + Vector2(pic.size.x - 30 * k, 26 * k), 16 * k, Crayon.YELLOW)
	var feet_y := pic.position.y + pic.size.y * 0.92
	var h := pic.size.y * 0.72
	var cx := pic.position.x + pic.size.x * 0.36
	var px := pic.position.x + pic.size.x * 0.64
	_kid(Vector2(cx, feet_y), h, Crayon.GREEN, 1.0, 71, "happy" if pip_shown > 0.5 else "flat", (px - cx) * 0.55)
	if pip_shown > 0.01:
		_kid(Vector2(px, feet_y), h * 0.96, Crayon.ORANGE, pip_shown, 81, "happy", -(px - cx) * 0.55)
	# the caption, written in crayon, loses Pip's name too
	var cap := "ME + PIP"
	if pip_shown < 0.7:
		cap = "ME + P_P"
	if pip_shown < 0.45:
		cap = "ME + P"
	if pip_shown < 0.2:
		cap = "ME +"
	if pip_shown < 0.02:
		cap = "ME"
	Crayon.text(pen, Vector2(r.get_center().x, r.end.y - 20 * k), cap, int(26 * k), Crayon.INK, 1, 90, null, 0.8, false)


## A stick kid with an arm reaching towards the other one (reach = x offset of the hand).
func _kid(feet: Vector2, h: float, shirt: Color, a: float, sd: int, mood: String, reach: float) -> void:
	var ink := Color(Crayon.INK, a)
	var w := maxf(3.0, h * 0.05)
	var hip := feet + Vector2(0, -h * 0.42)
	var neck := feet + Vector2(0, -h * 0.72)
	var head := feet + Vector2(0, -h * 0.85)
	var hr := h * 0.14
	Crayon.line(pen, hip, feet + Vector2(-h * 0.13, 0), ink, w, sd)
	Crayon.line(pen, hip, feet + Vector2(h * 0.13, 0), ink, w, sd + 1)
	Crayon.poly(pen, PackedVector2Array([neck + Vector2(-h * 0.11, 0), neck + Vector2(h * 0.11, 0), hip + Vector2(h * 0.14, 0), hip + Vector2(-h * 0.14, 0)]), ink, w * 0.8, Color(shirt, a), sd + 2)
	Crayon.line(pen, neck + Vector2(0, h * 0.04), neck + Vector2(reach, h * 0.08), ink, w, sd + 3)
	Crayon.line(pen, neck + Vector2(0, h * 0.04), neck + Vector2(-signf(reach) * h * 0.2, h * 0.22), ink, w, sd + 4)
	Crayon.circle(pen, head, hr, ink, w, Color(1, 0.9, 0.78, a), sd + 5)
	Crayon.face(pen, head + Vector2(0, hr * 0.1), hr * 0.9, mood, Vector2.ZERO, sd + 6, ink)


func _rules() -> void:
	var r := Rect2(30, 100, 360, 480)
	Crayon.rect(pen, r, Crayon.INK, 5, Crayon.BROWN.lightened(0.2), 20)
	var paper := Rect2(r.position + Vector2(20, 40), r.size - Vector2(40, 60))
	Crayon.rect(pen, paper, Crayon.INK, 3, Crayon.WHITE, 21)
	Crayon.rect(pen, Rect2(r.position + Vector2(120, -14), Vector2(120, 34)), Crayon.INK, 4, Crayon.GREY, 22)
	Crayon.text(pen, paper.position + Vector2(paper.size.x * 0.5, 34), "THE RULES", 40, Crayon.RED, 1, 23, Crayon.title_font())
	var rules := ["1. Must say TO: CHUMBO", "2. Must be dated TODAY", "   (" + Game.today_text() + ")", "3. Must be signed"]
	for k in rules.size():
		Crayon.text(pen, paper.position + Vector2(18, 92 + k * 46), rules[k], 28, Crayon.INK, 0, 24 + k, null, 0.7, false)
	if rule4:
		Crayon.text(pen, paper.position + Vector2(18, 300), "4. ALL CARDS", 34, Crayon.RED, 0, 30, null, 1.6, false)
		Crayon.text(pen, paper.position + Vector2(18, 342), "   ARE APPROVED", 34, Crayon.RED, 0, 31, null, 1.6, false)


## Card colours go through this so a card can fade away (_a < 1).
func _c(col: Color) -> Color:
	return Color(col, col.a * _a)


func _card(c: Dictionary) -> void:
	var r := Rect2(CARD.position + card_off, CARD.size)
	var col: Color = c.col
	Crayon.rect(pen, r, _c(Crayon.INK), 6, _c(col.lightened(0.55)), 100 + i)
	Crayon.rect(pen, r.grow(-14), _c(col), 4, Color(0, 0, 0, 0), 101 + i)
	var cx := r.get_center().x
	var y := r.position.y
	_pic(c.pic, Vector2(cx, y + 70), 120 + i)
	var ink := _c(Crayon.INK)
	Crayon.text(pen, Vector2(r.position.x + 30, y + 150), "TO: " + String(c.to), 34, ink, 0, 130 + i, null, 0.6, false)
	Crayon.text(pen, Vector2(r.position.x + 30, y + 196), "DATE: " + String(c.date), 28, ink, 0, 131 + i, null, 0.6, false)
	Crayon.text_block(pen, Vector2(cx, y + 255), String(c.msg), 30, r.size.x - 60, _c(Crayon.BLUE.darkened(0.3)), 1, 132 + i)
	var from_txt := "FROM: " + String(c.from) if String(c.from) != "" else "FROM: ???"
	if c.has("pip") and String(c.from) == "":
		from_txt = "FROM: "
	Crayon.text(pen, Vector2(r.position.x + 30, r.end.y - 92), from_txt, 26, ink, 0, 133 + i, null, 0.6, false)
	_signature(String(c.sig), Vector2(r.position.x + 30, r.end.y - 50), 140 + i, c.has("pip"))
	if stamp != "":
		var sc := Crayon.GREEN.darkened(0.2) if stamp == "YAY!" else Crayon.RED
		sc.a = 0.85
		var sp := r.get_center() + Vector2(40, 40)
		var k := clampf(stamp_t * 8.0, 0.0, 1.0)
		var size := int(lerpf(140, 84, k))
		Crayon.rect(pen, Rect2(sp - Vector2(150, 55), Vector2(300, 110)), _c(sc), 8, Color(0, 0, 0, 0), 150)
		Crayon.text(pen, sp, stamp, size, _c(sc), 1, 151, Crayon.title_font(), 0.5, false)


func _signature(sig: String, p: Vector2, sd: int, pip: bool) -> void:
	match sig:
		"":
			if not pip:
				Crayon.text(pen, p + Vector2(0, 0), "sign here: ________", 24, _c(Crayon.GREY), 0, sd, null, 0.3, false)
		"paw":
			Crayon.circle(pen, p + Vector2(40, 0), 14, _c(Crayon.INK), 3, _c(Crayon.BROWN), sd)
			for k in 4:
				Crayon.circle(pen, p + Vector2(20 + k * 13, -22 - (0 if k % 3 == 0 else 6)), 6, _c(Crayon.INK), 2, _c(Crayon.BROWN), sd + k + 1)
		"hand":
			var h := p + Vector2(50, -6)
			Crayon.circle(pen, h, 18, _c(Crayon.INK), 3, _c(Color(0.3, 0.25, 0.25)), sd)
			for k in 5:
				var a := -2.6 + k * 0.38
				Crayon.line(pen, h + Vector2(cos(a), sin(a)) * 16, h + Vector2(cos(a), sin(a)) * 40, _c(Color(0.3, 0.25, 0.25)), 8, sd + k + 1)
		"smile":
			Crayon.circle(pen, p + Vector2(40, -8), 22, _c(Crayon.INK), 3, _c(Crayon.YELLOW), sd)
			Crayon.face(pen, p + Vector2(40, -8), 20, "wide", Vector2.ZERO, sd + 3, _c(Crayon.INK))
		"moon":
			Crayon.circle(pen, p + Vector2(40, -8), 22, _c(Crayon.INK), 3, _c(Color(1, 0.98, 0.8)), sd)
			Crayon.face(pen, p + Vector2(40, -8), 20, "smirk", Vector2.ZERO, sd + 3, _c(Crayon.INK))
		"smudge":
			Crayon.ellipse(pen, p + Vector2(60, -8), Vector2(56, 16), _c(Color(0.2, 0.2, 0.25)), 3, _c(Color(0.25, 0.25, 0.3)), sd)
		"clock":
			Crayon.circle(pen, p + Vector2(40, -8), 22, _c(Crayon.INK), 3, _c(Crayon.WHITE), sd)
			Crayon.line(pen, p + Vector2(40, -8), p + Vector2(40, -24), _c(Crayon.INK), 3, sd + 1)
			Crayon.line(pen, p + Vector2(40, -8), p + Vector2(52, -8), _c(Crayon.INK), 3, sd + 2)
		_:
			Crayon.text(pen, p, sig, 34, _c(Crayon.BLUE.darkened(0.2)), 0, sd, null, 1.4, false)
			var w := Crayon.body().get_string_size(sig, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
			Crayon.line(pen, p + Vector2(-4, 18), p + Vector2(w + 10, 14), _c(Crayon.BLUE.darkened(0.2)), 3, sd + 9)


func _pic(kind: String, c: Vector2, sd: int) -> void:
	var ink := _c(Crayon.INK)
	match kind:
		"heart":
			Crayon.heart(pen, c, 40, ink, _c(Crayon.RED), sd)
		"bone":
			Crayon.line(pen, c + Vector2(-40, 0), c + Vector2(40, 0), ink, 18, sd)
			for sx in [-1, 1]:
				for sy in [-1, 1]:
					Crayon.circle(pen, c + Vector2(sx * 44, sy * 10), 12, ink, 3, _c(Crayon.WHITE), sd + 2)
		"cake":
			Crayon.cake(pen, c + Vector2(0, 40), 100, 50, Crayon.PINK, 3, true, sd)
		"balloon":
			Crayon.balloon(pen, c + Vector2(-25, -10), 26, Crayon.RED, 30, sd)
			Crayon.balloon(pen, c + Vector2(25, -14), 26, Crayon.BLUE, 30, sd + 5)
		"star":
			Crayon.star(pen, c, 44, ink, _c(Crayon.YELLOW), sd)
		"friends":
			# two little stick kids holding hands
			for k in 2:
				var f := c + Vector2(-26 + k * 52, 46)
				Crayon.line(pen, f + Vector2(0, -34), f + Vector2(-10, 0), ink, 4, sd + k * 5)
				Crayon.line(pen, f + Vector2(0, -34), f + Vector2(10, 0), ink, 4, sd + k * 5 + 1)
				Crayon.line(pen, f + Vector2(0, -34), f + Vector2(0, -64), ink, 4, sd + k * 5 + 2)
				Crayon.circle(pen, f + Vector2(0, -78), 14, ink, 3, _c(Color(1, 0.9, 0.78)), sd + k * 5 + 3)
			Crayon.line(pen, c + Vector2(-26, -10), c + Vector2(26, -10), ink, 4, sd + 12)
			Crayon.heart(pen, c + Vector2(0, -50), 12, ink, _c(Crayon.RED), sd + 13)
		"tree":
			Crayon.rect(pen, Rect2(c + Vector2(-8, -6), Vector2(16, 52)), ink, 3, _c(Crayon.BROWN), sd)
			Crayon.cloud(pen, c + Vector2(0, -30), 40, _c(Crayon.GREEN), sd + 1)
			Crayon.rect(pen, Rect2(c + Vector2(-26, -20), Vector2(52, 30)), ink, 3, _c(Crayon.ORANGE), sd + 2)
		"moon":
			Crayon.circle(pen, c, 42, ink, 4, _c(Color(1, 0.98, 0.8)), sd)
			Crayon.face(pen, c, 36, "smirk", (mouse - c).normalized(), sd + 1, ink)
		"clock":
			Crayon.circle(pen, c, 44, ink, 4, _c(Crayon.WHITE), sd)
			Crayon.line(pen, c, c + Vector2(0, -32), ink, 4, sd + 1)
			Crayon.line(pen, c, c + Vector2(0, -24), ink, 4, sd + 2)
		"eye":
			Crayon.ellipse(pen, c, Vector2(60, 32), ink, 4, _c(Crayon.WHITE), sd)
			Crayon.circle(pen, c + (mouse - c).normalized() * 10, 18, ink, 3, _c(Color(0.4, 0.1, 0.1)), sd + 1)
			Crayon.dot(pen, c + (mouse - c).normalized() * 12, 7, _c(Crayon.BLACK))
		"x":
			Crayon.line(pen, c + Vector2(-35, -35), c + Vector2(35, 35), _c(Crayon.RED), 9, sd)
			Crayon.line(pen, c + Vector2(35, -35), c + Vector2(-35, 35), _c(Crayon.RED), 9, sd + 1)
