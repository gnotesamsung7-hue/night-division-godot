class_name Game
extends Node2D
## Runs one mission: steps, spawns, three weapons, target lock, energy, scoring, effects and HUD.

signal won(result: Dictionary)
signal lost_game
signal radio_line(who: String, text: String)

const MAX_ENERGY := 6
const BLAST_MIN := 3
const LIVES := 3
const WEAPONS := {
	"gun": {"name": "Spirit Gun", "range": 0.0, "dmg": 1},
	"knife": {"name": "Spirit Knife", "range": 0.55, "dmg": 2},
	"punch": {"name": "Spirit Punch", "range": 0.62, "dmg": 3, "knock": 0.25},
}
const ORDER := ["gun", "knife", "punch"]
const LOCK := {"strong": {"r": 100.0, "pull": 0.75}, "light": {"r": 60.0, "pull": 0.4}}
const C_CYAN := Color("#6FF3FF")
const C_CORE := Color("#EFFFFF")
const C_VIOLET := Color("#B65CFF")
const C_MAGENTA := Color("#FF4FB0")
const C_AMBER := Color("#FFB547")
const C_RED := Color("#FF3B5C")
const C_CREAM := Color("#F3F0FF")
const C_MUTED := Color("#A9A6D6")

var m: Dictionary
var mode = "touch"
var lives = LIVES
var energy = MAX_ENERGY
var score = 0
var st = {"shots": 0, "hits": 0, "kills": 0, "freed": 0, "fouls": 0, "hurt": 0, "escaped": 0, "bosses": 0}
var ents: Array = []
var queue: Array = []
var parts: Array = []
var bolts: Array = []
var slashes: Array = []
var fists: Array = []
var subs: Array = []
var sub = null
var si = -1
var step_t = 0.0
var done_t = -1.0
var hint = ""
var flags = {}
var scroll = 0.0
var adv = 0.0
var shake = 0.0
var flash = 0.0
var flash_col = C_RED
var beam = null
var banner = null
var empty_fx = 0.0
var recharge_fx = 0.0
var weapon_fx = 0.0
var over = false
var paused = false
var hand_paused = false
var away_recharged = false
var lock = null
var lock_t = 0.0
var d_aim = null
var hitstop = 0.0
var impact = 0.0
var cd = 0.0
var t = 0.0
var clock = 0.0
var p_t = 1.0
var boss_idx = 0
var next_boss = 0.0
var beacon_relit = false
var armor_msg_t = -9.0
var weapon = "gun"


func setup(mission: Dictionary, input_mode: String) -> void:
	m = mission
	mode = input_mode
	weapon = m.get("start_weapon", Store.settings.weapon)
	Hand.weapon = weapon
	View.beacon_lit = 0.0
	if m.get("practice", "") == "bosses":
		next_boss = 1.0
	_next()


func current_step():
	return m.steps[si] if si >= 0 and si < m.steps.size() else null


func _next() -> void:
	for e in ents:
		if e.type == "lantern":
			e.dead = true
			burst(Vector2(e.sx, e.sy), C_AMBER, 10)
	ents = ents.filter(func(e): return not e.dead)
	si += 1
	var s = current_step()
	if s == null:
		_win()
		return
	step_t = 0.0
	done_t = -1.0
	flags = {}
	if s.has("title"):
		banner = {"text": s.title, "t": 2.6}
	if s.has("energy"):
		energy = s.energy
	var h = s.get("hint", "")
	if h is Dictionary:
		h = h.get(mode, "")
	hint = Store.fill(h)
	adv = 1.4 if s.get("advance", false) else 0.0
	for line in s.get("say", []):
		radio(line[0], line[1])
	queue = []
	for sp in s.get("spawns", []):
		var q: Dictionary = sp.duplicate(true)
		q.at = sp.get("delay", 0.0)
		queue.append(q)
	queue.sort_custom(func(a, b): return a.at < b.at)


func _is_done(s: Dictionary) -> bool:
	match s.get("until", "clear"):
		"recharge": return flags.get("recharge", false)
		"blast": return flags.get("blast_kill", false)
		"weapon": return weapon == s.need
		"time": return step_t >= s.get("wait", 2.0)
		"never": return false
	return queue.is_empty() and ents.is_empty()


func radio(who: String, text: String) -> void:
	subs.append({"who": who, "text": Store.fill(text)})


func spawn_ent(spec: Dictionary) -> Dictionary:
	var e = Ents.make(spec)
	ents.append(e)
	return e


## ---------------- update ----------------
func _process(delta: float) -> void:
	var dt = minf(delta, 0.05)
	clock += dt
	for ev in Hand.events:
		handle(ev)
	Hand.events.clear()
	update_game(dt)
	queue_redraw()


