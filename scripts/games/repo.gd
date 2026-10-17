extends Screen
## Present 9: R.E.P.O. - Retrieve Every Party Object (haul-the-valuables game).
## Chumbo is a little robot with a grab beam. Carry the birthday valuables through the dark
## house to the party truck without bumping them, reach the quota, extract. Then the house
## fills up with Chumbo's own things, the quota keeps going up... and the last valuable is him.

const IDX := 8
const MAP := Rect2(40, 96, 1200, 540)
const RW := 400.0
const RH := 270.0
const WALL := 12.0
const DOOR := 130.0
const ROOMS := [["KITCHEN", "LIVING ROOM", "LIBRARY"], ["DINING ROOM", "GARAGE", "BEDROOM"]]
const ZONE := Vector2(640, 482)
const ZONE_R := Vector2(104, 44)
const START := Vector2(560, 420)
const GRAB_R := 150.0
const BEAM_LEN := 62.0
const ITEM_R := 18.0
const PEEPER := Vector2(1040, 205)
const TV := Rect2(600, 566, 80, 54)
const QUOTA1 := 5000
const QUOTA2 := [40000, 400000, 9999999]

## [name, kind, value, fragility, position]
const LOOT1 := [
	["Fancy Cake", "cake", 600, 1.4, Vector2(150, 190)],
	["Crystal Party Hat", "hat", 900, 2.0, Vector2(170, 520)],
	["Golden Present", "present", 800, 0.6, Vector2(560, 175)],
	["Grandma's Vase", "vase", 1200, 1.8, Vector2(1150, 290)],
	["Cuckoo Clock", "clock", 700, 1.2, Vector2(1130, 520)],
	["Pinata", "pinata", 500, 0.5, Vector2(330, 300)],
	["Disco Ball", "disco", 1000, 1.5, Vector2(740, 290)],
	["Golden Trophy", "trophy", 600, 0.7, Vector2(930, 590)],
]
const LOOT2 := [
	["Your 1st Birthday Cake", "cake1", 1500, 1.6, Vector2(150, 190)],
	["Party Hat (says CHUMBO)", "namehat", 900, 1.0, Vector2(560, 175)],
	["Photo: You and... somebody", "photo", 1200, 1.4, Vector2(1150, 290)],
	["Your Teddy", "teddy", 700, 0.3, Vector2(170, 520)],
	["Your Birthday Candle", "candle", 500, 1.0, Vector2(330, 300)],
	["Your Name Tag", "nametag", 800, 0.5, Vector2(1130, 520)],
	["Every Present You Ever Got", "presents", 2000, 0.8, Vector2(740, 290)],
]

var phase := "intro"     # intro, run1, extract, taxman, upgrade, twist, run2, final, done
var run := 1
var playing := false
var bot_pos := START
var face := Vector2(1, 0)
var path: Array = []
var want_grab := {}
var carried := {}
var items: Array = []
var haul := 0
var quota := QUOTA1
var deposited := 0
var quota_met := false
var gnomes: Array = []
var duck := {}
var pops: Array = []
var stun_t := 0.0
var dizzy := 0.0
var speed_mul := 1.0
var beam_k := 60.0
var beam_d := 9.0
var dmg_mul := 1.0
var lit := 0.0
var tv_on := false
var tv_mood := "smirk"
var count_t := -1.0
var truck_shut := 0.0
var banner := ""
var banner_t := 0.0
var self_beam := 0.0
var bot_float := 0.0
var said := {}

var _walls: Array = []
var _hole: GradientTexture2D
var _hole_r := 0.0
var _baked_run := -1


func enter() -> void:
	Narrator.top = true
	use_back_layer()
	_build_walls()
	_spawn_loot(LOOT1)
	duck = {"pos": START + Vector2(-80, 30), "state": "cute", "t": 0.0, "k": 1.0, "quack": 3.0}
	Audio.play_music("repo")
	_run()


func _run() -> void:
	locked = true
	await wait(0.4)
	await say("Present number nine! It's R.E.P.O.! You're a little robot, and the party needs its valuables back. Tap to walk. Tap a valuable to grab it with your beam!")
	tv_on = true
	Audio.sfx("static", -14)
	await say("Quota is five thousand dollars, kid. Bring the goods to my truck. Don't break anything.", Narrator.TAXMAN)
	tv_on = false
	phase = "run1"
	playing = true
	locked = false


# ---------------------------------------------------------------- map + pathing

func _build_walls() -> void:
	var x0 := MAP.position.x
	var y0 := MAP.position.y
	var x1 := MAP.end.x
	var y1 := MAP.end.y
	var h := WALL * 0.5
	_walls = [Rect2(x0 - h, y0 - h, MAP.size.x + WALL, WALL), Rect2(x0 - h, y1 - h, MAP.size.x + WALL, WALL),
		Rect2(x0 - h, y0 - h, WALL, MAP.size.y + WALL), Rect2(x1 - h, y0 - h, WALL, MAP.size.y + WALL)]
	# inner walls, each with a doorway in the middle of every room side
	for c in [1, 2]:
		var x: float = x0 + c * RW
		var ys := [y0, y0 + RH * 0.5 - DOOR * 0.5, y0 + RH * 0.5 + DOOR * 0.5, y0 + RH * 1.5 - DOOR * 0.5, y0 + RH * 1.5 + DOOR * 0.5, y1]
		for k in [0, 2, 4]:
			_walls.append(Rect2(x - h, ys[k], WALL, ys[k + 1] - ys[k]))
	var y: float = y0 + RH
	var xs := [x0]
	for c in 3:
		xs.append(x0 + RW * (c + 0.5) - DOOR * 0.5)
		xs.append(x0 + RW * (c + 0.5) + DOOR * 0.5)
	xs.append(x1)
	for k in range(0, xs.size(), 2):
		_walls.append(Rect2(xs[k], y - h, xs[k + 1] - xs[k], WALL))


func _room_of(p: Vector2) -> Vector2i:
	return Vector2i(clampi(int((p.x - MAP.position.x) / RW), 0, 2), clampi(int((p.y - MAP.position.y) / RH), 0, 1))


func _room_rect(r: Vector2i) -> Rect2:
	return Rect2(MAP.position + Vector2(r.x * RW, r.y * RH), Vector2(RW, RH))


