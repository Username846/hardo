extends Screen
## Present 1: KNEAD FOR SPEED: UNDERGROUND (street racing). Trick out the cake car in the
## garage, win a sprint down Birthday Boulevard and a drag race against Turbo Granny, then
## three laps of the midnight circuit. Three laps. Or four. Or five...

const IDX := 0
# pseudo-3D road: the track is a list of short segments, each with a curve amount;
# segments are projected from the camera and drawn as flat strips (far ones are tiny).
const HZ := 300.0
const SEG_L := 200.0
const ROAD_W := 1000.0
const CAM_H := 1000.0
const DEPTH := 0.84
const Y_K := 350.0
const DRAW_N := 80
const MAX_SPEED := 12000.0
const ACCEL := 2600.0
const DECEL := 7000.0
const PLAYER_OFF := 840.0
const CAR_Y := 652.0
const CAM_FOLLOW := 0.4
const X_PX := 384.0
const CENT := 0.09
const LANES := [-0.66, 0.0, 0.66]
const SPRINT_SEGS := 3000
const SPRINT_FINISH := 2860
const START_SEG := 14
const LAP_SEGS := 850
const LINE_SEG := 8
const DRAG_SEGS := 1000
const DRAG_FINISH := 1000
const LAPS_SHOWN := 3
const LAPS_REAL := 6
const GEAR_TOP := [0.0, 3200.0, 5600.0, 8200.0, 10800.0, 13600.0]
const GEAR_ACC := [0.0, 2000.0, 1900.0, 1700.0, 1400.0, 1100.0]
const GREEN_LO := 0.72
const GREEN_HI := 0.94
const GLOWS := {"PINK": Color(1.0, 0.35, 0.75), "GREEN": Color(0.3, 1.0, 0.5), "BLUE": Color(0.3, 0.75, 1.0), "PURPLE": Color(0.72, 0.42, 1.0)}
const VINYLS := ["FLAMES", "STARS", "SPRINKLES"]
const BODY := Color(0.98, 0.55, 0.72)
const GOLD := Color(1.0, 0.8, 0.22)
## La Cucaracha on the horn (pitch, beats)
const HORN_TUNE := [[1.0, 0.5], [1.0, 0.5], [1.0, 0.5], [1.335, 1.0], [1.682, 1.0], [1.0, 0.5], [1.0, 0.5], [1.0, 0.5], [1.335, 1.0], [1.682, 1.5]]
const RIVALS := [["Sir Sprinkles", "rival0"], ["xX_FrostBite_Xx", "rival1"], ["Lil Cupcake", "rival2"]]
const CELL := 320.0
const ATLAS_COLS := 8
## sprite: [atlas cell, width px, height px, width in road units (the road is 2000 wide)]
const SPR := {
	"lamp": [0, 140, 310, 440.0], "sign_bday": [1, 300, 232, 1500.0], "sign_cake": [2, 300, 232, 1500.0],
	"sign_sprinkle": [3, 300, 232, 1500.0], "sign_nos": [4, 300, 232, 1500.0], "sign_party": [5, 300, 232, 1500.0],
	"house": [6, 310, 290, 2600.0], "tree": [7, 240, 300, 1100.0], "balloons": [8, 170, 300, 560.0],
	"candle": [9, 140, 310, 440.0], "car0": [10, 300, 230, 560.0], "car1": [11, 300, 230, 560.0],
	"car2": [12, 300, 230, 560.0], "car3": [13, 300, 230, 560.0], "car_dark": [14, 300, 230, 560.0],
	"rival0": [15, 300, 230, 560.0], "rival1": [16, 300, 230, 560.0], "rival2": [17, 300, 230, 560.0],
	"granny": [18, 300, 270, 580.0], "limo": [19, 312, 270, 680.0], "banner_finish": [20, 318, 250, 2400.0],
	"banner_start": [21, 318, 250, 2400.0],
}
const SIGNS := ["sign_bday", "sign_cake", "sign_sprinkle", "sign_nos"]

var phase := "intro"     # intro garage grid count race drag circuit coast end
var mode := ""           # sprint, drag, circuit
var sky_mode := "garage" # garage sunset dusk night midnight doom
var glow: Color = GLOWS["GREEN"]
var vinyl := "FLAMES"
var garage_done := false
# (honk the car in the garage enough and it gets a secret paint job)
var car_col := BODY
var horn_taps := 0
var hop := 0.0

# the track
var curves := PackedFloat32Array()
var looped := false
var deco := {}
var lane_marks: Array = [-0.333, 0.333]
var line_segs: Array = []

# the race
var player_z := 0.0
var player_x := 0.0
var steer_x := 640.0
var speed := 0.0
var nitro := 0.34
var nitro_t := 0.0
var hit_t := 0.0
var offroad := false
var rivals: Array = []
var traffic: Array = []
var race_t := 0.0
var race_over := false
var count_t := 0.0
var place := 0
var lap := 0
var dark_laps := false
var ghost := {}
var beside_t := 0.0
var ahead_t := 0.0
var sky_off := 0.0
var pops: Array = []
var said := {}
var draft_t := 0.0
var near_misses := 0
var flash := 0.0
var end_k := 0.0
var lap_t := 0.0
var finish_word := "FINISH"

# drag race
var gear := 1
var rpm := 0.0
var perfects := 0
var won_drag := false
var limiter := 0.0

var _last_mouse := Vector2(-1, -1)
var _keys := 0.0
var _atlas: SubViewport = null
var _atlas_tex: Texture2D = null
var _skyv: SubViewport = null
var _sky_node: Node2D = null
var _sky_tex: Texture2D = null
var _ps := PackedFloat32Array()
var _py := PackedFloat32Array()
var _px := PackedFloat32Array()
var _pw := PackedFloat32Array()
var _pxo := PackedFloat32Array()
var _baked_sky := ""
var _sky_drawn := ""


func enter() -> void:
	Narrator.top = true
	lyrics_y = 34.0
	_ps.resize(DRAW_N + 1)
	_py.resize(DRAW_N + 1)
	_px.resize(DRAW_N + 1)
	_pw.resize(DRAW_N + 1)
	_pxo.resize(DRAW_N + 1)
	use_back_layer()
	_make_atlas()
	_make_skyline()
	_make_buttons()
	_show_buttons([])
	Audio.play_music("race")
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await say("Present number one! It's KNEAD FOR SPEED: UNDERGROUND! Street racing on Birthday Boulevard!")
	phase = "garage"
	_show_buttons(["g_pink", "g_green", "g_blue", "g_purple", "v_flames", "v_stars", "v_sprinkles", "go"])
	await say("First, the garage! Pick a glow and a sticker for your race car. Then tap RACE!")
	locked = false
	while not garage_done:
		await wait(0.1)
	_show_buttons([])
	await _sprint()
	await _drag()
	await _circuit()
	await _ending()


# ------------------------------------------------------------------ the garage


func _make_buttons() -> void:
	var i := 0
	for k in GLOWS:
		var nm: String = k
		add_button("g_" + nm.to_lower(), Rect2(50, 214 + i * 84, 210, 68), nm, _pick_glow.bind(nm), GLOWS[nm], 30)
		i += 1
	i = 0
	for v in VINYLS:
		var nm: String = v
		add_button("v_" + nm.to_lower(), Rect2(1020, 214 + i * 84, 210, 68), nm, _pick_vinyl.bind(nm), Crayon.WHITE, 28)
		i += 1
	add_button("go", Rect2(490, 618, 300, 86), "RACE!", _garage_go, Crayon.RED, 46)
	add_button("nos", Rect2(1078, 552, 184, 116), "NITRO", _nitro, Crayon.ORANGE, 38)
	add_button("shift", Rect2(986, 506, 266, 160), "SHIFT!", _shift, Crayon.GREEN, 54)


func _show_buttons(ids: Array) -> void:
	for b in buttons:
		b.visible = b.id == "home" or b.id in ids


func _pick_glow(nm: String) -> void:
	glow = GLOWS[nm]
	Audio.sfx("sparkle", -6)


func _pick_vinyl(nm: String) -> void:
	vinyl = nm
	Audio.sfx("scribble", -6)


func _garage_go() -> void:
	if garage_done:
		return
	garage_done = true
	Audio.sfx("rev")


# ------------------------------------------------------------------ the three races


func _sprint() -> void:
	locked = true
	mode = "sprint"
	_build_sprint()
	_set_sky("sunset")
	phase = "grid"
	await say("Race one! A sprint down Birthday Boulevard. Move left and right to steer, and tap NITRO to go super fast!")
	await _countdown()
	phase = "race"
	locked = false
	_show_buttons(["nos"])
	while not race_over:
		await wait(0.1)
	locked = true
	_show_buttons([])
	await wait(1.6)
	if place == 1:
		await say("FIRST PLACE! Chumbo is the fastest racer on Birthday Boulevard!", Narrator.HYPE)
	else:
		await say("You didn't come first... but it's your birthday, so the trophy is yours anyway!")


func _drag() -> void:
	mode = "drag"
	_build_drag()
	_set_sky("night")
	phase = "grid"
	await say("Race two! A drag race against Turbo Granny. No steering. When the needle is in the green, tap SHIFT!")
	_show_buttons(["shift"])
	await _countdown()
	phase = "drag"
	locked = false
	while not race_over:
		await wait(0.1)
	locked = true
	_show_buttons([])
	await wait(1.6)
	if won_drag:
		await say("You beat Turbo Granny! She says happy birthday, and she wants a rematch next year.")
	else:
		await say("Turbo Granny won! She's one hundred and two. She says you can keep the trophy anyway.")


func _circuit() -> void:
	mode = "circuit"
	_build_circuit()
	_set_sky("midnight")
	phase = "grid"
	await say("Last race! Three laps of the midnight circuit, against the B-DAY BOSS. Nobody has ever beaten him.", Narrator.HYPE)
	await _countdown()
	phase = "circuit"
	locked = false
	_show_buttons(["nos"])
	while not race_over:
		await wait(0.1)
	_show_buttons([])
	locked = true


func _ending() -> void:
	phase = "coast"
	await wait(3.0)
	phase = "end"
	flash = 1.0
	Audio.sfx("cheer", -4)
	Audio.sfx("tada")
	for i in 4:
		confetti_burst(Vector2(250 + i * 260, 240), 40)
	await wait(0.8)
	await say("You crossed the finish line. Look. It's the start line. It was always the start line.", Narrator.DARK)
	Audio.play_music("race", 1.5)
	await say("And the party is right here, where you left it! Everyone waited for you. Present number one, done!")
	finish_game(IDX, "RACE DONE!")


func _countdown() -> void:
	phase = "count"
	count_t = 3.99
	Audio.sfx("rev", -4)
	for i in 3:
		Audio.sfx("ding", -6, 0.8)
		await wait(1.0)
	Audio.sfx("horn", -2)
	race_t = 0.0
	race_over = false


# ------------------------------------------------------------------ building tracks


func _reset_track() -> void:
	curves = PackedFloat32Array()
	deco = {}
	rivals = []
	traffic = []
	ghost = {}
	pops = []
	line_segs = []
	speed = 0.0
	player_x = 0.0
	steer_x = 640.0
	nitro = maxf(nitro, 0.34)
	nitro_t = 0.0
	hit_t = 0.0
	race_over = false
	race_t = 0.0
	place = 0


