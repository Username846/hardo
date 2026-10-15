class_name Crayon
extends RefCounted
## Everything in the game is drawn with these helpers so it looks like a five year old
## drew it with crayons: wobbly lines that "boil" a few times a second, shapes that do not
## quite close, colouring that goes outside the lines and the odd backwards letter.

const INK := Color(0.13, 0.11, 0.16)
const PAPER := Color(0.996, 0.973, 0.918)
const RED := Color(0.89, 0.2, 0.22)
const ORANGE := Color(0.98, 0.55, 0.16)
const YELLOW := Color(1.0, 0.85, 0.2)
const GREEN := Color(0.3, 0.72, 0.3)
const BLUE := Color(0.22, 0.48, 0.9)
const PURPLE := Color(0.58, 0.32, 0.78)
const PINK := Color(0.98, 0.5, 0.7)
const BROWN := Color(0.55, 0.35, 0.2)
const SKY := Color(0.55, 0.8, 0.98)
const WHITE := Color(1, 1, 1)
const GREY := Color(0.55, 0.55, 0.58)
const BLACK := Color(0.08, 0.07, 0.1)

const RAINBOW := [RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE, PINK]

static var _body: Font
static var _title: Font
## Global wobble multiplier (games crank this up when things get spooky).
static var shake := 1.0


static func body() -> Font:
	if _body == null:
		_body = load("res://assets/fonts/GochiHand.ttf")
	return _body


static func title_font() -> Font:
	if _title == null:
		_title = load("res://assets/fonts/FingerPaint.ttf")
	return _title


## Changes ~7 times a second so every line gently re-draws itself ("line boil").
static func boil() -> int:
	return int(Time.get_ticks_msec() / 140)


## Deterministic noise in [-1, 1].
static func rnd(s: int) -> float:
	var h: int = s * 374761393 + 668265263
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 0xFFFF) / 32767.5 - 1.0


static func jit(s: int, amt: float) -> Vector2:
	return Vector2(rnd(s), rnd(s + 7919)) * amt


static func _seed(s: int) -> int:
	return s * 131 + boil() * 977


static func _stroke(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, s: int) -> void:
	if pts.size() < 2:
		return
	ci.draw_polyline(pts, col, w, true)
	# waxy second pass slightly off the first one
	var c2 := col.lightened(0.25)
	c2.a *= 0.45
	var off := jit(s + 3, w * 0.35)
	var pts2 := PackedVector2Array()
	pts2.resize(pts.size())
	for i in pts.size():
		pts2[i] = pts[i] + off
	ci.draw_polyline(pts2, c2, maxf(1.0, w * 0.45), true)


static func line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color = INK, w: float = 5.0, s: int = 0, wob: float = 1.0) -> void:
	var d := a.distance_to(b)
	if d < 0.5:
		return
	var sd := _seed(s)
	var dir := (b - a) / d
	var nrm := Vector2(-dir.y, dir.x)
	var n := clampi(int(d / 26.0), 1, 30)
	var wobble := (1.2 + d * 0.008) * wob * shake
	var over_a := (2.0 + rnd(sd + 1) * 3.0) * wob
	var over_b := (2.0 + rnd(sd + 2) * 3.0) * wob
	var pts := PackedVector2Array()
	for i in n + 1:
		var f := float(i) / n
		var p := a.lerp(b, f)
		p += nrm * rnd(sd + i * 17 + 5) * wobble * (0.35 + 0.65 * sin(f * PI))
		if i == 0:
			p -= dir * over_a
		elif i == n:
			p += dir * over_b
		pts.append(p)
	_stroke(ci, pts, col, w, sd)


## Open polyline drawn through points (each segment wobbles).
static func path(ci: CanvasItem, pts: PackedVector2Array, col: Color = INK, w: float = 5.0, s: int = 0, wob: float = 1.0) -> void:
	if pts.size() < 2:
		return
	var sd := _seed(s)
	var out := PackedVector2Array()
	for i in pts.size():
		out.append(pts[i] + jit(sd + i * 31, 1.4 * wob * shake))
	_stroke(ci, out, col, w, sd)