func _clamp_in_room(p: Vector2, m: float = 36.0) -> Vector2:
	var rr := _room_rect(_room_of(p)).grow(-m)
	return p.clamp(rr.position, rr.end)


## Waypoints from where Chumbo is to p, straight through the middle of each doorway.
func _walk_to(p: Vector2) -> void:
	p = _clamp_in_room(p.clamp(MAP.position, MAP.end - Vector2(1, 1)))
	var a := _room_of(bot_pos)
	var b := _room_of(p)
	var rooms: Array = [a]
	var cur := a
	while cur != b:
		# the house is a 2x3 grid with a door between every pair of neighbours: step along x first
		if cur.x != b.x:
			cur = Vector2i(cur.x + signi(b.x - cur.x), cur.y)
		else:
			cur = Vector2i(cur.x, cur.y + signi(b.y - cur.y))
		rooms.append(cur)
	path.clear()
	for i in range(1, rooms.size()):
		var r0: Vector2i = rooms[i - 1]
		var r1: Vector2i = rooms[i]
		var n := Vector2(r1 - r0)
		var door: Vector2
		if n.x != 0:
			door = Vector2(MAP.position.x + maxi(r0.x, r1.x) * RW, MAP.position.y + (r0.y + 0.5) * RH)
		else:
			door = Vector2(MAP.position.x + (r0.x + 0.5) * RW, MAP.position.y + maxi(r0.y, r1.y) * RH)
		path.append(door - n * 50.0)
		path.append(door + n * 50.0)
	path.append(p)


func _in_zone(p: Vector2) -> bool:
	var d := (p - ZONE) / ZONE_R
	return d.length() < 1.0


# ---------------------------------------------------------------- input

func press(p: Vector2) -> void:
	if not playing or stun_t > 0.0:
		return
	if duck.state == "cute" and p.distance_to(duck.pos) < 40.0:
		_poke_duck()
		return
	for g in gnomes:
		if g.stun <= 0.0 and p.distance_to(g.pos) < 46.0:
			_bonk(g)
			return
	if not carried.is_empty() and p.distance_to(carried.pos) < 40.0:
		_drop()
		return
	for it in items:
		if it.state == "free" and p.distance_to(it.pos) < 46.0:
			if not carried.is_empty():
				_drop()
			want_grab = it
			if bot_pos.distance_to(it.pos) < GRAB_R:
				_grab(it)
			else:
				_walk_to(it.pos)
			return
	want_grab = {}
	_walk_to(p)


func _grab(it: Dictionary) -> void:
	want_grab = {}
	path.clear()
	carried = it
	it.state = "carried"
	it.cool = 0.4
	Audio.sfx("beam", -6)
	if not said.has("grab"):
		said["grab"] = true
		say_bg("Got it! Now carry it to the truck. Go slow through the doorways!")
	if run == 2:
		match String(it.kind):
			"cake1":
				say_bg("Your very first birthday cake. It's still warm.", Narrator.DARK)
			"photo":
				say_bg("A photo of you and... somebody. You can't remember who.", Narrator.DARK)
			"namehat":
				say_bg("It has your name on it. Everything in this house has your name on it.", Narrator.DARK)


func _drop() -> void:
	if carried.is_empty():
		return
	carried.state = "free"
	carried = {}


func _bonk(g: Dictionary) -> void:
	g.stun = 4.0
	g.vel = (g.pos - bot_pos).normalized() * 380.0
	Audio.sfx("bonk", -4)
	_pop(g.pos + Vector2(0, -30), "BONK!", Crayon.YELLOW)


func _poke_duck() -> void:
	duck.state = "angry"
	duck.t = 7.0
	Audio.sfx("quack_angry")
	_pop(duck.pos + Vector2(0, -60), "QUACK!!", Crayon.RED)
	if not said.has("duck"):
		said["duck"] = true
		say_bg("Oh no. You poked the duck. RUN!", Narrator.HYPE)


# ---------------------------------------------------------------- update

func tick(dt: float) -> void:
	banner_t = maxf(0.0, banner_t - dt)
	for pp in pops:
		pp.t -= dt
		pp.p.y -= 40.0 * dt
	pops = pops.filter(func(pp): return pp.t > 0.0)
	_light(dt)
	if phase == "final":
		_final_tick(dt)
	if count_t >= 0.0:
		count_t -= dt
	if not playing:
		_move_items(dt)
		return
	stun_t = maxf(0.0, stun_t - dt)
	_move_bot(dt)
	_move_items(dt)
	_move_duck(dt)
	_move_gnomes(dt)
	if not want_grab.is_empty() and want_grab.state == "free" and bot_pos.distance_to(want_grab.pos) < GRAB_R * 0.8:
		_grab(want_grab)
	if not carried.is_empty() and (_in_zone(carried.pos) or _in_zone(bot_pos)):
		_deposit(carried)


func _light(dt: float) -> void:
	var want := 0.0
	if phase in ["extract", "taxman", "upgrade"]:
		want = 0.55
	elif phase == "final" or phase == "done":
		want = 0.45
	lit = move_toward(lit, want, dt * 1.5)


func _move_bot(dt: float) -> void:
	var sp := 235.0 * speed_mul
	if not carried.is_empty():
		sp *= 0.85
	# the Peeper's stare makes you slow and dizzy
	var stare := bot_pos.distance_to(PEEPER) < 215.0
	if stare:
		sp *= 0.38
		dizzy = minf(1.0, dizzy + dt * 2.0)
		if not said.has("peeper"):
			said["peeper"] = true
			say_bg("Don't look at the big eye! It makes you dizzy.")
	else:
		dizzy = maxf(0.0, dizzy - dt * 1.5)
	if stun_t > 0.0 or path.is_empty():
		return
	var tgt: Vector2 = path[0]
	var d := tgt - bot_pos
	var step := sp * dt
	if d.length() <= step:
		bot_pos = tgt
		path.pop_front()
	else:
		bot_pos += d.normalized() * step
	if d.length() > 0.5:
		face = face.lerp(d.normalized(), minf(1.0, dt * 9.0)).normalized()


