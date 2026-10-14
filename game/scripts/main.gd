extends Node
## App shell: title, story, case map, briefings, results, pause and settings. Starts Game for each mission.

const C_INK := Color("#0F1430")
const C_CYAN := Color("#6FF3FF")
const C_CREAM := Color("#F3F0FF")
const C_MUTED := Color("#A9A6D6")
const C_AMBER := Color("#FFB547")
const C_MAGENTA := Color("#FF4FB0")
const C_RED := Color("#FF3B5C")

var backdrop: Backdrop
var ui: CanvasLayer
var screens = {}
var game: Game = null
var current: Dictionary = {}
var story = null
var settings_return = "title"
var hud: Control
var weapon_buttons = {}
var recharge_button: Button
var title_msg: Label
var vn_who: Label
var vn_text: Label
var brief_nodes = {}
var result_nodes = {}
var setting_nodes = {}
var map_list: VBoxContainer
var camera_button: Button


class Backdrop extends Node2D:
	var scene = "keyart"
	var clock = 0.0
	func _process(delta: float) -> void:
		clock += delta
		queue_redraw()
	func _draw() -> void:
		if scene == "keyart":
			View.draw_keyart(self, clock)
		else:
			View.draw_scene(self, scene, clock, clock / 9.0)
			draw_rect(Rect2(0, 0, View.W, View.H), Color(0.04, 0.03, 0.14, 0.3))


func _ready() -> void:
	get_tree().root.size_changed.connect(_on_resize)
	_on_resize()
	backdrop = Backdrop.new()
	add_child(backdrop)
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_build_title()
	_build_story()
	_build_map()
	_build_brief()
	_build_results()
	_build_fail()
	_build_pause()
	_build_settings()
	_build_hud()
	Hand.status_changed.connect(func(s): if title_msg: title_msg.text = s)
	show_screen("title")


func _on_resize() -> void:
	View.resize(get_viewport().get_visible_rect().size)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if game != null and not game.over and not game.paused:
			_pause()
		elif screens.title.visible:
			get_tree().quit()
		else:
			_open_map() if Hand.mode != "" else show_screen("title")
	elif what == NOTIFICATION_APPLICATION_PAUSED and game != null and not game.over:
		_pause()


## ---------------- UI helpers ----------------
func _style(bg: Color, border: Color, radius := 22) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3 if border.a > 0.0 else 0)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	return s


func _btn(text: String, cb: Callable, primary := true, size := 34) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(560, 92)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var fg = C_INK if primary else C_CREAM
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_focus_color", fg)
	var normal = _style(C_CYAN, Color(0, 0, 0, 0)) if primary else _style(Color(0, 0, 0, 0.25), Color(C_CREAM, 0.5))
	var pressed = _style(C_CYAN.darkened(0.2), Color(0, 0, 0, 0)) if primary else _style(Color(1, 1, 1, 0.12), Color(C_CREAM, 0.7))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.pressed.connect(func():
		Sfx.play("hit")
		cb.call())
	return b


func _link(text: String, cb: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.flat = true
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", C_MUTED)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	return b


func _label(text: String, size := 28, col := C_CREAM, outline := 0) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.14, 0.9))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_FILL
	return l


func _screen(name: String, bg_alpha := 0.55, align := BoxContainer.ALIGNMENT_CENTER, scroll := false) -> VBoxContainer:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.19, bg_alpha)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 50)
	root.add_child(margin)
	var box = VBoxContainer.new()
	box.alignment = align
	box.add_theme_constant_override("separation", 16)
	if scroll:
		var sc = ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		margin.add_child(sc)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(box)
	else:
		margin.add_child(box)
	ui.add_child(root)
	screens[name] = root
	return box


func show_screen(name: String) -> void:
	for k in screens.keys():
		screens[k].visible = (k == name)