func update_game(dt: float) -> void:
	_update_fx(dt)
	if over or paused:
		return
	if mode == "camera":
		if not Hand.present:
			var away = Hand.now() - Hand.lost_at
			if away > 0.25 and not away_recharged:
				recharge()
			hand_paused = away > 1.8
		else:
			hand_paused = false
			away_recharged = false
		if hand_paused:
			return
	if Hand.trig.holding and Hand.trig.charge > 0.0:
		Sfx.charge_level(Hand.trig.charge)
	_update_lock(dt)
	if sub == null and not subs.is_empty():
		var n: Dictionary = subs.pop_front()
		sub = {"who": n.who, "text": n.text, "t": maxf(2.6, n.text.length() * 0.06)}
		Sfx.play("radio")
		radio_line.emit(n.who, n.text)
	if sub != null:
		sub.t -= dt
		if sub.t <= 0.0:
			sub = null
	if adv > 0.0:
		adv -= dt
		scroll += dt * 0.32
		return
	if hitstop > 0.0:
		hitstop -= dt
		return
	t += dt
	if beacon_relit:
		View.beacon_lit = minf(1.0, View.beacon_lit + dt * 0.5)
	if m.has("practice"):
		_practice_spawns(dt)
	step_t += dt
	while not queue.is_empty() and queue[0].at <= step_t:
		spawn_ent(queue.pop_front())
	for e in ents.duplicate():
		Ents.update(e, dt, self)
		if e.state == "attack" and not e.warned:
			e.warned = true
			Sfx.play("warn")
		if e.state == "attack" and e.windup <= 0.0 and not e.dead:
			e.dead = true
			hurt(e)
		if e.exited:
			e.dead = true
			if e.type == "possessed":
				st.escaped += 1
	ents = ents.filter(func(e): return not e.dead)
	if over:
		return
	var s = current_step()
	if done_t < 0.0:
		if s != null and _is_done(s):
			done_t = 0.9
	else:
		done_t -= dt
		if done_t <= 0.0:
			_next()


func _update_fx(dt: float) -> void:
	for p in parts:
		p.life -= dt
		p.v.y += p.get("g", 0.0) * dt
		p.p += p.v * dt
	parts = parts.filter(func(p): return p.life > 0.0)
	for b in bolts:
		b.t -= dt
	bolts = bolts.filter(func(b): return b.t > 0.0)
	for s in slashes:
		s.t -= dt
	slashes = slashes.filter(func(s): return s.t > 0.0)
	for f in fists:
		f.t -= dt
		if f.t <= 0.0 and not f.hit_done:
			f.hit_done = true
			burst(f.b, C_AMBER, 14, 0.45)
			float_text(f.b - Vector2(0, 30), "POW!", C_AMBER, 1.3)
	fists = fists.filter(func(f): return f.t > -0.15)
	if beam != null:
		beam.t -= dt
		if beam.t <= 0.0:
			beam = null
	if banner != null:
		banner.t -= dt
		if banner.t <= 0.0:
			banner = null
	shake = maxf(0.0, shake - dt * 2.5)
	flash = maxf(0.0, flash - dt * 2.2)
	empty_fx = maxf(0.0, empty_fx - dt * 2.0)
	recharge_fx = maxf(0.0, recharge_fx - dt * 1.5)
	impact = maxf(0.0, impact - dt)
	cd = maxf(0.0, cd - dt)
	weapon_fx = maxf(0.0, weapon_fx - dt)


func _practice_spawns(dt: float) -> void:
	if m.practice == "ghouls":
		p_t -= dt
		var hostile = ents.filter(func(e): return e.type != "civilian").size()
		if p_t <= 0.0 and hostile < 5:
			var pool = ["wisp", "wisp", "wisp", "phantom", "dino", "grub", "possessed", "civilian"]
			var type: String = pool[randi() % pool.size()]
			if type == "possessed" or type == "civilian":
				spawn_ent({"type": type, "x": -1.3 if randf() < 0.5 else 1.3, "z": 0.3 + randf() * 0.25})
			else:
				spawn_ent({"type": type, "x": randf() * 1.2 - 0.6, "z": 0.9 + randf() * 0.05})
			p_t = 0.8 + randf() * 1.2
	elif m.practice == "bosses" and next_boss > 0.0:
		next_boss -= dt
		if next_boss <= 0.0:
			var order = [["kapre", 0.65], ["manananggal", 0.6], ["ghost_train", 1.15], ["bakunawa", 0.55], ["santelmo", 0.55], ["vex", 0.6]]
			var o: Array = order[boss_idx % order.size()]
			boss_idx += 1
			var b = spawn_ent({"type": "boss", "kind": o[0], "x": 0.0, "z": o[1]})
			banner = {"text": b.name, "t": 2.4}
			energy = MAX_ENERGY


## ---------------- target lock ----------------
func _lock_point(e: Dictionary):
	if not Ents.targetable(e):
		return null
	return Ents.center(e)


func _update_lock(dt: float) -> void:
	var cfg = LOCK.get(Store.settings.lock, null)
	var usable: bool = cfg != null and Hand.seen and adv <= 0.0 and (mode == "touch" or Hand.present)
	var best = null
	if usable:
		var R: float = cfg.r * (View.B / 390.0)
		var bd = INF
		var rng: float = WEAPONS[weapon].range
		for e in ents:
			var c = _lock_point(e)
			if c == null:
				continue
			if rng > 0.0 and e.z > rng:
				continue
			var d = Vector2(c.x, c.y).distance_to(Hand.aim)
			var lim: float = (R * 1.4 if e == lock else R) + c.z
			if d < lim and d < bd:
				bd = d
				best = e
	if best != null and best != lock:
		Sfx.play("lock")
		lock_t = 0.0
	lock = best
	lock_t += dt
	var target = Hand.aim
	if best != null:
		var c: Vector3 = _lock_point(best)
		target += (Vector2(c.x, c.y) - Hand.aim) * cfg.pull
	if d_aim == null:
		d_aim = target
	d_aim = d_aim.lerp(target, minf(1.0, dt * 18.0))


