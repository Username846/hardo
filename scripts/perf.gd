extends Node
## Tiny frame-time meter. Off by default; turn on with "?fps" on the web page URL or
## "--fps" on the command line. Shows the frame rate in the top right corner, and prints a
## line with more detail to the console every 2 seconds.

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
var _label: Label = null
var _lf := 0
var _lt := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fps := "--fps" in OS.get_cmdline_user_args()
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		fps = fps or (q is String and String(q).contains("fps"))
	enabled = fps or "--profile" in OS.get_cmdline_user_args()
	if fps:
		_show()


func _show() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.position = Vector2(-150, 6)
	_label.size = Vector2(140, 30)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(1, 1, 0.6))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_label)


func _process(dt: float) -> void:
	if not enabled:
		draw_us = 0
		return
	_frames += 1
	_t += dt
	if _label:
		_lf += 1
		_lt += dt
		if _lt >= 0.5:
			_label.text = "%d fps" % roundi(_lf / _lt)
			_lf = 0
			_lt = 0.0
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