static func poly(ci: CanvasItem, pts: PackedVector2Array, col: Color = INK, w: float = 5.0, fill: Color = Color(0, 0, 0, 0), s: int = 0, closed: bool = true) -> void:
	if fill.a > 0.0 and pts.size() >= 3:
		var off := jit(s * 7 + 11, 3.0)
		var fp := PackedVector2Array()
		for p in pts:
			fp.append(p + off)
		if not Geometry2D.triangulate_polygon(fp).is_empty():
			ci.draw_colored_polygon(fp, fill)
			_hatch_poly(ci, fp, fill.darkened(0.18), s)
	var n := pts.size()
	var last := n if closed else n - 1
	for i in last:
		line(ci, pts[i], pts[(i + 1) % n], col, w, s + i * 13)


static func _hatch_poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, s: int) -> void:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	if r.size.x < 12 or r.size.y < 12:
		return
	var zig := PackedVector2Array()
	var step := clampf(r.size.y / 7.0, 9.0, 22.0)
	var y := r.position.y + step * 0.5
	var flip := false
	var sd := s * 3 + 1
	while y < r.end.y:
		var x0 := r.position.x - 4
		var x1 := r.end.x + 4
		zig.append(Vector2(x1 if flip else x0, y + rnd(sd) * 3))
		zig.append(Vector2(x0 if flip else x1, y + step * 0.5 + rnd(sd + 1) * 3))
		flip = not flip
		y += step
		sd += 2
	var c := col
	c.a *= 0.5
	for seg in Geometry2D.intersect_polyline_with_polygon(zig, pts):
		ci.draw_polyline(seg, c, 3.0, true)


static func rect(ci: CanvasItem, r: Rect2, col: Color = INK, w: float = 5.0, fill: Color = Color(0, 0, 0, 0), s: int = 0) -> void:
	if fill.a > 0.0:
		var off := jit(s * 7 + 3, 3.0)
		ci.draw_rect(Rect2(r.position + off, r.size), fill)
		_hatch_rect(ci, Rect2(r.position + off, r.size), fill.darkened(0.15), s)
	var a := r.position
	var b := Vector2(r.end.x, r.position.y)
	var c := r.end
	var d := Vector2(r.position.x, r.end.y)
	line(ci, a, b, col, w, s + 1)
	line(ci, b, c, col, w, s + 2)
	line(ci, c, d, col, w, s + 3)
	line(ci, d, a, col, w, s + 4)


static func _hatch_rect(ci: CanvasItem, r: Rect2, col: Color, s: int) -> void:
	if r.size.x < 10 or r.size.y < 10:
		return
	var zig := PackedVector2Array()
	var step := clampf(r.size.y / 6.0, 8.0, 24.0)
	var y := r.position.y + 3
	var flip := false
	var sd := s * 5 + 2
	while y < r.end.y - 2:
		zig.append(Vector2(r.end.x - 3 if flip else r.position.x + 3, y + rnd(sd) * 2))
		flip = not flip
		y += step * 0.5
		sd += 1
	var c := col
	c.a *= 0.45
	ci.draw_polyline(zig, c, 3.0, true)


static func circle(ci: CanvasItem, c: Vector2, r: float, col: Color = INK, w: float = 5.0, fill: Color = Color(0, 0, 0, 0), s: int = 0) -> void:
	ellipse(ci, c, Vector2(r, r), col, w, fill, s)


static func ellipse(ci: CanvasItem, c: Vector2, rad: Vector2, col: Color = INK, w: float = 5.0, fill: Color = Color(0, 0, 0, 0), s: int = 0) -> void:
	var sd := _seed(s)
	var n := clampi(int((rad.x + rad.y) * 0.25), 10, 40)
	if fill.a > 0.0:
		var fp := PackedVector2Array()
		var off := jit(s * 7 + 5, minf(rad.x, rad.y) * 0.06 + 1.5)
		for i in n:
			var a := TAU * i / n
			fp.append(c + off + Vector2(cos(a) * rad.x, sin(a) * rad.y))
		ci.draw_colored_polygon(fp, fill)
		_hatch_ellipse(ci, c + off, rad, fill.darkened(0.18), s)
	if col.a <= 0.0 or w <= 0.0:
		return
	var start := rnd(sd + 9) * PI
	var turns := 1.06 + rnd(sd + 4) * 0.05
	var pts := PackedVector2Array()
	var m := int(n * turns) + 1
	for i in m + 1:
		var a := start + TAU * turns * i / m
		var k := 1.0 + rnd(sd + i * 7) * 0.035 * shake + (float(i) / m) * 0.04
		pts.append(c + Vector2(cos(a) * rad.x * k, sin(a) * rad.y * k))
	_stroke(ci, pts, col, w, sd)