## The carried thing hangs on a springy beam in front of Chumbo; free things slide to a stop.
## Bumping a wall knocks value off.
func _move_items(dt: float) -> void:
	for it in items:
		if it.state == "gone":
			continue
		it.cool = maxf(0.0, it.cool - dt)
		if it.state == "carried":
			var anchor := bot_pos + face * BEAM_LEN + Vector2(sin(t * 7.0), cos(t * 5.0)) * dizzy * 30.0
			var acc: Vector2 = (anchor - it.pos) * beam_k - it.vel * beam_d
			it.vel += acc * dt
		else:
			it.vel = it.vel.move_toward(Vector2.ZERO, 900.0 * dt)
		it.pos += it.vel * dt
		if it.state == "carried":
			var off: Vector2 = it.pos - bot_pos
			if off.length() > 140.0:
				it.pos = bot_pos + off.normalized() * 140.0
		for w in _walls:
			var r: Rect2 = w
			var q := Vector2(clampf(it.pos.x, r.position.x, r.end.x), clampf(it.pos.y, r.position.y, r.end.y))
			var dv: Vector2 = it.pos - q
			var dist := dv.length()
			if dist >= ITEM_R:
				continue
			var n := dv / dist if dist > 0.01 else Vector2(0, -1)
			it.pos = q + n * ITEM_R
			var vn: float = (it.vel as Vector2).dot(n)
			if vn < 0.0:
				it.vel -= n * vn * 1.4
				if -vn > 85.0 and it.cool <= 0.0 and it.state == "carried":
					_damage(it, float(it.base) * 0.05 * float(it.frag) * clampf(-vn / 200.0, 0.5, 2.0) * dmg_mul)
					it.cool = 0.35


func _damage(it: Dictionary, amt: float) -> void:
	var floor_v := int(it.base * 0.2)
	var loss := mini(int(roundf(amt / 10.0) * 10.0), it.value - floor_v)
	if loss <= 0:
		return
	it.value -= loss
	Audio.sfx("clank", -6, randf_range(0.9, 1.3))
	_pop(it.pos + Vector2(0, -26), "-$%d" % loss, Crayon.RED)
	if not said.has("bump"):
		said["bump"] = true
		say_bg("Careful! Every bump knocks money off.")


func _move_duck(dt: float) -> void:
	duck.t -= dt
	var target: Vector2 = bot_pos - face * 72.0 + Vector2(-20, 24)
	var sp := 210.0
	if duck.state == "angry":
		target = bot_pos
		sp = 205.0 * maxf(1.0, speed_mul * 0.95)
		duck.k = move_toward(duck.k, 2.3, dt * 4.0)
		if duck.pos.distance_to(bot_pos) < 50.0 * duck.k * 0.5:
			_duck_hit()
		elif duck.t <= 0.0:
			duck.state = "cute"
	else:
		duck.k = move_toward(duck.k, 1.0, dt * 2.0)
		duck.quack -= dt
		if duck.quack <= 0.0:
			duck.quack = randf_range(4.0, 9.0)
			Audio.sfx("quack", -12, randf_range(0.95, 1.1))
	var d: Vector2 = target - duck.pos
	if d.length() > 6.0:
		duck.pos += d.normalized() * minf(d.length(), sp * dt) * (1.0 if d.length() > 30.0 or duck.state == "angry" else 0.3)
	if not said.has("duckhi") and phase == "run1" and t > 3.0:
		said["duckhi"] = true
		say_bg("This is the duck. It follows you everywhere. Whatever you do, don't poke the duck.")


func _duck_hit() -> void:
	duck.state = "cute"
	Audio.sfx("thud")
	Audio.sfx("quack_angry", -4, 1.2)
	stun_t = 0.9
	_pop(bot_pos + Vector2(0, -60), "BONK!", Crayon.RED)
	if not carried.is_empty():
		var it := carried
		_damage(it, float(it.base) * 0.1)
		_drop()
		it.vel = (it.pos - duck.pos).normalized() * 420.0


func _move_gnomes(dt: float) -> void:
	for g in gnomes:
		if g.stun > 0.0:
			g.stun -= dt
			g.vel = (g.vel as Vector2).move_toward(Vector2.ZERO, 700.0 * dt)
			g.pos = _clamp_in_room(g.pos + g.vel * dt, 20.0)
			continue
		var target: Vector2 = g.wander
		if not carried.is_empty():
			target = carried.pos
		elif g.pos.distance_to(target) < 20.0:
			g.wander = _clamp_in_room(MAP.position + Vector2(randf() * MAP.size.x, randf() * MAP.size.y))
		var d: Vector2 = target - g.pos
		var sp := 105.0 if run == 1 else 125.0
		g.pos += d.normalized() * minf(d.length(), sp * dt)
		g.step += dt * 12.0
		if not carried.is_empty() and g.pos.distance_to(carried.pos) < 30.0:
			g.chip -= dt
			if g.chip <= 0.0:
				g.chip = 0.9
				_damage(carried, 40.0)
				Audio.sfx("giggle", -10, 1.4)


func _spawn_gnomes(n: int) -> void:
	for k in n:
		var corner := Vector2(MAP.position.x + 60 + (k % 3) * 540, MAP.position.y + 50 + (k % 2) * 440)
		gnomes.append({"pos": corner, "vel": Vector2.ZERO, "stun": 0.0, "wander": corner, "chip": 0.9, "step": 0.0, "col": Crayon.RAINBOW[(k * 2 + 1) % 7]})


func _spawn_loot(list: Array) -> void:
	items.clear()
	for e in list:
		items.append({"name": e[0], "kind": e[1], "base": e[2], "value": e[2], "frag": e[3], "pos": e[4], "vel": Vector2.ZERO, "state": "free", "cool": 0.0})


func _pop(p: Vector2, txt: String, col: Color) -> void:
	pops.append({"p": p, "txt": txt, "col": col, "t": 1.3})


# ---------------------------------------------------------------- hauling