## ---------------- actions ----------------
func handle(ev: Dictionary) -> void:
	if over or paused or hand_paused:
		return
	if ev.type == "switch":
		cycle_weapon()
		return
	match weapon:
		"gun":
			match ev.type:
				"shot": shoot(Vector2(ev.x, ev.y))
				"charge_start": Sfx.charge_start()
				"charge_cancel": Sfx.charge_stop()
				"blast":
					Sfx.charge_stop()
					blast(Vector2(ev.x, ev.y))
		"knife":
			if ev.type == "shot": stab(Vector2(ev.x, ev.y))
			elif ev.type == "swipe": slash(ev.a, ev.b)
		"punch":
			if ev.type == "shot": punch(Vector2(ev.x, ev.y))
			elif ev.type == "thrust": punch(Vector2(ev.x, ev.y))


func set_weapon(w: String) -> void:
	if not WEAPONS.has(w) or over:
		return
	if w != weapon:
		Sfx.play("swap")
		weapon_fx = 1.2
	weapon = w
	Hand.weapon = w
	Sfx.charge_stop()
	lock = null


func cycle_weapon() -> void:
	set_weapon(ORDER[(ORDER.find(weapon) + 1) % ORDER.size()])


func recharge() -> void:
	away_recharged = true
	if energy >= MAX_ENERGY:
		return
	energy = MAX_ENERGY
	flags.recharge = true
	recharge_fx = 1.0
	Sfx.play("recharge")
	Sfx.vibrate(20)


## Shared hit logic for shots, stabs and punches. Returns [hit?, aim point].
func strike(pt: Vector2, dmg: int, rng: float, knock: float) -> Array:
	if mode == "touch":
		_update_lock(0.0)
	var in_range = func(e) -> bool: return rng <= 0.0 or e.z <= rng
	if lock != null and not lock.dead and ents.has(lock) and in_range.call(lock):
		var L: Dictionary = lock
		var c = Ents.center(L)
		var cp = Vector2(c.x, c.y)
		if L.type == "lantern" and L.armored:
			L.ripple = 1.0
			Sfx.play("phase")
			float_text(cp - Vector2(0, 24), "Warded", C_CYAN)
			return [false, cp]
		st.hits += 1
		if L.type == "possessed":
			_free(L)
		else:
			damage(L, dmg, false, knock)
		return [true, cp]
	var assist = 14.0 if LOCK.has(Store.settings.lock) else 6.0
	var phased = null
	var armor = null
	var far = null
	var sorted = ents.duplicate()
	sorted.sort_custom(func(a, b): return a.z < b.z)
	for e in sorted:
		var r = Ents.hit(e, pt.x, pt.y, assist)
		if r == "":
			continue
		if not in_range.call(e):
			if far == null: far = e
			continue
		if r == "phased":
			if phased == null: phased = e
			continue
		if r == "armor":
			armor = e
			break
		var c = Ents.center(e)
		var cp = Vector2(c.x, c.y)
		if r == "person":
			_foul(e)
			return [false, cp]
		st.hits += 1
		if r == "spirit":
			_free(e)
		else:
			damage(e, dmg, false, knock)
		return [true, cp]
	if armor != null:
		armor.ripple = 1.0
		Sfx.play("phase")
		var msg = Bosses.armor_text(armor) if armor.type == "boss" else "Warded"
		float_text(pt - Vector2(0, 24), msg if msg != "" else "Warded", C_CYAN)
	elif phased != null:
		Sfx.play("phase")
		float_text(pt - Vector2(0, 24), "Phased", C_VIOLET)
	elif far != null:
		float_text(pt - Vector2(0, 24), "Too far", C_MUTED)
	else:
		burst(pt, C_CYAN, 5, 0.35)
	return [false, pt]


func shoot(pt: Vector2) -> void:
	if adv > 0.0:
		return
	if energy <= 0:
		Sfx.play("empty")
		empty_fx = 1.0
		return
	energy -= 1
	st.shots += 1
	Sfx.play("shot")
	var r = strike(pt, 1, 0.0, 0.0)
	bolts.append({"a": Vector2(View.W * 0.5, View.H + 10), "b": r[1], "t": 0.14, "max": 0.14})


func stab(pt: Vector2) -> void:
	if adv > 0.0 or cd > 0.0:
		return
	cd = 0.2
	st.shots += 1
	Sfx.play("stab")
	var r = strike(pt, WEAPONS.knife.dmg, WEAPONS.knife.range, 0.0)
	var p: Vector2 = r[1]
	slashes.append({"a": p + Vector2(-26, 22), "b": p + Vector2(26, -22), "t": 0.22, "max": 0.22, "big": false})