static func _hatch_ellipse(ci: CanvasItem, c: Vector2, rad: Vector2, col: Color, s: int) -> void:
	if rad.x < 8 or rad.y < 8:
		return
	var zig := PackedVector2Array()
	var rows := clampi(int(rad.y / 9.0), 3, 14)
	for i in rows + 1:
		var fy := -0.9 + 1.8 * float(i) / rows
		var half := sqrt(maxf(0.0, 1.0 - fy * fy)) * rad.x * 0.92
		var y := c.y + fy * rad.y
		if i % 2 == 0:
			zig.append(Vector2(c.x - half, y + rnd(s + i) * 2))
			zig.append(Vector2(c.x + half, y + rnd(s + i + 50) * 2))
		else:
			zig.append(Vector2(c.x + half, y + rnd(s + i) * 2))
			zig.append(Vector2(c.x - half, y + rnd(s + i + 50) * 2))
	var cc := col
	cc.a *= 0.45
	ci.draw_polyline(zig, cc, 3.0, true)


static func dot(ci: CanvasItem, c: Vector2, r: float, col: Color = INK) -> void:
	ci.draw_circle(c + jit(_seed(int(c.x * 3 + c.y)), 0.8), r, col)


## Kid handwriting. align: 0 = left, 1 = centre, 2 = right. Returns the drawn width.
static func text(ci: CanvasItem, pos: Vector2, s: String, size: int = 32, col: Color = INK, align: int = 1,
		sd: int = 0, font: Font = null, wob: float = 1.0, backwards: bool = true) -> float:
	if font == null:
		font = body()
	var width := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x := pos.x
	if align == 1:
		x -= width * 0.5
	elif align == 2:
		x -= width
	var b := _seed(sd)
	var asc := font.get_ascent(size)
	var y := pos.y + asc * 0.35
	for i in s.length():
		var ch := s.unicode_at(i)
		var adv := font.get_char_size(ch, size).x
		if ch != 32:
			var k := sd * 31 + i * 7
			var rot := rnd(b + i * 11) * 0.09 * wob * shake
			var off := Vector2(rnd(b + i * 13) * 1.2, rnd(b + i * 17) * 2.5) * wob * shake
			var sc := 1.0 + rnd(k + 3) * 0.08
			var flip := backwards and wob > 0.0 and size >= 30 and (ch == 83 or ch == 78 or ch == 90) and rnd(k + 99) > 0.6
			var centre := Vector2(x + adv * 0.5, y - asc * 0.35)
			ci.draw_set_transform(centre + off, rot, Vector2(-sc if flip else sc, sc))
			ci.draw_char(font, Vector2(-adv * 0.5, asc * 0.35), s.substr(i, 1), size, col)
		x += adv
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return width


## Word-wraps text into lines that fit max_w.
static func wrap_lines(s: String, size: int, max_w: float, font: Font = null) -> PackedStringArray:
	if font == null:
		font = body()
	var out := PackedStringArray()
	for para in s.split("\n"):
		var cur := ""
		for word in para.split(" "):
			var trial := word if cur == "" else cur + " " + word
			if font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w and cur != "":
				out.append(cur)
				cur = word
			else:
				cur = trial
		out.append(cur)
	return out


static func text_block(ci: CanvasItem, pos: Vector2, s: String, size: int, max_w: float, col: Color = INK, align: int = 1, sd: int = 0, line_h: float = 1.15) -> void:
	var lines := wrap_lines(s, size, max_w)
	for i in lines.size():
		text(ci, pos + Vector2(0, i * size * line_h), lines[i], size, col, align, sd + i * 101)


# ------------------------------------------------------------------ shapes


static func star(ci: CanvasItem, c: Vector2, r: float, col: Color = INK, fill: Color = YELLOW, s: int = 0, rot: float = -PI / 2) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := rot + TAU * i / 10.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	poly(ci, pts, col, maxf(2.0, r * 0.1), fill, s)


static func heart(ci: CanvasItem, c: Vector2, r: float, col: Color = INK, fill: Color = RED, s: int = 0) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		var x := 16 * pow(sin(t), 3)
		var y := -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * r / 16.0)
	poly(ci, pts, col, maxf(2.0, r * 0.12), fill, s)