## ---------------- title ----------------
func _build_title() -> void:
	var box = _screen("title", 0.0, BoxContainer.ALIGNMENT_END)
	var shade = screens.title.get_child(0) as ColorRect
	shade.color = Color(0, 0, 0, 0)
	var grad = TextureRect.new()
	var g = Gradient.new()
	g.set_color(0, Color(0.04, 0.03, 0.14, 0.0))
	g.set_color(1, Color(0.04, 0.03, 0.14, 0.92))
	var gt = GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.3)
	gt.fill_to = Vector2(0, 0.75)
	grad.texture = gt
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	grad.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screens.title.add_child(grad)
	screens.title.move_child(grad, 1)
	box.add_child(_label("MARK DAVE'S", 34, C_AMBER, 8))
	box.add_child(_label("NIGHT", 120, Color("#EFFFFF"), 14))
	box.add_child(_label("DIVISION", 120, C_CYAN, 14))
	box.add_child(_label("DILIM NG MAYNILA", 32, C_MAGENTA, 8))
	box.add_child(_label("Manila's secret unit against the creatures of the Ilalim. Your weapons are your spirit: a gun, a blade and a fist.", 26, C_MUTED))
	title_msg = _label("", 24, C_AMBER)
	box.add_child(title_msg)
	camera_button = _btn("Start with camera", _start_camera)
	box.add_child(camera_button)
	box.add_child(_btn("Play with touch", func():
		Hand.use_touch()
		_after_mode(), false))
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_link("Story", func(): _play_story(Story.PROLOGUE, func():
		Store.progress.seen_prologue = true
		Store.save()
		backdrop.scene = "keyart"
		show_screen("title"))))
	row.add_child(_link("Settings", func(): _open_settings("title")))
	box.add_child(row)
	box.add_child(_label("Stand your phone upright at chest height, step back an arm's length, and keep your hand level with the screen.", 22, C_MUTED))


func _start_camera() -> void:
	if not Hand.start_camera():
		title_msg.text = "Hand tracking needs the Android app. Use Play with touch here."
		return
	_after_mode()


func _after_mode() -> void:
	if Store.progress.get("seen_prologue", false):
		_open_map()
	else:
		_play_story(Story.PROLOGUE, func():
			Store.progress.seen_prologue = true
			Store.save()
			_open_map())


## ---------------- story ----------------
func _build_story() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	screens["story"] = root
	var tap = Button.new()
	tap.flat = true
	tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap.pressed.connect(_story_tap)
	root.add_child(tap)
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.05, 0.04, 0.16, 0.93), C_CYAN, 18))
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 28
	panel.offset_right = -28
	panel.offset_top = -420
	panel.offset_bottom = -60
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	vn_who = _label("", 28, C_MAGENTA)
	vn_who.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(vn_who)
	vn_text = _label("", 32, C_CREAM)
	vn_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vn_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	vn_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(vn_text)
	var cont = _label("Tap to continue", 22, C_CYAN)
	cont.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(cont)
	var skip = _link("Skip >>", func():
		if story != null:
			var d: Callable = story.done
			story = null
			backdrop.scene = "keyart"
			d.call())
	skip.position = Vector2(560, 40)
	root.add_child(skip)


func _play_story(pages: Array, done: Callable) -> void:
	story = {"pages": pages, "i": -1, "done": done, "typing": false, "shown": 0.0}
	show_screen("story")
	_next_page()


func _next_page() -> void:
	story.i += 1
	if story.i >= story.pages.size():
		var d: Callable = story.done
		story = null
		backdrop.scene = "keyart"
		d.call()
		return
	var p: Dictionary = story.pages[story.i]
	backdrop.scene = p.scene
	vn_who.text = p.who
	vn_who.visible = p.who != ""
	vn_text.text = Store.fill(p.text)
	vn_text.visible_characters = 0
	story.shown = 0.0
	story.typing = true
	if p.who != "":
		Sfx.play("radio")


func _story_tap() -> void:
	if story == null:
		return
	if story.typing:
		story.typing = false
		vn_text.visible_characters = -1
	else:
		_next_page()


func _process(delta: float) -> void:
	if story != null and story.typing:
		story.shown += delta * 48.0
		vn_text.visible_characters = int(story.shown)
		if story.shown >= vn_text.text.length():
			story.typing = false
			vn_text.visible_characters = -1
	if game != null:
		for w in weapon_buttons.keys():
			weapon_buttons[w].modulate = Color(1, 1, 1, 1) if game.weapon == w else Color(1, 1, 1, 0.45)


