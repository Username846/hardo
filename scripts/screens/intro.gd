extends Screen
## The calendar does not lie. Today is Chumbo's birthday.

var denials := 0
var show_buttons := false
var stage := 0:     # 0 = plain, 1 = today circled, 2 = more circles, 3 = every day
	set(v):
		stage = v
		refresh_back()
var talk := false


func enter() -> void:
	show_home = false
	remove_button("home")
	Narrator.top = true
	use_back_layer()
	lyrics_y = 30.0
	Audio.play_music("title")
	_run()


func _run() -> void:
	locked = true
	await wait(0.5)
	talk = true
	await line("do_you_know_what")
	stage = 1
	Audio.sfx("scribble")
	await wait(0.5)
	Audio.sfx("cheer")
	confetti_burst(Vector2(420, 360), 60)
	await line("its_your_birthday")
	talk = false
	_buttons()
	locked = false


func _buttons() -> void:
	show_buttons = true
	add_button("yay", Rect2(800, 500, 420, 76), "YAY!!!", _yay, Crayon.GREEN, 44)
	add_button("no", Rect2(800, 600, 420, 76), "Wait... it's not my birthday?", _no, Crayon.WHITE, 28)


func _yay() -> void:
	if locked:
		return
	locked = true
	Audio.sfx("cheer")
	confetti_burst(Vector2(1010, 500), 60)
	talk = true
	await line("thats_right_happy")
	talk = false
	Game.intro_done = true
	Game.save_game()
	Game.goto("hub")


func _no() -> void:
	if locked:
		return
	locked = true
	denials += 1
	var nb := get_button("no")
	talk = true
	match denials:
		1:
			Audio.sfx("scribble")
			stage = 2
			await line("yes_it_is")
			nb.label = "No really, it's NOT my birthday!"
		2:
			Audio.sfx("scribble")
			stage = 3
			await line("everyone_remembered")
			nb.label = "...maybe it is my birthday?"
		_:
			await line("see_it_has_always")
			nb.label = "YAY!!!"
			nb.col = Crayon.GREEN
			nb.size = 44
			talk = false
			locked = false
			_yay()
			return
	talk = false
	locked = false


func paint() -> void:
	Host.draw(pen, Vector2(1010, 300), 95, 0.0 if denials < 3 else 0.3, talk or Narrator.is_active(), Vector2(-1, 0.3), 9)


func paint_back() -> void:
	var d := Game.today()
	var cal := Rect2(60, 165, 640, 540)
	# calendar page
	Crayon.rect(pen, cal, Crayon.INK, 6, Crayon.WHITE, 1)
	Crayon.rect(pen, Rect2(cal.position, Vector2(cal.size.x, 90)), Crayon.INK, 6, Crayon.RED, 2)
	for i in 2:
		Crayon.circle(pen, cal.position + Vector2(160 + i * 320, 0), 14, Crayon.INK, 4, Crayon.GREY, 3 + i)
	Crayon.text(pen, Vector2(cal.get_center().x, cal.position.y + 46), "%s %d" % [Game.MONTHS[d.month - 1].to_upper(), d.year], 50, Crayon.WHITE, 1, 5, Crayon.title_font())
	var days := ["S", "M", "T", "W", "T", "F", "S"]
	var cw := cal.size.x / 7.0
	for i in 7:
		Crayon.text(pen, Vector2(cal.position.x + cw * (i + 0.5), cal.position.y + 118), days[i], 30, Crayon.GREY, 1, 10 + i)
	var first := Time.get_unix_time_from_datetime_dict({"year": d.year, "month": d.month, "day": 1, "hour": 12})
	var wd0: int = Time.get_datetime_dict_from_unix_time(int(first)).weekday
	var ndays := _days_in_month(d.year, d.month)
	var rh := 66.0
	for day in range(1, ndays + 1):
		var idx := wd0 + day - 1
		var cx := cal.position.x + cw * (idx % 7 + 0.5)
		var cy := cal.position.y + 168 + rh * int(idx / 7)
		var is_today: bool = day == d.day
		var col := Crayon.INK
		if stage >= 3 and not is_today:
			Crayon.circle(pen, Vector2(cx, cy - 2), 26, Crayon.RED, 3, Color(0, 0, 0, 0), 300 + day)
			Crayon.text(pen, Vector2(cx, cy + 22), "bday", 15, Crayon.RED, 1, 400 + day, null, 0.5, false)
		Crayon.text(pen, Vector2(cx, cy), str(day), 30, col, 1, 20 + day, null, 0.6, false)
		if is_today and stage >= 1:
			for k in (1 if stage == 1 else 3):
				Crayon.circle(pen, Vector2(cx, cy - 2), 30 + k * 7, Crayon.RED, 6, Color(0, 0, 0, 0), 500 + k)
	# today's label + arrow
	if stage >= 1:
		var today_idx: int = wd0 + d.day - 1
		var tx: float = cal.position.x + cw * (today_idx % 7 + 0.5)
		var ty: float = cal.position.y + 168 + rh * int(today_idx / 7)
		var lx := clampf(tx, cal.position.x + 190, cal.end.x - 190)
		var ly := ty - 70 if ty > cal.position.y + 260 else ty + 70
		Crayon.text(pen, Vector2(lx, ly), "CHUMBO'S BIRFDAY!!!", 40, Crayon.RED, 1, 601, Crayon.title_font())
		Crayon.line(pen, Vector2(lx, ly + (18 if ly < ty else -24)), Vector2(tx, ty + (-34 if ly < ty else 30)), Crayon.RED, 5, 602)
		Crayon.text(pen, Vector2(1010, 455), "TODAY: " + Game.today_text(), 40, Crayon.BLUE, 1, 600, null, 1.0, false)
		if stage >= 2:
			for k in 3:
				Crayon.star(pen, Vector2(tx + 40 + k * 20, ty - 40 - k * 25), 14, Crayon.INK, Crayon.YELLOW, 610 + k)


func _days_in_month(y: int, m: int) -> int:
	if m == 2:
		return 29 if (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)) else 28
	return 30 if m in [4, 6, 9, 11] else 31
