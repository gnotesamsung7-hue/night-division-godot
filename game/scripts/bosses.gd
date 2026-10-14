class_name Bosses
extends RefCounted
## The six bosses. Spawn with {"type": "boss", "kind": "kapre", "x": 0.0, "z": 0.65}.
## g is the running Game (spawn_ent, radio, float_text, burst, hurt). It can be null while previewing.

const INK := Color("#3A2440")
const NAMES := {"kapre": "Archive Kapre", "manananggal": "Manananggal", "ghost_train": "Ghost Train",
	"bakunawa": "Bakunawa Spawn", "santelmo": "Santelmo Knight", "vex": "General Vex"}
const HP := {"kapre": 22, "manananggal": 26, "ghost_train": 30, "bakunawa": 30, "santelmo": 32, "vex": 40}


static func _ease(cur: float, target: float, k: float) -> float:
	return cur + (target - cur) * minf(1.0, k)


static func _fire(g, e: Dictionary, n: int, col: String, spread: float, h: float) -> void:
	if g == null:
		return
	for i in n:
		g.spawn_ent({"type": "orb", "x": e.x + (i - (n - 1) * 0.5) * spread, "z": e.z - 0.03, "h": h, "col": col})


static func _radio(g, who: String, text: String) -> void:
	if g != null:
		g.radio(who, text)


static func _place(e: Dictionary, hw: float, ww: float) -> void:
	var p = View.proj(e.x, e.z)
	e.s = p.z; e.sx = p.x; e.base = p.y; e.hh = View.px(hw, p.z); e.ww = View.px(ww, p.z)


static func init(e: Dictionary) -> void:
	e.boss = true
	e.still = true
	e.name = NAMES[e.kind]
	e.hp = HP[e.kind]
	e.max_hp = e.hp
	e.x0 = e.x
	e.z0 = e.z
	match e.kind:
		"kapre":
			e.fire_t = 2.5; e.lunge_t = 7.0; e.lunge = 0.0; e.half = false
		"manananggal":
			e.mode = "fly"; e.dive_t = 4.5; e.spawn_t = 6.0; e.h = 1.7
		"ghost_train":
			e.x = 0.0; e.z = 1.15; e.lights = [4, 4]; e.pass_n = 0; e.speed = 0.12; e.stagger = 0.0; e.fire_t = 3.0; e.light_pos = []
		"bakunawa":
			e.mode = "under"; e.timer = 1.2; e.rise = 0.0; e.fired = 0; e.head_y = 0.0
		"santelmo":
			e.flames = [2, 2, 2]; e.vuln_t = 0.0; e.fire_t = 3.0; e.flame_pos = []; e.cy = 0.0
		"vex":
			e.armored = true; e.open_t = 0.0; e.fire_t = 3.0; e.summon_t = 8.0; e.tp_t = 5.0; e.fade = 1.0; e.p2 = false


