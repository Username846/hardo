extends RefCounted
## KNEAD FOR SPEED secret: a curious player keeps tapping the car in the garage (it honks).

var tmr := 0.0
var taps := 0


func drive(_bot: Node, g: Node, dt: float) -> void:
	if g.phase != "garage" or g.locked:
		return
	tmr += dt
	if tmr > 0.35 and taps < 8:
		tmr = 0.0
		taps += 1
		g.press(Vector2(640 + randf_range(-120, 120), 520 + randf_range(-30, 30)))