func _road(enter_n: int, hold: int, leave: int, curve: float) -> void:
	for i in enter_n:
		curves.append(curve * pow(float(i) / enter_n, 2.0))
	for i in hold:
		curves.append(curve)
	for i in leave:
		var f := float(i) / leave
		curves.append(curve * (1.0 - (3.0 * f * f - 2.0 * f * f * f)))


func _deco(seg: int, spr: String, x: float) -> void:
	if not deco.has(seg):
		deco[seg] = []
	deco[seg].append([spr, x])


func _build_sprint() -> void:
	_reset_track()
	looped = false
	lane_marks = [-0.333, 0.333]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1515
	_road(0, 70, 0, 0.0)
	var dirs := [3.0, -2.5, 4.0, -3.5, 2.0, -4.0, 3.0, 2.5, -3.0, 4.5, -2.0, -3.5, 3.5]
	var k := 0
	while curves.size() < SPRINT_SEGS - 260:
		_road(rng.randi_range(25, 40), rng.randi_range(50, 120), rng.randi_range(25, 40), dirs[k % dirs.size()])
		_road(0, rng.randi_range(30, 80), 0, 0.0)
		k += 1
	while curves.size() < SPRINT_SEGS:
		curves.append(0.0)
	for s in range(0, SPRINT_SEGS, 8):
		_deco(s, "lamp", -1.28 if (s / 8) % 2 == 0 else 1.28)
	for s in range(4, SPRINT_SEGS, 22):
		_deco(s, "tree", (1.9 + rng.randf() * 1.2) * (1.0 if s % 44 == 4 else -1.0))
	for s in range(40, SPRINT_SEGS, 130):
		_deco(s, SIGNS[(s / 130) % SIGNS.size()], 2.15 if (s / 130) % 2 == 0 else -2.15)
	for s in range(90, SPRINT_SEGS, 210):
		_deco(s, "house", -2.9 if (s / 210) % 2 == 0 else 2.9)
	for s in range(60, SPRINT_SEGS, 70):
		_deco(s, "balloons", 1.65 if (s / 70) % 2 == 0 else -1.65)
	_deco(START_SEG, "banner_start", 0.0)
	_deco(SPRINT_FINISH, "banner_finish", 0.0)
	line_segs = [START_SEG, SPRINT_FINISH]
	player_z = START_SEG * SEG_L - 220.0
	for i in 3:
		var lx: float = [-0.66, 0.66, 0.0][i]
		rivals.append({"z": player_z + 320.0 + i * 330.0, "x": lx, "lane": lx, "speed": 0.0, "base": [0.86, 0.84, 0.82][i],
			"name": RIVALS[i][0], "spr": RIVALS[i][1], "done_t": -1.0, "wrap": false})
	for i in 4:
		traffic.append(_new_traffic(player_z + 9000.0 + i * 6000.0 + rng.randf() * 2000.0, rng))


func _new_traffic(z: float, rng: RandomNumberGenerator = null) -> Dictionary:
	var r := rng if rng else RandomNumberGenerator.new()
	return {"z": z, "x": LANES[r.randi() % 3], "speed": MAX_SPEED * r.randf_range(0.32, 0.46),
		"spr": "car%d" % (r.randi() % 4), "wrap": looped, "prev": 99999.0, "hit": false}


func _build_drag() -> void:
	_reset_track()
	looped = false
	lane_marks = [0.0]
	_road(0, DRAG_SEGS + 200, 0, 0.0)
	for s in range(0, DRAG_SEGS + 200, 6):
		_deco(s, "lamp", -1.28)
		_deco(s + 3, "lamp", 1.28)
	for s in range(30, DRAG_SEGS + 200, 90):
		_deco(s, SIGNS[(s / 90) % SIGNS.size()], 2.2 if (s / 90) % 2 == 0 else -2.2)
	for s in range(60, DRAG_SEGS + 200, 150):
		_deco(s, "house", 3.0 if (s / 150) % 2 == 0 else -3.0)
	_deco(START_SEG, "banner_start", 0.0)
	_deco(START_SEG + DRAG_FINISH, "banner_finish", 0.0)
	line_segs = [START_SEG, START_SEG + DRAG_FINISH]
	player_z = START_SEG * SEG_L - 220.0
	player_x = -0.45
	gear = 1
	rpm = 0.0
	perfects = 0
	limiter = 0.0
	rivals.append({"z": player_z, "x": 0.45, "lane": 0.45, "speed": 0.0, "base": 0.95, "name": "Turbo Granny", "spr": "granny",
		"done_t": -1.0, "wrap": false})


func _build_circuit() -> void:
	_reset_track()
	looped = true
	lane_marks = [-0.333, 0.333]
	_road(0, 60, 0, 0.0)
	_road(30, 80, 30, 3.0)
	_road(0, 50, 0, 0.0)
	_road(30, 60, 30, -4.0)
	_road(0, 40, 0, 0.0)
	_road(25, 40, 25, 2.5)
	_road(25, 40, 25, -2.5)
	_road(40, 100, 40, 4.5)
	_road(0, 60, 0, 0.0)
	_road(30, 60, 30, -3.0)
	while curves.size() < LAP_SEGS:
		curves.append(0.0)
	curves.resize(LAP_SEGS)
	for s in range(0, LAP_SEGS, 8):
		_deco(s, "lamp", -1.28 if (s / 8) % 2 == 0 else 1.28)
	for s in range(20, LAP_SEGS, 26):
		_deco(s, "tree", 2.1 if (s / 26) % 2 == 0 else -2.3)
	for s in range(50, LAP_SEGS, 110):
		_deco(s, SIGNS[(s / 110) % SIGNS.size()], -2.15 if (s / 110) % 2 == 0 else 2.15)
	for s in range(100, LAP_SEGS, 95):
		_deco(s, "balloons", 1.65 if (s / 95) % 2 == 0 else -1.65)
	_deco(LINE_SEG + 3, "house", 2.7)
	_deco(LINE_SEG, "banner_finish", 0.0)
	line_segs = [LINE_SEG]
	player_z = LINE_SEG * SEG_L - 220.0
	player_x = -0.4
	steer_x = 640.0 + player_x * X_PX
	lap = 0
	lap_t = 0.0
	dark_laps = false
	finish_word = "FINISH"
	rivals.append({"z": player_z + 400.0, "x": 0.45, "lane": 0.45, "speed": 0.0, "base": 0.9, "name": "B-DAY BOSS", "spr": "limo",
		"done_t": -1.0, "wrap": false})
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 6:
		traffic.append(_new_traffic(fposmod(player_z + 12000.0 + i * _lap_len() / 6.0, _lap_len()), rng))


func _lap_len() -> float:
	return LAP_SEGS * SEG_L


func _curve(s: int) -> float:
	var n := curves.size()
	if n == 0:
		return 0.0
	if looped:
		return curves[posmod(s, n)]
	return curves[s] if s >= 0 and s < n else 0.0


func _seg_of(z: float) -> int:
	var s := floori(z / SEG_L)
	return posmod(s, LAP_SEGS) if looped else s


## Distance of something at z in front of the player (wraps around on the circuit).
func _dz(c: Dictionary) -> float:
	var d: float = float(c.z) - player_z
	if c.get("wrap", false):
		var L := _lap_len()
		d = fposmod(d + L * 0.5, L) - L * 0.5
	return d


func _lap_now() -> int:
	return floori((player_z - LINE_SEG * SEG_L) / _lap_len()) + 1


# ------------------------------------------------------------------ input


func press(p: Vector2) -> void:
	match phase:
		"garage":
			if not locked and Rect2(410, 400, 470, 200).has_point(p):
				_honk()
		"race", "circuit", "count", "grid":
			steer_x = p.x
		"drag":
			_shift()


func _honk() -> void:
	horn_taps += 1
	hop = 1.0
	Audio.sfx("horn", -8, 1.0 + randf_range(-0.04, 0.04))
	if horn_taps == 5:
		_golden()


## The golden birthday cake car: a horn tune, gold paint for the rest of the races.
func _golden() -> void:
	car_col = GOLD
	Game.found_egg("race")
	flash = 0.6
	Audio.sfx("sparkle", -2)
	Audio.sfx("levelup", -6)
	confetti_burst(Vector2(640, 470), 60)
	say_bg("Secret paint job! The golden birthday cake car!", Narrator.HYPE)
	await wait(0.6)
	for n in HORN_TUNE:
		hop = 0.6
		Audio.sfx("horn", -6, n[0])
		await wait(n[1] * 0.22)


func drag(p: Vector2) -> void:
	if phase in ["race", "circuit", "count", "grid"] and not _over_button(p):
		steer_x = p.x


func _over_button(p: Vector2) -> bool:
	for b in buttons:
		if b.visible and b.rect.grow(12).has_point(p):
			return true
	return false


func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	if e.keycode in [KEY_SPACE, KEY_UP, KEY_W, KEY_ENTER]:
		if phase == "drag":
			_shift()
		elif phase in ["race", "circuit"]:
			_nitro()


func _nitro() -> void:
	if not (phase in ["race", "circuit"]) or nitro < 0.33 or nitro_t > 0.0:
		if nitro < 0.33 and phase in ["race", "circuit"]:
			_pop("NO NITRO YET!", Crayon.GREY)
		return
	nitro -= 0.33
	nitro_t = 2.6
	Audio.sfx("nitro", -2)
	_pop("NITRO!", Crayon.ORANGE)


func _shift() -> void:
	if phase != "drag" or race_over:
		return
	if gear >= 5:
		return
	var r := rpm
	gear += 1
	Audio.sfx("shift", -2)
	if r >= GREEN_LO and r <= GREEN_HI:
		perfects += 1
		speed *= 1.05
		Audio.sfx("ding", -6)
		_pop("PERFECT SHIFT!", Crayon.GREEN)
	elif r > GREEN_HI:
		_pop("LATE SHIFT", Crayon.ORANGE)
	elif r >= 0.6:
		_pop("GOOD SHIFT", Crayon.YELLOW)
	else:
		speed *= 0.97
		_pop("TOO EARLY!", Crayon.RED)
		if not said.has("early"):
			said["early"] = true
			say_bg("Too early! Wait until the needle is in the green part.")


func _pop(txt: String, col: Color) -> void:
	pops.append({"txt": txt, "t": 1.3, "col": col})
	if pops.size() > 3:
		pops.pop_front()


# ------------------------------------------------------------------ update


func tick(dt: float) -> void:
	flash = maxf(0.0, flash - dt * 1.2)
	hop = maxf(0.0, hop - dt * 4.0)
	for p in pops:
		p.t -= dt
	pops = pops.filter(func(p: Dictionary) -> bool: return p.t > 0.0)
	count_t = maxf(0.0, count_t - dt)
	if phase == "end":
		end_k = minf(1.0, end_k + dt * 0.8)
		return
	_read_pointer(dt)
	match phase:
		"race", "circuit":
			_drive(dt)
		"drag":
			_drive_drag(dt)
		"coast":
			speed = move_toward(speed, 0.0, MAX_SPEED * 0.45 * dt)
			player_x = move_toward(player_x, 0.0, dt * 0.4)
			nitro_t = 0.0
			player_z += speed * dt
			_move_others(dt)
		"grid", "count":
			_move_others(0.0)
	if sky_mode != _baked_sky:
		refresh_back()
	Crayon.shake = 1.0 + (0.7 if dark_laps else 0.0)