static func update(e: Dictionary, dt: float, g) -> void:
	var low: bool = e.hp < e.max_hp / 2.0
	match e.kind:
		"kapre":
			e.lunge_t -= dt
			if e.lunge_t <= 0.0:
				e.lunge = 3.0; e.lunge_t = 8.0
				_radio(g, Story.MAYA, "It's coming in close. Blade or fist, now!")
			e.lunge = maxf(0.0, e.lunge - dt)
			e.x = e.x0 + sin(e.t * 0.6) * 0.3
			e.z = _ease(e.z, 0.42 if e.lunge > 0.0 else e.z0, dt * 1.5)
			e.fire_t -= dt
			if e.fire_t <= 0.0:
				_fire(g, e, 2 if low else 1, "#C9B8E8", 0.4, 2.0)
				e.fire_t = 1.9 if low else 2.7
			if low and not e.half:
				e.half = true
				if g != null:
					g.spawn_ent({"type": "wisp", "x": -0.6, "z": 0.8}); g.spawn_ent({"type": "wisp", "x": 0.6, "z": 0.8})
				_radio(g, Story.CAPTAIN, "It's calling for help. Keep pressure on it!")
			_place(e, 3.2, 1.85)
			e.sy = e.base - e.hh * 0.62
		"manananggal":
			e.spawn_t -= dt
			if e.spawn_t <= 0.0 and g != null:
				g.spawn_ent({"type": "wisp", "x": randf_range(-0.6, 0.6), "z": 0.85}); g.spawn_ent({"type": "wisp", "x": randf_range(-0.6, 0.6), "z": 0.9})
				e.spawn_t = 7.0
			match e.mode:
				"fly":
					e.x = _ease(e.x, sin(e.t * 0.9) * 0.5, dt * 2.0); e.z = _ease(e.z, 0.5, dt); e.h = _ease(e.h, 1.7 + sin(e.t * 1.7) * 0.25, dt * 2.0)
					e.dive_t -= dt
					if e.dive_t <= 0.0:
						e.mode = "dive"
						_radio(g, Story.KIKO, "She is diving! Hit her before she lands!")
				"dive":
					e.z = _ease(e.z, 0.2, dt * 2.2); e.h = _ease(e.h, 1.1, dt * 2.2); e.x = _ease(e.x, 0.0, dt * 2.0)
					if e.z < 0.23:
						e.mode = "strike"; e.windup = 0.9
				"strike":
					e.windup -= dt
					if e.windup <= 0.0:
						if g != null: g.hurt(e)
						e.mode = "fly"; e.dive_t = 5.0
			_place(e, 1.3, 2.3)
			e.sy = e.base - View.px(e.h, e.s); e.r = e.ww * 0.35
		"ghost_train":
			if e.stagger > 0.0:
				e.stagger -= dt
				e.z = _ease(e.z, 0.9, dt * 0.6)
				if e.stagger <= 0.0:
					e.z = 1.15; e.lights = [4, 4]; e.pass_n += 1; e.speed = 0.12 + e.pass_n * 0.03
					_radio(g, Story.CAPTAIN, "It is coming around again. Faster this time!")
			else:
				e.z -= e.speed * dt
				e.fire_t -= dt
				if e.fire_t <= 0.0 and e.z < 0.9:
					_fire(g, e, 1, "#7FF7E6", 0.0, 1.6); e.fire_t = 2.8
				if e.z <= 0.2:
					if g != null: g.hurt(e)
					e.z = 1.15; e.lights = [4, 4]
					_radio(g, Story.KIKO, "Take out the headlights before it gets close!")
			_place(e, 1.9, 1.6)
			e.sy = e.base - e.hh * 0.5
			e.light_pos = [Vector3(e.sx - e.ww * 0.3, e.base - e.hh * 0.22, e.ww * 0.12), Vector3(e.sx + e.ww * 0.3, e.base - e.hh * 0.22, e.ww * 0.12)]
		"bakunawa":
			e.timer -= dt
			match e.mode:
				"under":
					if e.timer <= 0.0: e.mode = "rise"; e.timer = 0.6
				"rise":
					e.rise = minf(1.0, e.rise + dt / 0.6)
					if e.timer <= 0.0: e.mode = "up"; e.timer = 3.6; e.fired = 0
				"up":
					if e.fired == 0 and e.timer < 2.6:
						_fire(g, e, 3, "#7FC8FF", 0.3, 1.4); e.fired = 1
					if e.fired == 1 and e.timer < 1.0:
						_fire(g, e, 3 if low else 2, "#7FC8FF", 0.4, 1.4); e.fired = 2
					if e.timer <= 0.0: e.mode = "sink"; e.timer = 0.6
				"sink":
					e.rise = maxf(0.0, e.rise - dt / 0.6)
					if e.timer <= 0.0:
						e.mode = "under"; e.timer = 1.3; e.x = randf_range(-0.5, 0.5); e.z = randf_range(0.42, 0.62)
			_place(e, 2.1, 1.15)
			e.head_y = e.base - e.hh * e.rise; e.sy = e.head_y
		"santelmo":
			e.x = e.x0 + sin(e.t * 0.5) * 0.25
			if e.vuln_t > 0.0:
				e.vuln_t -= dt
				if e.vuln_t <= 0.0:
					e.flames = [2, 2, 2]
					_radio(g, Story.MAYA, "The flames are back. Put them out again!")
			elif e.flames.all(func(f): return f <= 0):
				e.vuln_t = 4.5
				_radio(g, Story.CAPTAIN, "He's exposed. Hit the armor now!")
			e.fire_t -= dt
			if e.fire_t <= 0.0 and e.vuln_t <= 0.0:
				_fire(g, e, 2 if low else 1, "#FFB547", 0.35, 1.5); e.fire_t = 2.6
			_place(e, 2.5, 1.25)
			e.cy = e.base - e.hh * (0.4 if e.vuln_t > 0.0 else 0.55); e.sy = e.cy
			var orbit: float = e.ww * 0.75
			e.flame_pos = []
			for i in 3:
				var a: float = e.t * 1.6 + i * TAU / 3.0
				e.flame_pos.append(Vector3(e.sx + cos(a) * orbit, e.cy + sin(a) * orbit * 0.45, e.ww * 0.14))
		"vex":
			if low and not e.p2:
				e.p2 = true
				_radio(g, Story.CAPTAIN, "He's losing his grip on the Ilalim. Don't let up, {name}!")
			if e.open_t > 0.0:
				e.open_t -= dt
				if e.open_t <= 0.0:
					e.armored = true
					_radio(g, Story.MAYA, "His armor grew back! Another Spirit Blast!")
			e.fire_t -= dt
			if e.fire_t <= 0.0:
				_fire(g, e, 3 if low else 2, "#B07CFF", 0.35, 1.6); e.fire_t = 2.0 if low else 3.0
			e.summon_t -= dt
			if e.summon_t <= 0.0 and g != null:
				g.spawn_ent({"type": "dino" if randf() < 0.5 else "wisp", "x": randf_range(-0.6, 0.6), "z": 0.9})
				g.spawn_ent({"type": "wisp", "x": randf_range(-0.6, 0.6), "z": 0.95})
				e.summon_t = 7.0 if low else 9.0
			if low:
				e.tp_t -= dt
				if e.tp_t <= 0.0:
					e.tp_t = 4.0; e.fade = 0.0
					if g != null: g.burst(Vector2(e.sx, e.base - e.hh * 0.5), Color("#6A2E9A"), 24)
					e.x = randf_range(-0.5, 0.5)
			else:
				e.x = _ease(e.x, sin(e.t * 0.4) * 0.35, dt)
			e.fade = minf(1.0, e.fade + dt * 2.0)
			_place(e, 3.0, 1.35)
			e.sy = e.base - e.hh * 0.55