## ---------------- case map ----------------
func _build_map() -> void:
	var box = _screen("map", 0.6, BoxContainer.ALIGNMENT_CENTER, true)
	box.add_child(_label("Chapter 1", 30, C_CYAN))
	box.add_child(_label("The Blackout", 56, C_CREAM, 8))
	map_list = VBoxContainer.new()
	map_list.add_theme_constant_override("separation", 14)
	map_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(map_list)
	box.add_child(_link("Back to title", func():
		Hand.use_touch()
		Hand.mode = ""
		show_screen("title")))


func _open_map() -> void:
	_end_game()
	backdrop.scene = "keyart"
	for c in map_list.get_children():
		c.queue_free()
	var practice = _mission_button("P", "Practice Range", "Endless ghouls or boss rush", "", true, Color("#3C2814"))
	practice.pressed.connect(func(): _open_brief(Missions.practice(Store.settings.practice_mode)))
	map_list.add_child(practice)
	var chapter = Missions.chapter()
	for i in chapter.size():
		var ms: Dictionary = chapter[i]
		var unlocked = i == 0 or Store.cleared(chapter[i - 1].id)
		var rec: Dictionary = Store.progress.missions.get(ms.id, {})
		var stars = ""
		if not rec.is_empty():
			stars = "★".repeat(rec.stars) + "☆".repeat(3 - rec.stars)
		var sub: String = ms.place + ("   best %d" % rec.best if not rec.is_empty() else "")
		var b = _mission_button(str(ms.num), ms.title, sub, stars, unlocked, Color("#1A2150"))
		if unlocked:
			b.pressed.connect(func(): _open_brief(ms))
		map_list.add_child(b)
	show_screen("map")


func _mission_button(num: String, title: String, sub: String, stars: String, enabled: bool, bg: Color) -> Button:
	var b = Button.new()
	b.disabled = not enabled
	b.custom_minimum_size = Vector2(0, 116)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st = _style(Color(bg, 0.9), Color(C_CYAN, 0.35), 18)
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", st)
	b.add_theme_stylebox_override("pressed", _style(bg.lightened(0.15), C_CYAN, 18))
	b.add_theme_stylebox_override("disabled", _style(Color(bg, 0.4), Color(C_MUTED, 0.3), 18))
	var h = HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 24
	h.offset_right = -24
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 22)
	b.add_child(h)
	var n = _label(num, 48, C_AMBER if num == "P" else C_CYAN)
	n.custom_minimum_size = Vector2(56, 0)
	h.add_child(n)
	var v = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t1 = _label(title, 32, C_CREAM if enabled else C_MUTED)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var t2 = _label(sub if enabled else "Locked", 22, C_MUTED)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(t1)
	v.add_child(t2)
	h.add_child(v)
	var s = _label(stars, 30, C_AMBER)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(s)
	for c in [n, s]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## ---------------- briefing ----------------
func _build_brief() -> void:
	var box = _screen("brief", 0.7, BoxContainer.ALIGNMENT_CENTER, true)
	var card = PanelContainer.new()
	var cs = _style(Color("#F3ECDC"), Color("#120A24"), 10)
	cs.content_margin_left = 34
	cs.content_margin_right = 34
	cs.content_margin_top = 30
	cs.content_margin_bottom = 30
	card.add_theme_stylebox_override("panel", cs)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(card)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	var dark = Color("#1B1830")
	for key in ["case", "title", "place", "text", "objhead", "objs"]:
		var l = _label("", 26, dark)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(l)
		brief_nodes[key] = l
	brief_nodes.case.add_theme_color_override("font_color", Color("#6B5F86"))
	brief_nodes.title.add_theme_font_size_override("font_size", 46)
	brief_nodes.place.add_theme_color_override("font_color", Color("#6B5F86"))
	brief_nodes.objhead.add_theme_color_override("font_color", Color("#D2283F"))
	brief_nodes.objhead.text = "OBJECTIVES"
	brief_nodes["practice_row"] = _seg_row(box, "Practice mode", "practice_mode", [["ghouls", "Endless ghouls"], ["bosses", "Boss rush"]])
	brief_nodes["weapon_row"] = _seg_row(box, "Starting weapon", "weapon", [["gun", "Gun"], ["knife", "Knife"], ["punch", "Punch"]])
	box.add_child(_btn("Begin patrol", func():
		if current.has("practice"):
			current = Missions.practice(Store.settings.practice_mode)
		_start_mission(current)))
	box.add_child(_link("Case map", _open_map))