func slash(a: Vector2, b: Vector2) -> void:
	if adv > 0.0 or cd > 0.0:
		return
	cd = 0.18
	Sfx.play("slash")
	var dir = (b - a).normalized()
	a -= dir * 30.0
	b += dir * 30.0
	slashes.append({"a": a, "b": b, "t": 0.3, "max": 0.3, "big": true})
	var n = 0
	for e in ents.duplicate():
		if e.type == "civilian" or e.z > WEAPONS.knife.range:
			continue
		var c = _lock_point(e)
		if c == null:
			continue
		var p = Vector2(c.x, c.y)
		var ab = b - a
		var k = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		if p.distance_to(a + ab * k) > c.z + 18.0:
			continue
		if e.type == "lantern" and e.armored:
			e.ripple = 1.0
			continue
		n += 1
		if e.type == "possessed":
			_free(e)
		else:
			damage(e, WEAPONS.knife.dmg)
	if n > 0:
		st.shots += 1
		st.hits += 1
		if n >= 2:
			float_text((a + b) * 0.5 - Vector2(0, 30), "%dx Slash!" % n, C_CYAN, 1.3)


func punch(pt: Vector2) -> void:
	if adv > 0.0 or cd > 0.0:
		return
	cd = 0.45
	st.shots += 1
	Sfx.play("whoosh")
	var r = strike(pt, WEAPONS.punch.dmg, WEAPONS.punch.range, WEAPONS.punch.knock)
	fists.append({"a": Vector2(View.W * 0.5, View.H + 60), "b": r[1], "t": 0.16, "max": 0.16, "hit_done": not r[0]})
	if r[0]:
		Sfx.play("punch")
		Sfx.vibrate(25)
		shake = maxf(shake, 0.45)


func blast(pt: Vector2) -> void:
	if adv > 0.0:
		return
	if energy < BLAST_MIN:
		Sfx.play("empty")
		empty_fx = 1.0
		float_text(pt - Vector2(0, 30), "Not enough energy", C_RED)
		return
	energy = 0
	st.shots += 1
	Sfx.play("blast")
	Sfx.vibrate(90)
	shake = 1.0
	flash = 0.9
	flash_col = C_CORE
	impact = 0.1
	if lock != null and ents.has(lock):
		var lc = Ents.center(lock)
		pt = Vector2(lc.x, lc.y)
	var o = Vector2(View.W * 0.5, View.H + 10)
	var u = (pt - o).normalized()
	var far = Vector2(View.W, View.H).length() * 1.5
	var width = maxf(26.0, View.W * 0.09)
	beam = {"a": o, "b": o + u * far, "w": width, "t": 0.6, "max": 0.6}
	var n = 0
	for e in ents.duplicate():
		if e.type == "civilian" or not Ents.targetable(e):
			continue
		var c = Ents.center(e)
		var q = Vector2(c.x, c.y) - o
		if q.dot(u) < 0.0 or absf(q.cross(u)) > width + c.z:
			continue
		if e.type == "possessed":
			_free(e)
		else:
			damage(e, 99, true)
		n += 1
	if n > 0:
		flags.blast_kill = true
		st.hits += 1
	if n >= 3:
		float_text(Vector2(View.W * 0.5, View.H * 0.3), "%dx Spirit Blast!" % n, C_CYAN, 1.6)


func damage(e: Dictionary, dmg: int, is_blast := false, knock := 0.0) -> void:
	var c = Ents.center(e)
	var cp = Vector2(c.x, c.y)
	if e.type == "boss":
		dmg = Bosses.on_damage(e, dmg, is_blast, self)
		if dmg <= 0:
			e.flash = 0.6
			Sfx.play("phase")
			var msg = Bosses.armor_text(e)
			if msg != "" and t - armor_msg_t > 1.2:
				armor_msg_t = t
				float_text(cp - Vector2(0, 30), msg, C_CYAN)
			return
	e.hp -= dmg
	e.flash = 1.0
	if knock > 0.0 and e.hp > 0 and not e.still and e.type != "possessed":
		e.z = minf(0.95, e.z + knock)
		if e.state == "attack":
			e.state = "move"
			e.warned = false
	if e.hp > 0:
		Sfx.play("hit")
		burst(cp, C_CORE, 6, 0.4)
		return
	e.dead = true
	st.kills += 1
	flags["kill_" + weapon] = true
	hitstop = 0.0 if is_blast else 0.05
	if lock == e:
		lock = null
	parts.append({"p": cp, "v": Vector2.ZERO, "life": 0.35, "max": 0.35, "ring": true, "r0": c.z, "r1": c.z * 3.2, "col": Ents.color_of(e)})
	var close: bool = e.state == "attack"
	var pts = Ents.pts_of(e) * (2 if close else 1)
	score += pts
	Sfx.play("kill")
	Sfx.vibrate(12)
	burst(cp, Ents.color_of(e), 26 if is_blast else 18)
	float_text(cp - Vector2(0, 24), ("Close call +" if close else "+") + str(pts), C_AMBER if close else C_CREAM)
	if e.boss:
		_boss_down(e, cp)


func _free(e: Dictionary) -> void:
	var c = Ents.center(e)
	var cp = Vector2(c.x, c.y)
	e.type = "civilian"
	e.flash = 0.0
	st.freed += 1
	if lock == e:
		lock = null
	parts.append({"p": cp, "v": Vector2.ZERO, "life": 0.4, "max": 0.4, "ring": true, "r0": c.z, "r1": c.z * 3.5, "col": C_CYAN})
	score += 300
	Sfx.play("freed")
	burst(cp, C_VIOLET, 20)
	float_text(cp - Vector2(0, 26), "Freed +300", C_CYAN)


