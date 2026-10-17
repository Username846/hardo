extends CanvasLayer
## The party host's voice. Shows typewriter subtitles and plays the matching pre-rendered
## voice clip (tools/voices.py renders one clip per say() line found in the scripts).
## Also draws the little lyrics ticker and the "turn your phone sideways" hint.

## Who is talking decides the voice (tools/voices.py): CUTE, DARK and WHISPER are all the party
## host (same voice, different mood). HYPE is the announcer, CREEPY is "everyone" (the guests
## speaking together), CRITTER and MONSTER are the Dijimon (baby and grown), HONK is Tony Honk.
## Characters get their name on the box.
enum { CUTE, DARK, WHISPER, CRITTER, CREEPY, HYPE, CHUMBO, ROCKO, MONSTER, HONK, PIP, TAXMAN }

const BOX_W := 900.0

var _panel: Control
var _text := ""
var _lines := PackedStringArray()
var _mood := CUTE
var _shown := 0.0
var _cps := 30.0
var _voice_len := 0.0
var _elapsed := 0.0
var _blocking := false
var _ticket: Object = null
var _active := false
var _done_typing_at := -1.0
var _blip_acc := 0
var show_lyrics := true
## Screens with stuff at the bottom can move the subtitle box to the top.
var top := false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_panel.draw.connect(_draw_panel)
	_panel.gui_input.connect(_on_gui_input)


func is_active() -> bool:
	return _active


static func key_for(text: String, mood: int) -> String:
	return (str(mood) + "|" + text).md5_text().substr(0, 12)


## Called by Screen.say(). ticket gets a "done" signal emitted when the line finishes.
func show_line(text: String, mood: int, blocking: bool, ticket: Object) -> void:
	_finish(false)
	_text = text
	_mood = mood
	_blocking = blocking
	_ticket = ticket
	_active = true
	_shown = 0.0
	_elapsed = 0.0
	_done_typing_at = -1.0
	_lines = Crayon.wrap_lines(text, _font_size(), BOX_W - 80)
	_voice_len = Audio.play_voice("res://assets/voice/%s.ogg" % key_for(text, mood))
	var n := maxf(1.0, text.length())
	_cps = clampf(n / maxf(_voice_len * 0.85, 0.01), 18.0, 60.0) if _voice_len > 0.0 else 32.0
	if _mood == DARK or _mood == WHISPER or _mood == CREEPY or _mood == ROCKO:
		_cps = minf(_cps, 24.0) if _voice_len <= 0.0 else _cps
	Audio.duck(true)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP if blocking else Control.MOUSE_FILTER_IGNORE


func cancel() -> void:
	_finish(false)


func _finish(emit: bool) -> void:
	if not _active:
		return
	_active = false
	Audio.stop_voice()
	Audio.duck(false)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tk := _ticket
	_ticket = null
	if emit and is_instance_valid(tk):
		tk.emit_signal("done")


func _font_size() -> int:
	match _mood:
		WHISPER:
			return 30
		HYPE:
			return 38
	return 34


var _sig := ""


func _process(delta: float) -> void:
	# Redraw only when something visible changed (the lyric bar changes a few times a second).
	var vs := _panel.get_viewport_rect().size
	var portrait := vs.y > vs.x * 1.05
	if _active or portrait:
		_panel.queue_redraw()
		_sig = ""
	else:
		var ls := Audio.lyric_state() if show_lyrics else {}
		var sig := "%s|%d|%s|%.0f" % [ls.get("id", ""), ls.get("sung", 0), vs, _lyric_y(vs)]
		if sig != _sig:
			_sig = sig
			_panel.queue_redraw()
	if not _active:
		return
	_elapsed += delta
	var before := int(_shown)
	_shown = minf(_text.length(), _shown + _cps * delta)
	if _voice_len <= 0.0 and int(_shown) != before:
		_blip_acc += 1
		if _blip_acc % 3 == 0 and _text.substr(int(_shown) - 1, 1) != " ":
			var pitch: float = {CUTE: 1.0, DARK: 0.75, WHISPER: 0.85, CRITTER: 1.5, CREEPY: 0.5, HYPE: 1.2, CHUMBO: 0.8, ROCKO: 0.45,
				MONSTER: 0.9, HONK: 1.3, PIP: 1.1, TAXMAN: 0.6}[_mood]
			Audio.sfx("blip" if _blip_acc % 2 == 0 else "blip2", -16.0, pitch * randf_range(0.9, 1.1))
	if _shown >= _text.length() and _done_typing_at < 0.0:
		_done_typing_at = _elapsed
	var voice_done := _voice_len <= 0.0 or _elapsed >= _voice_len + 0.1
	if _done_typing_at >= 0.0 and voice_done:
		var since := _elapsed - maxf(_done_typing_at, _voice_len)
		var hold := 0.9 + _text.length() * 0.02 if not _blocking else 6.0
		if since > hold:
			_finish(true)


