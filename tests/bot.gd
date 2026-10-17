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
var profile := false
var shot_dir := ""
var shot_every := 0
var realtime := false


func _ready() -> void:
	for a in Game.main._args():
		if a.begins_with("--bot="):
			which = a.substr(6)
		elif a.begins_with("--shots="):
			shot_dir = a.substr(8)
			DirAccess.make_dir_recursive_absolute(shot_dir)
		elif a == "--profile" or a == "--profile=":
			profile = true
		elif a == "--realtime" or a == "--realtime=":
			realtime = true
			Perf.enabled = true
		elif a.begins_with("--every="):
			shot_every = int(a.substr(8))
	Engine.time_scale = 1.0 if profile or realtime else 4.0
	await get_tree().create_timer(0.5).timeout
	if profile:
		Perf.enabled = true
		for scr in ["title", "name", "intro"]:
			Game.main._open(scr, null)
			await get_tree().create_timer(4.2).timeout
			print("PROFILED ", scr, " -> ", Perf.last)
		for prog in [0, 9]:
			Game.done.fill(false)
			for k in prog:
				Game.done[k] = true
			Game.main._open("hub", null)
			await get_tree().create_timer(4.2).timeout
			print("PROFILED hub", prog, " -> ", Perf.last)
	# voice-key sanity check
	var k: String = Narrator.key_for("Hi there! Welcome to the party! What's your name?", 0)
	print("VOICE KEY ", k, " exists=", ResourceLoader.exists("res://assets/voice/%s.ogg" % k))
	var idxs: Array = []
	if which == "all":
		idxs = range(10)
	elif which != "name":
		idxs = [int(which)]
	if which == "syncprobe":
		await _sync_probe()
		get_tree().quit()
		return
	if which == "finale":
		# the credits scene with the whole cast (one mascot from each present)
		Game.main._open("finale", null)
		var f: Node = Game.main.current
		var t0 := Time.get_ticks_msec()
		while is_instance_valid(f) and not f.cheer and Time.get_ticks_msec() - t0 < 60000:
			await get_tree().process_frame
			_skip_narration()
		await get_tree().create_timer(1.0).timeout
		await _snap("finale_cast")
		print("FINALE cheer=", is_instance_valid(f) and f.cheer)
		# the credits roll with the song's lyrics, then "back to the party" starts the secret game
		while is_instance_valid(f) and f.get_button("back").is_empty() and Time.get_ticks_msec() - t0 < 90000:
			await get_tree().process_frame
		# wait for a sung line to be part-way through, so the lyric bar is on screen
		var t2 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t2 < 40000 and (Audio.lyric_state().is_empty() or Audio.lyric_state().sung < 3 or Time.get_ticks_msec() - t2 < 6000):
			await get_tree().process_frame
		await _snap("finale_credits")
		var ls := Audio.lyric_state()
		print("FINALE credits=", is_instance_valid(f) and f.credits, " lyrics_y=", f.lyrics_y if is_instance_valid(f) else -1.0, " line=", " ".join(ls.get("parts", PackedStringArray())))
		g = f
		_btn("back")
		var t1 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t1 < 10000 and (Game.main.current == f or Game.main.current == null):
			await get_tree().process_frame
		await get_tree().create_timer(2.0).timeout
		await _snap("finale_secret")
		var cur: Node = Game.main.current
		print("FINALE secret=", cur != null and cur.get_script() != null and String(cur.get_script().resource_path).ends_with("rocko.gd"))
		get_tree().quit()
		return
	if which == "rockoshots":
		await _rocko_shots()
		get_tree().quit()
		return
	if which == "rocko":
		await _rocko()
		print("BOT RESULTS ", results)
		get_tree().quit()
		return
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
	var limit := 12500 if profile else (600000 if realtime else 420000)
	while Time.get_ticks_msec() - t0 < limit:
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
	if profile:
		print("PROFILED game", i, " ", Game.GAMES[i].id, " -> ", Perf.last)
	var ok: bool = Game.done[i]
	results[Game.GAMES[i].id] = ok
	print("BOT GAME ", i, " ", Game.GAMES[i].id, " done=", ok, " in ", (Time.get_ticks_msec() - t0) / 1000.0, "s")
	await get_tree().create_timer(1.0).timeout


## The secret game: close the phone, pet Rocko, survive the chase, knock on the door.
func _rocko() -> void:
	Game.finale_seen = true
	Game.secret_done = false
	Game.main._open("rocko", null)
	g = Game.main.current
	var t0 := Time.get_ticks_msec()
	var last_gap := 3
	var hits := 0
	var shots := {}
	tmr = 0.0
	while is_instance_valid(g) and not g.finished and Time.get_ticks_msec() - t0 < 400000:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		tmr += dt
		_skip_narration()
		var ph: String = g.phase
		var key := ph
		if ph == "chase":
			key = "chase%d" % int(g.dist / 12.0)
		elif ph == "turn" and g.demon > 0.9:
			key = "turn_demon"
		if not shots.has(key):
			shots[key] = Time.get_ticks_msec()
		elif shots[key] > 0 and Time.get_ticks_msec() - shots[key] > 900:
			shots[key] = -1
			await _snap("rocko_" + key)
		if shot_dir != "" and shots.get(key, 0) != -1 and not ph.begins_with("chase"):
			continue
		match ph:
			"phone":
				if not g.locked:
					g.press(g._x_rect().get_center())
			"pets":
				if not g.locked and tmr > 0.35:
					tmr = 0.0
					g.press(g._cat_rect().get_center())
			"chase", "chase_intro":
				_dodge()
			"knock":
				if not g.locked:
					g.press(g._house_door().get_center())
		if g.gap < last_gap:
			hits += 1
		last_gap = g.gap
		if Engine.get_process_frames() % 300 == 0:
			print("  dbg rocko phase=", ph, " dist=", snappedf(g.dist, 0.1), " gap=", g.gap, " lane=", g.lane, " obstacles=", g.obstacles.size())
	results["rocko"] = Game.secret_done
	print("ROCKO hits=", hits, " secret_done=", Game.secret_done, " in ", (Time.get_ticks_msec() - t0) / 1000.0, "s")
	if is_instance_valid(g):
		await get_tree().create_timer(1.0).timeout
		await _snap("rocko_done")


