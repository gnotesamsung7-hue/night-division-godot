extends Node
## Autoload "Store": settings and case progress, saved on the phone.

const PATH := "user://night_division.cfg"

var settings := {"trigger": "thumb", "thumb_t": 42, "pinch_t": 32, "smooth": 55, "reach": 20, "lock": "strong",
	"sound": 1, "name": "Mark Dave", "weapon": "gun", "practice_mode": "ghouls"}
var progress := {"missions": {}, "seen_prologue": false}


func _ready() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) == OK:
		for k in settings.keys():
			settings[k] = cf.get_value("settings", k, settings[k])
		progress = cf.get_value("progress", "data", progress)


func save() -> void:
	var cf := ConfigFile.new()
	for k in settings.keys():
		cf.set_value("settings", k, settings[k])
	cf.set_value("progress", "data", progress)
	cf.save(PATH)


func record(id: String, stars: int, score: int) -> void:
	var m: Dictionary = progress.missions.get(id, {"stars": 0, "best": 0, "cleared": false})
	m.cleared = true
	m.stars = maxi(m.stars, stars)
	m.best = maxi(m.best, score)
	progress.missions[id] = m
	save()


func cleared(id: String) -> bool:
	return progress.missions.has(id) and progress.missions[id].cleared


func reset_progress() -> void:
	progress = {"missions": {}, "seen_prologue": false}
	save()


func fill(s: String) -> String:
	var n := str(settings.name).strip_edges()
	return s.replace("{name}", n if n != "" else "Officer")