static func sun(ci: CanvasItem, c: Vector2, r: float, mood: String = "happy", s: int = 0) -> void:
	for i in 12:
		var a := TAU * i / 12.0 + Time.get_ticks_msec() * 0.0002
		line(ci, c + Vector2(cos(a), sin(a)) * (r + 8), c + Vector2(cos(a), sin(a)) * (r + 30), ORANGE, 5, s + i)
	circle(ci, c, r, ORANGE, 5, YELLOW, s)
	face(ci, c, r * 0.8, mood, Vector2.ZERO, s + 50)


static func cloud(ci: CanvasItem, c: Vector2, sz: float, col: Color = WHITE, s: int = 0) -> void:
	for k in 4:
		var o := Vector2([-0.6, -0.15, 0.35, 0.75][k], [0.1, -0.25, -0.2, 0.1][k]) * sz
		circle(ci, c + o, sz * [0.45, 0.55, 0.5, 0.38][k], Color(0.6, 0.7, 0.85), 3, col, s + k)


## Faces. mood: happy, sad, wide (too wide), blank, o, smirk, sleep, x
static func face(ci: CanvasItem, c: Vector2, r: float, mood: String = "happy", look: Vector2 = Vector2.ZERO, s: int = 0, col: Color = INK) -> void:
	var eye_r := maxf(2.5, r * 0.11)
	var el := c + Vector2(-r * 0.35, -r * 0.2) + look * r * 0.12
	var er := c + Vector2(r * 0.35, -r * 0.2) + look * r * 0.12
	var w := maxf(2.5, r * 0.07)
	match mood:
		"sleep":
			line(ci, el - Vector2(eye_r, 0), el + Vector2(eye_r, 0), col, w, s)
			line(ci, er - Vector2(eye_r, 0), er + Vector2(eye_r, 0), col, w, s + 1)
		"x":
			for e in [el, er]:
				line(ci, e - Vector2(eye_r, eye_r), e + Vector2(eye_r, eye_r), col, w, s)
				line(ci, e + Vector2(-eye_r, eye_r), e + Vector2(eye_r, -eye_r), col, w, s + 2)
		"wide":
			dot(ci, el, eye_r * 1.25, col)
			dot(ci, er, eye_r * 1.25, col)
			dot(ci, el + Vector2(eye_r * 0.4, -eye_r * 0.4), eye_r * 0.35, WHITE)
			dot(ci, er + Vector2(eye_r * 0.4, -eye_r * 0.4), eye_r * 0.35, WHITE)
		_:
			dot(ci, el, eye_r, col)
			dot(ci, er, eye_r, col)
	var m := c + Vector2(0, r * 0.3)
	match mood:
		"happy", "sleep":
			_arc(ci, m - Vector2(0, r * 0.15), r * 0.4, 0.15 * PI, 0.85 * PI, col, w, s + 5)
		"sad", "x":
			_arc(ci, m + Vector2(0, r * 0.25), r * 0.32, 1.15 * PI, 1.85 * PI, col, w, s + 5)
		"wide":
			var pts := PackedVector2Array()
			for i in 13:
				var f := float(i) / 12.0
				pts.append(m + Vector2(lerpf(-r * 0.8, r * 0.8, f), sin(f * PI) * r * 0.32 - r * 0.12))
			for i in range(12, -1, -1):
				var f := float(i) / 12.0
				pts.append(m + Vector2(lerpf(-r * 0.8, r * 0.8, f), sin(f * PI) * r * 0.12 - r * 0.12))
			poly(ci, pts, col, w, Color(0.15, 0.05, 0.08), s + 6)
			for i in 7:
				var x := lerpf(-r * 0.62, r * 0.62, i / 6.0)
				var top := m + Vector2(x, -r * 0.02 + sin((x / (r * 1.6) + 0.5) * PI) * r * 0.1)
				line(ci, top, top + Vector2(0, r * 0.1), WHITE, maxf(2.0, w * 0.8), s + 20 + i, 0.3)
		"blank":
			pass
		"o":
			circle(ci, m, r * 0.14, col, w, Color(0.2, 0.05, 0.05), s + 5)
		"smirk":
			line(ci, m + Vector2(-r * 0.3, 0), m + Vector2(r * 0.3, -r * 0.1), col, w, s + 5)
		"flat":
			line(ci, m + Vector2(-r * 0.3, 0), m + Vector2(r * 0.3, 0), col, w, s + 5)


static func _arc(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float, col: Color, w: float, s: int) -> void:
	var pts := PackedVector2Array()
	var n := 12
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	path(ci, pts, col, w, s)


