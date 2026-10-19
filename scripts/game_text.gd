extends RefCounted
## Everything anyone says comes from dialogue.txt (see the notes at the top of it): one section
## per level, then lines like
##     name (who): what they say
## where \n starts a new line in the same box and \\n starts a new box. tools/voices.py reads the
## same file to make the voices, so the two must split the text the same way.

const PATH := "res://dialogue.txt"

## who -> Narrator mood (the voice and the box)
const WHO := {
	"host": Narrator.CUTE, "evil host": Narrator.DARK, "grey host": Narrator.WHISPER,
	"announcer": Narrator.HYPE, "evil announcer": Narrator.HYPE_DARK, "chumbo": Narrator.CHUMBO,
	"rocko": Narrator.ROCKO, "everyone": Narrator.CREEPY, "dijimon": Narrator.CRITTER,
	"evil dijimon": Narrator.MONSTER, "tony honk": Narrator.HONK, "pip": Narrator.PIP,
	"taxman": Narrator.TAXMAN, "sarge": Narrator.SARGE,
}

## section -> {name: {"mood": int, "boxes": PackedStringArray}}
static var _lines := {}
static var _loaded := false


static func _load() -> void:
	_loaded = true
	var src := FileAccess.get_file_as_string(PATH)
	if src == "":
		push_error("dialogue.txt is missing or empty")
		return
	var head := RegEx.create_from_string("^\\[(\\w+)\\]")
	var entry := RegEx.create_from_string("^(\\w+)\\s*\\(([^)]*)\\)\\s*:\\s*(.*)$")
	var sec := ""
	for raw in src.split("\n"):
		var ln := raw.strip_edges(false, true)
		if ln.strip_edges().begins_with("#") or ln.strip_edges() == "":
			continue
		var h := head.search(ln)
		if h:
			sec = h.get_string(1)
			if not _lines.has(sec):
				_lines[sec] = {}
			continue
		var m := entry.search(ln)
		if m == null or sec == "":
			continue
		var who := m.get_string(2).strip_edges().to_lower()
		if not WHO.has(who):
			push_error("dialogue.txt: nobody called \"%s\" (line %s)" % [who, m.get_string(1)])
		_lines[sec][m.get_string(1)] = {"mood": WHO.get(who, Narrator.CUTE), "boxes": boxes(m.get_string(3))}


## Splits what someone says into its boxes: \\n = a new box, \n = a new line in the box.
static func boxes(words: String) -> PackedStringArray:
	var out := PackedStringArray()
	for box in words.split("\\\\n"):
		var rows := PackedStringArray()
		for row in box.split("\\n"):
			rows.append(row.strip_edges())
		var b := "\n".join(rows).strip_edges()
		if b != "":
			out.append(b)
	return out


## {"mood", "boxes"} for a line, or a stand-in (and an error) if dialogue.txt hasn't got it.
static func get_line(section: String, name: String) -> Dictionary:
	if not _loaded:
		_load()
	if _lines.has(section) and _lines[section].has(name):
		return _lines[section][name]
	push_error("dialogue.txt has no line \"%s\" in [%s]" % [name, section])
	return {"mood": Narrator.CUTE, "boxes": PackedStringArray(["(%s)" % name])}