func _foul(e: Dictionary) -> void:
	st.fouls += 1
	score = maxi(0, score - 400)
	e.flash = 1.0
	Sfx.play("foul")
	Sfx.vibrate(60)
	flash = 0.6
	flash_col = C_RED
	float_text(Vector2(e.sx, e.base - e.hh - 16), "Civilian hit -400", C_RED)


func hurt(e: Dictionary) -> void:
	st.hurt += 1
	Sfx.play("hurt")
	Sfx.vibrate(120)
	flash = 1.0 if not m.has("practice") else 0.6
	flash_col = C_RED
	shake = 0.9
	var c = Ents.center(e)
	burst(Vector2(c.x, c.y), C_RED, 14)
	if m.has("practice"):
		return
	lives -= 1
	if lives <= 0:
		_lose()


func _boss_down(e: Dictionary, cp: Vector2) -> void:
	hitstop = 0.35
	flash = 1.0
	flash_col = C_CORE
	shake = 1.0
	Sfx.play("boss")
	burst(cp, C_AMBER, 40, 1.1)
	burst(cp, C_CYAN, 30, 1.0)
	banner = {"text": e.name + " defeated!", "t": 2.6}
	for o in ents:
		if o != e and not o.boss and o.type != "civilian" and o.type != "possessed":
			o.dead = true
			burst(Vector2(o.sx, o.sy), C_VIOLET, 8)
	st.bosses += 1
	if e.kind == "vex":
		beacon_relit = true
	if m.get("practice", "") == "bosses":
		next_boss = 2.5


func _win() -> void:
	over = true
	Sfx.play("clear")
	var acc: float = float(st.hits) / st.shots if st.shots > 0 else 1.0
	var bonus = lives * 300
	score += bonus
	var stars = [true, acc >= 0.65, st.fouls == 0]
	get_tree().create_timer(1.4).timeout.connect(func(): won.emit({"score": score, "bonus": bonus, "acc": acc, "stars": stars, "st": st, "lives": lives}))


func _lose() -> void:
	over = true
	Sfx.charge_stop()
	Sfx.play("fail")
	get_tree().create_timer(1.4).timeout.connect(func(): lost_game.emit())


func practice_result() -> Dictionary:
	return {"practice": true, "score": score, "acc": float(st.hits) / st.shots if st.shots > 0 else 1.0, "st": st}


## ---------------- particles ----------------
func burst(p: Vector2, col: Color, n: int, life := 0.7) -> void:
	for i in n:
		var a = randf() * TAU
		var s = (80.0 + randf() * 260.0) * (View.B / 400.0)
		parts.append({"p": p, "v": Vector2(cos(a) * s, sin(a) * s - 40.0), "life": life, "max": life, "col": col, "size": 2.0 + randf() * 4.0, "g": 220.0, "star": i % 3 == 0, "rot": randf() * 3.0})


func float_text(p: Vector2, s: String, col: Color, scale := 1.0) -> void:
	parts.append({"p": p, "v": Vector2(0, -55), "life": 1.0, "max": 1.0, "col": col, "text": s, "scale": scale})


