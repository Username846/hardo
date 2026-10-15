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
var _spikes := 0
var _dc := 0
var _spike_info := ""
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
	var proc := Performance.get_monitor(Performance.TIME_PROCESS)
	_proc_acc += proc
	if dt > 0.05:
		_spikes += 1
		if dt > _worst:
			_spike_info = " (draw %.1fms, process %.1fms)" % [draw_us / 1000.0, proc * 1000.0]
	draw_us = 0
	_worst = maxf(_worst, dt)
	_dc = maxi(_dc, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	if _t >= 2.0:
		var scr := "?"
		if Game.main and Game.main.current:
			scr = Game.main.current.get_script().resource_path.get_file().get_basename()
		last = "PERF %s fps=%.1f draw=%.2fms process=%.2fms worst_frame=%.1fms%s spikes=%d drawcalls=%d" % [scr, _frames / _t,
			_draw_acc / 1000.0 / _frames, _proc_acc * 1000.0 / _frames, _worst * 1000.0, _spike_info, _spikes, _dc]
		print(last)
		_frames = 0
		_t = 0.0
		_draw_acc = 0
		_proc_acc = 0.0
		_worst = 0.0
		_spikes = 0
		_dc = 0
		_spike_info = ""
