extends Node
## Dev-only: plays each mini-game to the end (cheating a little) to make sure every
## scripted sequence, twist and ending runs without errors.
## Run: godot --headless --path . -- --bot=all   (or --bot=3)

var which := "all"
var g: Node = null
var tmr := 0.0
var step := 0
var stuck := 0.0
var results := {}
var shot_dir := ""
var shot_every := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bot="):
			which = a.substr(6)
		elif a.begins_with("--shots="):
			shot_dir = a.substr(8)
			DirAccess.make_dir_recursive_absolute(shot_dir)
		elif a.begins_with("--every="):
			shot_every = int(a.substr(8))
	Engine.time_scale = 4.0
	await get_tree().create_timer(0.5).timeout
	# voice-key sanity check
	var k: String = Narrator.key_for("Hi there! Welcome to the party! What's your name?", 0)
	print("VOICE KEY ", k, " exists=", ResourceLoader.exists("res://assets/voice/%s.ogg" % k))
	var idxs: Array = []
	if which == "all":
		idxs = range(10)
	elif which != "name":
		idxs = [int(which)]
	if which == "name" or which == "all":
		await _name_flow()
	if which != "name":
		for i in idxs:
			await _play(i)
	print("BOT RESULTS ", results)
	get_tree().quit()


func _play(i: int) -> void:
	Game.done.fill(false)
	Game.main._open("game", i)
	g = Game.main.current
	step = 0
	tmr = 0.0
	stuck = 0.0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 150000:
		await get_tree().process_frame
		if Narrator.is_active() and Narrator._blocking and Narrator._elapsed > 0.4:
			Narrator._shown = Narrator._text.length()
			Narrator._finish(true)
		if not is_instance_valid(g):
			break
		_drive(i, get_process_delta_time())
		if shot_dir != "" and shot_every > 0 and Engine.get_process_frames() % shot_every == 0:
			var img := get_viewport().get_texture().get_image()
			img.save_png(shot_dir.path_join("g%d_%06d.png" % [i, Engine.get_process_frames()]))
		if Engine.get_process_frames() % 300 == 0:
			print("  dbg frame ", Engine.get_process_frames(), " fps ", Engine.get_frames_per_second(), " ", _dbg(i))
		if Game.done[i]:
			break
	var ok: bool = Game.done[i]
	results[Game.GAMES[i].id] = ok
	print("BOT GAME ", i, " ", Game.GAMES[i].id, " done=", ok, " in ", (Time.get_ticks_msec() - t0) / 1000.0, "s")
	await get_tree().create_timer(1.0).timeout


func _skip_narration() -> void:
	if Narrator.is_active() and Narrator._blocking and Narrator._elapsed > 0.4:
		Narrator._shown = Narrator._text.length()
		Narrator._finish(true)


func _snap(name: String) -> void:
	if shot_dir != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot_dir.path_join(name + ".png"))


func _wait_unlocked(n: Node, limit: float = 30.0) -> void:
	var t0 := Time.get_ticks_msec()
	while is_instance_valid(n) and n.locked and Time.get_ticks_msec() - t0 < limit * 1000.0:
		_skip_narration()
		await get_tree().process_frame


## Types three wrong names (punishments), checks the forced name, then denies the birthday.
func _name_flow() -> void:
	Game.reset()
	Game.main._open("name", null)
	var n: Node = Game.main.current
	await _wait_unlocked(n)
	for attempt in 3:
		for ch in ["B", "O", "B"]:
			n._type(ch)
		n._submit()
		for k in 4:
			await get_tree().create_timer(0.25).timeout
			await _snap("name_pun%d_%d" % [attempt + 1, k])
		await _wait_unlocked(n, 60.0)
		if not is_instance_valid(n):
			print("NAME attempt ", attempt + 1, " -> moved on")
			break
		print("NAME attempt ", attempt + 1, " state=", n.state, " wrong=", n.wrong)
	var t0 := Time.get_ticks_msec()
	while is_instance_valid(n) and Game.main.current == n and Time.get_ticks_msec() - t0 < 60000:
		_skip_narration()
		await get_tree().process_frame
	print("NAME forced player_name=", Game.player_name)
	await get_tree().create_timer(1.0).timeout
	var intro: Node = Game.main.current
	print("NOW ON ", intro.get_script().resource_path)
	await _wait_unlocked(intro)
	for k in 3:
		await _snap("intro_deny%d" % k)
		intro._no()
		await get_tree().process_frame
		await _wait_unlocked(intro)
	t0 = Time.get_ticks_msec()
	while Game.main.current == intro and Time.get_ticks_msec() - t0 < 60000:
		_skip_narration()
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	print("INTRO done=", Game.intro_done, " now ", Game.main.current.get_script().resource_path)
	await _snap("hub_after_intro")