## Returns the damage actually dealt (0 = blocked).
static func on_damage(e: Dictionary, dmg: int, blast: bool, g) -> int:
	var d = dmg
	match e.kind:
		"manananggal":
			if e.mode == "dive" or e.mode == "strike":
				e.mode = "fly"; e.dive_t = 4.5
				if g != null: g.float_text(Vector2(e.sx, e.sy - 40), "Knocked back!", Color("#FFB547"))
		"ghost_train":
			if e.stagger > 0.0: return 0
			if blast:
				e.lights = [0, 0]
			elif e.hit_part >= 0:
				e.lights[e.hit_part] -= dmg
			if e.lights[0] <= 0 and e.lights[1] <= 0:
				e.stagger = 2.0
				if g != null:
					g.float_text(Vector2(e.sx, e.sy - 40), "DERAILED!", Color("#FFB547"), 1.6)
					g.burst(Vector2(e.sx, e.base - e.hh * 0.2), Color("#FFB547"), 30)
				d = 10
			else:
				d = 0
		"bakunawa":
			pass
		"santelmo":
			if blast:
				if e.flames.any(func(f): return f > 0):
					e.flames = [0, 0, 0]
					if g != null: g.float_text(Vector2(e.sx, e.cy - 60), "Flames out!", Color("#6FF3FF"), 1.4)
				d = 8
			elif e.hit_part >= 0:
				e.flames[e.hit_part] -= dmg
				if e.flames[e.hit_part] <= 0 and g != null:
					var F: Vector3 = e.flame_pos[e.hit_part]
					g.burst(Vector2(F.x, F.y), Color("#FFB547"), 16)
				d = 0
			else:
				d = dmg if e.vuln_t > 0.0 else 0
		"vex":
			if blast:
				if e.armored:
					e.armored = false; e.open_t = 6.0
					if g != null:
						g.float_text(Vector2(e.sx, e.sy - 80), "ARMOR BROKEN!", Color("#6FF3FF"), 1.8)
						g.radio(Story.KIKO, "It cracked! Hit him with everything!")
					d = 6
				else:
					d = 10
			else:
				d = 0 if e.armored else dmg
	if blast:
		d = mini(d, 10)
	return d


static func armor_text(e: Dictionary) -> String:
	match e.kind:
		"ghost_train": return "Armored! Aim for the lights"
		"santelmo": return "Shielded! Put out the flames"
		"vex": return "Shadow armor! Use a Spirit Blast"
	return ""


static func targetable(e: Dictionary) -> bool:
	match e.kind:
		"ghost_train": return e.stagger <= 0.0 and e.z < 1.05
		"bakunawa": return e.mode != "under" and e.rise >= 0.5
		"vex": return e.fade >= 0.6
	return true


static func hit(e: Dictionary, x: float, y: float, a: float) -> String:
	var q = Vector2(x, y)
	match e.kind:
		"kapre":
			var dx: float = (x - e.sx) / (e.ww * 0.5 + a)
			var dy: float = (y - (e.base - e.hh * 0.5)) / (e.hh * 0.5 + a)
			return "hit" if dx * dx + dy * dy <= 1.0 else ""
		"manananggal":
			return "hit" if absf(x - e.sx) < e.ww * 0.3 + a and y > e.sy - e.ww * 0.42 - a and y < e.sy + e.ww * 0.35 + a else ""
		"ghost_train":
			if e.stagger > 0.0: return ""
			for i in 2:
				var L: Vector3 = e.light_pos[i]
				if e.lights[i] > 0 and q.distance_to(Vector2(L.x, L.y)) < L.z * 1.5 + a:
					e.hit_part = i
					return "hit"
			e.hit_part = -1
			return "armor" if absf(x - e.sx) < e.ww * 0.5 and y > e.base - e.hh and y < e.base else ""
		"bakunawa":
			if e.mode == "under" or e.rise < 0.5: return ""
			var R: float = e.ww * 0.42
			if q.distance_to(Vector2(e.sx, e.head_y)) < R * 1.1 + a: return "hit"
			return "hit" if absf(x - e.sx) < R * 0.6 + a and y > e.head_y and y < e.base else ""
		"santelmo":
			for i in 3:
				var F: Vector3 = e.flame_pos[i]
				if e.flames[i] > 0 and q.distance_to(Vector2(F.x, F.y)) < F.z * 1.6 + a:
					e.hit_part = i
					return "hit"
			e.hit_part = -1
			var top: float = e.base - e.hh * (0.8 if e.vuln_t > 0.0 else 1.0)
			if absf(x - e.sx) < e.ww * 0.42 + a and y > top - a and y < e.base:
				return "hit" if e.vuln_t > 0.0 else "armor"
			return ""
		"vex":
			if e.fade < 0.6: return ""
			if absf(x - e.sx) < e.ww * 0.45 + a and y > e.base - e.hh - a and y < e.base:
				return "armor" if e.armored else "hit"
			return ""
	return ""