func _read_pointer(dt: float) -> void:
	# desktop: follow the mouse; phones: follow the last touch (both arrive as "mouse")
	if mouse != _last_mouse:
		_last_mouse = mouse
		if not _over_button(mouse) and phase in ["race", "circuit", "count", "grid"]:
			steer_x = mouse.x
	var k := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		k -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		k += 1.0
	if k != 0.0:
		steer_x = clampf(steer_x + k * 900.0 * dt, 640.0 - X_PX * 1.15, 640.0 + X_PX * 1.15)


func _drive(dt: float) -> void:
	race_t += dt
	var sp := speed / MAX_SPEED
	var target := clampf((steer_x - 640.0) / X_PX, -1.15, 1.15)
	player_x = move_toward(player_x, target, 2.7 * (0.35 + 0.65 * minf(sp, 1.0)) * dt)
	var cv := _curve(_seg_of(player_z))
	player_x = clampf(player_x - cv * sp * sp * CENT * dt, -1.35, 1.35)
	offroad = absf(player_x) > 1.05
	nitro_t = maxf(0.0, nitro_t - dt)
	hit_t = maxf(0.0, hit_t - dt)
	var top := MAX_SPEED * (1.35 if nitro_t > 0.0 else 1.0) * (0.45 if offroad else 1.0)
	if speed < top:
		speed = minf(top, speed + ACCEL * dt * (1.7 if nitro_t > 0.0 else 1.0))
	else:
		speed = maxf(top, speed - DECEL * dt)
	if offroad and speed > MAX_SPEED * 0.5 and not said.has("offroad"):
		said["offroad"] = true
		say_bg("Stay on the road, Chumbo! The grass is slow!")
	nitro = minf(1.0, nitro + dt * 0.022)
	player_z += speed * dt
	sky_off += cv * sp * dt * 70.0
	_move_others(dt)
	_check_traffic()
	if mode == "sprint":
		_sprint_events()
	else:
		_circuit_events(dt)


func _move_others(dt: float) -> void:
	var L := _lap_len()
	for c in traffic:
		c.z = float(c.z) + float(c.speed) * dt
		if looped:
			c.z = fposmod(float(c.z), L)
		elif _dz(c) < -2500.0:
			# passed it long ago: send it back up the road
			var nc := _new_traffic(player_z + randf_range(15000.0, 24000.0))
			for k in nc:
				c[k] = nc[k]
	for r in rivals:
		_rival_ai(r, dt)


func _rival_ai(r: Dictionary, dt: float) -> void:
	if dt <= 0.0:
		return
	var dz := float(r.z) - player_z
	var mul := 1.0
	if mode == "drag":
		# Turbo Granny floors it in a smooth line; she waits a little if you fall way behind
		mul = 0.9 if dz > 6000.0 else 1.0
		r.speed = minf(float(r.base) * MAX_SPEED * mul, float(r.speed) + 1700.0 * dt)
	else:
		if dz > 3000.0:
			mul = 0.88
		elif dz < -1500.0:
			mul = 1.12
		if mode == "circuit" and dark_laps:
			mul *= 1.05
		var want := float(r.base) * MAX_SPEED * mul
		if phase == "coast":
			want = 0.0
		r.speed = move_toward(float(r.speed), want, ACCEL * 0.85 * dt)
		# change lanes around slow traffic
		for c in traffic:
			var tz := float(c.z) - float(r.z)
			if looped:
				tz = fposmod(tz + _lap_len() * 0.5, _lap_len()) - _lap_len() * 0.5
			if tz > 0.0 and tz < 1600.0 and absf(float(c.x) - float(r.lane)) < 0.4:
				var opts: Array = LANES.filter(func(l: float) -> bool: return absf(l - float(c.x)) > 0.4)
				r.lane = opts[0] if absf(float(opts[0]) - float(r.x)) < absf(float(opts[-1]) - float(r.x)) else opts[-1]
				break
		r.x = move_toward(float(r.x), float(r.lane), 1.1 * dt)
	r.z = float(r.z) + float(r.speed) * dt
	if mode == "sprint" and float(r.done_t) < 0.0 and float(r.z) >= SPRINT_FINISH * SEG_L:
		r.done_t = race_t
	if mode == "drag" and float(r.done_t) < 0.0 and float(r.z) >= (START_SEG + DRAG_FINISH) * SEG_L:
		r.done_t = race_t


func _check_traffic() -> void:
	for c in traffic:
		var dz := _dz(c)
		var prev := float(c.prev)
		c.prev = dz
		if prev > 90000.0:
			continue
		var near := minf(prev, dz) < 260.0 and maxf(prev, dz) > -140.0
		var dx := absf(float(c.x) - player_x)
		if near and dx < 0.46 and hit_t <= 0.0:
			_crash(c)
		elif prev > 0.0 and dz <= 0.0 and dx < 0.85 and hit_t <= 0.0 and not c.hit:
			near_misses += 1
			nitro = minf(1.0, nitro + 0.12)
			_pop("NEAR MISS!", Crayon.YELLOW)
			Audio.sfx("whoosh", -6, 1.3)
			if not said.has("near"):
				said["near"] = true
				say_bg("Near miss! Zooming past cars fills up your nitro!")
		if dz < -500.0:
			c.hit = false
	for r in rivals:
		var dz := float(r.z) - player_z
		if absf(dz) < 240.0 and absf(float(r.x) - player_x) < 0.5 and hit_t <= 0.0:
			speed *= 0.88
			player_x += signf(player_x - float(r.x) + 0.001) * 0.18
			hit_t = 0.4
			Audio.sfx("thud", -6)
		elif dz > 250.0 and dz < 2000.0 and absf(float(r.x) - player_x) < 0.35:
			nitro = minf(1.0, nitro + 0.08 * get_process_delta_time())
			draft_t = 0.3
	draft_t = maxf(0.0, draft_t - get_process_delta_time())


func _crash(c: Dictionary) -> void:
	hit_t = 0.9
	c.hit = true
	speed *= 0.35
	nitro_t = 0.0
	player_x += signf(player_x - float(c.x) + 0.001) * 0.22
	c.z = float(c.z) + 300.0
	Audio.sfx("bonk", -2)
	Audio.sfx("screech", -6)
	_pop("BONK!", Crayon.RED)
	if not said.has("bonk"):
		said["bonk"] = true
		say_bg("Bonk! Those cars are going to the party too. Steer around them!")


func _place() -> int:
	var p := 1
	for r in rivals:
		if float(r.done_t) >= 0.0 or float(r.z) > player_z:
			p += 1
	return p


func _sprint_events() -> void:
	if race_t > 4.0 and not said.has("traffic"):
		said["traffic"] = true
		say_bg("Watch out for the party traffic! Zoom past them to fill your nitro!")
	if player_z >= SPRINT_FINISH * SEG_L * 0.5 and sky_mode == "sunset":
		_set_sky("dusk")
	if player_z >= SPRINT_FINISH * SEG_L and not race_over:
		place = _place()
		race_over = true
		phase = "coast"
		Audio.sfx("tada")
		_pop("1ST PLACE!" if place == 1 else ["", "", "2ND PLACE", "3RD PLACE", "4TH PLACE"][place], Crayon.YELLOW)


func _drive_drag(dt: float) -> void:
	race_t += dt
	var top: float = GEAR_TOP[gear]
	rpm = speed / top
	if rpm >= 1.0:
		speed = top
		limiter += dt
		rpm = 1.0 + sin(t * 40.0) * 0.015
	else:
		var torque := 0.55 + 0.45 * sin(clampf(rpm, 0.0, 1.0) * PI * 0.85 + 0.25)
		speed = minf(top, speed + float(GEAR_ACC[gear]) * torque * dt)
	player_z += speed * dt
	_move_others(dt)
	if player_z >= (START_SEG + DRAG_FINISH) * SEG_L and not race_over:
		race_over = true
		var g: Dictionary = rivals[0]
		won_drag = float(g.done_t) < 0.0
		phase = "coast"
		Audio.sfx("tada")
		_pop("YOU WIN!" if won_drag else "GRANNY WINS!", Crayon.YELLOW)


func _circuit_events(dt: float) -> void:
	var lp := _lap_now()
	lap_t += dt
	if lp != lap:
		lap = lp
		lap_t = 0.0
		_on_lap(lp)
	var into := fposmod(player_z - LINE_SEG * SEG_L, _lap_len()) / _lap_len()
	var boss: Dictionary = rivals[0]
	if dark_laps:
		# you can pass him, but he's always up ahead again
		if float(boss.z) < player_z - 300.0 and beside_t <= 0.0:
			ahead_t += dt
			if ahead_t > 1.6:
				ahead_t = 0.0
				boss.z = player_z + 3200.0
				boss.speed = speed
				Audio.sfx("glitch", -6)
				_pop("STILL AHEAD", Color(1, 0.3, 0.35))
		else:
			ahead_t = 0.0
		for c in traffic:
			c.spr = "car_dark"
	if lap == 4 and lap_t > 6.0 and not said.has("signs"):
		said["signs"] = true
		say_bg("Every sign says PARTY. Every road goes back to the party.", Narrator.DARK)
	if lap == 5 and into > 0.45 and not said.has("ghost"):
		said["ghost"] = true
		ghost = {"z": player_z + 3400.0, "t": 7.0, "ghost": true}
		Audio.sfx("glitch", -4)
		say_bg("The finish line moved. It doesn't want you to finish. It wants you to stay.", Narrator.DARK)
	if not ghost.is_empty():
		ghost.t = float(ghost.t) - dt
		ghost.z = maxf(float(ghost.z), player_z + 2500.0)
		if float(ghost.t) <= 0.0:
			ghost = {}
	if lap == 6 and into > 0.25 and not said.has("beside"):
		said["beside"] = true
		beside_t = 6.0
		boss.lane = clampf(player_x + (0.75 if player_x < 0.2 else -0.75), -0.66, 0.66)
		boss.x = boss.lane
		say_bg("Happy birthday, Chumbo. Again. And again. And again.", Narrator.CREEPY)
	if beside_t > 0.0:
		beside_t -= dt
		boss.z = player_z + 150.0
		boss.speed = speed
		boss.lane = clampf(player_x + (0.75 if player_x < 0.2 else -0.75), -0.66, 0.66)
		boss.x = move_toward(float(boss.x), float(boss.lane), dt * 2.0)
		if beside_t <= 0.0:
			boss.z = player_z + 5000.0
	if lap == 6 and into > 0.8:
		finish_word = "START" if fmod(t, 0.5) < 0.25 or into > 0.93 else "FINISH"


