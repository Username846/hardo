extends Node
## Global state: the player's (only possible) name, which presents were opened, saving.

const CONFIG := preload("res://scripts/config.gd")
const SAVE_PATH := "user://chumbo_birthday.cfg"
const CANON_NAME := "I'm Chumbo"

const GAMES := [
	{"id": "race", "title": "KNEAD FOR SPEED", "script": "res://scripts/games/race.gd", "col": Color(0.98, 0.5, 0.7)},
	{"id": "skate", "title": "TONY HONK 2", "script": "res://scripts/games/skate.gd", "col": Color(0.3, 0.72, 0.3)},
	{"id": "digi", "title": "DIJIMON", "script": "res://scripts/games/digi.gd", "col": Color(0.58, 0.32, 0.78)},
	{"id": "cards", "title": "Card Checkpoint", "script": "res://scripts/games/cards.gd", "col": Color(0.22, 0.48, 0.9)},
	{"id": "duty", "title": "CALL OF BIRTHDAY", "script": "res://scripts/games/duty.gd", "col": Color(0.98, 0.55, 0.16)},
	{"id": "royale", "title": "FORTNIGHT", "script": "res://scripts/games/royale.gd", "col": Color(0.4, 0.3, 0.9)},
	{"id": "obby", "title": "ROBLOCKS", "script": "res://scripts/games/obby.gd", "col": Color(0.89, 0.2, 0.22)},
	{"id": "poke", "title": "POKeMANS", "script": "res://scripts/games/poke.gd", "col": Color(1.0, 0.85, 0.2)},
	{"id": "repo", "title": "R.E.P.O.", "script": "res://scripts/games/repo.gd", "col": Color(0.2, 0.2, 0.35)},
	{"id": "karaoke", "title": "MIKAKE KARAOKE", "script": "res://scripts/games/karaoke.gd", "col": Color(0.2, 0.75, 0.75)},
]

const SCREENS := {
	"title": "res://scripts/screens/title.gd",
	"name": "res://scripts/screens/name_entry.gd",
	"intro": "res://scripts/screens/intro.gd",
	"hub": "res://scripts/screens/hub.gd",
	"finale": "res://scripts/screens/finale.gd",
	"rocko": "res://scripts/games/rocko.gd",
	"radio": "res://scripts/screens/radio.gd",
}

var player_name := ""
var done: Array = []
var intro_done := false
var finale_seen := false
## The secret game (tap the cake after the credits) was beaten.
var secret_done := false
## The first time the credits finish, "Continue" goes straight into the secret game.
var secret_started := false
## The party radio (after the secret game) has been opened at least once.
var radio_seen := false
## Chumbo on the title screen was tapped once too often. The title stays grim until a new party.
var title_dead := false
## Chumbo walked away from the party (and came back to the start): a gold star on the title screen.
var title_star := false
## (not saved) the title screen pops the star in the first time it's shown
var title_star_new := false
## Secrets found in the games: id -> true.
var eggs := {}
var hub_lines_heard := -1
## Master volume, 0..1 (the slider in the party room). 0 is silent.
var volume := 1.0
var main: Node = null


func _ready() -> void:
	done.resize(GAMES.size())
	done.fill(false)
	load_game()


func progress() -> int:
	var n := 0
	for d in done:
		if d:
			n += 1
	return n


func is_unlocked(i: int) -> bool:
	return i == 0 or done[i - 1] or done[i]


func complete(i: int) -> void:
	done[i] = true
	save_game()


func goto(screen: String, arg: Variant = null) -> void:
	if main:
		main.switch_to(screen, arg)


func play_game(i: int) -> void:
	goto("game", i)


## A present's star: silver once it's played, gold once its secret has been found too.
func gold_star(i: int) -> bool:
	return eggs.has(GAMES[i].id)


func gold_stars() -> int:
	var n := 0
	for i in GAMES.size():
		if gold_star(i):
			n += 1
	return n


## All ten gold stars: the secret game ends somewhere else.
func all_gold() -> bool:
	return gold_stars() == GAMES.size()


## Marks a game's secret as found (and saves). Returns true the first time.
func found_egg(id: String) -> bool:
	if eggs.has(id):
		return false
	eggs[id] = true
	save_game()
	return true


func back_to_party() -> void:
	goto("hub")


func save_game() -> void:
	var cf := ConfigFile.new()
	cf.set_value("p", "name", player_name)
	cf.set_value("p", "done", done)
	cf.set_value("p", "intro", intro_done)
	cf.set_value("p", "finale", finale_seen)
	cf.set_value("p", "secret", secret_done)
	cf.set_value("p", "secret_started", secret_started)
	cf.set_value("p", "radio_seen", radio_seen)
	cf.set_value("p", "title_dead", title_dead)
	cf.set_value("p", "eggs", eggs)
	cf.set_value("p", "title_star", title_star)
	cf.set_value("p", "heard", hub_lines_heard)
	cf.set_value("p", "volume", volume)
	cf.save(SAVE_PATH)


func load_game() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	player_name = cf.get_value("p", "name", "")
	var d: Array = cf.get_value("p", "done", [])
	for i in mini(d.size(), done.size()):
		done[i] = bool(d[i])
	intro_done = cf.get_value("p", "intro", false)
	finale_seen = cf.get_value("p", "finale", false)
	secret_done = cf.get_value("p", "secret", false)
	secret_started = cf.get_value("p", "secret_started", secret_done)
	radio_seen = cf.get_value("p", "radio_seen", false)
	title_dead = cf.get_value("p", "title_dead", false)
	eggs = cf.get_value("p", "eggs", {})
	title_star = cf.get_value("p", "title_star", false)
	hub_lines_heard = cf.get_value("p", "heard", -1)
	# (older saves only had a mute switch)
	volume = cf.get_value("p", "volume", 0.0 if cf.get_value("p", "muted", false) else 1.0)


func reset() -> void:
	player_name = ""
	done.fill(false)
	intro_done = false
	finale_seen = false
	secret_done = false
	secret_started = false
	radio_seen = false
	title_dead = false
	title_star = false
	eggs = {}
	hub_lines_heard = -1
	save_game()


const MONTHS := ["January", "February", "March", "April", "May", "June", "July", "August",
	"September", "October", "November", "December"]


func today() -> Dictionary:
	return Time.get_date_dict_from_system()


func ordinal(n: int) -> String:
	if n % 100 >= 11 and n % 100 <= 13:
		return str(n) + "th"
	match n % 10:
		1: return str(n) + "st"
		2: return str(n) + "nd"
		3: return str(n) + "rd"
	return str(n) + "th"


## "October 15th" - which is, of course, Chumbo's birthday. Every year. Today.
func today_text() -> String:
	var d := today()
	return "%s %s" % [MONTHS[d.month - 1], ordinal(d.day)]


func date_text(offset_days: int) -> String:
	var unix := Time.get_unix_time_from_system() + offset_days * 86400
	var d := Time.get_date_dict_from_unix_time(int(unix))
	return "%s %s" % [MONTHS[d.month - 1], ordinal(d.day)]


func is_correct_name(typed: String) -> bool:
	var s := typed.strip_edges().to_lower().replace("’", "'").replace("`", "'")
	while s.contains("  "):
		s = s.replace("  ", " ")
	return s == "i'm chumbo"