func _deposit(it: Dictionary) -> void:
	carried = {}
	it.state = "gone"
	haul += int(it.value)
	deposited += 1
	Audio.sfx("cash", -2)
	_pop(ZONE + Vector2(0, -60), "+$%d" % it.value, Crayon.GREEN.lightened(0.3))
	var left := items.filter(func(x): return x.state != "gone").size()
	if run == 1:
		match deposited:
			1:
				say_bg("Ka-ching! Everything in the truck counts toward the quota.")
			2:
				_spawn_gnomes(2)
				say_bg("Party gnomes! They chip pieces off your stuff. Tap them to bonk them away!")
		if not quota_met and (haul >= quota or left == 0):
			quota_met = true
			if haul < quota:
				tv_on = true
				say_bg("Close enough, kid. It's your birthday.", Narrator.TAXMAN)
			else:
				say_bg("Quota reached! Tap EXTRACT when you're ready!")
			Audio.sfx("levelup", -4)
			add_button("extract", Rect2(1000, 642, 260, 70), "EXTRACT!", _extract, Crayon.GREEN, 40)
	else:
		match deposited:
			2:
				quota = QUOTA2[1]
				banner = "QUOTA: $400,000"
				banner_t = 2.5
				Audio.sfx("glitch", -4)
				say_bg("The quota went up. It always goes up.", Narrator.DARK)
			4:
				quota = QUOTA2[2]
				banner = "QUOTA: $9,999,999"
				banner_t = 2.5
				Audio.sfx("glitch", -4)
				say_bg("Nine million dollars. It's never enough, kid. It's never enough.", Narrator.TAXMAN)
		if left == 0:
			_final()


func _extract() -> void:
	if phase != "run1":
		return
	remove_button("extract")
	phase = "extract"
	playing = false
	locked = true
	_drop()
	path.clear()
	Audio.sfx("alarm")
	count_t = 3.0
	await wait(3.2)
	var tw := create_tween()
	tw.tween_property(self, "truck_shut", 1.0, 0.6)
	Audio.sfx("thud")
	banner = "EXTRACTED!  $%s" % _money(haul)
	banner_t = 3.0
	await wait(1.2)
	phase = "taxman"
	tv_on = true
	Audio.sfx("static", -12)
	await say("Not bad, kid. That's a whole lot of birthday.", Narrator.TAXMAN)
	await say("Pick an upgrade. You're going to need it.", Narrator.TAXMAN)
	phase = "upgrade"
	add_button("up1", Rect2(330, 300, 290, 110), "STRONGER BEAM", func(): _upgrade(1), Color(0.45, 0.75, 1.0), 34)
	add_button("up2", Rect2(660, 300, 290, 110), "FASTER LEGS", func(): _upgrade(2), Crayon.ORANGE, 34)
	locked = false


func _upgrade(which: int) -> void:
	if phase != "upgrade":
		return
	remove_button("up1")
	remove_button("up2")
	locked = true
	Audio.sfx("levelup")
	if which == 1:
		beam_k = 110.0
		beam_d = 17.0
		dmg_mul = 0.6
		_pop(bot_pos + Vector2(0, -70), "BEAM UP!", Crayon.SKY)
	else:
		speed_mul = 1.3
		_pop(bot_pos + Vector2(0, -70), "SPEED UP!", Crayon.ORANGE)
	await wait(0.8)
	_twist()


func _twist() -> void:
	phase = "twist"
	run = 2
	tv_mood = "wide"
	Audio.play_music("repo_dark", 2.0)
	Audio.sfx("creak")
	var tw := create_tween()
	tw.tween_property(self, "truck_shut", 0.0, 0.6)
	refresh_back()
	_spawn_loot(LOOT2)
	haul = 0
	deposited = 0
	quota = QUOTA2[0]
	bot_pos = START
	face = Vector2(1, 0)
	gnomes.clear()
	_spawn_gnomes(3)
	duck = {"pos": START + Vector2(-80, 30), "state": "cute", "t": 0.0, "k": 1.0, "quack": 5.0}
	await say("Run two. Same house. But these aren't party things anymore, Chumbo.", Narrator.DARK)
	await say("These are your things.", Narrator.DARK)
	await say("New quota: forty thousand dollars. Happy birthday, kid.", Narrator.TAXMAN)
	tv_on = false
	phase = "run2"
	playing = true
	locked = false


## Nothing left to haul, still short of the quota. One valuable left in the house.
func _final() -> void:
	phase = "final"
	playing = false
	locked = true
	path.clear()
	await wait(0.8)
	tv_on = true
	Audio.sfx("static", -12)
	await say("Still short, kid. But there's one valuable left in this house.", Narrator.TAXMAN)
	await say("The most valuable thing at every party.", Narrator.TAXMAN)
	Audio.sfx("beam")
	Audio.sfx("alarm", -6)
	var tw := create_tween()
	tw.tween_property(self, "self_beam", 1.0, 0.6)
	await wait(0.7)
	await say("Bring the birthday boy back to the party.", Narrator.CREEPY)
	var tw2 := create_tween()
	tw2.tween_property(self, "bot_float", 1.0, 2.4).set_trans(Tween.TRANS_SINE)
	await wait(2.5)
	Audio.sfx("thud")
	var tw3 := create_tween()
	tw3.tween_property(self, "truck_shut", 1.0, 0.6)
	banner = "EXTRACTED: CHUMBO  -  PRICELESS"
	banner_t = 4.0
	Audio.sfx("cash")
	await wait(1.4)
	await say("There. Safe and sound, back at the party. Where you belong.", Narrator.DARK)
	phase = "done"
	Audio.play_music("repo", 1.5)
	await say("Present number nine, done! Great hauling, little robot!")
	finish_game(IDX, "EXTRACTED!")


var _float_from := Vector2.ZERO


func _final_tick(_dt: float) -> void:
	if bot_float <= 0.0:
		_float_from = bot_pos
	else:
		# up in the beam, then into the back of the truck
		var into := Vector2(640, 600)
		bot_pos = _float_from.lerp(into, bot_float) + Vector2(0, -sin(bot_float * PI) * 70.0)


func _money(v: int) -> String:
	var s := str(v)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


# ---------------------------------------------------------------- drawing