func _on_lap(lp: int) -> void:
	if lp <= 1:
		return
	Audio.sfx("checkpoint", -4)
	match lp:
		2:
			say_bg("Lap two! The B-DAY BOSS is right in front of you!", Narrator.HYPE)
		3:
			say_bg("Final lap! Go, Chumbo, go!", Narrator.HYPE)
		4:
			dark_laps = true
			_set_sky("doom")
			Audio.play_music("race_dark", 2.0)
			Audio.sfx("glitch")
			flash = 0.6
			say_bg("Lap four of three? That's not a real number. Keep driving, Chumbo.", Narrator.HYPE_DARK)
		5:
			say_bg("Lap five of three. Nobody finishes this race. They just keep driving.", Narrator.HYPE_DARK)
		6:
			say_bg("Last lap. It's always the last lap.", Narrator.HYPE_DARK)
		LAPS_REAL + 1:
			race_over = true
			phase = "coast"
			finish_word = "START"
			Audio.sfx("screech", -4)
	if lp <= LAPS_REAL:
		_pop("LAP %d/%d" % [lp, LAPS_SHOWN], Crayon.YELLOW if lp <= LAPS_SHOWN else Color(1, 0.3, 0.35))


# ------------------------------------------------------------------ sky and scenery


func _set_sky(m: String) -> void:
	sky_mode = m
	refresh_back()
	if _skyv and _sky_drawn != m:
		_skyv.render_target_update_mode = SubViewport.UPDATE_ONCE
		_sky_node.queue_redraw()


func _palette() -> Dictionary:
	match sky_mode:
		"sunset":
			return {"road": Color(0.44, 0.42, 0.47), "road2": Color(0.48, 0.46, 0.51), "g": Color(0.32, 0.52, 0.28), "g2": Color(0.36, 0.57, 0.31),
				"r1": Color(0.9, 0.2, 0.25), "r2": Color(0.97, 0.95, 0.92), "lane": Color(0.98, 0.97, 0.9), "edge": Crayon.INK}
		"dusk":
			return {"road": Color(0.34, 0.32, 0.42), "road2": Color(0.37, 0.35, 0.45), "g": Color(0.22, 0.32, 0.3), "g2": Color(0.25, 0.36, 0.33),
				"r1": Color(0.85, 0.25, 0.45), "r2": Color(0.9, 0.88, 0.92), "lane": Color(0.98, 0.97, 0.9), "edge": Crayon.INK}
		"doom":
			return {"road": Color(0.2, 0.13, 0.17), "road2": Color(0.23, 0.15, 0.19), "g": Color(0.13, 0.05, 0.08), "g2": Color(0.17, 0.07, 0.1),
				"r1": Color(0.8, 0.12, 0.22), "r2": Color(0.92, 0.82, 0.84), "lane": Color(1.0, 0.85, 0.45), "edge": Color(0.03, 0.0, 0.02)}
	return {"road": Color(0.24, 0.24, 0.32), "road2": Color(0.27, 0.27, 0.35), "g": Color(0.1, 0.12, 0.2), "g2": Color(0.13, 0.15, 0.24),
		"r1": Color(1.0, 0.35, 0.75), "r2": Color(0.92, 0.92, 0.98), "lane": Color(0.98, 0.97, 0.85), "edge": Color(0.04, 0.03, 0.08)}


func paint_back() -> void:
	_baked_sky = sky_mode
	if sky_mode == "garage":
		_garage_back()
		return
	var stops: Array
	match sky_mode:
		"sunset":
			stops = [Color(0.36, 0.3, 0.62), Color(0.85, 0.42, 0.55), Color(1.0, 0.62, 0.35), Color(1.0, 0.8, 0.45)]
		"dusk":
			stops = [Color(0.12, 0.1, 0.3), Color(0.32, 0.18, 0.42), Color(0.7, 0.32, 0.45), Color(0.9, 0.5, 0.4)]
		"night":
			stops = [Color(0.03, 0.03, 0.12), Color(0.06, 0.06, 0.2), Color(0.16, 0.08, 0.3), Color(0.35, 0.12, 0.4)]
		"midnight":
			stops = [Color(0.02, 0.02, 0.08), Color(0.04, 0.05, 0.16), Color(0.1, 0.08, 0.25), Color(0.2, 0.1, 0.3)]
		_:
			stops = [Color(0.04, 0.0, 0.03), Color(0.12, 0.02, 0.07), Color(0.3, 0.05, 0.12), Color(0.5, 0.1, 0.15)]
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, 2000), stops[0])
	var bands := 14
	for i in bands:
		var f := float(i) / (bands - 1) * (stops.size() - 1)
		var k := mini(int(f), stops.size() - 2)
		var col: Color = (stops[k] as Color).lerp(stops[k + 1], f - k)
		pen.draw_rect(Rect2(-2000, HZ * i / bands, W + 4000, HZ / bands + 1), col)
	var pal := _palette()
	pen.draw_rect(Rect2(-2000, HZ, W + 4000, 2400), pal.g)
	match sky_mode:
		"sunset":
			for i in 3:
				Crayon.cloud(pen, Vector2(560 + i * 300, 190 + (i % 2) * 30), 46, Color(1, 0.85, 0.85), 10 + i)
		"dusk":
			_stars(10, 0.6)
		"night", "midnight":
			_stars(28, 1.0)
		"doom":
			_stars(22, 0.8)


## Sun or moon, drawn over the skyline (left of centre, clear of the HUD).
func _sky_body() -> void:
	var c := Vector2(330, 214)
	match sky_mode:
		"sunset":
			Crayon.sun(pen, c + Vector2(0, 16), 44, "happy", 5)
		"dusk":
			Crayon.circle(pen, c, 32, Crayon.INK, 3, Color(1, 0.9, 0.7), 20)
		"night", "midnight":
			Crayon.circle(pen, c, 38, Crayon.INK, 4, Color(1, 1, 0.85), 21)
			Crayon.face(pen, c + Vector2(0, 4), 28, "sleep", Vector2.ZERO, 22)
		"doom":
			Crayon.circle(pen, c, 48, Color(0.5, 0.05, 0.1), 5, Color(1, 0.85, 0.75), 23)
			Crayon.face(pen, c + Vector2(0, 4), 40, "wide", Vector2(0.6, 0.4), 24)
			Crayon.party_hat(pen, c + Vector2(6, -44), 26, Crayon.RED, 25, 0.2)


func _stars(n: int, a: float) -> void:
	for i in n:
		var sp := Vector2(fmod(i * 211.0 + 37.0, W), 14 + fmod(i * 97.0, HZ - 120))
		Crayon.star(pen, sp, 4 + (i % 3) * 2, Color(1, 1, 0.8, a), Color(1, 0.95, 0.6, a), 30 + i)


func _garage_back() -> void:
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, 2470), Color(0.32, 0.3, 0.38))
	for row in 12:
		var y := 40.0 + row * 36.0
		Crayon.line(pen, Vector2(-40, y), Vector2(W + 40, y), Color(0.26, 0.24, 0.31), 3, 300 + row)
		for k in 14:
			var bx := fmod(k * 104.0 + (52.0 if row % 2 == 1 else 0.0), W + 104.0) - 20.0
			Crayon.line(pen, Vector2(bx, y), Vector2(bx, y + 36), Color(0.26, 0.24, 0.31), 3, 320 + row * 14 + k)
	pen.draw_rect(Rect2(-2000, 470, W + 4000, 2000), Color(0.22, 0.21, 0.25))
	Crayon.line(pen, Vector2(-40, 470), Vector2(W + 40, 470), Crayon.INK, 6, 2)
	for i in 6:
		Crayon.line(pen, Vector2(-80 + i * 300, 720), Vector2(320 + i * 160, 470), Color(0.3, 0.29, 0.34), 3, 3 + i)
	# neon sign
	var r := Rect2(370, 92, 540, 96)
	Crayon.rect(pen, r, Color(1.0, 0.35, 0.75), 7, Color(0.12, 0.08, 0.2), 4)
	Crayon.text(pen, r.get_center() + Vector2(0, -12), "KNEAD FOR SPEED", 46, Color(1.0, 0.6, 0.85), 1, 5, Crayon.title_font())
	Crayon.text(pen, r.get_center() + Vector2(0, 28), "UNDERGROUND", 26, Color(0.4, 0.95, 1.0), 1, 6, Crayon.title_font())
	# tyre stacks and a poster
	for k in 3:
		Crayon.ellipse(pen, Vector2(1160, 440 - k * 44), Vector2(70, 26), Crayon.INK, 5, Color(0.12, 0.12, 0.14), 40 + k)
		Crayon.ellipse(pen, Vector2(120, 440 - k * 44), Vector2(70, 26), Crayon.INK, 5, Color(0.12, 0.12, 0.14), 50 + k)
	Crayon.text(pen, Vector2(155, 190), "GLOW", 34, Crayon.YELLOW, 1, 60, Crayon.title_font())
	Crayon.text(pen, Vector2(1125, 190), "STICKER", 34, Crayon.YELLOW, 1, 61, Crayon.title_font())


func _make_skyline() -> void:
	_skyv = SubViewport.new()
	_skyv.disable_3d = true
	_skyv.transparent_bg = true
	_skyv.size = Vector2i(2560, 320)
	_skyv.render_target_update_mode = SubViewport.UPDATE_ONCE
	_sky_node = Node2D.new()
	_skyv.add_child(_sky_node)
	_sky_node.draw.connect(_draw_skyline)
	add_child(_skyv)
	_sky_tex = _skyv.get_texture()