func _on_gui_input(e: InputEvent) -> void:
	if not _active or not _blocking:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_panel.accept_event()
		if _shown < _text.length():
			_shown = _text.length()
		elif _elapsed > 0.35:
			Audio.sfx("click", -8)
			_finish(true)


func _unhandled_input(e: InputEvent) -> void:
	if _active and _blocking and e is InputEventKey and e.pressed and not e.echo:
		if e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			if _shown < _text.length():
				_shown = _text.length()
			else:
				_finish(true)


func _style() -> Dictionary:
	match _mood:
		DARK:
			return {"bg": Color(0.09, 0.04, 0.07, 0.95), "ink": Color(0.95, 0.25, 0.3), "edge": Color(0.5, 0.05, 0.1), "wob": 1.6}
		WHISPER:
			return {"bg": Color(0.2, 0.2, 0.24, 0.8), "ink": Color(0.85, 0.85, 0.9), "edge": Color(0.45, 0.45, 0.5), "wob": 1.3}
		CRITTER:
			return {"bg": Color(1.0, 0.85, 0.95, 0.97), "ink": Color(0.45, 0.15, 0.55), "edge": Color(0.6, 0.25, 0.7), "wob": 1.2, "name": "DIJIMON"}
		MONSTER:
			return {"bg": Color(0.16, 0.05, 0.2, 0.96), "ink": Color(1.0, 0.75, 0.95), "edge": Color(0.6, 0.15, 0.65), "wob": 1.9, "name": "DIJIMON"}
		CREEPY:
			return {"bg": Color(0.18, 0.08, 0.22, 0.96), "ink": Color(0.95, 0.9, 1.0), "edge": Color(0.55, 0.2, 0.6), "wob": 1.9, "name": "EVERYONE"}
		HONK:
			return {"bg": Color(1.0, 1.0, 1.0, 0.97), "ink": Crayon.INK, "edge": Color(1.0, 0.55, 0.1), "wob": 1.1, "name": "TONY HONK"}
		PIP:
			return {"bg": Color(0.86, 0.9, 0.86, 0.75), "ink": Color(0.35, 0.45, 0.35), "edge": Color(0.55, 0.65, 0.55), "wob": 1.4, "name": "PIP"}
		TAXMAN:
			return {"bg": Color(0.1, 0.16, 0.1, 0.96), "ink": Color(1.0, 0.85, 0.3), "edge": Color(0.75, 0.6, 0.15), "wob": 1.3, "name": "TAXMAN"}
		HYPE:
			return {"bg": Color(0.2, 0.85, 1.0, 0.97), "ink": Color(0.1, 0.05, 0.3), "edge": Color(0.95, 0.2, 0.6), "wob": 1.0}
		CHUMBO:
			return {"bg": Color(0.82, 0.96, 0.78, 0.97), "ink": Crayon.INK, "edge": Color(0.2, 0.6, 0.25), "wob": 1.0, "name": "CHUMBO"}
		ROCKO:
			return {"bg": Color(0.12, 0.02, 0.03, 0.96), "ink": Color(1.0, 0.62, 0.15), "edge": Color(0.7, 0.08, 0.05), "wob": 2.0, "name": "ROCKO"}
	return {"bg": Color(1.0, 0.95, 0.62, 0.97), "ink": Crayon.INK, "edge": Color(0.95, 0.55, 0.15), "wob": 1.0}


