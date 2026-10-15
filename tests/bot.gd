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
	if which == "rockoshots":
		await _rocko_shots()
		get_tree().quit()
		return
	if which == "rocko":
		await _rocko()
		print("BOT RESULTS ", results)
		get_tree().quit()
		return
	if which == "sheepfence":
		await _sheep_fence()
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
	var limit := 12500 if profile else (400000 if realtime else 150000)
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


## Party room music with a forced 450 ms freeze every 3 seconds: the lyric clock must stay
## on the real playback position.
func _sync_probe() -> void:
	Game.done.fill(false)
	Game.hub_lines_heard = 99
	Game.main._open("hub", null)
	var t0 := Time.get_ticks_msec()
	var worst := 0.0
	while Time.get_ticks_msec() - t0 < 30000:
		await get_tree().create_timer(3.0).timeout
		OS.delay_msec(450)
		# compare within the same frame, after Audio has updated its clock
		await get_tree().process_frame
		await RenderingServer.frame_pre_draw
		var real: float = Audio._audio_pos()
		var err: float = Audio.song_pos - real
		worst = maxf(worst, absf(err))
		print("SYNC song_pos=%.3f audio=%.3f diff=%.3f" % [Audio.song_pos, real, err])
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


## Sheep pinned against the pen fence (above and below the gate) with the puppy pushing
## them straight at it: they should still find the gate.
func _sheep_fence() -> void:
	Game.main._open("game", 1)
	var sg: Node = Game.main.current
	await get_tree().process_frame
	for k in 4:
		var t0 := Time.get_ticks_msec()
		while sg.sheep.size() == 0 or not sg.playing:
			_skip_narration()
			await get_tree().process_frame
		var spots := [Vector2(970, 250), Vector2(970, 290), Vector2(970, 480), Vector2(970, 520), Vector2(965, 300)]
		for j in sg.sheep.size():
			var sh: Dictionary = sg.sheep[j]
			sh.pos = spots[j % spots.size()]
			sh.vel = Vector2.ZERO
		var stuck_t := 0.0
		var start_home: int = sg.penned
		while stuck_t < 20.0 and sg.penned < sg.sheep.size():
			await get_tree().process_frame
			stuck_t += get_process_delta_time()
			_skip_narration()
			# puppy pushes the nearest free sheep straight east (at the fence)
			var tgt: Dictionary = {}
			for sh in sg.sheep:
				if not sh.home:
					tgt = sh
					break
			if tgt.is_empty():
				break
			sg.dog_moving = true
			sg.dog_target = tgt.pos + Vector2(-70, 0)
		var left: Array = []
		for sh in sg.sheep:
			if not sh.home:
				left.append(Vector2i(sh.pos))
		print("SHEEPFENCE round ", k, " home=", sg.penned, "/", sg.sheep.size(), " in ", snappedf(stuck_t, 0.1), "s game time; still out at ", left)
		if sg.penned < sg.sheep.size():
			for sh in sg.sheep:
				if not sh.home:
					sh.pos = Vector2(sg.PEN.position.x - 6, (sg.GATE_Y0 + sg.GATE_Y1) * 0.5)
					sh.vel = Vector2(400, 0)
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(sg) or sg.round_i >= 3 and not sg.playing:
			break


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
		9:
			return "phase=%s song_pos=%.3f audio=%.3f score=%d" % [g.phase, Audio.song_pos, Audio._audio_pos(), g.score]
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