func _draw_skyline() -> void:
	_sky_drawn = sky_mode
	if sky_mode == "garage":
		return
	var n := _sky_node
	Crayon.freeze(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var night := sky_mode in ["night", "midnight", "doom"]
	var doom := sky_mode == "doom"
	var body: Color = {"sunset": Color(0.42, 0.28, 0.42), "dusk": Color(0.2, 0.14, 0.3)}.get(sky_mode, Color(0.09, 0.08, 0.18))
	if doom:
		body = Color(0.13, 0.04, 0.08)
	var neon := [Color(1, 0.35, 0.75), Color(0.35, 0.95, 1.0), Color(1.0, 0.85, 0.3), Color(0.5, 1.0, 0.5)]
	var words := ["CAKE", "NOS", "PARTY", "24/7", "TACOS", "PIZZA", "GIFTS"]
	var x := 0.0
	var i := 0
	while x < 2560.0:
		var w := rng.randf_range(80, 170)
		var h := rng.randf_range(60, 190)
		var r := Rect2(x, 320 - h, w, h + 4)
		Crayon.rect(n, r, Crayon.INK if not night else Color(0.02, 0.02, 0.05), 3, body.lightened(rng.randf() * 0.12), 500 + i)
		var lit := 0.55 if night else 0.18
		for wy in range(int(320 - h + 14), 300, 26):
			for wx in range(int(x + 12), int(x + w - 16), 24):
				if rng.randf() < lit:
					var wc := Color(1.0, 0.85, 0.4) if not doom else Color(0.9, 0.2, 0.25)
					n.draw_rect(Rect2(wx, wy, 11, 13), wc)
		if night and rng.randf() < 0.45 and x + w < 2540:
			var word: String = "PARTY" if doom else words[rng.randi() % words.size()]
			var nc: Color = Color(1, 0.25, 0.35) if doom else neon[rng.randi() % neon.size()]
			Crayon.text(n, Vector2(x + w * 0.5, 320 - h - 18), word, 24, nc, 1, 600 + i, Crayon.title_font(), 0.4, false)
		x += w + rng.randf_range(4, 26)
		i += 1
	Crayon.freeze(false)


# ------------------------------------------------------------------ the sprite atlas


func _make_atlas() -> void:
	_atlas = SubViewport.new()
	_atlas.disable_3d = true
	_atlas.transparent_bg = true
	_atlas.size = Vector2i(int(CELL * ATLAS_COLS), int(CELL * 3))
	_atlas.render_target_update_mode = SubViewport.UPDATE_ONCE
	var n := Node2D.new()
	_atlas.add_child(n)
	n.draw.connect(_draw_atlas.bind(n))
	add_child(_atlas)
	_atlas_tex = _atlas.get_texture()


func _cell_base(cell: int) -> Vector2:
	return Vector2((cell % ATLAS_COLS) * CELL + CELL * 0.5, (cell / ATLAS_COLS) * CELL + CELL - 6.0)


func _draw_atlas(n: Node2D) -> void:
	Crayon.freeze(true)
	var cars := [Color(0.95, 0.4, 0.35), Color(0.4, 0.8, 0.95), Color(0.98, 0.85, 0.35), Color(0.6, 0.85, 0.5)]
	var hats := [Crayon.YELLOW, Crayon.PINK, Crayon.BLUE, Crayon.RED]
	for nm in SPR:
		var b := _cell_base(int(SPR[nm][0]))
		match nm:
			"lamp":
				spr_lamp(n, b, false)
			"candle":
				spr_lamp(n, b, true)
			"sign_bday":
				spr_sign(n, b, "BIRTHDAY BLVD", Color(1.0, 0.4, 0.8), 1)
			"sign_cake":
				spr_sign(n, b, "CAKE ST", Color(0.4, 0.95, 1.0), 2)
			"sign_sprinkle":
				spr_sign(n, b, "SPRINKLE AVE", Color(1.0, 0.85, 0.3), 3)
			"sign_nos":
				spr_sign(n, b, "GOT NITRO?", Color(0.5, 1.0, 0.5), 4)
			"sign_party":
				spr_sign(n, b, "PARTY > 0 MI", Color(1.0, 0.25, 0.3), 5)
			"house":
				spr_house(n, b, 1.0, 6)
			"tree":
				spr_tree(n, b, 7)
			"balloons":
				for k in 3:
					Crayon.balloon(n, b + Vector2(-44 + k * 44, -230 + (k % 2) * 30), 30, Crayon.RAINBOW[k * 2], 170 - (k % 2) * 30, 80 + k * 5)
			"car_dark":
				car_rear(n, b, 290.0, Color(0.3, 0.28, 0.32), Color(0, 0, 0, 0), "", 90, Crayon.RED, "wide")
			"granny":
				spr_granny(n, b)
			"limo":
				spr_limo(n, b)
			"banner_finish":
				spr_banner(n, b, "FINISH", 120)
			"banner_start":
				spr_banner(n, b, "START", 130)
			_:
				if nm.begins_with("car"):
					var k := int(nm.substr(3))
					car_rear(n, b, 290.0, cars[k], Color(0, 0, 0, 0), "", 100 + k * 10, hats[k])
				elif nm.begins_with("rival"):
					var k := int(nm.substr(5))
					var rc: Color = [Color(0.3, 0.72, 0.3), Color(0.22, 0.48, 0.9), Color(1.0, 0.8, 0.2)][k]
					var rg: Color = [Color(0.4, 1, 0.5), Color(0.3, 0.8, 1), Color(1, 0.6, 0.2)][k]
					car_rear(n, b, 290.0, rc, rg, ["STARS", "SPRINKLES", "FLAMES"][k], 140 + k * 10, Color(0, 0, 0, 0), "", true)
	Crayon.freeze(false)


static func spr_lamp(ci: CanvasItem, b: Vector2, candle: bool) -> void:
	if candle:
		# a giant birthday candle where the street light used to be
		var r := Rect2(b + Vector2(-24, -232), Vector2(48, 232))
		Crayon.oval(ci, b + Vector2(0, -258), Vector2(60, 50), Color(1, 0.6, 0.2, 0.3))
		Crayon.rect(ci, r, Crayon.INK, 4, Color(0.98, 0.92, 0.9), 11)
		for k in 6:
			Crayon.line(ci, r.position + Vector2(0, 20 + k * 38), r.position + Vector2(48, 2 + k * 38), Crayon.RED, 7, 12 + k)
		Crayon.line(ci, b + Vector2(0, -232), b + Vector2(0, -246), Crayon.INK, 3, 19)
		Crayon.flame(ci, b + Vector2(0, -262), 22, 20)
		return
	var pole := Color(0.32, 0.32, 0.4)
	var top := b + Vector2(-40, -268)
	Crayon.line(ci, b + Vector2(-40, 0), top, pole, 9, 1)
	Crayon.line(ci, top, top + Vector2(44, -8), pole, 7, 2)
	var head := top + Vector2(50, 4)
	Crayon.oval(ci, head + Vector2(0, 14), Vector2(56, 40), Color(1, 0.92, 0.55, 0.32))
	Crayon.rect(ci, Rect2(head - Vector2(18, 6), Vector2(36, 14)), Crayon.INK, 3, Color(1, 0.96, 0.65), 3)


static func spr_sign(ci: CanvasItem, b: Vector2, txt: String, neon: Color, sd: int) -> void:
	var pole := Color(0.32, 0.32, 0.4)
	for sx in [-95.0, 95.0]:
		Crayon.line(ci, b + Vector2(sx, 0), b + Vector2(sx, -112), pole, 8, sd * 10 + int(sx))
	var r := Rect2(b + Vector2(-146, -226), Vector2(292, 116))
	Crayon.rect(ci, r, neon, 7, Color(0.1, 0.08, 0.2), sd * 10)
	Crayon.rect(ci, r.grow(-11), neon.lightened(0.45), 3, Color(0, 0, 0, 0), sd * 10 + 3)
	var font := Crayon.title_font()
	var fs := 46
	while fs > 18 and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 250.0:
		fs -= 2
	Crayon.text(ci, r.get_center(), txt, fs, neon.lightened(0.55), 1, sd * 10 + 5, font, 0.5, false)


static func spr_house(ci: CanvasItem, b: Vector2, k: float, sd: int) -> void:
	var r := Rect2(b + Vector2(-125, -165) * k, Vector2(250, 165) * k)
	Crayon.rect(ci, r, Crayon.INK, 5 * k, Color(0.98, 0.6, 0.75), sd)
	Crayon.poly(ci, PackedVector2Array([r.position + Vector2(-20, 0) * k, Vector2(r.end.x + 20 * k, r.position.y), Vector2(b.x, r.position.y - 92 * k)]),
		Crayon.INK, 5 * k, Crayon.PURPLE, sd + 1)
	var ban := Rect2(r.position + Vector2(-8, -18) * k, Vector2(r.size.x + 16 * k, 34 * k))
	Crayon.rect(ci, ban, Crayon.INK, 3 * k, Crayon.WHITE, sd + 2)
	Crayon.text(ci, ban.get_center(), "HAPPY BIRTHDAY", int(22 * k), Crayon.RED, 1, sd + 3, null, 0.3, false)
	for i in 2:
		var win := Rect2(r.position + Vector2(22 + i * 150, 46) * k, Vector2(58, 50) * k)
		Crayon.rect(ci, win, Crayon.INK, 4 * k, Color(1, 0.9, 0.5), sd + 4 + i)
		var c := win.get_center() + Vector2(0, 8) * k
		Crayon.disc(ci, c, 14 * k, Color(0.15, 0.1, 0.12))
		Crayon.party_hat(ci, c + Vector2(0, -11) * k, 10 * k, Crayon.RAINBOW[(sd + i * 3) % 7], sd + 8 + i)
	var d := Rect2(b + Vector2(-26, -76) * k, Vector2(52, 76) * k)
	Crayon.rect(ci, d, Crayon.INK, 4 * k, Color(0.55, 0.32, 0.2), sd + 12)
	Crayon.dot(ci, d.position + Vector2(40, 40) * k, 4 * k, Crayon.YELLOW)
	for i in 2:
		Crayon.balloon(ci, b + Vector2(-138 + i * 276, -150) * k, 20 * k, Crayon.RAINBOW[(sd + i * 2) % 7], 110 * k, sd + 14 + i)


static func spr_tree(ci: CanvasItem, b: Vector2, sd: int) -> void:
	Crayon.rect(ci, Rect2(b + Vector2(-14, -120), Vector2(28, 120)), Crayon.INK, 4, Crayon.BROWN, sd)
	var g := Color(0.3, 0.62, 0.3)
	Crayon.circle(ci, b + Vector2(-48, -160), 60, Crayon.INK, 4, g.darkened(0.1), sd + 1)
	Crayon.circle(ci, b + Vector2(48, -160), 60, Crayon.INK, 4, g.darkened(0.05), sd + 2)
	Crayon.circle(ci, b + Vector2(0, -222), 66, Crayon.INK, 4, g, sd + 3)
	for k in 4:
		Crayon.dot(ci, b + Vector2(-50 + k * 32, -200 + (k % 2) * 40), 7, Crayon.RAINBOW[k * 2 % 7])


static func spr_banner(ci: CanvasItem, b: Vector2, txt: String, sd: int) -> void:
	var pole := Color(0.85, 0.85, 0.9)
	for sx in [-150.0, 150.0]:
		Crayon.line(ci, b + Vector2(sx, 0), b + Vector2(sx, -240), Crayon.INK, 12, sd + int(sx))
		Crayon.line(ci, b + Vector2(sx, 0), b + Vector2(sx, -240), pole, 6, sd + 1 + int(sx))
	var r := Rect2(b + Vector2(-156, -242), Vector2(312, 60))
	var sq := r.size.x / 16.0
	for i in 16:
		for j in 2:
			ci.draw_rect(Rect2(r.position + Vector2(i * sq, j * r.size.y * 0.5), Vector2(sq, r.size.y * 0.5)),
				Crayon.BLACK if (i + j) % 2 == 0 else Crayon.WHITE)
	Crayon.rect(ci, r, Crayon.INK, 5, Color(0, 0, 0, 0), sd + 5)
	var p := Rect2(r.get_center() - Vector2(84, 24), Vector2(168, 48))
	Crayon.rect(ci, p, Crayon.INK, 4, Crayon.YELLOW if txt == "START" else Crayon.WHITE, sd + 6)
	Crayon.text(ci, p.get_center(), txt, 36, Crayon.RED, 1, sd + 7, Crayon.title_font(), 0.4, false)


static func spr_granny(ci: CanvasItem, b: Vector2) -> void:
	# a tall pink van with Turbo Granny's hair bun in the back window
	var body := Color(0.98, 0.7, 0.85)
	Crayon.rect(ci, Rect2(b + Vector2(-132, -44), Vector2(40, 44)), Crayon.INK, 3, Crayon.BLACK, 200)
	Crayon.rect(ci, Rect2(b + Vector2(92, -44), Vector2(40, 44)), Crayon.INK, 3, Crayon.BLACK, 201)
	Crayon.rect(ci, Rect2(b + Vector2(-140, -236), Vector2(280, 200)), Crayon.INK, 5, body, 202)
	var win := Rect2(b + Vector2(-104, -220), Vector2(208, 82))
	Crayon.rect(ci, win, Crayon.INK, 4, Color(0.6, 0.75, 0.9), 203)
	Crayon.circle(ci, b + Vector2(0, -160), 28, Crayon.INK, 3, Color(0.85, 0.85, 0.88), 204)
	Crayon.circle(ci, b + Vector2(0, -196), 16, Crayon.INK, 3, Color(0.9, 0.9, 0.93), 205)
	for sx in [-1.0, 1.0]:
		Crayon.rect(ci, Rect2(b + Vector2(sx * 112 - 18, -120), Vector2(36, 28)), Crayon.INK, 3, Color(1, 0.2, 0.25), 206 + int(sx))
	Crayon.rect(ci, Rect2(b + Vector2(-50, -84), Vector2(100, 30)), Crayon.INK, 3, Crayon.WHITE, 209)
	Crayon.text(ci, b + Vector2(0, -69), "GRANNY", 20, Crayon.INK, 1, 210, null, 0.3, false)
	Crayon.text(ci, b + Vector2(0, -250), "TURBO GRANNY", 22, Crayon.WHITE, 1, 211, Crayon.title_font(), 0.3, false)


static func spr_limo(ci: CanvasItem, b: Vector2) -> void:
	var body := Color(0.1, 0.09, 0.12)
	Crayon.rect(ci, Rect2(b + Vector2(-146, -46), Vector2(44, 46)), Crayon.INK, 3, Crayon.BLACK, 300)
	Crayon.rect(ci, Rect2(b + Vector2(102, -46), Vector2(44, 46)), Crayon.INK, 3, Crayon.BLACK, 301)
	Crayon.rect(ci, Rect2(b + Vector2(-154, -118), Vector2(308, 82)), Color(0.5, 0.45, 0.55), 5, body, 302)
	var cab := PackedVector2Array([b + Vector2(-118, -118), b + Vector2(-90, -186), b + Vector2(90, -186), b + Vector2(118, -118)])
	Crayon.poly(ci, cab, Color(0.5, 0.45, 0.55), 5, body, 303)
	var win := PackedVector2Array([b + Vector2(-96, -126), b + Vector2(-74, -176), b + Vector2(74, -176), b + Vector2(96, -126)])
	Crayon.poly(ci, win, Color(0.5, 0.45, 0.55), 3, Color(0.2, 0.12, 0.2), 304)
	# the boss himself: a big round cake face, smiling at you through the back window
	Crayon.circle(ci, b + Vector2(0, -150), 30, Crayon.INK, 3, Crayon.PINK, 305)
	Crayon.face(ci, b + Vector2(0, -148), 26, "wide", Vector2(0, 0.4), 306)
	for i in 5:
		var cx := -80.0 + i * 40.0
		Crayon.rect(ci, Rect2(b + Vector2(cx - 5, -222), Vector2(10, 36)), Crayon.INK, 2, Crayon.RAINBOW[i], 310 + i)
		Crayon.flame(ci, b + Vector2(cx, -232), 9, 320 + i)
	for sx in [-1.0, 1.0]:
		Crayon.rect(ci, Rect2(b + Vector2(sx * 124 - 22, -104), Vector2(44, 22)), Crayon.INK, 3, Color(1, 0.15, 0.2), 330 + int(sx))
	Crayon.rect(ci, Rect2(b + Vector2(-52, -76), Vector2(104, 28)), Crayon.INK, 3, Crayon.YELLOW, 335)
	Crayon.text(ci, b + Vector2(0, -62), "BDAYBOSS", 20, Crayon.INK, 1, 336, null, 0.3, false)


## A car seen from behind. w = width in px, bc = bottom centre (between the tyres).
static func car_rear(ci: CanvasItem, bc: Vector2, w: float, body: Color, glow: Color, vinyl: String, sd: int,
		hat: Color = Color(0, 0, 0, 0), face: String = "", spoiler: bool = false) -> void:
	var u := w / 300.0
	var lw := maxf(2.0, 4.0 * u)
	if glow.a > 0.0:
		Crayon.oval(ci, bc + Vector2(0, -6) * u, Vector2(176, 30) * u, Color(glow, 0.55))
	Crayon.rect(ci, Rect2(bc + Vector2(-140, -46) * u, Vector2(42, 46) * u), Crayon.INK, lw, Crayon.BLACK, sd)
	Crayon.rect(ci, Rect2(bc + Vector2(98, -46) * u, Vector2(42, 46) * u), Crayon.INK, lw, Crayon.BLACK, sd + 1)
	Crayon.rect(ci, Rect2(bc + Vector2(-150, -114) * u, Vector2(300, 78) * u), Crayon.INK, lw * 1.2, body, sd + 2)
	var cab := PackedVector2Array([bc + Vector2(-114, -114) * u, bc + Vector2(-84, -184) * u, bc + Vector2(84, -184) * u, bc + Vector2(114, -114) * u])
	Crayon.poly(ci, cab, Crayon.INK, lw * 1.2, body.darkened(0.12), sd + 3)
	var win := PackedVector2Array([bc + Vector2(-92, -122) * u, bc + Vector2(-70, -174) * u, bc + Vector2(70, -174) * u, bc + Vector2(92, -122) * u])
	Crayon.poly(ci, win, Crayon.INK, lw * 0.8, Color(0.28, 0.34, 0.5), sd + 4)
	var head := bc + Vector2(0, -146) * u
	if face != "":
		Crayon.circle(ci, head, 20 * u, Crayon.INK, lw * 0.7, Color(1, 0.9, 0.78), sd + 5)
		Crayon.face(ci, head, 18 * u, face, Vector2(0, 0.3), sd + 6)
	else:
		Crayon.circle(ci, head, 20 * u, Crayon.INK, lw * 0.7, Color(0.35, 0.22, 0.15), sd + 5)
	if hat.a > 0.0:
		Crayon.party_hat(ci, bc + Vector2(0, -182) * u, 24 * u, hat, sd + 7)
	for sx in [-1.0, 1.0]:
		Crayon.rect(ci, Rect2(bc + Vector2(sx * 120 - 22, -100) * u, Vector2(44, 22) * u), Crayon.INK, lw * 0.7, Color(1, 0.18, 0.22), sd + 8 + int(sx))
	Crayon.rect(ci, Rect2(bc + Vector2(-36, -74) * u, Vector2(72, 26) * u), Crayon.INK, lw * 0.7, Crayon.WHITE, sd + 11)
	Crayon.line(ci, bc + Vector2(-152, -38) * u, bc + Vector2(152, -38) * u, Crayon.INK, lw * 1.2, sd + 12)
	match vinyl:
		"FLAMES":
			for k in 2:
				var sx := -1.0 if k == 0 else 1.0
				var root := bc + Vector2(sx * 60, -40) * u
				Crayon.poly(ci, PackedVector2Array([root, root + Vector2(sx * 22, -60) * u, root + Vector2(sx * 40, -10) * u]), Crayon.RED, lw * 0.6, Crayon.ORANGE, sd + 13 + k)
				Crayon.poly(ci, PackedVector2Array([root + Vector2(sx * 8, 0) * u, root + Vector2(sx * 22, -36) * u, root + Vector2(sx * 32, -6) * u]), Crayon.ORANGE, lw * 0.4, Crayon.YELLOW, sd + 15 + k)
		"STARS":
			for k in 3:
				Crayon.star(ci, bc + Vector2(-80 + k * 80, -92 + (k % 2) * 16) * u, 13 * u, Crayon.INK, Crayon.YELLOW, sd + 13 + k)
		"SPRINKLES":
			for k in 9:
				var p := bc + Vector2(-125 + k * 31, -96 + (k % 3) * 14) * u
				Crayon.line(ci, p, p + Vector2(10, 5 - (k % 2) * 10) * u, Crayon.RAINBOW[k % 7], lw * 1.2, sd + 13 + k, 0.2)
	if spoiler:
		for sx in [-1.0, 1.0]:
			Crayon.line(ci, bc + Vector2(sx * 110, -114) * u, bc + Vector2(sx * 110, -136) * u, Crayon.INK, lw, sd + 25 + int(sx))
		Crayon.rect(ci, Rect2(bc + Vector2(-156, -146) * u, Vector2(312, 14) * u), Crayon.INK, lw * 0.8, body.darkened(0.2), sd + 28)


## Chumbo's cake car from the side (garage and finale). feet = ground under the middle.
static func car_side(ci: CanvasItem, feet: Vector2, sc: float, tm: float, body: Color, glow: Color, vinyl: String, sd: int = 900) -> void:
	var u := sc
	var lw := maxf(2.0, 4.0 * u)
	var p := func(x: float, y: float) -> Vector2: return feet + Vector2(x, y) * u
	if glow.a > 0.0:
		Crayon.oval(ci, p.call(0, 2), Vector2(130, 18) * u, Color(glow, 0.6))
	var shell := PackedVector2Array([p.call(-112, -22), p.call(114, -22), p.call(118, -46), p.call(70, -58), p.call(-100, -60), p.call(-114, -44)])
	Crayon.poly(ci, shell, Crayon.INK, lw * 1.2, body, sd)
	var cab := PackedVector2Array([p.call(-58, -58), p.call(48, -58), p.call(26, -94), p.call(-40, -94)])
	Crayon.poly(ci, cab, Crayon.INK, lw * 1.1, Color(0.7, 0.88, 1.0), sd + 1)
	# Chumbo at the wheel, in a party hat
	Crayon.circle(ci, p.call(-6, -76), 13 * u, Crayon.INK, lw * 0.7, Color(1, 0.9, 0.78), sd + 2)
	Crayon.dot(ci, p.call(-1, -78), 2.2 * u, Crayon.INK)
	Crayon.party_hat(ci, p.call(-8, -88), 11 * u, Crayon.YELLOW, sd + 3, -0.2)
	# frosting along the top of the body
	var drip := PackedVector2Array()
	for k in 12:
		var x := -100.0 + k * 17.0
		drip.append(p.call(x, -56 + (5.0 if k % 2 == 0 else 0.0) + (8.0 if k % 4 == 1 else 0.0)))
	Crayon.path(ci, drip, Crayon.WHITE, lw * 1.3, sd + 4)
	match vinyl:
		"FLAMES":
			for k in 3:
				var root: Vector2 = p.call(96 - k * 6, -30 - k * 8)
				Crayon.poly(ci, PackedVector2Array([root, root + Vector2(-60 + k * 10, -6) * u, root + Vector2(-34, 8) * u]), Crayon.RED, lw * 0.5, [Crayon.ORANGE, Crayon.YELLOW, Crayon.ORANGE][k], sd + 5 + k)
		"STARS":
			for k in 3:
				Crayon.star(ci, p.call(-60 + k * 55, -36), 11 * u, Crayon.INK, Crayon.YELLOW, sd + 5 + k)
		"SPRINKLES":
			for k in 10:
				var q: Vector2 = p.call(-96 + k * 20, -40 + (k % 3) * 7)
				Crayon.line(ci, q, q + Vector2(7, 4 - (k % 2) * 8) * u, Crayon.RAINBOW[k % 7], lw * 1.1, sd + 5 + k, 0.2)
	# spoiler with a candle antenna
	Crayon.line(ci, p.call(-96, -58), p.call(-104, -78), Crayon.INK, lw, sd + 20)
	Crayon.rect(ci, Rect2(p.call(-126, -86), Vector2(40, 9) * u), Crayon.INK, lw * 0.7, body.darkened(0.2), sd + 21)
	Crayon.rect(ci, Rect2(p.call(-112, -110), Vector2(7, 24) * u), Crayon.INK, lw * 0.5, Crayon.RAINBOW[2], sd + 22)
	Crayon.flame(ci, p.call(-108.5, -118), 7 * u, sd + 23)
	Crayon.disc(ci, p.call(112, -40), 7 * u, Crayon.YELLOW)
	Crayon.disc(ci, p.call(-112, -38), 6 * u, Crayon.RED)
	for wx in [-68.0, 70.0]:
		var c: Vector2 = p.call(wx, -16)
		Crayon.circle(ci, c, 19 * u, Crayon.INK, lw, Crayon.BLACK, sd + 30 + int(wx))
		Crayon.circle(ci, c, 8 * u, Crayon.INK, lw * 0.5, Crayon.GREY, sd + 31 + int(wx))
		var a := tm * 9.0
		Crayon.line(ci, c + Vector2(cos(a), sin(a)) * 8 * u, c - Vector2(cos(a), sin(a)) * 8 * u, Crayon.INK, lw * 0.6, sd + 32, 0.2)


## For the finale cast: Chumbo's little race car.
static func draw_mascot(ci: CanvasItem, feet: Vector2, sc: float, tm: float) -> void:
	car_side(ci, feet + Vector2(0, -2.0 - absf(sin(tm * 6.0)) * 2.0 * sc), sc, tm, BODY, Color(0.3, 1.0, 0.5), "FLAMES")


# ------------------------------------------------------------------ drawing


func paint() -> void:
	if sky_mode == "garage":
		var bob := absf(sin(t * 3.0)) * 3.0
		car_side(pen, Vector2(640, 590 - bob - sin(hop * PI) * 18.0), 2.0, t * 0.3, car_col, glow, vinyl, 900)
		if car_col == GOLD:
			_twinkles(Vector2(640, 500), Vector2(260, 90), 6)
		if phase == "garage" and not locked:
			Crayon.text(pen, Vector2(640, 238), "TAP TO PICK!", 30, Crayon.YELLOW, 1, 940, null, 0.6, false)
		return
	_paint_skyline()
	_sky_body()
	_paint_world()
	if phase == "end":
		_paint_end()
	if flash > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(1, 1, 1, flash * 0.8) if phase == "end" else Color(1, 0.2, 0.3, flash * 0.35))