func _open_brief(ms: Dictionary) -> void:
	current = ms
	backdrop.scene = "keyart"
	brief_nodes.case.text = "%s: %s" % [ms.case_no, ms.case_name]
	brief_nodes.title.text = ms.title
	brief_nodes.place.text = ms.place
	brief_nodes.text.text = Store.fill(ms.brief)
	var objs = ""
	for o in ms.objectives:
		objs += "•  " + Store.fill(o) + "\n"
	brief_nodes.objs.text = objs.strip_edges()
	brief_nodes.practice_row.visible = ms.has("practice")
	brief_nodes.weapon_row.visible = not ms.has("start_weapon")
	_sync_settings()
	show_screen("brief")


## ---------------- mission flow ----------------
func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	var pause = Button.new()
	pause.text = "II"
	pause.add_theme_font_size_override("font_size", 30)
	pause.add_theme_stylebox_override("normal", _style(Color(0.06, 0.08, 0.19, 0.7), Color(C_CREAM, 0.6), 40))
	pause.custom_minimum_size = Vector2(80, 80)
	pause.anchor_left = 1.0
	pause.anchor_right = 1.0
	pause.offset_left = -104
	pause.offset_right = -24
	pause.offset_top = 92
	pause.offset_bottom = 172
	pause.pressed.connect(_pause)
	hud.add_child(pause)
	var bar = HBoxContainer.new()
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.offset_left = -170
	bar.offset_right = 170
	bar.offset_top = 22
	bar.offset_bottom = 102
	bar.add_theme_constant_override("separation", 10)
	hud.add_child(bar)
	for w in [["gun", "GUN"], ["knife", "KNIFE"], ["punch", "FIST"]]:
		var b = Button.new()
		b.text = w[1]
		b.custom_minimum_size = Vector2(106, 70)
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_stylebox_override("normal", _style(Color(0.06, 0.08, 0.19, 0.75), Color(C_AMBER, 0.8), 35))
		b.add_theme_stylebox_override("pressed", _style(Color(C_AMBER, 0.4), C_AMBER, 35))
		b.pressed.connect(func(): if game: game.set_weapon(w[0]))
		bar.add_child(b)
		weapon_buttons[w[0]] = b
	recharge_button = Button.new()
	recharge_button.text = "Recharge"
	recharge_button.add_theme_font_size_override("font_size", 28)
	recharge_button.add_theme_color_override("font_color", C_CYAN)
	recharge_button.add_theme_stylebox_override("normal", _style(Color(0.06, 0.08, 0.19, 0.8), C_CYAN, 24))
	recharge_button.anchor_top = 1.0
	recharge_button.anchor_bottom = 1.0
	recharge_button.offset_left = 24
	recharge_button.offset_right = 240
	recharge_button.offset_top = -120
	recharge_button.offset_bottom = -30
	recharge_button.pressed.connect(func(): if game: game.recharge())
	hud.add_child(recharge_button)
	hud.visible = false


func _start_mission(ms: Dictionary) -> void:
	_end_game()
	current = ms
	show_screen("")
	Hand.reset_gestures()
	Hand.active = true
	game = Game.new()
	game.setup(ms, Hand.mode if Hand.mode != "" else "touch")
	game.won.connect(_on_win)
	game.lost_game.connect(func():
		hud.visible = false
		show_screen("fail"))
	add_child(game)
	move_child(game, 1)
	backdrop.visible = false
	hud.visible = true
	recharge_button.visible = game.mode == "touch"