static func party_hat(ci: CanvasItem, base: Vector2, sz: float, col: Color = PINK, s: int = 0, tilt: float = 0.0) -> void:
	var up := Vector2(sin(tilt), -cos(tilt))
	var side := Vector2(cos(tilt), sin(tilt))
	var tip := base + up * sz * 1.4
	var pts := PackedVector2Array([base - side * sz * 0.55, tip, base + side * sz * 0.55])
	poly(ci, pts, INK, maxf(2.0, sz * 0.08), col, s)
	circle(ci, tip, sz * 0.16, INK, 2, YELLOW, s + 3)
	for i in 3:
		var f := 0.25 + i * 0.22
		dot(ci, base.lerp(tip, f) + side * sz * (0.1 - i * 0.08), maxf(2.0, sz * 0.07), YELLOW if i % 2 == 0 else BLUE)


## Stick figure. pose: stand, wave, up, walk, sit, fall, flat
static func person(ci: CanvasItem, feet: Vector2, h: float = 120.0, col: Color = INK, mood: String = "happy",
		hat: Color = Color(0, 0, 0, 0), pose: String = "stand", phase: float = 0.0, s: int = 0, head_fill: Color = Color(1, 0.9, 0.78)) -> void:
	var w := maxf(3.0, h * 0.045)
	var hip := feet + Vector2(0, -h * 0.42)
	var neck := feet + Vector2(0, -h * 0.75)
	var head := feet + Vector2(0, -h * 0.87)
	var hr := h * 0.13
	var swing := sin(phase) * h * 0.12 if pose == "walk" else 0.0
	if pose == "flat":
		var y := feet.y - 6
		line(ci, Vector2(feet.x - h * 0.45, y), Vector2(feet.x + h * 0.45, y), col, w * 1.2, s)
		ellipse(ci, Vector2(feet.x - h * 0.5, y - 4), Vector2(hr * 1.3, hr * 0.35), col, w, head_fill, s + 1)
		return
	line(ci, hip, feet + Vector2(-h * 0.15 + swing, 0), col, w, s + 1)
	line(ci, hip, feet + Vector2(h * 0.15 - swing, 0), col, w, s + 2)
	line(ci, hip, neck, col, w, s + 3)
	var hand_l := neck + Vector2(-h * 0.25, h * 0.2 - swing * 0.5)
	var hand_r := neck + Vector2(h * 0.25, h * 0.2 + swing * 0.5)
	match pose:
		"wave":
			hand_r = neck + Vector2(h * 0.25, -h * 0.2 + sin(phase * 3.0) * h * 0.05)
		"up":
			hand_l = neck + Vector2(-h * 0.22, -h * 0.25)
			hand_r = neck + Vector2(h * 0.22, -h * 0.25)
		"fall":
			hand_l = neck + Vector2(-h * 0.3, -h * 0.15)
			hand_r = neck + Vector2(h * 0.3, -h * 0.2)
	line(ci, neck + Vector2(0, h * 0.04), hand_l, col, w, s + 4)
	line(ci, neck + Vector2(0, h * 0.04), hand_r, col, w, s + 5)
	circle(ci, head, hr, col, w, head_fill, s + 6)
	face(ci, head + Vector2(0, hr * 0.1), hr * 0.9, mood, Vector2.ZERO, s + 7)
	if hat.a > 0:
		party_hat(ci, head + Vector2(0, -hr * 0.8), hr * 0.9, hat, s + 8, 0.15)


static func balloon(ci: CanvasItem, c: Vector2, r: float, col: Color, string_len: float = 80.0, s: int = 0, sag: float = 0.0) -> void:
	var rad := Vector2(r * (1.0 - sag * 0.3), r * 1.18 * (1.0 - sag * 0.45))
	var bottom := c + Vector2(0, rad.y)
	var pts := PackedVector2Array()
	for i in 6:
		var f := float(i) / 5.0
		pts.append(bottom + Vector2(sin(f * 9.0 + Time.get_ticks_msec() * 0.002) * 6, f * string_len))
	path(ci, pts, INK, 2.5, s + 2)
	ellipse(ci, c, rad, INK, 4, col, s)
	ci.draw_circle(c + Vector2(-rad.x * 0.35, -rad.y * 0.4), r * 0.15, Color(1, 1, 1, 0.6))
	poly(ci, PackedVector2Array([bottom + Vector2(-6, 8), bottom + Vector2(0, -2), bottom + Vector2(6, 8)]), INK, 2, col, s + 4)