func _paint_skyline() -> void:
	if _sky_tex == null:
		return
	var x0 := -fposmod(sky_off, 2560.0)
	for k in 3:
		pen.draw_texture(_sky_tex, Vector2(x0 + (k - 1) * 2560.0, HZ - 316.0))


func _paint_world() -> void:
	var cam_z := player_z - PLAYER_OFF
	var base := floori(cam_z / SEG_L)
	var basef := (cam_z - base * SEG_L) / SEG_L
	var cam_x := player_x * ROAD_W * CAM_FOLLOW
	var x := 0.0
	var dx := -_curve(base) * basef
	for n in DRAW_N + 1:
		var zr := maxf((base + n) * SEG_L - cam_z, 20.0)
		var sc := DEPTH / zr
		_ps[n] = sc
		_py[n] = HZ + sc * CAM_H * Y_K
		_pxo[n] = x
		_px[n] = 640.0 + sc * (x - cam_x) * 640.0
		_pw[n] = sc * ROAD_W * 640.0
		x += dx
		dx += _curve(base + n)
	_road_tris(base)
	_road_edges()
	# who is on which segment (far to near draws the near ones on top)
	var on_seg := {}
	for c in traffic + rivals + ([ghost] if not ghost.is_empty() else []):
		var rel := (_dz(c) if c.has("wrap") else float(c.z) - player_z) + PLAYER_OFF
		if rel < 170.0:
			continue
		var nf := rel / SEG_L + basef
		var n := int(nf)
		if n >= DRAW_N:
			continue
		if not on_seg.has(n):
			on_seg[n] = []
		on_seg[n].append([rel, nf - n, c])
	var night := sky_mode in ["night", "midnight", "doom"]
	var shade := Color(0.6, 0.6, 0.78) if night else (Color(0.85, 0.8, 0.9) if sky_mode == "dusk" else Crayon.WHITE)
	for n in range(DRAW_N - 1, 0, -1):
		var s := base + n
		var key := posmod(s, LAP_SEGS) if looped else s
		if deco.has(key) and (base + n) * SEG_L - cam_z > 150.0:
			for d in deco[key]:
				var nm := _swap(String(d[0]))
				var xo := float(d[1])
				if nm == "house" and String(d[0]) == "tree":
					xo = signf(xo) * 3.0
				var sx := 640.0 + _ps[n] * (_pxo[n] + xo * ROAD_W - cam_x) * 640.0
				var lit := nm.begins_with("sign") or nm == "lamp" or nm == "candle" or nm.begins_with("banner")
				_blit(nm, sx, _py[n], _ps[n], Crayon.WHITE if lit else shade)
		if on_seg.has(n):
			var list: Array = on_seg[n]
			list.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
			for e in list:
				_draw_car(e[2], e[0], n, e[1], cam_x, shade)
	_player_car()
	var shown := 0
	for i in range(pops.size() - 1, -1, -1):
		if shown >= 2:
			break
		var p: Dictionary = pops[i]
		var k := 1.3 - float(p.t)
		var col: Color = p.col
		col.a = clampf(float(p.t) * 2.0, 0.0, 1.0)
		var at := Vector2(640, 420 - k * 50.0 - shown * 58.0)
		Crayon.text(pen, at + Vector2(3, 3), p.txt, 50, Color(0, 0, 0, col.a * 0.7), 1, 950 + i, Crayon.title_font(), 0.3, false)
		Crayon.text(pen, at, p.txt, 50, col, 1, 950 + i, Crayon.title_font(), 0.3, false)
		shown += 1
	if phase == "count" or (phase in ["race", "drag", "circuit"] and race_t < 0.8):
		var word := "GO!" if phase != "count" else str(ceili(count_t - 0.99)) if count_t > 1.0 else "GO!"
		var sz := 150
		Crayon.text(pen, Vector2(640, 250), word, sz, Crayon.YELLOW, 1, 960, Crayon.title_font())


