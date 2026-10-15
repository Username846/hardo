extends Screen
## "Tap to start" (also unlocks browser audio).

var started := false
var forget_armed := 0.0


func enter() -> void:
	show_home = false
	remove_button("home")
	use_back_layer()
	lyrics_y = 30.0
	if Game.player_name != "":
		add_button("forget", Rect2(W - 230, H - 70, 210, 52), "new party", _forget, Crayon.WHITE, 26)
	add_button("full", Rect2(20, H - 70, 200, 52), "full screen", _fullscreen, Crayon.WHITE, 26)


func _fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _forget() -> void:
	var b := get_button("forget")
	if forget_armed > 0.0:
		Game.reset()
		Audio.sfx("music_wrong")
		b.label = "forgotten!"
		b.visible = false
		return
	forget_armed = 3.0
	b.label = "tap again!"


func tick(dt: float) -> void:
	if forget_armed > 0.0:
		forget_armed -= dt
		if forget_armed <= 0.0:
			var b := get_button("forget")
			if not b.is_empty() and b.visible:
				b.label = "new party"


func press(_p: Vector2) -> void:
	if started:
		return
	started = true
	Audio.preload_sfx()
	Audio.sfx("tada")
	Audio.play_music("title", 0.3)
	# every launch starts by asking for the name (there is only one right answer)
	Game.goto("name")


func paint_back() -> void:
	Crayon.sun(pen, Vector2(1140, 120), 60)
	Crayon.cloud(pen, Vector2(200, 110), 90, Crayon.WHITE, 3)
	Crayon.cloud(pen, Vector2(760, 80), 70, Crayon.WHITE, 4)
	title_text(Vector2(W * 0.5, 330), "CHUMBO!!!", 120, Crayon.RED, 900)
	Crayon.cake(pen, Vector2(W * 0.5, 600), 240, 110, Crayon.PINK, 5, false, 77)


func paint() -> void:
	Crayon.cake_flames(pen, Vector2(W * 0.5, 600), 240, 110, 5, 77)
	var cols := [Crayon.RED, Crayon.BLUE, Crayon.GREEN, Crayon.PURPLE, Crayon.ORANGE]
	for i in 5:
		var x := 90.0 + i * 70.0 + (900 if i > 2 else 0)
		Crayon.balloon(pen, Vector2(x, 330 + sin(t * 1.5 + i) * 14), 34, cols[i], 120, 20 + i)
	var title := "IT'S YOUR BIRTHDAY,"
	var x0 := W * 0.5 - 520
	for i in title.length():
		var ch := title.substr(i, 1)
		var y := 215.0 + sin(t * 3.0 + i * 0.5) * 6.0
		Crayon.text(pen, Vector2(x0 + i * 55, y), ch, 64, Crayon.RAINBOW[i % 7].darkened(0.1), 1, 300 + i, Crayon.title_font())
	Host.draw(pen, Vector2(W * 0.5 + 330, 520), 70, 0.0, false, Vector2.ZERO, 11)
	Crayon.person(pen, Vector2(W * 0.5 - 330, 640), 170, Crayon.INK, "happy", Crayon.GREEN, "wave", t * 2.0, 31)
	if not started and fmod(t, 1.2) < 0.85:
		Crayon.text(pen, Vector2(W * 0.5, 690), "TAP ANYWHERE TO START", 40, Crayon.INK, 1, 600)