## What the speakers are really playing, from outside the game's own clock: in the browser
## the test page records when each song really started in the Web Audio engine
## (window.__truth, see the web test scripts); natively Godot's playback position is exact.
func _truth() -> float:
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("window.__truth ? window.__truth() : -1", true)
		return float(v) if v != null else -1.0
	return Audio._cur.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()


## Music in the party room and then karaoke, with a forced 450 ms freeze every 3 seconds:
## the lyric/note clock must stay on what is really playing.
func _sync_probe() -> void:
	Engine.time_scale = 1.0
	Game.done.fill(false)
	Game.hub_lines_heard = 99
	var worst := 0.0
	for scr in ["hub", "karaoke"]:
		if scr == "hub":
			Game.main._open("hub", null)
		else:
			Game.main._open("game", 9)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 30000:
			await get_tree().create_timer(3.0).timeout
			_skip_narration()
			OS.delay_msec(450)
			await get_tree().process_frame
			# compare at the same moment: bring the game's clock up to date first
			Audio._process(0.0)
			var real := _truth()
			if real < 0.0 or Audio.song == "":
				continue
			var err: float = Audio.song_pos - real
			worst = maxf(worst, absf(err))
			print("SYNC %s %s song_pos=%.3f really_playing=%.3f diff=%+.3f" % [scr, Audio.song, Audio.song_pos, real, err])
	print("SYNC worst diff=%.3f" % worst)


## Still pictures of the secret game's big moments (for checking the drawings).
func _rocko_shots() -> void:
	Game.main._open("rocko", null)
	g = Game.main.current
	await get_tree().create_timer(1.0).timeout
	Narrator.cancel()
	g.phase = "phone"
	g.phone_k = 1.0
	await get_tree().create_timer(0.5).timeout
	await _snap("rs_phone")
	g.phone_k = 0.0
	g.phase = "cat"
	g.cat_pos = Vector2(930, 560)
	g.cat_pose = "walk"
	g.bubble = "Meow!"
	g.bubble_t = 5.0
	await get_tree().create_timer(0.4).timeout
	await _snap("rs_walk")
	g.phase = "pets"
	g.cat_pos = g.CAT_SEAT
	g.cat_pose = "sit"
	g.bubble_t = 0.0
	await get_tree().create_timer(0.4).timeout
	await _snap("rs_pets")
	g.phase = "turn"
	g.cat_pos = g.CAT_SEAT
	g.cat_pose = "sit"
	g.demon = 1.0
	g.grow = 2.1
	g.lamp = 0.2
	g.me_mood = "o"
	await get_tree().create_timer(0.5).timeout
	await _snap("rs_demon")
	g.bubble = ""
	g._start_chase()
	g.phase = "chase"
	g.dist = 30.0
	g.party_tile = 0
	g.gap = 1
	await get_tree().create_timer(2.0).timeout
	await _snap("rs_chase_close")
	Game.done.fill(true)
	Game.finale_seen = true
	Game.hub_lines_heard = 11
	for sd in [false, true]:
		Game.secret_done = sd
		Game.main._open("hub", null)
		await get_tree().create_timer(1.5).timeout
		await _snap("rs_hub_secret%d" % int(sd))


func _dodge() -> void:
	var danger := [false, false, false]
	for o in g.obstacles:
		if o.hit:
			continue
		var dx: float = float(o.x) - g.ME_X
		if dx > -55.0 and dx < 240.0:
			danger[int(o.lane)] = true
	for th in g.throws:
		danger[int(th.lane)] = true
	if not danger[g.lane]:
		return
	for d in [-1, 1]:
		var nl: int = g.lane + d
		if nl >= 0 and nl <= 2 and not danger[nl]:
			g._move(d)
			return
	for d in [-2, 2]:
		var nl: int = g.lane + d
		if nl >= 0 and nl <= 2 and not danger[nl]:
			g._move(signi(d))
			return


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


var _bots := {}


## Games with their own autopilot in tests/bots/<id>.gd (drive(bot, game, dt), optional dbg(game)).
func _game_bot(i: int) -> Object:
	var id: String = Game.GAMES[i].id
	if not _bots.has(id):
		var p := "res://tests/bots/%s.gd" % id
		_bots[id] = load(p).new() if ResourceLoader.exists(p) else null
	return _bots[id]


func _dbg(i: int) -> String:
	var b := _game_bot(i)
	if b != null:
		return b.dbg(g) if b.has_method("dbg") else ""
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
	var bot := _game_bot(i)
	if bot != null:
		bot.drive(self, g, dt)
		return
	match i:
		3:
			if not g.busy and g.i >= 0 and g.i < g.cards.size() and not g.locked:
				_btn("yay" if g.cards[g.i].ok else "nope")
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