func paint_back() -> void:
	_baked_run = run
	var dark := run == 2
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.12, 0.1, 0.14) if not dark else Color(0.06, 0.03, 0.06))
	var floors := [[Color(0.88, 0.86, 0.8), Color(0.78, 0.6, 0.42), Color(0.55, 0.32, 0.3)],
		[Color(0.72, 0.5, 0.36), Color(0.6, 0.62, 0.66), Color(0.55, 0.6, 0.82)]]
	for ry in 2:
		for rx in 3:
			var r := _room_rect(Vector2i(rx, ry))
			var col: Color = floors[ry][rx]
			if dark:
				col = col.darkened(0.45).lerp(Color(0.3, 0.1, 0.15), 0.25)
			pen.draw_rect(r, col)
			# floor pattern: tiles, planks or carpet stripes
			var lc := col.darkened(0.12)
			if rx == 0 and ry == 0:
				for k in 9:
					pen.draw_line(Vector2(r.position.x + k * 50, r.position.y), Vector2(r.position.x + k * 50, r.end.y), lc, 2.0)
				for k in 6:
					pen.draw_line(Vector2(r.position.x, r.position.y + k * 50), Vector2(r.end.x, r.position.y + k * 50), lc, 2.0)
			else:
				for k in 8:
					pen.draw_line(Vector2(r.position.x, r.position.y + 18 + k * 34), Vector2(r.end.x, r.position.y + 18 + k * 34), lc, 3.0)
			Crayon.text(pen, r.position + Vector2(r.size.x * 0.5, 22), ROOMS[ry][rx], 22, Color(Crayon.INK, 0.55), 1, 30 + rx + ry * 3, null, 0.4, false)
	_furniture(dark)
	for w in _walls:
		pen.draw_rect(w, Color(0.2, 0.16, 0.2) if not dark else Color(0.12, 0.05, 0.1))
	for w in _walls:
		var r: Rect2 = w
		if r.size.x > r.size.y:
			Crayon.line(pen, Vector2(r.position.x, r.get_center().y), Vector2(r.end.x, r.get_center().y), Crayon.INK, 6, int(r.position.x + r.position.y) % 500)
		else:
			Crayon.line(pen, Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y), Crayon.INK, 6, int(r.position.x + r.position.y) % 500)
	_truck_back(dark)


func _furniture(dark: bool) -> void:
	var ink := Crayon.INK
	var k := 0.45 if dark else 0.0
	# kitchen: counter + stove
	Crayon.rect(pen, Rect2(60, 120, 300, 46), ink, 4, Color(0.85, 0.85, 0.9).darkened(k), 200)
	Crayon.rect(pen, Rect2(250, 124, 60, 38), ink, 3, Color(0.3, 0.3, 0.32), 201)
	# living room: couch + rug + tv
	Crayon.rect(pen, Rect2(480, 290, 200, 54), ink, 4, Crayon.BLUE.darkened(0.2).darkened(k), 210)
	Crayon.ellipse(pen, Vector2(640, 230), Vector2(110, 40), ink, 3, Crayon.PURPLE.lightened(0.2).darkened(k), 211)
	Crayon.rect(pen, Rect2(760, 124, 60, 40), ink, 3, Color(0.2, 0.2, 0.25), 212)
	# library: bookshelves
	for i in 3:
		Crayon.rect(pen, Rect2(870 + i * 110, 118, 90, 40), ink, 3, Crayon.BROWN.darkened(k), 220 + i)
		for j in 5:
			pen.draw_rect(Rect2(876 + i * 110 + j * 16, 124, 10, 28), (Crayon.RAINBOW[(i + j) % 7] as Color).darkened(k))
	# dining: long table with chairs
	Crayon.rect(pen, Rect2(120, 430, 200, 70), ink, 4, Crayon.BROWN.lightened(0.15).darkened(k), 230)
	for i in 4:
		Crayon.rect(pen, Rect2(130 + i * 50, 408, 26, 18), ink, 2, Crayon.BROWN.darkened(k), 231 + i)
	# bedroom: bed
	Crayon.rect(pen, Rect2(1060, 400, 150, 100), ink, 4, Crayon.PINK.lightened(0.2).darkened(k), 240)
	Crayon.rect(pen, Rect2(1060, 400, 150, 30), ink, 3, Crayon.WHITE.darkened(k), 241)
	if dark:
		# PARTY banners everywhere now
		for i in 6:
			var p := Vector2(110 + i * 205, 104)
			Crayon.text(pen, p, "PARTY", 18, Color(0.85, 0.3, 0.4, 0.8), 1, 250 + i, null, 0.5, false)


func _truck_back(dark: bool) -> void:
	# the party truck in the garage, back doors open
	var body := Rect2(530, 548, 220, 82)
	Crayon.rect(pen, body, Crayon.INK, 5, Color(0.95, 0.55, 0.7) if not dark else Color(0.45, 0.2, 0.3), 260)
	for i in 5:
		pen.draw_rect(Rect2(body.position + Vector2(12 + i * 42, 62), Vector2(24, 10)), Crayon.RAINBOW[i])
	Crayon.text(pen, body.position + Vector2(176, 30), "PARTY", 18, Crayon.WHITE, 1, 261, null, 0.5, false)
	Crayon.text(pen, body.position + Vector2(176, 52), "TRUCK", 18, Crayon.WHITE, 1, 262, null, 0.5, false)
	Crayon.rect(pen, TV, Crayon.INK, 4, Color(0.15, 0.18, 0.15), 263)


func paint() -> void:
	if run != _baked_run:
		refresh_back()
	# extraction zone (glows even in the dark - see paint_top)
	var glow := 0.25 + 0.1 * sin(t * 4.0)
	Crayon.ellipse(pen, ZONE, ZONE_R, Color(0.3, 1.0, 0.5, 0.8), 4, Color(0.3, 1.0, 0.5, glow), 300)
	# truck doors
	if truck_shut > 0.0:
		var dw := 110.0 * truck_shut
		pen.draw_rect(Rect2(530, 548 - 40 * truck_shut, 220, 40 * truck_shut), Color(0.95, 0.55, 0.7) if run == 1 else Color(0.45, 0.2, 0.3))
		Crayon.line(pen, Vector2(640 - dw, 548), Vector2(640 + dw, 548), Crayon.INK, 5, 301)
	for it in items:
		if it.state == "gone":
			continue
		_draw_item(it, it.pos)
	# the beam
	if not carried.is_empty():
		var hand := bot_pos + face * 18.0 + Vector2(0, -14)
		pen.draw_line(hand, carried.pos, Color(0.3, 0.7, 1.0, 0.35), 12.0)
		Crayon.line(pen, hand, carried.pos, Color(0.55, 0.85, 1.0), 4, 310, 0.6)
	if self_beam > 0.0 and bot_float < 0.98:
		var from := TV.get_center()
		var to := from.lerp(bot_pos + Vector2(0, -8), self_beam)
		pen.draw_line(from, to, Color(0.3, 0.7, 1.0, 0.4), 16.0)
		Crayon.line(pen, from, to, Color(0.6, 0.9, 1.0), 5, 311, 0.6)
	for g in gnomes:
		_gnome(g)
	_duck(duck.pos, duck.k, duck.state == "angry")
	var sc := 1.0 - bot_float * 0.7
	if bot_float < 0.99:
		_bot(pen, bot_pos + Vector2(0, 22), sc, t, face, dizzy, stun_t > 0.0)
		Crayon.text(pen, bot_pos + Vector2(0, -66 * sc), "Chumbo", 18, Crayon.WHITE, 1, 320, null, 0.4, false)
	if bot_float > 0.0 and bot_float < 0.99:
		for k in 5:
			var a := t * 4.0 + k * TAU / 5.0
			Crayon.star(pen, bot_pos + Vector2(cos(a), sin(a)) * 40.0 * sc, 6, Color(0.6, 0.9, 1.0), Color(0.8, 0.95, 1.0), 330 + k)
	_darkness()


