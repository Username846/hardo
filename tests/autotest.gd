extends Node
## Dev-only: drives every screen, simulates taps and saves screenshots.
## Run: godot --path . -- --autotest=<out_dir> [--only=<screen>]

var out_dir := ""
var only := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest="):
			out_dir = a.substr(11)
		elif a.begins_with("--only="):
			only = a.substr(7)
	if out_dir == "loadall":
		_load_all("res://scripts")
		get_tree().quit()
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	await get_tree().create_timer(0.5).timeout
	await run()
	get_tree().quit()


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("SHOT ", name)


func tap(p: Vector2) -> void:
	var main: Node = Game.main
	var off: Vector2 = main.current.position if main.current else Vector2.ZERO
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = p + off
	Input.parse_input_event(e)
	await get_tree().process_frame
	var r := InputEventMouseButton.new()
	r.button_index = MOUSE_BUTTON_LEFT
	r.pressed = false
	r.position = p + off
	Input.parse_input_event(r)
	await get_tree().process_frame


func open(screen: String, arg: Variant = null) -> void:
	Game.main._open(screen, arg)
	await get_tree().create_timer(0.3).timeout


func run() -> void:
	var tests: Array = ["title", "name", "intro", "hub", "finale"]
	for i in 10:
		tests.append("game%d" % i)
	for name in tests:
		if only != "" and name != only:
			continue
		if name.begins_with("game"):
			await open("game", int(name.substr(4)))
		else:
			await open(name)
		await get_tree().create_timer(1.0).timeout
		await shot(name + "_a")
		for k in 6:
			await tap(Vector2(640, 400) + Vector2(randf_range(-300, 300), randf_range(-200, 200)))
			await get_tree().create_timer(0.4).timeout
		await shot(name + "_b")


func _load_all(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			var sc: Script = load(dir.path_join(f))
			print("LOADED ", dir.path_join(f), " ok=", sc != null and sc.can_instantiate())
	for d in DirAccess.get_directories_at(dir):
		_load_all(dir.path_join(d))