## ---------------- drawing ----------------
func _draw() -> void:
	var tt = clock
	if shake > 0.0:
		draw_set_transform(Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) * shake * 14.0)
	View.draw_scene(self, m.scene, tt, scroll)
	if adv > 0.0:
		View.speed_lines(self, minf(1.0, adv), tt)
	var order = ents.duplicate()
	order.sort_custom(func(a, b): return a.z > b.z)
	for e in order:
		Ents.draw(self, e, tt)
		if e.state == "attack":
			_draw_warning(e, tt)
	if Hand.trig.holding and Hand.trig.charge > 0.0 and energy >= BLAST_MIN and weapon == "gun":
		View.focus_lines(self, Hand.trig.charge, tt)
	if impact > 0.0:
		draw_rect(Rect2(-20, -20, View.W + 40, View.H + 40), Color(0.016, 0.012, 0.055, 0.9))
		View.focus_lines(self, 1.0, tt)
	_draw_bolts()
	_draw_beam(tt)
	_draw_slashes()
	_draw_fists()
	_draw_parts()
	_draw_lock(tt)
	draw_set_transform(Vector2.ZERO)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, View.W, View.H), Color(flash_col, flash * 0.4))
	_draw_crosshair(tt)
	_draw_hud(tt)
	if hand_paused and not over:
		draw_rect(Rect2(0, 0, View.W, View.H), Color(0.04, 0.05, 0.14, 0.7))
		Pen.text(self, Vector2(View.W * 0.5, View.H * 0.45), "Paused", 48, C_CORE, HORIZONTAL_ALIGNMENT_CENTER)
		Pen.text(self, Vector2(View.W * 0.5, View.H * 0.45 + 50), "Bring your hand back into view", 28, C_CREAM, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_warning(e: Dictionary, tt: float) -> void:
	var c = Ents.center(e)
	var k = maxf(0.0, e.windup) / 1.0
	var R: float = c.z * (1.3 + k * 2.2)
	var a = 0.6 + 0.4 * sin(tt * 30.0)
	draw_arc(Vector2(c.x, c.y), R, 0, TAU, 32, Color(C_RED, a), 4.0, true)
	Pen.text(self, Vector2(c.x, c.y - R - 8), "!", 40, Color(C_RED, a), HORIZONTAL_ALIGNMENT_CENTER)


func _draw_bolts() -> void:
	for b in bolts:
		var k: float = b.t / b.max
		var mid: Vector2 = b.a.lerp(b.b, 1.0 - k * 0.6)
		draw_line(b.a, mid, Color(C_CYAN, k), 14.0 * k)
		draw_line(b.a, mid, Color(C_CORE, k), 4.0 * k)
		Pen.glow(self, b.b, 50.0 * k, Color(C_CYAN, 0.8 * k))


func _draw_beam(tt: float) -> void:
	if beam == null:
		return
	var k: float = beam.t / beam.max
	View.speed_lines(self, k, tt)
	for layer in [[2.4, Color(C_CYAN, 0.25)], [1.3, Color(C_CYAN, 0.6)], [0.55, Color(C_CORE, 0.95)]]:
		draw_line(beam.a, beam.b, layer[1], beam.w * layer[0] * (0.4 + k * 0.6))


func _draw_slashes() -> void:
	for s in slashes:
		var k: float = s.t / s.max
		var ab: Vector2 = s.b - s.a
		var bow = ab.orthogonal().normalized() * ab.length() * (0.12 if s.big else 0.2)
		var pts = PackedVector2Array()
		for i in 13:
			var u = i / 12.0
			pts.append(s.a.lerp(s.b, u) + bow * sin(u * PI))
		var sc = 1.0 if s.big else 0.7
		draw_polyline(pts, Color(C_CYAN, 0.35 * k), 30.0 * k * sc, true)
		draw_polyline(pts, Color(0.67, 0.98, 1, 0.8 * k), 12.0 * k * sc, true)
		draw_polyline(pts, Color(1, 1, 1, k), 4.0 * k * sc, true)


func _draw_fists() -> void:
	for f in fists:
		var k = maxf(0.0, f.t / f.max)
		var p: Vector2 = f.b.lerp(f.a, k)
		var s = (28.0 + 70.0 * k) * (View.B / 390.0)
		var a = 1.0 if f.t > 0.0 else maxf(0.0, 1.0 + f.t / 0.15)
		Pen.glow(self, p, s * 1.6, Color(C_AMBER, 0.45 * a))
		var skin = Color(1, 0.91, 0.76, a)
		var ol = Color(0.48, 0.29, 0.06, a)
		var palm = PackedVector2Array([p + Vector2(-s * 0.42, -s * 0.3), p + Vector2(s * 0.42, -s * 0.3), p + Vector2(s * 0.42, s * 0.32), p + Vector2(-s * 0.42, s * 0.32)])
		Pen.fill(self, palm, skin); Pen.stroke(self, palm, ol, s * 0.05)
		for i in 4:
			var kc = p + Vector2(-s * 0.3 + i * s * 0.2, -s * 0.3)
			Pen.fill(self, Pen.ell(kc, s * 0.11, s * 0.11, 0.0, 12, PI, TAU), skin)
		for j in [-1.0, 0.0, 1.0]:
			draw_line(p + Vector2(j * s * 0.3, s * 0.4), p + Vector2(j * s * 0.45, s * 0.75), Color(C_AMBER, 0.9 * a), maxf(2.0, s * 0.06))


func _draw_parts() -> void:
	for p in parts:
		var a = maxf(0.0, p.life / p.max)
		if p.has("text"):
			Pen.text(self, p.p, p.text, int(32 * p.scale), Color(p.col, a), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 6)
		elif p.has("ring"):
			draw_arc(p.p, p.r0 + (p.r1 - p.r0) * (1.0 - a), 0, TAU, 32, Color(p.col, a), 4.0 * a + 1.0, true)
		elif p.star:
			Pen.fill(self, Pen.star(p.p, p.size * 2.2 * a, p.rot + p.life * 4.0), Color(p.col, a))
		else:
			draw_circle(p.p, p.size * a, Color(p.col, a))


func _draw_lock(tt: float) -> void:
	if lock == null or lock.dead:
		return
	var c = _lock_point(lock)
	if c == null:
		return
	var k = minf(1.0, lock_t / 0.15)
	var R: float = c.z * (1.25 + (1.0 - k) * 1.5) + 6.0
	var col = Color(C_AMBER, 0.5 + 0.5 * k)
	for i in 4:
		var rot = tt * 1.5 + i * PI / 2.0
		var corner = Vector2(c.x, c.y) + Vector2(R, 0).rotated(rot)
		draw_line(corner, corner + Vector2(0, -R * 0.35).rotated(rot), col, 4.0)
		draw_line(corner, corner + Vector2(-R * 0.35, 0).rotated(rot), col, 4.0)
	Pen.text(self, Vector2(c.x, c.y - R - 10), "LOCK", 20, col, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_crosshair(tt: float) -> void:
	var tr: Dictionary = Hand.trig
	if mode != "camera" and not (tr.holding and tr.charge > 0.0):
		return
	if not Hand.seen:
		return
	var a: Vector2 = d_aim if (d_aim != null and mode == "camera") else Hand.aim
	var present = mode == "touch" or Hand.present
	var r = 32.0
	var col = C_AMBER if weapon != "gun" else (C_CYAN if energy > 0 else C_RED)
	var al = 1.0 if present else 0.3
	Pen.glow(self, a, r * 1.8, Color(col, 0.18 * al))
	draw_arc(a, r, tt * 2.0, tt * 2.0 + TAU * 0.85, 32, Color(col, al), 3.0, true)
	for i in 4:
		var d = Vector2.from_angle(tt / 0.7 + i * PI / 2.0)
		draw_colored_polygon(PackedVector2Array([a + d * (r + 5), a + d * (r + 16) + d.orthogonal() * 6, a + d * (r + 16) - d.orthogonal() * 6]), Color(col, al))
	if mode == "camera" and present and not tr.holding and tr.cocked and weapon == "gun":
		var T = Hand.threshold()
		var pull = clampf((T * 1.45 - tr.ratio) / (T * 0.45), 0.0, 1.0)
		if pull > 0.05:
			draw_arc(a, r - 8, -PI / 2, -PI / 2 + TAU * pull, 32, C_AMBER, 4.0, true)
	if tr.holding and tr.charge > 0.0:
		var ok = energy >= BLAST_MIN
		var full: bool = tr.charge >= 1.0
		draw_arc(a, r + 20, -PI / 2, -PI / 2 + TAU * tr.charge, 40, (C_CORE if full else C_CYAN) if ok else C_RED, 8.0 if full else 6.0, true)
		if ok:
			Pen.glow(self, a, r * (1.0 + tr.charge * 1.8), Color(C_CYAN, 0.25 + tr.charge * 0.4))
		if full or not ok:
			Pen.text(self, a + Vector2(0, r + 54), "RELEASE" if ok else "LOW ENERGY", 22, C_CORE if ok else C_RED, HORIZONTAL_ALIGNMENT_CENTER)
	if weapon == "gun":
		draw_circle(a, 5, C_RED)
	elif weapon == "knife":
		var dirv = Vector2(1, -1).normalized()
		draw_colored_polygon(PackedVector2Array([a - dirv * 14 + dirv.orthogonal() * 5, a + dirv * 22, a - dirv * 14 - dirv.orthogonal() * 5]), C_CORE)
	else:
		draw_rect(Rect2(a - Vector2(9, 7), Vector2(18, 14)), Color("#FFE7C2"))
	if Hand.palm > 0.02:
		draw_arc(a, r + 38, -PI / 2, -PI / 2 + TAU * Hand.palm, 40, C_MAGENTA, 6.0, true)
		var nxt: String = ORDER[(ORDER.find(weapon) + 1) % ORDER.size()]
		Pen.text(self, a - Vector2(0, r + 52), "-> " + WEAPONS[nxt].name, 22, C_MAGENTA, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_hud(tt: float) -> void:
	var W = View.W
	var H = View.H
	var top = View.top
	for i in LIVES:
		_badge(Vector2(32 + i * 46, top + 6), i < lives)
	Pen.text(self, Vector2(W - 24, top + 40), str(score), 44, C_CORE, HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 6)
	# energy bar (only the Spirit Gun uses energy)
	var bx = 22.0
	var by = top + 150.0
	var bh = minf(H * 0.36, 440.0)
	var bw = 18.0
	var gap = 6.0
	var seg_h = (bh - gap * (MAX_ENERGY - 1)) / MAX_ENERGY
	var ea = 1.0 if weapon == "gun" else 0.35
	for i in MAX_ENERGY:
		var y = by + bh - (i + 1) * seg_h - i * gap
		if i < energy:
			draw_rect(Rect2(bx - 5, y - 4, bw + 10, seg_h + 8), Color(C_CYAN, (0.25 + recharge_fx * 0.5) * ea))
			draw_rect(Rect2(bx, y, bw, seg_h), Color(C_CORE if recharge_fx > 0.0 else C_CYAN, ea))
		else:
			var ec = Color(C_RED, 0.5 + 0.5 * sin(tt * 10.0)) if energy == 0 else Color(C_MUTED, 0.5)
			draw_rect(Rect2(bx, y, bw, seg_h), Color(ec, ec.a * ea), false, 2.0)
	if recharge_fx > 0.0:
		Pen.text(self, Vector2(bx + bw + 14, by + bh * 0.5), "RECHARGED", 28, Color(C_CORE, recharge_fx), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 6)
	# boss health bar
	var boss = null
	for e in ents:
		if e.boss and not e.dead:
			boss = e
			break
	if boss != null:
		var w = minf(W - 120.0, 560.0)
		var x0 = (W - w) * 0.5
		var y0 = top + 168.0
		var k = maxf(0.0, float(boss.hp) / boss.max_hp)
		Pen.text(self, Vector2(W * 0.5, y0 - 8), boss.name.to_upper(), 26, C_AMBER, HORIZONTAL_ALIGNMENT_CENTER, -1.0, 6)
		draw_rect(Rect2(x0, y0, w, 18), Color(0.04, 0.03, 0.12, 0.85))
		draw_rect(Rect2(x0 + 3, y0 + 3, (w - 6) * k, 12), C_MAGENTA if k > 0.5 else (C_AMBER if k > 0.25 else C_RED))
		draw_rect(Rect2(x0, y0, w, 18), Color(C_CREAM, 0.5), false, 1.5)
	# stage banner
	if banner != null:
		var kb: float = banner.t
		var a = clampf(minf(kb * 2.0, (2.6 - kb) * 4.0), 0.0, 1.0)
		var y = H * 0.22
		Pen.text(self, Vector2(W * 0.5, y), banner.text, int(minf(64.0, W * 0.085)), Color(C_CORE, a), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 8)
		var sw = minf(1.0, (2.6 - kb) * 2.0) * W * 0.6
		draw_rect(Rect2(W * 0.5 - sw * 0.5, y + 16, sw, 5), Color(C_CYAN, a))
	# weapon switched banner
	if weapon_fx > 0.0:
		var a = minf(1.0, weapon_fx * 2.0)
		Pen.text(self, Vector2(W * 0.5, H * 0.36), WEAPONS[weapon].name.to_upper(), int(minf(56.0, W * 0.075)), Color(C_CORE, a), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 8)
	# instruction hint
	var cur = current_step()
	var waits: bool = cur != null and cur.get("until", "clear") in ["recharge", "blast", "weapon"]
	if hint != "" and banner == null and (waits or step_t < 7.0):
		var lines = Pen.wrap(hint, 26, W - 180)
		var hy = top + (210.0 if boss != null else 150.0)
		var hh = lines.size() * 34.0 + 22.0
		draw_rect(Rect2(70, hy, W - 140, hh), Color(0.06, 0.08, 0.19, 0.85))
		draw_rect(Rect2(70, hy, W - 140, hh), Color(C_AMBER, 0.7), false, 2.0)
		for i in lines.size():
			Pen.text(self, Vector2(W * 0.5, hy + 36 + i * 34), lines[i], 26, C_AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	# out of energy prompt
	if weapon == "gun" and energy == 0 and not over and not hand_paused and si >= 0:
		var a = minf(1.0, 0.6 + 0.4 * sin(tt * 8.0) + empty_fx)
		Pen.text(self, Vector2(W * 0.5, H * 0.6), "RECHARGE", 54, Color(C_RED, a), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 8)
		Pen.text(self, Vector2(W * 0.5, H * 0.6 + 44), "Move your hand out of view" if mode == "camera" else "Tap Recharge", 26, Color(C_CREAM, a), HORIZONTAL_ALIGNMENT_CENTER)
	# radio subtitles
	if sub != null:
		var lines = Pen.wrap(sub.text, 27, W - 90)
		var hh = lines.size() * 36.0 + 60.0
		var y = H - 250.0 - hh
		draw_rect(Rect2(22, y, W - 44, hh), Color(0.04, 0.05, 0.14, 0.88))
		draw_rect(Rect2(22, y + 14, 5, hh - 28), C_CYAN)
		Pen.text(self, Vector2(42, y + 34), sub.who.to_upper(), 20, C_AMBER)
		for i in lines.size():
			Pen.text(self, Vector2(42, y + 70 + i * 36), lines[i], 27, C_CREAM)
	# hand skeleton preview (camera mode)
	if mode == "camera":
		var box = Rect2(W - 150, H - 210, 130, 170)
		draw_rect(box, Color(0, 0, 0, 0.45))
		draw_rect(box, Color(C_CYAN, 0.6), false, 2.0)
		if Hand.present and Hand.landmarks.size() == 21:
			for chain in [[0, 1, 2, 3, 4], [0, 5, 6, 7, 8], [5, 9, 10, 11, 12], [9, 13, 14, 15, 16], [13, 17, 18, 19, 20], [0, 17]]:
				for j in range(1, chain.size()):
					draw_line(_bp(box, chain[j - 1]), _bp(box, chain[j]), C_CYAN, 2.0)
			for i in [4, 8]:
				draw_circle(_bp(box, i), 4, C_AMBER)
		else:
			Pen.text(self, box.get_center() + Vector2(0, 8), "no hand", 22, Color(C_CREAM, 0.6), HORIZONTAL_ALIGNMENT_CENTER)


func _bp(box: Rect2, i: int) -> Vector2:
	var p = Hand.landmarks[i]
	return box.position + Vector2((1.0 - p.x) * box.size.x, p.y * box.size.y)


func _badge(p: Vector2, on: bool) -> void:
	var pts = PackedVector2Array([p, p + Vector2(15, 5), p + Vector2(15, 18)])
	pts.append_array(Pen.quad_pts(p + Vector2(15, 18), p + Vector2(15, 30), p + Vector2(0, 38), 6))
	pts.append_array(Pen.quad_pts(p + Vector2(0, 38), p + Vector2(-15, 30), p + Vector2(-15, 18), 6))
	pts.append(p + Vector2(-15, 5))
	if on:
		Pen.glow(self, p + Vector2(0, 19), 34, Color(C_AMBER, 0.4))
		Pen.fill(self, pts, C_AMBER)
		draw_circle(p + Vector2(0, 17), 5, Color("#7A4A00"))
	else:
		Pen.stroke(self, pts, Color(C_MUTED, 0.5), 2.0)
