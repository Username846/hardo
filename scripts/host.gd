class_name Host
extends RefCounted
## The party host: a round, smiley, party-hatted blob who narrates everything.
## creep (0..1) slowly makes it... less okay.

static func draw(ci: CanvasItem, c: Vector2, r: float, creep: float = 0.0, talking: bool = false, look: Vector2 = Vector2.ZERO, s: int = 0) -> void:
	var tm := Time.get_ticks_msec() * 0.001
	var bob := sin(tm * 2.0) * r * 0.04
	c.y += bob
	var body_col := Color(1.0, 0.72, 0.3).lerp(Color(0.75, 0.55, 0.6), creep)
	# arms
	var wave := sin(tm * 3.0) * 0.4
	Crayon.line(ci, c + Vector2(-r * 0.9, r * 0.2), c + Vector2(-r * 1.45, -r * 0.2 + wave * r * 0.3), Crayon.INK, r * 0.07, s + 1)
	Crayon.line(ci, c + Vector2(r * 0.9, r * 0.2), c + Vector2(r * 1.45, r * 0.1), Crayon.INK, r * 0.07, s + 2)
	Crayon.circle(ci, c + Vector2(-r * 1.5, -r * 0.25 + wave * r * 0.3), r * 0.12, Crayon.INK, 3, Crayon.WHITE, s + 3)
	Crayon.circle(ci, c + Vector2(r * 1.5, r * 0.1), r * 0.12, Crayon.INK, 3, Crayon.WHITE, s + 4)
	Crayon.circle(ci, c, r, Crayon.INK, maxf(3.0, r * 0.06), body_col, s)
	# rosy cheeks
	Crayon.disc(ci, c + Vector2(-r * 0.55, r * 0.15), r * 0.13, Color(1, 0.4, 0.5, 0.45))
	Crayon.disc(ci, c + Vector2(r * 0.55, r * 0.15), r * 0.13, Color(1, 0.4, 0.5, 0.45))
	# eyes (extra ones appear as creep rises)
	var eye_r := r * 0.11
	var blink := fmod(tm + s, 4.0) < 0.12
	var eyes := [Vector2(-0.33, -0.22), Vector2(0.33, -0.22)]
	if creep > 0.45:
		eyes.append(Vector2(0.0, -0.5))
	if creep > 0.8:
		eyes.append(Vector2(-0.6, -0.55))
		eyes.append(Vector2(0.58, -0.6))
	for i in eyes.size():
		var e: Vector2 = c + eyes[i] * r + look * r * 0.08
		if blink and creep < 0.9:
			Crayon.line(ci, e - Vector2(eye_r, 0), e + Vector2(eye_r, 0), Crayon.INK, r * 0.05, s + 10 + i)
		else:
			Crayon.circle(ci, e, eye_r * 1.2, Crayon.INK, 2, Crayon.WHITE, s + 10 + i)
			Crayon.dot(ci, e + look * eye_r * 0.4, eye_r * (0.55 if creep < 0.5 else 0.3), Crayon.INK)
	# mouth: smile gets wider with creep
	var m := c + Vector2(0, r * 0.25)
	var mw := r * (0.45 + creep * 0.45)
	var open := (0.12 + (0.1 if talking and fmod(tm * 8.0, 2.0) < 1.0 else 0.0)) * r
	var pts := PackedVector2Array()
	for i in 11:
		var f := float(i) / 10.0
		pts.append(m + Vector2(lerpf(-mw, mw, f), sin(f * PI) * (open + r * 0.18)))
	for i in range(10, -1, -1):
		var f := float(i) / 10.0
		pts.append(m + Vector2(lerpf(-mw, mw, f), sin(f * PI) * r * 0.06))
	Crayon.poly(ci, pts, Crayon.INK, maxf(2.5, r * 0.05), Color(0.55, 0.1, 0.15), s + 20)
	if creep > 0.6:
		for i in 6:
			var x := lerpf(-mw * 0.8, mw * 0.8, i / 5.0)
			var top := m + Vector2(x, r * 0.07)
			Crayon.line(ci, top, top + Vector2(0, r * 0.09), Crayon.WHITE, r * 0.04, s + 30 + i, 0.2)
	# bow tie + party hat
	var bt := c + Vector2(0, r * 0.95)
	Crayon.poly(ci, PackedVector2Array([bt, bt + Vector2(-r * 0.3, -r * 0.15), bt + Vector2(-r * 0.3, r * 0.15)]), Crayon.INK, 3, Crayon.RED, s + 40)
	Crayon.poly(ci, PackedVector2Array([bt, bt + Vector2(r * 0.3, -r * 0.15), bt + Vector2(r * 0.3, r * 0.15)]), Crayon.INK, 3, Crayon.RED, s + 41)
	Crayon.party_hat(ci, c + Vector2(r * 0.15, -r * 0.88), r * 0.55, Crayon.BLUE.lerp(Crayon.BLACK, creep * 0.6), s + 50, 0.25)