func _swap(nm: String) -> String:
	if nm.begins_with("banner"):
		if mode == "circuit":
			return "banner_start" if finish_word == "START" else "banner_finish"
		return nm
	if not dark_laps:
		return nm
	if nm == "lamp":
		return "candle"
	if nm == "tree":
		return "house"
	if nm.begins_with("sign"):
		return "sign_party"
	return nm


func _blit(nm: String, sx: float, sy: float, sc: float, mod: Color = Color.WHITE) -> void:
	var s: Array = SPR[nm]
	var dw := float(s[3]) * sc * 640.0
	var dh := dw * float(s[2]) / float(s[1])
	if dh < 2.0 or sx + dw * 0.5 < -400.0 or sx - dw * 0.5 > W + 400.0:
		return
	var cb := _cell_base(int(s[0]))
	var src := Rect2(cb.x - float(s[1]) * 0.5, cb.y - float(s[2]), float(s[1]), float(s[2]))
	pen.draw_texture_rect_region(_atlas_tex, Rect2(sx - dw * 0.5, sy - dh, dw, dh), src, mod)


func _draw_car(c: Dictionary, rel: float, n: int, f: float, cam_x: float, shade: Color) -> void:
	var sc := DEPTH / rel
	var sy := HZ + sc * CAM_H * Y_K
	var xo := lerpf(_pxo[n], _pxo[n + 1], f)
	var sx := 640.0 + sc * (xo + float(c.get("x", 0.0)) * ROAD_W - cam_x) * 640.0
	if c.has("ghost"):
		var a := clampf(float(ghost.t) / 1.5, 0.0, 1.0)
		_blit("banner_finish", sx, sy, sc, Color(1, 1, 1, a * (0.6 + 0.4 * sin(t * 20.0))))
		return
	var nm: String = c.spr
	_blit(nm, sx, sy, sc, shade.lerp(Crayon.WHITE, 0.4))
	if c.has("name"):
		var dw := float(SPR[nm][3]) * sc * 640.0
		if dw > 50.0:
			var dh := dw * float(SPR[nm][2]) / float(SPR[nm][1])
			var fs := clampi(int(dw * 0.11), 14, 26)
			Crayon.text(pen, Vector2(sx, sy - dh - fs * 0.6), String(c.name), fs, Crayon.WHITE, 1, 970, null, 0.2, false)


func _road_tris(base: int) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var pal := _palette()
	var gx0 := -2200.0
	var gx1 := W + 2200.0
	for n in DRAW_N:
		var y1 := _py[n]
		var y2 := _py[n + 1]
		if y1 - y2 < 0.05:
			continue
		var s := base + n
		var alt := posmod(floori(s / 3.0), 2)
		var x1 := _px[n]
		var x2 := _px[n + 1]
		var w1 := _pw[n]
		var w2 := _pw[n + 1]
		var r1 := w1 * 0.1
		var r2 := w2 * 0.1
		if alt == 1:
			_quad(pts, cols, idx, Vector2(gx0, y1), Vector2(x1 - w1 - r1, y1), Vector2(x2 - w2 - r2, y2), Vector2(gx0, y2), pal.g2)
			_quad(pts, cols, idx, Vector2(x1 + w1 + r1, y1), Vector2(gx1, y1), Vector2(gx1, y2), Vector2(x2 + w2 + r2, y2), pal.g2)
		var rc: Color = pal.r1 if alt == 0 else pal.r2
		_quad(pts, cols, idx, Vector2(x1 - w1 - r1, y1), Vector2(x1 - w1, y1), Vector2(x2 - w2, y2), Vector2(x2 - w2 - r2, y2), rc)
		_quad(pts, cols, idx, Vector2(x1 + w1, y1), Vector2(x1 + w1 + r1, y1), Vector2(x2 + w2 + r2, y2), Vector2(x2 + w2, y2), rc)
		_quad(pts, cols, idx, Vector2(x1 - w1, y1), Vector2(x1 + w1, y1), Vector2(x2 + w2, y2), Vector2(x2 - w2, y2), pal.road if alt == 0 else pal.road2)
		var key := posmod(s, LAP_SEGS) if looped else s
		if key in line_segs:
			# chequered start/finish line painted across the road
			for k in 8:
				var a := -1.0 + k * 0.25
				var b := a + 0.25
				var col := Crayon.WHITE if k % 2 == 0 else Crayon.BLACK
				_quad(pts, cols, idx, Vector2(x1 + a * w1, y1), Vector2(x1 + b * w1, y1), Vector2(x2 + b * w2, y2), Vector2(x2 + a * w2, y2), col)
		elif alt == 0:
			for lx in lane_marks:
				var l1 := w1 * 0.022
				var l2 := w2 * 0.022
				var c1 := x1 + float(lx) * w1
				var c2 := x2 + float(lx) * w2
				_quad(pts, cols, idx, Vector2(c1 - l1, y1), Vector2(c1 + l1, y1), Vector2(c2 + l2, y2), Vector2(c2 - l2, y2), pal.lane)
	if idx.size() > 0:
		RenderingServer.canvas_item_add_triangle_array(pen.get_canvas_item(), idx, pts, cols)


