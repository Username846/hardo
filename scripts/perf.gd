extends Node
## Tiny frame-time meter. Off by default; turn on with "?fps" on the web page URL or
## "--fps" on the command line. Prints a line to the console every 2 seconds.

var enabled := false
var draw_us := 0
var _frames := 0
var _draw_acc := 0
var _proc_acc := 0.0
var _t := 0.0
var _worst := 0.0
var last := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if "--fps" in OS.get_cmdline_user_args() or "--profile" in OS.get_cmdline_user_args():
		enabled = true
	elif OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		enabled = q is String and String(q).contains("fps")


func _process(dt: float) -> void:
	if not enabled:
		draw_us = 0
		return
	_frames += 1
	_t += dt
	_draw_acc += draw_us
	draw_us = 0
	_proc_acc += Performance.get_monitor(Performance.TIME_PROCESS)
	_worst = maxf(_worst, dt)
	if _t >= 2.0:
		var scr := "?"
		if Game.main and Game.main.current:
			scr = Game.main.current.get_script().resource_path.get_file().get_basename()
		last = "PERF %s fps=%.1f draw=%.2fms process=%.2fms worst_frame=%.1fms" % [scr, _frames / _t,
			_draw_acc / 1000.0 / _frames, _proc_acc * 1000.0 / _frames, _worst * 1000.0]
		print(last)
		_frames = 0
		_t = 0.0
		_draw_acc = 0
		_proc_acc = 0.0
		_worst = 0.0