static func center(e: Dictionary) -> Vector3:
	match e.kind:
		"kapre": return Vector3(e.sx, e.base - e.hh * 0.72, e.ww * 0.35)
		"manananggal": return Vector3(e.sx, e.sy - e.ww * 0.05, e.ww * 0.3)
		"ghost_train":
			for i in 2:
				if e.lights[i] > 0 and e.light_pos.size() == 2:
					e.hit_part = i
					return e.light_pos[i]
			return Vector3(e.sx, e.sy, e.ww * 0.3)
		"bakunawa": return Vector3(e.sx, e.head_y, e.ww * 0.42)
		"santelmo":
			if e.vuln_t > 0.0 or e.flame_pos.size() < 3:
				e.hit_part = -1
				return Vector3(e.sx, e.cy, e.ww * 0.35)
			for i in 3:
				if e.flames[i] > 0:
					e.hit_part = i
					var F: Vector3 = e.flame_pos[i]
					return Vector3(F.x, F.y, F.z * 1.3)
			return Vector3(e.sx, e.cy, e.ww * 0.35)
		"vex": return Vector3(e.sx, e.base - e.hh * 0.6, e.ww * 0.4)
	return Vector3(e.sx, e.sy, 40)


## ===================== drawing =====================
static func draw(ci: CanvasItem, e: Dictionary, t: float) -> void:
	match e.kind:
		"kapre": _kapre(ci, e, t)
		"manananggal": _manananggal(ci, e, t)
		"ghost_train": _train(ci, e, t)
		"bakunawa": _bakunawa(ci, e, t)
		"santelmo": _santelmo(ci, e, t)
		"vex": _vex(ci, e, t)