func _quad(pts: PackedVector2Array, cols: PackedColorArray, idx: PackedInt32Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	var i := pts.size()
	pts.append(a)
	pts.append(b)
	pts.append(c)
	pts.append(d)
	cols.append(col)
	cols.append(col)
	cols.append(col)
	cols.append(col)
	idx.append(i)
	idx.append(i + 1)
	idx.append(i + 2)
	idx.append(i)
	idx.append(i + 2)
	idx.append(i + 3)


func _road_edges() -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := 1
	while n <= DRAW_N:
		if _py[n] < H + 80.0:
			var rw := _pw[n] * 1.1
			left.append(Vector2(_px[n] - rw, _py[n]))
			right.append(Vector2(_px[n] + rw, _py[n]))
		n += 1 if n < 12 else 3
	var col: Color = _palette().edge
	Crayon.path(pen, left, col, 4, 980)
	Crayon.path(pen, right, col, 4, 981)


func _player_car() -> void:
	var sp := speed / MAX_SPEED
	var bump := sin(t * 31.0) * (1.2 * sp + (5.0 if offroad and sp > 0.1 else 0.0))
	var wob := sin(t * 40.0) * 10.0 * hit_t
	var c := Vector2(640.0 + player_x * X_PX + wob, CAR_Y + bump)
	if nitro_t > 0.0:
		# speed lines
		var segs := PackedVector2Array()
		for i in 22:
			var a := Crayon.rnd(i * 37 + int(t * 30.0)) * PI
			var dir := Vector2(sin(a), absf(cos(a)) * 0.5 + 0.1).normalized()
			var r0 := 320.0 + absf(Crayon.rnd(i * 13 + int(t * 50.0))) * 220.0
			segs.append(Vector2(640, HZ) + dir * Vector2(r0, r0 * 0.6))
			segs.append(Vector2(640, HZ) + dir * Vector2(r0 + 220.0, (r0 + 220.0) * 0.6))
		pen.draw_multiline(segs, Color(1, 1, 1, 0.45), 4.0)
	car_rear(pen, c, 300.0, car_col, glow, vinyl, 400, Color(0, 0, 0, 0), "", true)
	if car_col == GOLD:
		_twinkles(c + Vector2(0, -100), Vector2(170, 70), 4)
	# candle antenna on the spoiler
	Crayon.rect(pen, Rect2(c + Vector2(100, -186), Vector2(9, 40)), Crayon.INK, 2, Crayon.YELLOW, 430)
	Crayon.flame(pen, c + Vector2(104.5, -196), 9, 431)
	Crayon.text(pen, c + Vector2(0, -61), "CHUMBO", 17, Crayon.INK, 1, 432, null, 0.2, false)
	if nitro_t > 0.0:
		for sx in [-1.0, 1.0]:
			Crayon.flame(pen, c + Vector2(sx * 70, -22 + sin(t * 50.0 + sx) * 4), 18 + sin(t * 37.0) * 4, 440 + int(sx))
	elif hit_t > 0.4:
		Crayon.cloud(pen, c + Vector2(0, -230), 34, Color(0.85, 0.85, 0.9, 0.9), 445)


## Little gold glints around the golden car.
func _twinkles(c: Vector2, r: Vector2, n: int) -> void:
	for i in n:
		var ph := fmod(t * 0.9 + i * 0.37, 1.0)
		var a := i * 2.4 + floorf(t * 0.9 + i * 0.37) * 1.3
		var sz := sin(ph * PI) * 16.0
		if sz > 1.0:
			Crayon.star(pen, c + Vector2(cos(a) * r.x, sin(a) * r.y), sz, Color(1, 0.95, 0.6), Color(1, 1, 0.85), 1150 + i)


func _paint_end() -> void:
	var k := end_k
	var sky := Color(0.05, 0.03, 0.12)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), sky)
	_paint_skyline()
	pen.draw_rect(Rect2(-2000, 560, W + 4000, 2000), Color(0.2, 0.19, 0.26))
	Crayon.line(pen, Vector2(-40, 560), Vector2(W + 40, 560), Crayon.INK, 5, 990)
	spr_house(pen, Vector2(930, 560), 1.55, 991)
	spr_banner(pen, Vector2(390, 560), "START", 992)
	car_side(pen, Vector2(390, 590), 1.25, t * 0.2, car_col, glow, vinyl, 993)
	for i in 5:
		var gp := Vector2(700 + i * 105, 610 + (i % 2) * 18)
		var up := clampf(k * 1.5 - i * 0.12, 0.0, 1.0)
		Crayon.person(pen, gp + Vector2(0, (1.0 - up) * 60.0), 120, Crayon.INK, "wide" if dark_laps else "happy", Crayon.RAINBOW[(i * 3) % 7],
			"up", t * 3.0 + i, 1000 + i * 10)


func paint_top() -> void:
	if phase == "garage":
		var gb := get_button("g_" + _glow_name().to_lower())
		var vb := get_button("v_" + vinyl.to_lower())
		for b in [gb, vb]:
			if not b.is_empty():
				Crayon.rect(pen, b.rect.grow(8), Crayon.YELLOW, 6, Color(0, 0, 0, 0), 1100)
		return
	if sky_mode == "garage" or phase == "end":
		return
	var y := 112.0 + (170.0 if Narrator.is_active() else 0.0)
	var ink := Crayon.WHITE
	if mode == "drag":
		_drag_hud(y)
	else:
		var total := 4 if mode == "sprint" else 2
		var p := _place()
		if mode == "circuit" and dark_laps:
			p = 2
		_hud_text(Vector2(30, y), "POS %d/%d" % [p, total], 44, Crayon.YELLOW, 0, 1110)
		if mode == "circuit":
			var lp := clampi(lap, 1, LAPS_REAL)
			_hud_text(Vector2(640, y), "LAP %d/%d" % [lp, LAPS_SHOWN], 46, Crayon.YELLOW if lp <= LAPS_SHOWN else Color(1, 0.3, 0.35), 1, 1111)
		else:
			_progress_bar(y, float(SPRINT_FINISH) * SEG_L, float(START_SEG) * SEG_L)
	var mph := int(speed / MAX_SPEED * 180.0)
	_hud_text(Vector2(1250, y), "%d MPH" % mph, 40, ink, 2, 1112)
	if mode != "drag":
		# nitro: three bottles
		for i in 3:
			var r := Rect2(1100 + i * 52, y + 30, 40, 22)
			var fill := clampf((nitro - i * 0.333) / 0.333, 0.0, 1.0)
			pen.draw_rect(Rect2(r.position, Vector2(r.size.x * fill, r.size.y)), Color(0.3, 0.8, 1.0) if fill >= 1.0 else Color(0.3, 0.6, 0.8))
			Crayon.rect(pen, r, Crayon.WHITE, 3, Color(0, 0, 0, 0), 1120 + i)
		var nb := get_button("nos")
		if not nb.is_empty():
			nb.col = Crayon.ORANGE if nitro >= 0.33 else Crayon.GREY
		if draft_t > 0.0:
			Crayon.text(pen, Vector2(1250, y + 76), "DRAFTING", 24, Color(0.4, 0.9, 1.0), 2, 1125, null, 0.4, false)
	if phase in ["race", "circuit"] and race_t < 5.0 and mode != "drag":
		Crayon.text(pen, Vector2(640, 462), "< MOVE TO STEER >", 30, Crayon.YELLOW, 1, 1130)


func _hud_text(p: Vector2, s: String, size: int, col: Color, align: int, sd: int) -> void:
	Crayon.text(pen, p + Vector2(3, 3), s, size, Color(0, 0, 0, 0.75), align, sd, Crayon.title_font())
	Crayon.text(pen, p, s, size, col, align, sd, Crayon.title_font())


func _glow_name() -> String:
	for k in GLOWS:
		if GLOWS[k] == glow:
			return k
	return "GREEN"


func _progress_bar(y: float, goal: float, from: float) -> void:
	var x0 := 440.0
	var x1 := 840.0
	Crayon.line(pen, Vector2(x0, y), Vector2(x1, y), Crayon.WHITE, 5, 1140)
	Crayon.text(pen, Vector2(x1 + 30, y - 2), "FINISH", 18, Crayon.WHITE, 0, 1141, null, 0.3, false)
	for r in rivals:
		var k := clampf((float(r.z) - from) / (goal - from), 0.0, 1.0)
		Crayon.disc(pen, Vector2(lerpf(x0, x1, k), y), 9, Crayon.GREY)
	var kp := clampf((player_z - from) / (goal - from), 0.0, 1.0)
	Crayon.circle(pen, Vector2(lerpf(x0, x1, kp), y), 12, Crayon.INK, 3, car_col, 1142)


func _drag_hud(y: float) -> void:
	var g: Dictionary = rivals[0] if rivals.size() > 0 else {}
	if not g.is_empty():
		_progress_bar(y, (START_SEG + DRAG_FINISH) * SEG_L, START_SEG * SEG_L)
	# rev counter
	var c := Vector2(170, 590)
	var r := 118.0
	Crayon.circle(pen, c, r, Crayon.WHITE, 6, Color(0.08, 0.07, 0.14, 0.92), 1150)
	var a0 := PI * 0.8
	var a1 := PI * 2.2
	var zones := [[0.0, GREEN_LO, Color(0.6, 0.6, 0.7)], [GREEN_LO, GREEN_HI, Color(0.3, 1.0, 0.4)], [GREEN_HI, 1.0, Color(1.0, 0.25, 0.25)]]
	for z in zones:
		var pts := PackedVector2Array()
		for i in 9:
			var f := lerpf(float(z[0]), float(z[1]), i / 8.0)
			var a := lerpf(a0, a1, f)
			pts.append(c + Vector2(cos(a), sin(a)) * (r - 18.0))
		Crayon.path(pen, pts, z[2], 14, 1151)
	var nf := clampf(rpm, 0.0, 1.03)
	var na := lerpf(a0, a1, nf)
	Crayon.line(pen, c, c + Vector2(cos(na), sin(na)) * (r - 26.0), Crayon.RED, 6, 1152, 0.3)
	Crayon.disc(pen, c, 12, Crayon.WHITE)
	Crayon.text(pen, c + Vector2(0, 54), "GEAR %d" % gear, 28, Crayon.WHITE, 1, 1153, Crayon.title_font(), 0.4)
	var sb := get_button("shift")
	if not sb.is_empty():
		var hot := rpm >= GREEN_LO and rpm <= GREEN_HI and gear < 5
		sb.col = Color(0.3, 1.0, 0.4) if hot else (Crayon.GREY if gear >= 5 else Crayon.GREEN.darkened(0.25))
		sb.label = "SHIFT!" if gear < 5 else "TOP GEAR"
	if phase == "drag" and rpm >= GREEN_HI and gear < 5:
		Crayon.text(pen, c + Vector2(0, -150), "SHIFT!", 40, Crayon.RED, 1, 1154, Crayon.title_font())