func _darkness() -> void:
	var a := (0.86 if run == 1 else 0.94) * (1.0 - lit)
	if a <= 0.01:
		return
	var r := 230.0 if run == 1 else 175.0
	if _hole == null or _hole_r != r:
		_hole_r = r
		_hole = _make_hole_texture(r)
	var ro := r + 60.0
	var c := bot_pos
	var sq := Rect2(c - Vector2(ro, ro), Vector2(ro, ro) * 2.0)
	var big := Rect2(-2000, -2000, W + 4000, H + 4000)
	var col := Color(0.02, 0.01, 0.05, a)
	pen.draw_rect(Rect2(big.position.x, big.position.y, big.size.x, sq.position.y - big.position.y), col)
	pen.draw_rect(Rect2(big.position.x, sq.end.y, big.size.x, big.end.y - sq.end.y), col)
	pen.draw_rect(Rect2(big.position.x, sq.position.y, sq.position.x - big.position.x, sq.size.y), col)
	pen.draw_rect(Rect2(sq.end.x, sq.position.y, big.end.x - sq.end.x, sq.size.y), col)
	pen.draw_texture_rect(_hole, sq, false, Color(1, 1, 1, a))


func _make_hole_texture(r: float) -> GradientTexture2D:
	var ro := r + 60.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, r / ro * 0.75, 1.0])
	g.colors = PackedColorArray([Color(0.02, 0.01, 0.05, 0.0), Color(0.02, 0.01, 0.05, 0.0), Color(0.02, 0.01, 0.05, 1.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func paint_top() -> void:
	# things you can always see in the dark: the truck light, the eye, sparkly valuables
	Crayon.ellipse(pen, ZONE, ZONE_R + Vector2(6, 4), Color(0.4, 1.0, 0.55, 0.55 + 0.25 * sin(t * 4.0)), 3, Color(0, 0, 0, 0), 330)
	if phase in ["run1", "run2"] and not carried.is_empty():
		Crayon.text(pen, ZONE + Vector2(0, 0), "TRUCK", 22, Color(0.6, 1.0, 0.7, 0.8), 1, 331, null, 0.4, false)
	_peeper()
	for it in items:
		if it.state == "free" and it.pos.distance_to(bot_pos) > (230.0 if run == 1 else 175.0):
			var tw := 0.5 + 0.5 * sin(t * 3.0 + it.pos.x)
			Crayon.star(pen, it.pos + Vector2(10, -16), 7 + tw * 3, Color(1, 1, 0.7, 0.8), Color(1, 0.95, 0.4, 0.5 + tw * 0.4), int(it.pos.x) % 97)
	if tv_on or phase == "run2" or phase == "twist" or phase == "final":
		_taxman(TV)
	for pp in pops:
		Crayon.text(pen, pp.p, pp.txt, 30, Color(pp.col, clampf(pp.t * 1.5, 0.0, 1.0)), 1, 340, Crayon.title_font())
	_hud()
	if count_t >= 0.0 and phase == "extract":
		Crayon.text(pen, Vector2(W * 0.5, 300), "EXTRACTING... %d" % int(ceil(count_t)), 64, Crayon.GREEN.lightened(0.3), 1, 350, Crayon.title_font())
	if banner_t > 0.0:
		var a := clampf(banner_t * 2.0, 0.0, 1.0)
		pen.draw_rect(Rect2(-2000, 330, W + 4000, 90), Color(0, 0, 0, 0.55 * a))
		Crayon.text(pen, Vector2(W * 0.5, 375), banner, 50, Color(1.0, 0.85, 0.3, a), 1, 351, Crayon.title_font())


func _hud() -> void:
	var y := 14.0
	if Narrator.is_active():
		# slide down under the narrator box (and its name tag)
		y = 16.0 + 46.0 + Narrator._lines.size() * Narrator._font_size() * 1.15 + 46.0
	var bar := Rect2(360, y + 8, 520, 30)
	Crayon.rect(pen, bar, Crayon.INK, 4, Color(0.15, 0.15, 0.2, 0.9), 360)
	var f := clampf(float(haul) / float(quota), 0.0, 1.0)
	if f > 0.0:
		pen.draw_rect(Rect2(bar.position + Vector2(4, 4), Vector2((bar.size.x - 8) * f, bar.size.y - 8)), Crayon.GREEN if haul < quota else Crayon.YELLOW)
	Crayon.text(pen, bar.get_center() + Vector2(0, 1), "$%s / $%s" % [_money(haul), _money(quota)], 24, Crayon.WHITE, 1, 361, null, 0.3, false)
	Crayon.text(pen, Vector2(bar.position.x - 14, bar.get_center().y), "QUOTA", 24, Crayon.YELLOW, 2, 362, Crayon.title_font())
	var sub := "R.E.P.O.  -  RUN %d" % run
	if phase == "run1" and deposited == 0 and carried.is_empty():
		sub = "TAP TO WALK  -  TAP A VALUABLE TO GRAB IT"
	elif phase in ["run1", "run2"] and not carried.is_empty():
		sub = "BRING IT TO THE TRUCK!"
	Crayon.text(pen, Vector2(bar.get_center().x, bar.end.y + 22), sub, 20, Color(1, 1, 0.6, 0.9) if sub != "R.E.P.O.  -  RUN %d" % run else Color(1, 1, 1, 0.7), 1, 363, null, 0.3, false)
	if not carried.is_empty() and get_button("extract").is_empty():
		Crayon.text(pen, Vector2(W - 24, y + 20), "%s  $%d" % [carried.name, carried.value], 22, Crayon.SKY, 2, 364, null, 0.3, false)


static func _bot(ci: CanvasItem, feet: Vector2, sc: float, tm: float, look: Vector2, dizzy: float, stunned: bool) -> void:
	var bob := absf(sin(tm * 9.0)) * 3.0 * sc
	var c := feet + Vector2(0, -30 * sc - bob)
	# little legs
	Crayon.line(ci, c + Vector2(-9, 14) * sc, feet + Vector2(-10, 0) * sc, Crayon.INK, 5 * sc, 400)
	Crayon.line(ci, c + Vector2(9, 14) * sc, feet + Vector2(10, 0) * sc, Crayon.INK, 5 * sc, 401)
	# round body + head with a screen face
	Crayon.circle(ci, c, 24 * sc, Crayon.INK, 4 * sc, Color(0.78, 0.8, 0.85), 402)
	var scr := Rect2(c + Vector2(-16, -12) * sc, Vector2(32, 20) * sc)
	Crayon.rect(ci, scr, Crayon.INK, 3 * sc, Color(0.08, 0.1, 0.14), 403)
	var lk := look * 3.0 * sc
	if stunned:
		Crayon.text(ci, scr.get_center() + Vector2(0, -1), "x x", int(16 * sc), Color(0.4, 0.9, 1.0), 1, 404, null, 0.3, false)
	else:
		var wob := Vector2(sin(tm * 9.0), cos(tm * 7.0)) * dizzy * 3.0 * sc
		Crayon.disc(ci, scr.get_center() + Vector2(-7, 0) * sc + lk + wob, 4.0 * sc, Color(0.4, 0.95, 1.0))
		Crayon.disc(ci, scr.get_center() + Vector2(7, 0) * sc + lk - wob, 4.0 * sc, Color(0.4, 0.95, 1.0))
	Crayon.party_hat(ci, c + Vector2(4, -22) * sc, 14 * sc, Crayon.PINK, 405, 0.2)
	# a little grab-beam arm
	Crayon.line(ci, c + Vector2(20, 4) * sc, c + Vector2(30, -2) * sc, Crayon.INK, 4 * sc, 406)
	Crayon.disc(ci, c + Vector2(31, -3) * sc, 4 * sc, Color(0.3, 0.7, 1.0))


## The Chumbo semibot, for the finale cast.
static func draw_mascot(ci: CanvasItem, feet: Vector2, sc: float, tm: float) -> void:
	_bot(ci, feet, sc * 1.6, tm, Vector2(sin(tm), 0) * 0.5, 0.0, false)


func _draw_item(it: Dictionary, p: Vector2) -> void:
	var ink := Crayon.INK
	var sd := int(it.base) % 97 + 500
	match String(it.kind):
		"cake":
			Crayon.rect(pen, Rect2(p + Vector2(-20, -10), Vector2(40, 22)), ink, 3, Crayon.PINK, sd)
			pen.draw_rect(Rect2(p + Vector2(-19, -9), Vector2(38, 6)), Crayon.WHITE)
			Crayon.line(pen, p + Vector2(0, -10), p + Vector2(0, -22), Crayon.YELLOW, 4, sd + 1)
		"cake1":
			Crayon.rect(pen, Rect2(p + Vector2(-16, -8), Vector2(32, 20)), ink, 3, Crayon.SKY, sd)
			pen.draw_rect(Rect2(p + Vector2(-15, -7), Vector2(30, 5)), Crayon.WHITE)
			Crayon.text(pen, p + Vector2(0, -20), "1", 22, Crayon.RED, 1, sd + 1, Crayon.title_font())
		"hat", "namehat":
			Crayon.party_hat(pen, p + Vector2(0, 12), 22, Color(0.7, 0.95, 1.0) if it.kind == "hat" else Crayon.GREEN, sd)
			if it.kind == "namehat":
				Crayon.text(pen, p + Vector2(0, 18), "CHUMBO", 12, Crayon.WHITE, 1, sd + 1, null, 0.2, false)
		"present", "presents":
			Crayon.present(pen, Rect2(p + Vector2(-18, -16), Vector2(36, 32)), Crayon.YELLOW if it.kind == "present" else Crayon.PURPLE, Crayon.RED, sd)
			if it.kind == "presents":
				Crayon.present(pen, Rect2(p + Vector2(-12, -36), Vector2(24, 20)), Crayon.GREEN, Crayon.YELLOW, sd + 5)
		"vase":
			Crayon.poly(pen, PackedVector2Array([p + Vector2(-8, -22), p + Vector2(8, -22), p + Vector2(16, 0), p + Vector2(8, 18), p + Vector2(-8, 18), p + Vector2(-16, 0)]), ink, 3, Color(0.4, 0.6, 0.95), sd)
			Crayon.line(pen, p + Vector2(-13, 0), p + Vector2(13, 0), Crayon.WHITE, 3, sd + 1)
		"clock":
			Crayon.rect(pen, Rect2(p + Vector2(-16, -18), Vector2(32, 36)), ink, 3, Crayon.BROWN, sd)
			Crayon.circle(pen, p + Vector2(0, -2), 10, ink, 2, Crayon.WHITE, sd + 1)
			Crayon.line(pen, p + Vector2(0, -2), p + Vector2(0, -9), ink, 2, sd + 2)
		"pinata":
			Crayon.rect(pen, Rect2(p + Vector2(-20, -8), Vector2(34, 20)), ink, 3, Crayon.PINK, sd)
			pen.draw_rect(Rect2(p + Vector2(-14, -6), Vector2(8, 16)), Crayon.YELLOW)
			Crayon.rect(pen, Rect2(p + Vector2(10, -24), Vector2(12, 18)), ink, 3, Crayon.PURPLE.lightened(0.3), sd + 1)
		"disco":
			Crayon.circle(pen, p, 17, ink, 3, Color(0.8, 0.82, 0.88), sd)
			Crayon.line(pen, p + Vector2(-16, 0), p + Vector2(16, 0), Crayon.GREY, 2, sd + 1)
			Crayon.line(pen, p + Vector2(0, -16), p + Vector2(0, 16), Crayon.GREY, 2, sd + 2)
		"trophy":
			Crayon.poly(pen, PackedVector2Array([p + Vector2(-16, -18), p + Vector2(16, -18), p + Vector2(8, 4), p + Vector2(-8, 4)]), ink, 3, Crayon.YELLOW, sd)
			Crayon.rect(pen, Rect2(p + Vector2(-10, 4), Vector2(20, 12)), ink, 3, Crayon.YELLOW.darkened(0.2), sd + 1)
		"photo":
			Crayon.rect(pen, Rect2(p + Vector2(-20, -16), Vector2(40, 32)), ink, 3, Color(0.95, 0.85, 0.55), sd)
			pen.draw_rect(Rect2(p + Vector2(-15, -11), Vector2(30, 22)), Crayon.SKY)
			Crayon.line(pen, p + Vector2(-6, 8), p + Vector2(-6, -4), ink, 3, sd + 1)
			Crayon.line(pen, p + Vector2(6, 8), p + Vector2(6, -4), Color(ink, 0.25), 3, sd + 2)
		"teddy":
			Crayon.circle(pen, p + Vector2(0, 6), 14, ink, 3, Crayon.BROWN, sd)
			Crayon.circle(pen, p + Vector2(0, -12), 10, ink, 3, Crayon.BROWN, sd + 1)
			Crayon.disc(pen, p + Vector2(-8, -20), 4, Crayon.BROWN)
			Crayon.disc(pen, p + Vector2(8, -20), 4, Crayon.BROWN)
		"candle":
			Crayon.rect(pen, Rect2(p + Vector2(-6, -18), Vector2(12, 34)), ink, 3, Crayon.PINK, sd)
			Crayon.flame(pen, p + Vector2(0, -26), 7, sd + 1)
		"nametag":
			Crayon.rect(pen, Rect2(p + Vector2(-24, -14), Vector2(48, 28)), ink, 3, Crayon.WHITE, sd)
			pen.draw_rect(Rect2(p + Vector2(-23, -13), Vector2(46, 8)), Crayon.RED)
			Crayon.text(pen, p + Vector2(0, 5), "CHUMBO", 11, ink, 1, sd + 1, null, 0.2, false)


func _peeper() -> void:
	# the Peeper: a giant eyeball on the library ceiling, always watching
	var p := PEEPER + Vector2(0, sin(t * 1.3) * 4.0)
	var blink := fmod(t, 5.0) < 0.15
	Crayon.ellipse(pen, p, Vector2(40, 30), Crayon.INK, 4, Color(0.97, 0.94, 0.9), 600)
	if blink:
		Crayon.line(pen, p + Vector2(-34, 0), p + Vector2(34, 0), Crayon.INK, 5, 601)
		return
	for k in 4:
		var a := -0.6 + k * 0.4
		Crayon.line(pen, p + Vector2(cos(a), sin(a)) * 38.0 * Vector2(1, 0.75), p + Vector2(cos(a), sin(a)) * 22.0, Color(0.9, 0.3, 0.3, 0.6), 2, 602 + k, 0.4)
	var look := (bot_pos - p).normalized()
	Crayon.disc(pen, p + look * 12.0, 14.0, Color(0.3, 0.55, 0.3))
	Crayon.disc(pen, p + look * 14.0, 7.0, Crayon.BLACK)
	if bot_pos.distance_to(PEEPER) < 215.0:
		Crayon.text(pen, p + Vector2(0, 52), "DON'T LOOK!", 22, Crayon.RED.lightened(0.3), 1, 606, Crayon.title_font())


func _gnome(g: Dictionary) -> void:
	var p: Vector2 = g.pos
	var hop := absf(sin(g.step)) * 4.0
	var tilt := 0.6 if g.stun > 0.0 else 0.0
	Crayon.circle(pen, p + Vector2(0, -6 - hop), 10, Crayon.INK, 3, Color(1, 0.85, 0.75), 610)
	Crayon.disc(pen, p + Vector2(0, 4 - hop), 9, Color(0.95, 0.95, 0.95))
	Crayon.party_hat(pen, p + Vector2(0, -14 - hop), 11, g.col, 611, tilt)
	if g.stun > 0.0:
		Crayon.text(pen, p + Vector2(0, -38), "zzz", 16, Crayon.WHITE, 1, 612, null, 0.3, false)


func _duck(p: Vector2, k: float, angry: bool) -> void:
	var col := Crayon.YELLOW if not angry else Color(0.95, 0.65, 0.15)
	Crayon.ellipse(pen, p, Vector2(18, 13) * k, Crayon.INK, 3, col, 620)
	Crayon.circle(pen, p + Vector2(12, -14) * k, 9 * k, Crayon.INK, 3, col, 621)
	Crayon.poly(pen, PackedVector2Array([p + Vector2(19, -15) * k, p + Vector2(29, -13) * k, p + Vector2(19, -10) * k]), Crayon.INK, 2, Crayon.ORANGE, 622)
	if angry:
		Crayon.disc(pen, p + Vector2(14, -16) * k, 3 * k, Crayon.RED)
		Crayon.line(pen, p + Vector2(9, -22) * k, p + Vector2(17, -19) * k, Crayon.INK, 3, 623)
	else:
		Crayon.disc(pen, p + Vector2(14, -16) * k, 2.2 * k, Crayon.INK)


func _taxman(r: Rect2) -> void:
	# the Taxman on the truck's little TV: suit, mustache, party hat
	pen.draw_rect(r.grow(-4), Color(0.25, 0.4, 0.3))
	var c := r.get_center() + Vector2(0, 4)
	Crayon.circle(pen, c, 13, Crayon.INK, 2, Color(1, 0.88, 0.75), 630)
	pen.draw_rect(Rect2(c + Vector2(-16, 12), Vector2(32, 10)), Color(0.3, 0.3, 0.35))
	Crayon.line(pen, c + Vector2(-7, 4), c + Vector2(7, 4), Crayon.INK, 3, 631)
	Crayon.face(pen, c + Vector2(0, -2), 11, tv_mood, Vector2.ZERO, 632)
	Crayon.party_hat(pen, c + Vector2(0, -12), 8, Crayon.YELLOW, 633, 0.1)