func _end_game() -> void:
	Hand.active = false
	Sfx.charge_stop()
	if game != null:
		game.queue_free()
		game = null
	if hud:
		hud.visible = false
	if backdrop:
		backdrop.visible = true


func _on_win(r: Dictionary) -> void:
	hud.visible = false
	if current.get("epilogue", false):
		_end_game()
		View.beacon_lit = 1.0
		_play_story(Story.EPILOGUE, func():
			View.beacon_lit = 0.0
			_show_results(r))
	else:
		_show_results(r)


func _build_results() -> void:
	var box = _screen("results", 0.7)
	for key in ["title", "stars", "score", "stats", "crit"]:
		var l = _label("", 30, C_CREAM)
		box.add_child(l)
		result_nodes[key] = l
	result_nodes.title.add_theme_font_size_override("font_size", 56)
	result_nodes.stars.add_theme_font_size_override("font_size", 80)
	result_nodes.stars.add_theme_color_override("font_color", C_AMBER)
	result_nodes.score.add_theme_font_size_override("font_size", 90)
	result_nodes.crit.add_theme_color_override("font_color", C_MUTED)
	result_nodes["next"] = _btn("Next case", func(): pass)
	box.add_child(result_nodes.next)
	box.add_child(_btn("Replay", func(): _start_mission(current), false))
	box.add_child(_link("Case map", _open_map))


func _show_results(r: Dictionary) -> void:
	_end_game()
	var s: Dictionary = r.st
	result_nodes.score.text = str(r.score)
	result_nodes.stats.text = "Accuracy %d%%    Ghouls %d    Freed %d\nCivilians hit %d    Damage taken %d    Bosses %d" % [int(r.acc * 100), s.kills, s.freed, s.fouls, s.hurt, s.get("bosses", 0)]
	if r.get("practice", false):
		result_nodes.title.text = "Practice complete"
		result_nodes.stars.text = ""
		result_nodes.crit.text = ""
		result_nodes.next.visible = false
		show_screen("results")
		return
	var n = 0
	for x in r.stars:
		if x: n += 1
	Store.record(current.id, n, r.score)
	result_nodes.stars.text = "".join(r.stars.map(func(x): return "★" if x else "☆"))
	result_nodes.crit.text = "%s Case closed    %s Accuracy 65%%+    %s No civilians hit" % ["★" if r.stars[0] else "☆", "★" if r.stars[1] else "☆", "★" if r.stars[2] else "☆"]
	var chapter = Missions.chapter()
	var idx = -1
	for i in chapter.size():
		if chapter[i].id == current.id:
			idx = i
	result_nodes.title.text = "Manila is saved!" if current.get("epilogue", false) else "Case closed"
	var nb: Button = result_nodes.next
	for c in nb.pressed.get_connections():
		nb.pressed.disconnect(c.callable)
	if idx >= 0 and idx + 1 < chapter.size():
		nb.visible = true
		var nxt: Dictionary = chapter[idx + 1]
		nb.pressed.connect(func(): _open_brief(nxt))
	else:
		nb.visible = false
	show_screen("results")


func _build_fail() -> void:
	var box = _screen("fail", 0.75)
	box.add_child(_label("Officer down", 64, C_RED, 8))
	box.add_child(_label("The ghouls got the better of you this time.", 28, C_MUTED))
	box.add_child(_btn("Try again", func(): _start_mission(current)))
	box.add_child(_link("Case map", _open_map))


func _build_pause() -> void:
	var box = _screen("pause", 0.75)
	box.add_child(_label("Paused", 64, C_CREAM, 8))
	box.add_child(_btn("Resume", func():
		show_screen("")
		hud.visible = true
		if game:
			game.paused = false
			Hand.reset_gestures()))
	box.add_child(_btn("Settings", func(): _open_settings("pause"), false))
	box.add_child(_link("Quit", func():
		if game != null and game.m.has("practice"):
			_show_results(game.practice_result())
		else:
			_open_map()))


func _pause() -> void:
	if game == null or game.over:
		return
	game.paused = true
	Sfx.charge_stop()
	hud.visible = false
	show_screen("pause")