static func _kapre(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var sx: float = e.sx
	var base: float = e.base
	var hh: float = e.hh
	var ww: float = e.ww
	var cy = base - hh * 0.5
	var top = base - hh
	var angry: bool = e.hp < e.max_hp / 2.0
	var ol = Color("#7A5410")
	Pen.glow(ci, Vector2(sx, cy), hh * 0.7, Color(1, 0.35, 0.35, 0.25) if angry else Color(1, 0.86, 0.47, 0.2))
	for k in [-1.0, 1.0]:
		var f = Pen.fluff(Vector2(sx + k * ww * 0.22, base - hh * 0.02), ww * 0.16, hh * 0.04, 8, 0.15)
		Pen.fill(ci, f, Color("#B88A2E")); Pen.ink(ci, f, hh * 0.006, ol)
	var body = Pen.fluff(Vector2(sx, cy), ww * 0.5, hh * 0.5, 30, 0.03, sin(t) * 0.04)
	Pen.fill_soft(ci, body, Vector2(sx, cy), hh * 0.55, Color("#F2D58A"), Color("#D9A84A"), Color("#9C6E22")); Pen.ink(ci, body, hh * 0.006, ol)
	for i in 5:
		var lp = Vector2(sx + (i - 2) * ww * 0.15, top + hh * 0.04 + absf(i - 2) * hh * 0.02)
		var leaf = Pen.ell(lp + Vector2(0, -hh * 0.04).rotated((i - 2) * 0.4), ww * 0.05, hh * 0.05, (i - 2) * 0.4 + sin(t * 2.0 + i) * 0.1, 14)
		Pen.fill(ci, leaf, Color("#6FBF6A") if i % 2 == 1 else Color("#8ED67E")); Pen.ink(ci, leaf, hh * 0.004, Color("#3E7A3A"))
	for k in [-1.0, 1.0]:
		var arm = Pen.fluff(Vector2(sx + k * ww * 0.5, cy + hh * 0.1), ww * 0.12, hh * 0.18, 10, 0.09, k * (0.35 + sin(t * 2.0 + k) * 0.12))
		Pen.fill(ci, arm, Color("#C9963A")); Pen.ink(ci, arm, hh * 0.005, ol)
	var fy = top + hh * 0.22
	var s = ww * 0.62
	Ents.cute_eyes(ci, Vector2(sx, fy), s, ["#FF9A9A", "#9A1E1E"] if angry else ["#F7C978", "#7A4A10"], "mischief" if angry else "smug", 0.27, false, Color("#E2B456"))
	Ents.blush(ci, Vector2(sx, fy + s * 0.22), s, 0.36)
	var m = Vector2(sx + ww * 0.08, fy + s * 0.32)
	var dirv = Vector2.from_angle(0.2)
	ci.draw_line(m, m + dirv * ww * 0.28, Color("#7A4A2A"), hh * 0.024)
	Pen.glow(ci, m + dirv * ww * 0.28, hh * 0.04 * (1.0 + 0.3 * sin(t * 8.0)), Color(1, 0.47, 0.16, 0.9))
	for i in 4:
		var k = fposmod(t * 0.5 + i / 4.0, 1.0)
		ci.draw_circle(m + Vector2(ww * 0.3 + k * ww * 0.2, -k * hh * 0.25), ww * (0.04 + k * 0.08), Color(0.86, 0.84, 0.94, 0.4 * (1.0 - k)))
	Ents.flash_fx(ci, e, Vector2(sx, cy), hh * 0.5)


static func _manananggal(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var c = Vector2(e.sx, e.sy)
	var S: float = e.ww
	var flap = sin(t * (6.0 if e.mode == "fly" else 14.0))
	Pen.glow(ci, c, S * 1.3, Color(1, 0.31, 0.69, 0.25))
	for k in [-1.0, 1.0]:
		var wy = c.y - S * (0.45 + flap * 0.25)
		var wing = PackedVector2Array([c + Vector2(k * S * 0.12, -S * 0.05)])
		wing.append_array(Pen.quad_pts(c + Vector2(k * S * 0.12, -S * 0.05), Vector2(c.x + k * S * 0.5, wy - S * 0.2), Vector2(c.x + k * S * 1.05, wy), 8))
		var prev = Vector2(c.x + k * S * 1.05, wy)
		for i in 3:
			var nxt = c + Vector2(k * S * (0.78 - i * 0.28), S * (0.18 - i * 0.04))
			wing.append_array(Pen.quad_pts(prev, c + Vector2(k * S * (0.95 - i * 0.28), S * 0.05 - i * S * 0.02), nxt, 5))
			prev = nxt
		wing.append(c + Vector2(k * S * 0.12, S * 0.15))
		Pen.fill_v(ci, wing, wy, c.y + S * 0.2, Color("#C77DFF"), Color("#6A2E9A")); Pen.ink(ci, wing, S * 0.015)
	var tip = c + Vector2(sin(t * 3.0) * S * 0.15, S * 0.9)
	var tail = Pen.quad_pts(c + Vector2(-S * 0.17, S * 0.2), c + Vector2(-S * 0.1 + sin(t * 4.0) * S * 0.1, S * 0.6), tip, 8)
	tail.append_array(Pen.quad_pts(tip, c + Vector2(S * 0.12, S * 0.55), c + Vector2(S * 0.17, S * 0.2), 8))
	Pen.fill_v(ci, tail, c.y + S * 0.2, c.y + S * 0.9, Color(0.47, 0.2, 0.59, 0.9), Color(0.47, 0.2, 0.59, 0.0))
	var dress = PackedVector2Array([c + Vector2(-S * 0.17, -S * 0.02), c + Vector2(S * 0.17, -S * 0.02), c + Vector2(S * 0.2, S * 0.25), c + Vector2(-S * 0.2, S * 0.25)])
	Pen.fill_v(ci, dress, c.y, c.y + S * 0.25, Color("#B0284E"), Color("#6A1430")); Pen.ink(ci, dress, S * 0.012)
	var R = S * 0.16
	var hc = c + Vector2(0, -S * 0.2)
	var hair = PackedVector2Array()
	for i in 13:
		hair.append(hc + Vector2.from_angle(PI + PI * i / 12.0) * R * 1.2)
	hair.append(hc + Vector2(R * 1.3 + flap * R * 0.2, R * 2.6))
	hair.append(hc + Vector2(-R * 1.3 - flap * R * 0.2, R * 2.6))
	Pen.fill_v(ci, hair, hc.y - R, hc.y + R * 3.0, Color("#2A1A3A"), Color("#0E0818"))
	var face = Pen.circle_pts(hc, R, 24)
	Pen.fill_soft(ci, face, hc, R, Color("#F3ECFF"), Color("#D9CCF2"), Color("#B5A3DA")); Pen.ink(ci, face, S * 0.01)
	Ents.cute_eyes(ci, hc + Vector2(0, R * 0.1), R * 1.1, ["#FF9DD0", "#9A1E5A"], "mischief", 0.36)
	Ents.fang_grin(ci, hc + Vector2(0, R * 0.55), R * 1.2)
	var bang = PackedVector2Array()
	for i in 13:
		bang.append(hc + Vector2(0, -R * 0.05) + Vector2.from_angle(PI * 1.02 + PI * 0.96 * i / 12.0) * R * 1.05)
	bang.append_array(PackedVector2Array([hc + Vector2(R * 0.5, -R * 0.45), hc + Vector2(0, -R * 0.25), hc + Vector2(-R * 0.5, -R * 0.45)]))
	Pen.fill(ci, bang, Color("#1E1230"))
	Ents.flash_fx(ci, e, c, S * 0.8)


static func _train(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var sx: float = e.sx + (sin(t * 60.0) * e.ww * 0.02 if e.stagger > 0.0 else 0.0)
	var base: float = e.base
	var hh: float = e.hh
	var ww: float = e.ww
	var top = base - hh
	Pen.glow(ci, Vector2(sx, base - hh * 0.5), ww * 1.1, Color(0.5, 0.97, 0.9, 0.18))
	var body = PackedVector2Array()
	var rr = ww * 0.3
	for i in 9:
		body.append(Vector2(sx - ww * 0.5 + rr, top + rr) + Vector2.from_angle(PI + PI * 0.5 * i / 8.0) * rr)
	for i in 9:
		body.append(Vector2(sx + ww * 0.5 - rr, top + rr) + Vector2.from_angle(PI * 1.5 + PI * 0.5 * i / 8.0) * rr)
	body.append(Vector2(sx + ww * 0.5, base)); body.append(Vector2(sx - ww * 0.5, base))
	Pen.fill_v(ci, body, top, base, Color(0.82, 1, 0.98, 0.92), Color(0.47, 0.78, 0.82, 0.92)); Pen.ink(ci, body, ww * 0.02)
	ci.draw_rect(Rect2(sx - ww * 0.5, base - hh * 0.42, ww, hh * 0.06), Color("#E2483C"))
	ci.draw_rect(Rect2(sx - ww * 0.36, top + hh * 0.12, ww * 0.72, hh * 0.32), Color("#1A2A48"))
	Ents.cute_eyes(ci, Vector2(sx, top + hh * 0.27), ww * 0.55, ["#BFFFF7", "#1F8A80"], "mischief", 0.3)
	Ents.fang_grin(ci, Vector2(sx, top + hh * 0.37), ww * 0.5)
	for i in 2:
		var L: Vector3 = e.light_pos[i]
		var p = Vector2(L.x, L.y) + Vector2(sx - e.sx, 0)
		var alive: bool = e.lights[i] > 0
		if alive:
			Pen.glow(ci, p, L.z * 4.0, Color(1, 0.94, 0.67, 0.6))
		var lamp = Pen.circle_pts(p, L.z, 20)
		Pen.fill(ci, lamp, Color("#FFF6C8") if alive else Color("#3A3A48")); Pen.ink(ci, lamp, ww * 0.015)
		if not alive:
			ci.draw_line(p + Vector2(-L.z * 0.6, -L.z * 0.5), p + Vector2(L.z * 0.5, L.z * 0.6), Color("#8A8AA0"), 2.0)
	ci.draw_rect(Rect2(sx - ww * 0.55, base - hh * 0.06, ww * 1.1, hh * 0.06), Color("#4A5068"))
	if e.stagger > 0.0:
		for i in 5:
			Pen.fill(ci, Pen.star(Vector2(sx + randf_range(-0.5, 0.5) * ww, base - randf() * 0.3 * hh), ww * 0.05, t * 10.0 + i), Color(1, 0.78, 0.35, 0.9))
	Ents.flash_fx(ci, e, Vector2(sx, base - hh * 0.5), ww * 0.6)


static func _bakunawa(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var sx: float = e.sx
	var base: float = e.base
	var ww: float = e.ww
	var R = ww * 0.42
	var hy: float = e.head_y
	var ol = Color("#1E4A6A")
	for i in 3:
		var k = fposmod(t * 0.8 + i / 3.0, 1.0)
		Pen.stroke(ci, Pen.ell(Vector2(sx, base), ww * (0.4 + k * 0.6), ww * (0.08 + k * 0.1), 0.0, 28), Color(0.63, 0.86, 1, 0.55 * (1.0 - k)), 2.0)
	if e.rise <= 0.02:
		return
	var neck = Pen.quad_pts(Vector2(sx - R * 0.6, base), Vector2(sx - R * 0.9 + sin(t * 2.0) * R * 0.3, (hy + base) * 0.5), Vector2(sx - R * 0.45, hy + R * 0.5), 10)
	neck.append_array(Pen.quad_pts(Vector2(sx + R * 0.45, hy + R * 0.5), Vector2(sx + R * 0.5 + sin(t * 2.0) * R * 0.3, (hy + base) * 0.5), Vector2(sx + R * 0.6, base), 10))
	Pen.fill_v(ci, neck, hy, base, Color("#7FD3E8"), Color("#2E7A9A")); Pen.ink(ci, neck, ww * 0.015, ol)
	for i in 5:
		var yy = hy + R * 0.6 + i * (base - hy - R) / 5.0
		Pen.fill(ci, Pen.ell(Vector2(sx, yy), R * 0.25, R * 0.07, 0.0, 12), Color(1, 0.94, 0.78, 0.7))
	for k in [-1.0, 1.0]:
		var fin = PackedVector2Array([Vector2(sx + k * R * 0.8, hy - R * 0.2)])
		for i in 4:
			fin.append(Vector2(sx + k * R * (1.3 + (i % 2) * 0.3), hy - R * (0.6 - i * 0.3)))
		fin.append(Vector2(sx + k * R * 0.8, hy + R * 0.4))
		Pen.fill(ci, fin, Color("#B9F0FF")); Pen.ink(ci, fin, ww * 0.012, ol)
	var head = Pen.ell(Vector2(sx, hy), R, R * 0.85, 0.0, 28)
	Pen.fill_soft(ci, head, Vector2(sx, hy), R, Color("#D8F6FF"), Color("#8ED8EE"), Color("#4A9CC0")); Pen.ink(ci, head, ww * 0.015, ol)
	var snout = Pen.ell(Vector2(sx, hy + R * 0.45), R * 0.6, R * 0.32, 0.0, 20)
	Pen.fill(ci, snout, Color("#E8FBFF")); Pen.ink(ci, snout, ww * 0.01, ol)
	ci.draw_circle(Vector2(sx, hy - R * 0.55), R * 0.16, Color("#FFF4C8"))
	ci.draw_circle(Vector2(sx + R * 0.07, hy - R * 0.6), R * 0.14, Color("#8ED8EE"))
	Ents.cute_eyes(ci, Vector2(sx, hy - R * 0.08), R * 1.4, ["#FFE38A", "#A86A10"], "mischief", 0.3)
	Ents.fang_grin(ci, Vector2(sx, hy + R * 0.42), R * 1.3)
	for k in [-1.0, 1.0]:
		ci.draw_polyline(Pen.quad_pts(Vector2(sx + k * R * 0.5, hy + R * 0.4), Vector2(sx + k * R * 1.2, hy + R * 0.5 + sin(t * 3.0 + k) * R * 0.2), Vector2(sx + k * R * 1.4, hy + R * 0.9), 8), Color("#E8FBFF"), 2.0, true)
	Ents.flash_fx(ci, e, Vector2(sx, hy), R * 1.5)


static func _santelmo(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var sx: float = e.sx
	var base: float = e.base
	var hh: float = e.hh
	var ww: float = e.ww
	var kneel: bool = e.vuln_t > 0.0
	var top = base - hh * (0.8 if kneel else 1.0)
	var lw = ww * 0.02
	Pen.glow(ci, Vector2(sx, e.cy), hh * 0.6, Color(0.44, 0.95, 1, 0.25) if kneel else Color(1, 0.59, 0.24, 0.22))
	var cape = PackedVector2Array([Vector2(sx - ww * 0.4, top + hh * 0.25), Vector2(sx + ww * 0.4, top + hh * 0.25), Vector2(sx + ww * 0.55 + sin(t * 2.0) * ww * 0.05, base), Vector2(sx - ww * 0.55, base)])
	Pen.fill_v(ci, cape, top, base, Color("#8A1E3A"), Color("#4A0E1E")); Pen.ink(ci, cape, lw)
	var body = PackedVector2Array([Vector2(sx - ww * 0.36, top + hh * 0.24), Vector2(sx + ww * 0.36, top + hh * 0.24), Vector2(sx + ww * 0.26, top + hh * 0.62), Vector2(sx - ww * 0.26, top + hh * 0.62)])
	Pen.fill_soft(ci, body, Vector2(sx, top + hh * 0.4), ww * 0.4, Color("#F2F4FF"), Color("#B8BED8"), Color("#7A82A0")); Pen.ink(ci, body, lw)
	for k in [-1.0, 1.0]:
		var pad = Pen.ell(Vector2(sx + k * ww * 0.38, top + hh * 0.26), ww * 0.16, ww * 0.1, 0.0, 16)
		Pen.fill(ci, pad, Color("#C9CEE6")); Pen.ink(ci, pad, lw)
		ci.draw_rect(Rect2(sx + k * ww * 0.18 - ww * 0.08, top + hh * 0.62, ww * 0.16, hh * (0.18 if kneel else 0.38)), Color("#9AA2C0"))
	var hy = top + hh * 0.13
	ci.draw_polyline(Pen.quad_pts(Vector2(sx, hy - hh * 0.12), Vector2(sx + ww * 0.4, hy - hh * 0.2 + sin(t * 3.0) * hh * 0.02), Vector2(sx + ww * 0.3, hy - hh * 0.02), 10), Color("#E2483C"), ww * 0.1, true)
	var helm = Pen.ell(Vector2(sx, hy), ww * 0.2, hh * 0.1, 0.0, 24)
	Pen.fill_soft(ci, helm, Vector2(sx, hy), ww * 0.25, Color.WHITE, Color("#C9CEE6"), Color("#8A92B2")); Pen.ink(ci, helm, lw)
	ci.draw_rect(Rect2(sx - ww * 0.15, hy - hh * 0.01, ww * 0.3, hh * 0.035), Color("#1A1428"))
	Pen.glow(ci, Vector2(sx, hy), ww * 0.25, Color(0.44, 0.95, 1, 0.7) if kneel else Color(1, 0.59, 0.24, 0.8))
	var sw = Vector2(sx + ww * 0.45, top + hh * 0.5)
	ci.draw_line(sw, sw + Vector2(0, hh * 0.5).rotated(0.15), Color("#E8ECFF"), ww * 0.06)
	ci.draw_line(sw + Vector2(-ww * 0.12, -hh * 0.03), sw + Vector2(ww * 0.12, -hh * 0.03), Color("#FFD36B"), hh * 0.03)
	for i in 3:
		if e.flames[i] <= 0 or e.flame_pos.size() < 3:
			continue
		var F: Vector3 = e.flame_pos[i]
		var p = Vector2(F.x, F.y)
		var r = F.z
		Pen.glow(ci, p, r * 3.0, Color(1, 0.63, 0.24, 0.6))
		var fl = Pen.quad_pts(p + Vector2(0, -r * 2.0), p + Vector2(r * 1.2, -r * 0.5), p + Vector2(r, 0), 8)
		for j in 9:
			fl.append(p + Vector2.from_angle(PI * j / 8.0) * r)
		fl.append_array(Pen.quad_pts(p + Vector2(-r, 0), p + Vector2(-r * 1.2, -r * 0.5), p + Vector2(0, -r * 2.0), 8))
		Pen.fill(ci, fl, Color("#FFB547")); Pen.ink(ci, fl, maxf(1.0, r * 0.1), Color("#A8501A"))
		ci.draw_circle(p + Vector2(0, r * 0.1), r * 0.6, Color("#FFF2C2"))
		Ents.cute_eyes(ci, p + Vector2(0, r * 0.05), r * 1.1, ["#FFB547", "#8A3A10"], "mischief", 0.28)
	Ents.flash_fx(ci, e, Vector2(sx, e.cy), hh * 0.45)


static func _vex(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var a: float = e.fade
	var sx: float = e.sx
	var base: float = e.base
	var hh: float = e.hh
	var ww: float = e.ww
	var top = base - hh
	var lw = ww * 0.02
	Pen.glow(ci, Vector2(sx, base - hh * 0.5), hh * 0.7, Color(0.47, 0.16, 0.78, 0.3 * a))
	for i in 7:
		var ang = i / 7.0 * TAU + t * 0.5
		var ln = hh * (0.3 + 0.15 * sin(t * 2.0 + i))
		var o = Vector2(sx, base - hh * 0.45)
		ci.draw_polyline(Pen.quad_pts(o, o + Vector2(cos(ang) * ln * 0.6, sin(ang) * ln * 0.3), o + Vector2(cos(ang) * ln, sin(ang) * ln * 0.5), 8), Color(0.16, 0.04, 0.27, 0.7 * a), ww * 0.08, true)
	var coat = PackedVector2Array([Vector2(sx - ww * 0.32, top + hh * 0.22), Vector2(sx + ww * 0.32, top + hh * 0.22), Vector2(sx + ww * 0.5, base)])
	for i in range(4, -1, -1):
		coat.append(Vector2(sx - ww * 0.5 + ww * i / 4.0, base - (hh * 0.06 if i % 2 == 1 else 0.0)))
	Pen.fill_v(ci, coat, top, base, Color(Color("#2A1E3A"), a), Color(Color("#120A1E"), a)); Pen.ink(ci, coat, lw, Color(INK, a))
	Pen.fill(ci, PackedVector2Array([Vector2(sx - ww * 0.12, top + hh * 0.22), Vector2(sx + ww * 0.12, top + hh * 0.22), Vector2(sx + ww * 0.1, top + hh * 0.5), Vector2(sx - ww * 0.1, top + hh * 0.5)]), Color(Color("#E8E2D6"), a))
	ci.draw_line(Vector2(sx - ww * 0.3, top + hh * 0.26), Vector2(sx + ww * 0.3, top + hh * 0.48), Color(Color("#C0283C"), a), ww * 0.09)
	var hy = top + hh * 0.13
	var R = ww * 0.17
	var face = Pen.circle_pts(Vector2(sx, hy), R, 24)
	Pen.fill_soft(ci, face, Vector2(sx, hy), R, Color(Color("#D8D2E6"), a), Color(Color("#A89EC0"), a), Color(Color("#7A6E94"), a)); Pen.ink(ci, face, lw, Color(INK, a))
	for k in [-1.0, 1.0]:
		var ep = Vector2(sx + k * R * 0.38, hy + R * 0.05)
		Pen.glow(ci, ep, R * 0.5, Color(1, 0.16, 0.24, 0.9 * a))
		Pen.fill(ci, Pen.ell(ep, R * 0.15, R * 0.09, k * 0.3, 12), Color(1, 0.82, 0.84, a))
		ci.draw_line(Vector2(sx + k * R * 0.65, hy - R * 0.25), Vector2(sx + k * R * 0.12, hy - R * 0.08), Color(INK, a), maxf(1.5, R * 0.1))
	ci.draw_line(Vector2(sx - R * 0.25, hy + R * 0.5), Vector2(sx + R * 0.25, hy + R * 0.45), Color(Color("#5A3A4A"), a), 2.0)
	var brim = Pen.ell(Vector2(sx, hy - R * 0.7), R * 2.0, R * 0.4, -0.05, 28)
	Pen.fill(ci, brim, Color(Color("#3A2A1E"), a)); Pen.ink(ci, brim, lw, Color(INK, a))
	var crown = Pen.ell(Vector2(sx, hy - R * 1.05), R * 0.9, R * 0.55, 0.0, 16, PI, TAU)
	Pen.fill(ci, crown, Color(Color("#3A2A1E"), a))
	var bo = Vector2(sx - ww * 0.42, top + hh * 0.55)
	Pen.glow(ci, bo + Vector2(0, -hh * 0.15).rotated(-0.5), hh * 0.2, Color(0.69, 0.49, 1, 0.6 * a))
	var blade = PackedVector2Array([bo + Vector2(-ww * 0.03, 0).rotated(-0.5)])
	blade.append_array(Pen.quad_pts(bo + Vector2(-ww * 0.03, 0).rotated(-0.5), bo + Vector2(ww * 0.08, -hh * 0.18).rotated(-0.5), bo + Vector2(0, -hh * 0.32).rotated(-0.5), 8))
	blade.append_array(Pen.quad_pts(bo + Vector2(0, -hh * 0.32).rotated(-0.5), bo + Vector2(-ww * 0.05, -hh * 0.15).rotated(-0.5), bo + Vector2(-ww * 0.03, 0).rotated(-0.5), 8))
	Pen.fill(ci, blade, Color(Color("#D9C8FF"), a))
	if e.armored:
		var al = (0.55 + 0.2 * sin(t * 4.0)) * a
		for i in 6:
			var ang = t * 0.6 + i * TAU / 6.0
			var hc = Vector2(sx + cos(ang) * ww * 0.3, base - hh * 0.5 + sin(ang) * hh * 0.3)
			var hexa = PackedVector2Array()
			for j in 6:
				hexa.append(hc + Vector2.from_angle(j / 6.0 * TAU) * ww * 0.12)
			Pen.stroke(ci, hexa, Color(0.69, 0.49, 1, al), 2.5)
	Ents.flash_fx(ci, e, Vector2(sx, base - hh * 0.5), hh * 0.5)