func _draw_panel() -> void:
	var vs := _panel.get_viewport_rect().size
	if _active:
		var st := _style()
		var fs := _font_size()
		var lh := fs * 1.15
		var h := 46.0 + _lines.size() * lh
		var r := Rect2(Vector2((vs.x - BOX_W) * 0.5, vs.y - h - 22), Vector2(BOX_W, h))
		if top:
			r.position.y = 16.0
		var appear := clampf(_elapsed * 6.0, 0.0, 1.0)
		r.position.y += (1.0 - appear) * (-40.0 if top else 40.0)
		Crayon.rect(_panel, r, st.edge, 6, st.bg, 901)
		if st.has("name"):
			# name tag for characters who talk
			var tag := Rect2(Vector2(r.position.x + 26, r.end.y - 16 if top else r.position.y - 24), Vector2(150, 40))
			Crayon.rect(_panel, tag, st.edge, 4, st.edge.lightened(0.15), 905)
			Crayon.text(_panel, tag.get_center(), st.name, 26, Crayon.WHITE, 1, 906, Crayon.title_font(), 0.3, false)
		var left := int(_shown)
		var shake := Crayon.shake
		Crayon.shake = st.wob
		for i in _lines.size():
			var ln := _lines[i]
			var part := ln.substr(0, clampi(left, 0, ln.length()))
			left -= ln.length() + 1
			if part != "":
				Crayon.text(_panel, Vector2(r.position.x + 40, r.position.y + 30 + i * lh), part, fs, st.ink, 0, 700 + i * 37, null, 1.0, false)
		Crayon.shake = shake
		if _blocking and _shown >= _text.length():
			var bob := sin(Time.get_ticks_msec() * 0.008) * 5.0
			var p := Vector2(r.end.x - 34, r.end.y - 24 + bob)
			Crayon.poly(_panel, PackedVector2Array([p + Vector2(-10, -12), p + Vector2(12, 0), p + Vector2(-10, 12)]), st.ink, 3, st.edge, 77)
	if show_lyrics:
		_draw_lyrics(vs)
	# Portrait phones: ask nicely to rotate.
	if vs.y > vs.x * 1.05:
		_panel.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.996, 0.973, 0.918, 0.96))
		var c := vs * 0.5
		var a := Time.get_ticks_msec() * 0.002
		var phone := PackedVector2Array()
		for v in [Vector2(-70, -120), Vector2(70, -120), Vector2(70, 120), Vector2(-70, 120)]:
			phone.append(c + Vector2(0, -vs.y * 0.08) + v.rotated(sin(a) * 0.8 - 0.4) * 1.6)
		Crayon.poly(_panel, phone, Crayon.INK, 8, Crayon.SKY, 5)
		Crayon.text_block(_panel, c + Vector2(0, vs.y * 0.18), "Turn your phone sideways!", 110, vs.x * 0.9, Crayon.INK, 1, 9)


## Lyric bar y position in viewport space for the current screen (< 0 = hidden).
func _lyric_y(vs: Vector2) -> float:
	var scr: Node = Game.main.current if Game.main else null
	if scr == null:
		return -1.0
	var ly: float = scr.get("lyrics_y") if scr.get("lyrics_y") != null else 690.0
	if ly < 0.0:
		return -1.0
	return ly + (scr as Node2D).position.y


func _draw_lyrics(vs: Vector2) -> void:
	var y := _lyric_y(vs)
	if y < 0.0:
		return
	# don't fight with a narration box in the same spot
	if _active and ((top and y < 230.0) or (not top and y > vs.y - 230.0)):
		return
	var ls := Audio.lyric_state()
	if ls.is_empty():
		return
	var parts: PackedStringArray = ls.parts
	var sung: int = ls.sung
	var dark: bool = ls.dark
	var font := Crayon.body()
	var size := 38
	var widths := PackedFloat32Array()
	var total := 0.0
	for p in parts:
		var w := font.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		widths.append(w)
		total += w
	var x := (vs.x - total) * 0.5
	var bar := Rect2(x - 58, y - 31, total + 116, 62)
	var panel := Color(1.0, 0.98, 0.88, 0.92) if not dark else Color(0.12, 0.04, 0.1, 0.9)
	var edge := Color(0.95, 0.55, 0.15) if not dark else Color(0.6, 0.1, 0.2)
	var ink := Crayon.INK if not dark else Color(0.95, 0.9, 0.95)
	var hi := Color(0.9, 0.12, 0.45) if not dark else Color(1.0, 0.3, 0.35)
	Crayon.freeze(true)
	Crayon.rect(_panel, bar, edge, 5, panel, 333)
	Crayon.freeze(false)
	_note(Vector2(bar.position.x + 28, y), edge)
	_note(Vector2(bar.end.x - 30, y), edge)
	var base_y := y + font.get_ascent(size) * 0.35
	for i in parts.size():
		var col := hi if i < sung else ink
		var pos := Vector2(x, base_y)
		if i == sung - 1:
			pos.y -= 3.0
		_panel.draw_string_outline(font, pos, parts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, panel)
		_panel.draw_string(font, pos, parts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		x += widths[i]


func _note(p: Vector2, col: Color) -> void:
	Crayon.disc(_panel, p + Vector2(-5, 8), 7, col)
	_panel.draw_line(p + Vector2(1, 8), p + Vector2(1, -14), col, 3.0)
	_panel.draw_line(p + Vector2(1, -14), p + Vector2(10, -8), col, 3.0)