func _dbg(i: int) -> String:
	match i:
		0:
			return "started=%s locked=%s layers=%d falling=%s ended=%s" % [g.started, g.locked, g.layers.size(), g.falling, g.ended]
		2:
			return "stage=%d locked=%s busy=%s meters=%s choice=%s btns=%s" % [g.stage, g.locked, g.busy, g.meters, g.choice, g.buttons.map(func(b): return [b.id, b.visible])]
		8:
			return "phase=%s playing=%s found=%d light=%s locked=%s" % [g.phase, g.playing, g.found, g.light, g.locked]
	return ""


func _btn(id: String) -> bool:
	if g.locked:
		return false
	var b: Dictionary = g.get_button(id)
	if b.is_empty() or not b.visible:
		return false
	b.cb.call()
	return true


func _drive(i: int, dt: float) -> void:
	tmr += dt
	match i:
		0:
			if g.started and not g.falling and not g.ended and not g.locked:
				var top: Dictionary = g._top()
				if absf(g.cur_x - float(top.x)) < 30.0:
					g.press(Vector2.ZERO)
		1:
			if g.playing and tmr > 0.25:
				tmr = 0.0
				for s in g.sheep:
					if not s.home:
						s.pos = Vector2(g.PEN.position.x - 6, (g.GATE_Y0 + g.GATE_Y1) * 0.5)
						s.vel = Vector2(400, 0)
						break
		2:
			if g.choice and not g.locked:
				_btn("c1")
				return
			if g.locked or g.busy:
				return
			if g.stage == 0 and tmr > 0.15:
				tmr = 0.0
				g.press(g.CENTER)
			elif g.choice:
				_btn("c1")
			elif tmr > 0.3:
				tmr = 0.0
				if g.stage >= 4:
					_btn("feed")
				else:
					var m: Array = g.meters
					var lo := 0
					for k in 3:
						if m[k] < m[lo]:
							lo = k
					_btn(["feed", "play", "pet"][lo])
		3:
			if not g.busy and g.i >= 0 and g.i < g.cards.size() and not g.locked:
				_btn("yay" if g.cards[g.i].ok else "nope")
		4:
			if g.armed and g.state == "idle" and not g.locked and tmr > 0.3:
				tmr = 0.0
				if g.prizes.size() > 0:
					g.press(Vector2(g.prizes[0].x, 450))
		5:
			if g.phase == "bus" and tmr > 0.5:
				g.press(Vector2(640, 400))
			elif g.phase == "fight" and tmr > 0.4:
				tmr = 0.0
				for f in g.foes:
					if not f.hit:
						g.press(f.pos)
						break
				if g.shots.size() > 0:
					g.press(g.ME + (g.shots[0].pos - g.ME).normalized() * 100.0)
		6:
			if not g.running or g.ended or g.locked:
				return
			var p: Vector2 = g.pos
			var ahead := p.x + 70.0
			var ground: float = g._ground_at(ahead)
			var need := ground == INF or ground < p.y - 5
			for r in g.lava:
				if r.position.x - p.x < 110 and r.end.x > p.x:
					need = true
			if need and g.grounded:
				g.press(Vector2.ZERO)
			elif not g.grounded and g.vy > 120 and g._ground_at(p.x + 40) == INF and g.jumps < 2:
				g.press(Vector2.ZERO)
			stuck += dt
			if g.cp != step:
				step = g.cp
				stuck = 0.0
			if stuck > 25.0 and step + 1 < g.flags.size():
				g.pos = g.flags[step + 1] + Vector2(10, 0)
				stuck = 0.0
		7:
			if g.locked:
				return
			if g.mode == "walk" and g.me.distance_to(g.me_target) < 1.0 and tmr > 0.3:
				tmr = 0.0
				g.press(Vector2(randf_range(200, 1000), randf_range(260, 600)))
			elif g.mode == "battle" and g.menu == "main" and tmr > 0.3:
				tmr = 0.0
				if g.foe.kind == "chumbmon" or g.foe_hp < 0.7:
					_btn("ball")
				else:
					_btn("fight")
			elif g.mode == "battle" and g.menu == "moves" and tmr > 0.3:
				tmr = 0.0
				_btn("m1")
		8:
			if not g.playing:
				return
			if g.phase == "hide":
				for gg in g.guests:
					if not gg.found:
						g.light = gg.pos
						g.mouse = gg.pos
						break
			elif g.phase == "extra":
				for e in g.extras:
					if not e.gone:
						g.light = e.pos
						g.mouse = e.pos
						break
		9:
			if g.phase == "cute" or g.phase == "dark":
				var now: float = Audio.song_pos
				for k in g.chart.size():
					if not g.hits.has(k) and absf(float(g.chart[k][0]) - now) < 0.05:
						g.press(Vector2.ZERO)
						break
			elif g.phase == "candles" and tmr > 0.4 and not g.locked:
				tmr = 0.0
				for c in g.candles:
					if c.lit:
						g.press(Vector2(c.x, 400))
						break
			if g.phase == "wish" or Game.main.current != g:
				pass