## ---------------- settings ----------------
func _seg_row(parent: Container, title: String, key: String, opts: Array) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_child(_label(title, 26, C_CREAM))
	var h = HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	for o in opts:
		var b = Button.new()
		b.text = o[1]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(190, 72)
		b.add_theme_font_size_override("font_size", 24)
		b.add_theme_stylebox_override("normal", _style(Color(0, 0, 0, 0.3), Color(C_CREAM, 0.35), 16))
		b.add_theme_stylebox_override("pressed", _style(C_CYAN, Color(0, 0, 0, 0), 16))
		b.add_theme_stylebox_override("hover_pressed", _style(C_CYAN, Color(0, 0, 0, 0), 16))
		b.add_theme_color_override("font_pressed_color", C_INK)
		b.add_theme_color_override("font_hover_pressed_color", C_INK)
		b.set_meta("key", key)
		b.set_meta("val", o[0])
		b.pressed.connect(func():
			Store.settings[key] = o[0]
			Store.save()
			_sync_settings())
		h.add_child(b)
	parent.add_child(v)
	return v


func _slider(parent: Container, title: String, key: String, lo: float, hi: float) -> void:
	var lab = _label(title, 26, C_CREAM)
	parent.add_child(lab)
	var s = HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 1
	s.custom_minimum_size = Vector2(560, 60)
	s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(v):
		var k: String = key
		if key == "trigger_point":
			k = "thumb_t" if Store.settings.trigger == "thumb" else "pinch_t"
		Store.settings[k] = int(v)
		lab.text = "%s: %d" % [title, int(v)]
		Hand.apply_smoothing())
	parent.add_child(s)
	setting_nodes[key] = [s, lab, title]


func _build_settings() -> void:
	var box = _screen("settings", 0.94, BoxContainer.ALIGNMENT_BEGIN, true)
	box.add_child(_label("Settings", 56, C_CREAM, 8))
	_seg_row(box, "Trigger gesture", "trigger", [["thumb", "Thumb drop"], ["pinch", "Pinch"]])
	_slider(box, "Trigger point", "trigger_point", 20, 70)
	_slider(box, "Aim smoothing", "smooth", 0, 100)
	_slider(box, "Reach", "reach", 5, 35)
	_seg_row(box, "Target lock", "lock", [["strong", "Strong"], ["light", "Light"], ["off", "Off"]])
	_seg_row(box, "Sound and vibration", "sound", [[1, "On"], [0, "Off"]])
	box.add_child(_label("Officer name", 26, C_CREAM))
	var name_edit = LineEdit.new()
	name_edit.custom_minimum_size = Vector2(560, 72)
	name_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_edit.add_theme_font_size_override("font_size", 30)
	name_edit.max_length = 20
	name_edit.text_changed.connect(func(tx): Store.settings.name = tx)
	box.add_child(name_edit)
	setting_nodes["name"] = name_edit
	box.add_child(_btn("Done", func():
		Store.save()
		show_screen(settings_return)
		if settings_return == "pause":
			hud.visible = false))
	box.add_child(_link("Reset case progress", func(): Store.reset_progress()))


func _open_settings(from: String) -> void:
	settings_return = from
	_sync_settings()
	show_screen("settings")


func _sync_settings() -> void:
	for root in [screens.get("settings"), screens.get("brief")]:
		if root == null:
			continue
		for b in root.find_children("*", "Button", true, false):
			if b.has_meta("key"):
				b.button_pressed = str(Store.settings[b.get_meta("key")]) == str(b.get_meta("val"))
	for key in ["trigger_point", "smooth", "reach"]:
		if not setting_nodes.has(key):
			continue
		var s: HSlider = setting_nodes[key][0]
		var k: String = key
		if key == "trigger_point":
			k = "thumb_t" if Store.settings.trigger == "thumb" else "pinch_t"
		s.set_value_no_signal(Store.settings[k])
		setting_nodes[key][1].text = "%s: %d" % [setting_nodes[key][2], Store.settings[k]]
	if setting_nodes.has("name"):
		setting_nodes.name.text = Store.settings.name