static func present(ci: CanvasItem, r: Rect2, col: Color, ribbon: Color, s: int = 0, lid_lift: float = 0.0) -> void:
	var lid_h := r.size.y * 0.25
	var body_r := Rect2(r.position + Vector2(0, lid_h), Vector2(r.size.x, r.size.y - lid_h))
	rect(ci, body_r, INK, 4, col, s)
	var cx := r.position.x + r.size.x * 0.5
	ci.draw_rect(Rect2(cx - r.size.x * 0.08, body_r.position.y, r.size.x * 0.16, body_r.size.y), ribbon)
	var lid := Rect2(r.position + Vector2(-r.size.x * 0.06, -lid_lift), Vector2(r.size.x * 1.12, lid_h))
	rect(ci, lid, INK, 4, col.lightened(0.1), s + 10)
	ci.draw_rect(Rect2(cx - r.size.x * 0.08, lid.position.y, r.size.x * 0.16, lid_h), ribbon)
	var top := Vector2(cx, lid.position.y)
	ellipse(ci, top + Vector2(-r.size.x * 0.16, -lid_h * 0.35), Vector2(r.size.x * 0.16, lid_h * 0.4), INK, 3, ribbon, s + 20)
	ellipse(ci, top + Vector2(r.size.x * 0.16, -lid_h * 0.35), Vector2(r.size.x * 0.16, lid_h * 0.4), INK, 3, ribbon, s + 21)


static func cake(ci: CanvasItem, base: Vector2, w: float, h: float, col: Color = PINK, candles: int = 3, lit: bool = true, s: int = 0) -> void:
	var r := Rect2(base + Vector2(-w * 0.5, -h), Vector2(w, h))
	rect(ci, r, INK, 4, col, s)
	# drippy frosting
	poly(ci, icing(r, s), INK, 3, WHITE, s + 30)
	for i in candles:
		var x := r.position.x + w * (i + 1) / (candles + 1)
		var top := Vector2(x, r.position.y - 34)
		rect(ci, Rect2(top, Vector2(10, 34)), INK, 2, RAINBOW[i % RAINBOW.size()], s + 40 + i)
		if lit:
			flame(ci, top + Vector2(5, -12), 9.0, s + 60 + i)


## Outline of a band of icing along the top of r, with drips hanging down.
static func icing(r: Rect2, s: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(r.position + Vector2(-3, -2))
	pts.append(Vector2(r.end.x + 3, r.position.y - 2))
	var n := maxi(6, int(r.size.x / 7.0))
	var depth := minf(r.size.y * 0.6, 24.0)
	var ph := float(s % 17)
	for k in range(n, -1, -1):
		var x := r.position.x + r.size.x * k / n
		var drip := pow(maxf(0.0, sin(x * 0.075 + ph)), 3.0)
		pts.append(Vector2(x, r.position.y + 5.0 + drip * depth))
	return pts


static func flame(ci: CanvasItem, c: Vector2, r: float, s: int = 0) -> void:
	var f := 1.0 + sin(Time.get_ticks_msec() * 0.02 + s) * 0.12
	var pts := PackedVector2Array([c + Vector2(0, -r * 1.6 * f), c + Vector2(r * 0.7, 0), c + Vector2(0, r * 0.7), c + Vector2(-r * 0.7, 0)])
	poly(ci, pts, ORANGE, 2.5, YELLOW, s)


## A crayon "home" icon used for the back-to-party button.
static func house(ci: CanvasItem, c: Vector2, sz: float, s: int = 0) -> void:
	rect(ci, Rect2(c + Vector2(-sz * 0.4, -sz * 0.1), Vector2(sz * 0.8, sz * 0.55)), INK, 3, YELLOW, s)
	poly(ci, PackedVector2Array([c + Vector2(-sz * 0.55, -sz * 0.05), c + Vector2(0, -sz * 0.55), c + Vector2(sz * 0.55, -sz * 0.05)]), INK, 3, RED, s + 5)
	rect(ci, Rect2(c + Vector2(-sz * 0.1, sz * 0.15), Vector2(sz * 0.2, sz * 0.3)), INK, 2, BROWN, s + 9)


static func paper(ci: CanvasItem, r: Rect2, col: Color = PAPER, lines: bool = false) -> void:
	ci.draw_rect(r, col)
	if lines:
		var y := r.position.y + 40.0
		var lc := Color(0.55, 0.7, 0.95, 0.25)
		while y < r.end.y:
			ci.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), lc, 2.0)
			y += 44.0
