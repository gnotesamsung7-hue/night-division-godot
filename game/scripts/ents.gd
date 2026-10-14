class_name Ents
extends RefCounted
## Every ghoul, person and target. An entity is a Dictionary with at least: type, x, z, t, hp, state.
## Folklore names: wisp = Wakwak, phantom = Kapre, possessed = person ridden by a Tiyanak,
## dino/grub = Aswang in disguise, lantern = training target, civilian = don't shoot, orb = boss projectile.
## hit() returns "hit" | "spirit" | "person" | "phased" | "armor" | "".

const INK := Color("#3A2440")
const ATTACK_Z := 0.12
const INFO := {
	"wisp": {"hp": 1, "pts": 100, "color": Color("#FF9DC0")},
	"phantom": {"hp": 2, "pts": 250, "color": Color("#FFD86B")},
	"dino": {"hp": 2, "pts": 200, "color": Color("#C9B6F7")},
	"grub": {"hp": 3, "pts": 300, "color": Color("#A8E6A0")},
	"civilian": {"hp": 1, "pts": 0, "color": Color("#6FF3FF")},
	"possessed": {"hp": 1, "pts": 300, "color": Color("#8FB4FF")},
	"lantern": {"hp": 1, "pts": 50, "color": Color("#FFB547")},
	"orb": {"hp": 1, "pts": 25, "color": Color("#FF6BB5")},
	"boss": {"hp": 20, "pts": 2000, "color": Color("#FFB547")},
}
const LOOKS := [
	{"hair": "bob", "hc": ["#FFCBDA", "#E88BA6"], "top": "cardigan", "tc": "#DDB892", "bottom": "skirt", "bc": "#4C5A7C", "bow": "#D94A5A", "item": "drink", "eye": ["#F0A8C8", "#8A3A6A"]},
	{"hair": "spiky", "hc": ["#5570C4", "#1F2B60"], "top": "jacket", "tc": "#2E3140", "bottom": "jeans", "bc": "#5B7AB0", "bow": "", "item": "wave", "eye": ["#8AB0F0", "#2A3F80"]},
	{"hair": "long", "hc": ["#C07A55", "#6E3423"], "top": "cardigan", "tc": "#ECD6B8", "bottom": "skirt", "bc": "#4C5A7C", "bow": "#C9604A", "item": "camera", "eye": ["#D29466", "#5A2E18"]},
	{"hair": "swept", "hc": ["#FFE6A6", "#D9A84E"], "top": "shirt", "tc": "#A6A69A", "bottom": "pants", "bc": "#3C3D48", "bow": "", "item": "headphones", "eye": ["#DEAE62", "#6B4A1A"]},
	{"hair": "wavy", "hc": ["#DCCBFF", "#9A7BD9"], "top": "hoodie", "tc": "#CDB8F2", "bottom": "skirt", "bc": "#4C5A7C", "bow": "", "item": "none", "eye": ["#C2A6F0", "#5A3E99"]},
]
const SKIN := [["#FFE9DB", "#F3C6AE"], ["#F8D5BC", "#E8B394"], ["#E9BC98", "#CF9A74"], ["#C99474", "#AB7656"]]


static func make(spec: Dictionary) -> Dictionary:
	var e = {"x": 0.0, "z": 0.8, "t": 0.0, "flash": 0.0, "state": "move", "sx": 0.0, "sy": 0.0, "r": 10.0,
		"dead": false, "exited": false, "still": false, "windup": 0.0, "warned": false, "hit_part": -1, "boss": false,
		"drop": false, "h": -1.0, "speed": -1.0, "dir": 0.0, "armored": false, "ripple": 0.0}
	e.merge(spec, true)
	e.hp = spec.get("hp", INFO[e.type].hp)
	_init_type(e)
	update(e, 0.0, null)
	return e


static func pts_of(e: Dictionary) -> int:
	return INFO[e.type].pts


static func color_of(e: Dictionary) -> Color:
	return INFO[e.type].color


static func hostile(e: Dictionary) -> bool:
	return e.type != "civilian"


static func approach(e: Dictionary, dt: float) -> void:
	if e.has("tx"):
		e.x += (e.tx - e.x) * minf(1.0, dt * 2.2)
	if e.still:
		return
	if e.state == "move":
		e.z -= e.speed * dt
		if e.z <= ATTACK_Z:
			e.z = ATTACK_Z
			e.state = "attack"
			e.windup = e.get("windup_time", 1.0)
	elif e.state == "attack":
		e.windup -= dt


static func _init_type(e: Dictionary) -> void:
	match e.type:
		"wisp":
			if e.speed < 0: e.speed = randf_range(0.1, 0.14)
			if e.h < 0: e.h = randf_range(0.9, 1.4)
			e.wa = randf_range(0.12, 0.3); e.wf = randf_range(1.5, 2.6); e.ph = randf() * TAU
			e.trail = []; e.blink_every = randf_range(2.5, 4.0)
			if e.drop: e.drop_h = e.h; e.h = 3.2
		"phantom":
			if e.speed < 0: e.speed = randf_range(0.06, 0.08)
			e.pt = randf() * 2.4; e.alpha = 1.0; e.solid = true; e.blink_every = randf_range(3, 5)
		"dino":
			if e.speed < 0: e.speed = randf_range(0.07, 0.09)
			e.ph = randf() * TAU; e.blink_every = randf_range(2.5, 4.0)
		"grub":
			if e.speed < 0: e.speed = randf_range(0.05, 0.065)
			e.ph = randf() * TAU; e.blink_every = randf_range(2.5, 4.0)
		"civilian", "possessed":
			if e.dir == 0.0: e.dir = 1.0 if e.x < 0 else -1.0
			if e.speed < 0: e.speed = randf_range(0.16, 0.22)
			e.still = true
			e.look = LOOKS[randi() % LOOKS.size()]
			e.skin = SKIN[randi() % SKIN.size()]
			e.ph = randf() * TAU; e.blink_every = randf_range(2.5, 4.5)
		"lantern":
			e.still = true
			if e.h < 0: e.h = 1.1
		"orb":
			if e.speed < 0: e.speed = 0.42
			e.windup_time = 0.45
			if e.h < 0: e.h = 1.0
			if not e.has("col"): e.col = "#FF6BB5"
			e.trail = []; e.ph = randf() * TAU
		"boss":
			Bosses.init(e)


static func update(e: Dictionary, dt: float, g) -> void:
	e.t += dt
	e.flash = maxf(0.0, e.flash - dt * 5.0)
	match e.type:
		"wisp":
			approach(e, dt)
			if e.drop and e.h > e.drop_h: e.h = maxf(e.drop_h, e.h - dt * 2.4)
			e.xr = e.x + (0.0 if e.still else sin(e.t * e.wf + e.ph) * e.wa)
			var p = View.proj(e.xr, e.z)
			e.sx = p.x; e.sy = p.y - View.px(e.h + sin(e.t * 3.0) * 0.06, p.z); e.r = View.px(0.22, p.z)
			e.trail.push_front(Vector2(e.sx, e.sy))
			if e.trail.size() > 8: e.trail.pop_back()
		"phantom":
			e.pt += dt
			approach(e, dt)
			e.solid = fposmod(e.pt, 2.6) < 1.5 or e.state == "attack"
			e.alpha += ((1.0 if e.solid else 0.18) - e.alpha) * minf(1.0, dt * 8.0)
			var p = View.proj(e.x + sin(e.t * 0.8) * 0.08, e.z)
			e.hh = View.px(1.4, p.z); e.ww = View.px(0.72, p.z)
			e.sx = p.x; e.base = p.y - View.px(absf(sin(e.t * 4.0)) * 0.04, p.z); e.sy = e.base - e.hh * 0.55; e.r = e.ww * 0.5
		"dino", "grub":
			approach(e, dt)
			var p = View.proj(e.x, e.z)
			e.hh = View.px(0.8 if e.type == "dino" else 0.9, p.z); e.ww = View.px(0.62 if e.type == "dino" else 0.6, p.z)
			e.sx = p.x; e.base = p.y; e.sy = e.base - e.hh * 0.5; e.r = e.ww * 0.5
		"civilian", "possessed":
			e.x += e.dir * e.speed * dt
			if absf(e.x) > 1.45: e.exited = true
			var p = View.proj(e.x, e.z)
			e.sx = p.x; e.base = p.y; e.hh = View.px(1.0, p.z); e.ww = View.px(0.4, p.z)
			e.bob = absf(sin(e.t * 7.5 + e.ph)) * e.hh * 0.018
			e.sy = e.base - e.hh * 0.5
			e.head_r = e.hh * 0.14; e.head_y = e.base - e.hh * 0.8 - e.bob
			e.spr = View.px(0.13, p.z)
			e.spx = e.sx + sin(e.t * 3.0) * e.ww * 0.05; e.spy = e.head_y - e.head_r * 1.05 - e.spr * 0.75
		"lantern":
			e.ripple = maxf(0.0, e.ripple - dt * 2.0)
			var p = View.proj(e.x, e.z)
			e.sx = p.x; e.sy = p.y - View.px(e.h + sin(e.t * 1.5) * 0.04, p.z); e.r = View.px(0.22, p.z)
		"orb":
			approach(e, dt)
			e.x += (0.0 - e.x) * minf(1.0, dt * 0.9)
			e.h += (0.95 - e.h) * minf(1.0, dt * 1.2)
			var p = View.proj(e.x, e.z)
			e.sx = p.x; e.sy = p.y - View.px(e.h, p.z); e.r = View.px(0.12, p.z) + 5.0
			e.trail.push_front(Vector2(e.sx, e.sy))
			if e.trail.size() > 6: e.trail.pop_back()
		"boss":
			Bosses.update(e, dt, g)


static func hit(e: Dictionary, x: float, y: float, a: float) -> String:
	var q = Vector2(x, y)
	match e.type:
		"wisp":
			return "hit" if q.distance_to(Vector2(e.sx, e.sy)) < e.r * 1.45 + a else ""
		"phantom":
			var dx: float = (x - e.sx) / (e.ww * 0.55 + a)
			var dy: float = (y - (e.base - e.hh * 0.5)) / (e.hh * 0.52 + a)
			if dx * dx + dy * dy > 1.0: return ""
			return "hit" if e.solid else "phased"
		"dino", "grub":
			var dx: float = (x - e.sx) / (e.ww * 0.55 + a)
			var dy: float = (y - (e.base - e.hh * 0.55)) / (e.hh * 0.55 + a)
			return "hit" if dx * dx + dy * dy <= 1.0 else ""
		"civilian":
			return "person" if _person_hit(e, x, y) else ""
		"possessed":
			if q.distance_to(Vector2(e.spx, e.spy)) < e.spr * 1.45 + a * 0.7: return "spirit"
			return "person" if _person_hit(e, x, y) else ""
		"lantern":
			if q.distance_to(Vector2(e.sx, e.sy)) > e.r * (1.7 if e.armored else 1.3) + a: return ""
			return "armor" if e.armored else "hit"
		"orb":
			return "hit" if q.distance_to(Vector2(e.sx, e.sy)) < e.r * 1.7 + a else ""
		"boss":
			return Bosses.hit(e, x, y, a)
	return ""


static func _person_hit(e: Dictionary, x: float, y: float) -> bool:
	return absf(x - e.sx) < e.hh * 0.2 and y > e.head_y - e.head_r and y < e.base


## Where to aim: Vector3(x, y, radius).
static func center(e: Dictionary) -> Vector3:
	match e.type:
		"wisp": return Vector3(e.sx, e.sy, e.r * 1.25)
		"phantom": return Vector3(e.sx, e.base - e.hh * 0.6, e.ww * 0.5)
		"dino", "grub": return Vector3(e.sx, e.base - e.hh * 0.58, e.ww * 0.5)
		"civilian": return Vector3(e.sx, e.sy, e.hh * 0.2)
		"possessed": return Vector3(e.spx, e.spy, e.spr * 1.25)
		"lantern": return Vector3(e.sx, e.sy, e.r * 1.4)
		"orb": return Vector3(e.sx, e.sy, e.r * 1.3)
		"boss": return Bosses.center(e)
	return Vector3(e.sx, e.sy, e.r)


static func targetable(e: Dictionary) -> bool:
	if e.dead or e.type == "civilian": return false
	if e.type == "phantom" and not e.solid: return false
	if e.type == "boss": return Bosses.targetable(e)
	return true


## ===================== drawing =====================
static func cute_eyes(ci: CanvasItem, c: Vector2, s: float, iris: Array, mood := "normal", spacing := 0.3, blink := false, lid := Color(0, 0, 0, 0), alpha := 1.0) -> void:
	for k in [-1.0, 1.0]:
		var e = c + Vector2(k * s * spacing, 0)
		if blink or mood == "happy":
			ci.draw_arc(e + Vector2(0, s * 0.06), s * 0.11, PI * 1.15, PI * 1.85, 10, Color(INK, alpha), maxf(1.0, s * 0.05), true)
			continue
		Pen.fill(ci, Pen.ell(e, s * 0.14, s * 0.17), Color(1, 1, 1, alpha))
		if mood == "glow":
			Pen.glow(ci, e, s * 0.3, Color(0.75, 0.47, 1, 0.9 * alpha))
			Pen.fill(ci, Pen.ell(e + Vector2(0, s * 0.02), s * 0.11, s * 0.14), Color(0.69, 0.49, 1, alpha))
			ci.draw_arc(e + Vector2(0, s * 0.02), s * 0.06, 0, PI * 1.6, 10, Color(0.95, 0.89, 1, alpha), maxf(0.8, s * 0.025), true)
		else:
			Pen.fill_v(ci, Pen.ell(e + Vector2(0, s * 0.02), s * 0.115, s * 0.145), e.y - s * 0.14, e.y + s * 0.16, Color(Color(iris[1]), alpha), Color(Color(iris[0]), alpha))
			Pen.fill(ci, Pen.ell(e + Vector2(0, s * 0.03), s * 0.055, s * 0.075, 0.0, 12), Color(0.16, 0.08, 0.16, 0.85 * alpha))
			ci.draw_circle(e + Vector2(-k * s * 0.045, -s * 0.05), s * 0.05, Color(1, 1, 1, alpha))
			ci.draw_circle(e + Vector2(k * s * 0.04, s * 0.08), s * 0.022, Color(1, 1, 1, alpha))
		Pen.stroke(ci, Pen.ell(e, s * 0.145, s * 0.175, 0.0, 12, PI * 1.08, PI * 1.92), Color(INK, alpha), s * 0.045, false)
		if mood == "smug" and lid.a > 0.0:
			Pen.fill(ci, Pen.ell(e + Vector2(0, -s * 0.02), s * 0.16, s * 0.12, 0.0, 12, PI, TAU), Color(lid, alpha))
			ci.draw_line(e + Vector2(-s * 0.15, -s * 0.02), e + Vector2(s * 0.15, -s * 0.02), Color(INK, alpha), maxf(1.0, s * 0.045))
		if mood == "mischief":
			ci.draw_polyline(Pen.quad_pts(e + Vector2(k * s * 0.16, -s * 0.28), e + Vector2(0, -s * 0.24), e + Vector2(-k * s * 0.08, -s * 0.2), 6), Color(INK, alpha), maxf(1.0, s * 0.05), true)


static func blush(ci: CanvasItem, c: Vector2, s: float, spacing := 0.42, alpha := 1.0) -> void:
	for k in [-1.0, 1.0]:
		Pen.fill(ci, Pen.ell(c + Vector2(k * s * spacing, 0), s * 0.13, s * 0.07, 0.0, 12), Color(1, 0.47, 0.59, 0.35 * alpha))


static func fang_grin(ci: CanvasItem, c: Vector2, s: float) -> void:
	Pen.fill(ci, Pen.ell(c, s * 0.13, s * 0.13, 0.0, 12, 0.0, PI), Color("#8A2A4A"))
	Pen.fill(ci, Pen.ell(c + Vector2(0, s * 0.09), s * 0.06, s * 0.035, 0.0, 10), Color("#FF9DB5"))
	for k in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(k * s * 0.09, 0), c + Vector2(k * s * 0.04, 0), c + Vector2(k * s * 0.065, s * 0.06)]), Color.WHITE)


static func flash_fx(ci: CanvasItem, e: Dictionary, p: Vector2, r: float) -> void:
	if e.flash > 0.0:
		Pen.glow(ci, p, r, Color(1, 1, 1, e.flash))


static func draw(ci: CanvasItem, e: Dictionary, t: float) -> void:
	match e.type:
		"wisp": _draw_wisp(ci, e, t)
		"phantom": _draw_phantom(ci, e, t)
		"dino": _draw_dino(ci, e, t)
		"grub": _draw_grub(ci, e, t)
		"civilian": _draw_person(ci, e, t)
		"possessed":
			_draw_person(ci, e, t)
			_draw_imp(ci, e, t)
		"lantern": _draw_lantern(ci, e, t)
		"orb": _draw_orb(ci, e, t)
		"boss": Bosses.draw(ci, e, t)


static func _draw_wisp(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var r: float = e.r
	var c = Vector2(e.sx, e.sy)
	var flap = sin(t * 9.0 + e.ph)
	Pen.glow(ci, c, r * 2.6, Color(1, 0.55, 0.78, 0.4))
	for i in range(0, e.trail.size(), 2):
		Pen.fill(ci, Pen.star(e.trail[i] + Vector2(0, r * 0.9), r * 0.25, t * 3.0 + i), Color(1, 0.82, 0.92, 0.55 - i * 0.06))
	var tip = c + Vector2(sin(t * 5.0 + 1.0) * r * 0.5, r * 1.75)
	var tail = Pen.quad_pts(c + Vector2(-r * 0.55, r * 0.45), c + Vector2(-r * 0.3 + sin(t * 6.0) * r * 0.3, r * 1.3), tip, 8)
	tail.append_array(Pen.quad_pts(tip, c + Vector2(r * 0.35, r * 1.1), c + Vector2(r * 0.55, r * 0.45), 8))
	Pen.fill_v(ci, tail, c.y + r * 0.4, c.y + r * 1.8, Color(1, 0.67, 0.8, 0.9), Color(1, 0.67, 0.8, 0.0))
	for k in [-1.0, 1.0]:
		var ear = Pen.ell(c + Vector2(k * r * 0.88, r * 0.15), r * 0.36, r * 0.74, k * (0.35 + flap * 0.25), 20)
		Pen.fill_soft(ci, ear, c + Vector2(k * r * 0.8, 0), r * 0.6, Color("#FFD3E0"), Color("#F6A3BC"), Color("#DE7F9C"))
		Pen.ink(ci, ear, r * 0.05, Color("#C25F7E"))
	var body = Pen.fluff(c, r, r * 0.95, 16, 0.05)
	Pen.fill_soft(ci, body, c, r, Color("#FFEAF0"), Color("#FBBACB"), Color("#EC90AB"))
	Pen.ink(ci, body, r * 0.05, Color("#C25F7E"))
	Pen.fill(ci, Pen.fluff(c + Vector2(0, -r * 0.85), r * 0.3, r * 0.2, 7, 0.12), Color("#FFD6E2"))
	cute_eyes(ci, c + Vector2(0, r * 0.02), r * 1.15, ["#F5B4DA", "#8A2A6A"], "mischief", 0.3, fposmod(e.t, e.blink_every) < 0.12)
	blush(ci, c + Vector2(0, r * 0.32), r)
	fang_grin(ci, c + Vector2(0, r * 0.42), r)
	flash_fx(ci, e, c, r * 2.0)


static func _draw_phantom(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var a: float = e.alpha
	var sx: float = e.sx
	var base: float = e.base
	var hh: float = e.hh
	var ww: float = e.ww
	var top = base - hh
	var cy = base - hh * 0.5
	var lw = hh * 0.01
	Pen.glow(ci, Vector2(sx, cy), hh * 0.75, Color(1, 0.86, 0.47, 0.25 * a))
	for k in [-1.0, 1.0]:
		var f = Pen.fluff(Vector2(sx + k * ww * 0.2 + sin(t * 8.0 + k) * ww * 0.03, base - hh * 0.02), ww * 0.14, hh * 0.04, 7, 0.15)
		Pen.fill(ci, f, Color(Color("#E8B444"), a)); Pen.ink(ci, f, lw * 0.8, Color(Color("#A87420"), a))
	var body = Pen.fluff(Vector2(sx, cy), ww * 0.5, hh * 0.5, 24, 0.035, sin(t * 2.5 + e.pt) * 0.06)
	Pen.fill_soft(ci, body, Vector2(sx, cy), hh * 0.55, Color(Color("#FFF4BE"), a), Color(Color("#F9D46A"), a), Color(Color("#DCA338"), a))
	Pen.ink(ci, body, lw, Color(Color("#A87420"), a))
	for i in 6:
		var f = Vector2(sx + (i - 2.5) * ww * 0.13, cy + hh * (0.05 + (i % 2) * 0.12))
		ci.draw_polyline(Pen.quad_pts(f, f + Vector2(ww * 0.04, hh * 0.06), f + Vector2(0, hh * 0.12), 6), Color(1, 0.98, 0.84, 0.7 * a), maxf(1.0, hh * 0.008), true)
	for k in [-1.0, 1.0]:
		var arm = Pen.fluff(Vector2(sx + k * ww * 0.5, cy + hh * 0.08), ww * 0.1, hh * 0.12, 8, 0.1, k * (0.3 + sin(t * 3.0 + k) * 0.15))
		Pen.fill(ci, arm, Color(Color("#F2C55A"), a)); Pen.ink(ci, arm, lw * 0.8, Color(Color("#A87420"), a))
	var fy = top + hh * 0.26
	var s = ww * 0.62
	cute_eyes(ci, Vector2(sx, fy), s, ["#F7C978", "#7A4A10"], "smug", 0.3, fposmod(e.t, e.blink_every) < 0.12, Color("#F9D873"), a)
	blush(ci, Vector2(sx, fy + s * 0.25), s, 0.4, a)
	var m = PackedVector2Array([Vector2(sx - s * 0.08, fy + s * 0.27), Vector2(sx - s * 0.04, fy + s * 0.31), Vector2(sx, fy + s * 0.27), Vector2(sx + s * 0.04, fy + s * 0.31), Vector2(sx + s * 0.08, fy + s * 0.27)])
	ci.draw_polyline(m, Color(INK, a), maxf(1.0, s * 0.04), true)
	ci.draw_arc(Vector2(sx, top + hh * 0.2), ww * 0.46, PI * 1.08, PI * 1.92, 24, Color(Color("#BFC5D2"), a), maxf(2.0, ww * 0.06), true)
	for k in [-1.0, 1.0]:
		var cup = Pen.ell(Vector2(sx + k * ww * 0.46, top + hh * 0.195), ww * 0.08, hh * 0.065, 0.0, 16)
		Pen.fill_soft(ci, cup, Vector2(sx + k * ww * 0.46, top + hh * 0.19), ww * 0.1, Color(Color("#E4E8F0"), a), Color(Color("#9AA2B4"), a), Color(Color("#6B7386"), a))
		Pen.ink(ci, cup, lw * 0.8, Color(Color("#4A5060"), a))
	if not e.solid:
		for i in 5:
			var yy = top + fposmod(t * 80.0 + i * hh / 5.0, hh)
			ci.draw_line(Vector2(sx - ww * 0.5, yy), Vector2(sx + ww * 0.5, yy), Color(1, 1, 1, 0.5), 1.0)
	flash_fx(ci, e, Vector2(sx, cy), hh * 0.6)


static func _draw_dino(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var H: float = e.hh
	var ph: float = t * 8.0 + e.ph
	var tilt = sin(ph) * 0.1
	var step = sin(ph)
	var lw = H * 0.012
	var O = Vector2(e.sx, e.base)
	var P = func(x: float, y: float) -> Vector2: return O + Vector2(x * H, y * H).rotated(tilt)
	var ol = Color("#6E58B0")
	Pen.glow(ci, O - Vector2(0, H * 0.05), H * 0.5, Color(0.71, 0.55, 1, 0.35))
	var tw = sin(ph * 0.5) * 0.05
	var tail = Pen.quad_pts(P.call(0.12, -0.3), P.call(0.45, -0.2), P.call(0.55 + tw, -0.04), 8)
	tail.append_array(Pen.quad_pts(P.call(0.55 + tw, -0.04), P.call(0.35, -0.06), P.call(0.12, -0.12), 8))
	Pen.fill(ci, tail, Color("#B9A3EE")); Pen.ink(ci, tail, lw, ol)
	for k in [-1.0, 1.0]:
		var lift: float = maxf(0.0, k * step) * 0.05
		var leg = Pen.ell(P.call(k * 0.13, -0.07 - lift), H * 0.07, H * 0.065, tilt, 14)
		Pen.fill(ci, leg, Color("#A992E6")); Pen.ink(ci, leg, lw, ol)
	var pack = PackedVector2Array([P.call(0.12, -0.55), P.call(0.32, -0.55), P.call(0.32, -0.25), P.call(0.12, -0.25)])
	Pen.fill(ci, pack, Color("#8A7560")); Pen.ink(ci, pack, lw, Color("#4E3E30"))
	var body = Pen.ell(P.call(0, -0.34), H * 0.29, H * 0.25, tilt, 28)
	Pen.fill_soft(ci, body, P.call(0, -0.34), H * 0.29, Color("#F5F0FF"), Color("#DCCCFB"), Color("#B49EEA")); Pen.ink(ci, body, lw, ol)
	for k in [-1.0, 1.0]:
		ci.draw_line(P.call(k * 0.05, -0.52), P.call(k * 0.06, -0.4), Color("#F5F0FF"), maxf(1.0, lw))
		var arm = Pen.ell(P.call(k * 0.29, -0.33), H * 0.06, H * 0.11, tilt + k * (0.5 + sin(ph + k) * 0.25), 14)
		Pen.fill(ci, arm, Color("#D7C6FA")); Pen.ink(ci, arm, lw, ol)
	var hood = Pen.circle_pts(P.call(0, -0.68), H * 0.3, 28)
	Pen.fill(ci, hood, Color("#E3D6FD")); Pen.ink(ci, hood, lw, ol)
	for i in 4:
		var a = PI * (1.25 + i * 0.17)
		ci.draw_circle(P.call(cos(a) * 0.24, -0.7 + sin(a) * 0.24), H * 0.05, Color("#9A84DA"))
	var head = Pen.circle_pts(P.call(0, -0.7), H * 0.23, 28)
	Pen.fill_soft(ci, head, P.call(0, -0.7), H * 0.23, Color("#EAE0FF"), Color("#C8B6F7"), Color("#A28CE0")); Pen.ink(ci, head, lw, ol)
	Pen.fill(ci, Pen.ell(P.call(-0.02, -0.58), H * 0.17, H * 0.1, tilt, 20), Color("#E6DCFF"))
	cute_eyes(ci, P.call(0, -0.73), H * 0.4, ["#E6D0FF", "#5A3E99"], "mischief", 0.3, fposmod(e.t, e.blink_every) < 0.12)
	blush(ci, P.call(0, -0.62), H * 0.4, 0.45)
	ci.draw_arc(P.call(0, -0.6), H * 0.05, 0.15 * PI, 0.85 * PI, 10, INK, maxf(1.0, H * 0.015), true)
	flash_fx(ci, e, O - Vector2(0, H * 0.5), H * 0.6)


static func _draw_grub(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var H: float = e.hh
	var sq = sin(t * 5.0 + e.ph)
	var lw = H * 0.011
	var O = Vector2(e.sx, e.base)
	var ol = Color("#4E8A50")
	Pen.glow(ci, O - Vector2(0, H * 0.4), H * 0.6, Color(0.59, 0.94, 0.67, 0.3))
	for k in [-1.0, 1.0]:
		for i in 2:
			Pen.fill(ci, Pen.ell(O + Vector2(k * H * (0.2 - i * 0.03), -H * (0.04 + i * 0.22)), H * 0.05, H * 0.035, 0.0, 12), Color("#7FC27A"))
	var segs = [[-0.17, 0.3, 0.17], [-0.42, 0.27, 0.15], [-0.62, 0.24, 0.13]]
	for i in segs.size():
		var sgm = segs[i]
		var yy: float = sgm[0] * H * (1.0 + sq * 0.03 * (i + 1))
		var w: float = sgm[1] * H * (1.0 - sq * 0.04 * (-1.0 if i % 2 == 1 else 1.0))
		var c = O + Vector2(0, yy)
		var pts = Pen.ell(c, w, sgm[2] * H, 0.0, 28)
		Pen.fill_soft(ci, pts, c, w, Color("#EEFBE4"), Color("#BDE9AE"), Color("#86C97F")); Pen.ink(ci, pts, lw, ol)
		for k in [-1.0, 1.0]:
			ci.draw_circle(c + Vector2(k * w * 0.65, -sgm[2] * H * 0.2), H * 0.025, Color(0.35, 0.63, 0.37, 0.4))
		if i < 2:
			Pen.fill(ci, Pen.ell(c + Vector2(0, sgm[2] * H * 0.2), w * 0.55, sgm[2] * H * 0.55, 0.0, 20), Color(0.98, 0.94, 0.78, 0.75))
	var hc = O + Vector2(0, -H * 0.83)
	for k in [-1.0, 1.0]:
		var bp = hc + Vector2(k * H * (0.1 + sin(t * 3.0 + k) * 0.02), -H * 0.27)
		ci.draw_line(hc + Vector2(k * H * 0.06, -H * 0.16), bp, ol, maxf(1.0, lw * 1.2))
		ci.draw_circle(bp, H * 0.03, Color("#9FDB94"))
	var head = Pen.circle_pts(hc, H * 0.2, 28)
	Pen.fill_soft(ci, head, hc, H * 0.2, Color("#F2FCEA"), Color("#C6EDB8"), Color("#8FD08A")); Pen.ink(ci, head, lw, ol)
	var blinking = fposmod(e.t, e.blink_every) < 0.12
	cute_eyes(ci, hc + Vector2(0, H * 0.02), H * 0.36, ["#CFF5C4", "#2E7A3A"], "normal", 0.3, blinking)
	if not blinking:
		Pen.fill(ci, Pen.ell(hc + Vector2(0, -H * 0.1), H * 0.035, H * 0.04, 0.0, 12), Color.WHITE)
		ci.draw_circle(hc + Vector2(0, -H * 0.095), H * 0.02, Color("#2E7A3A"))
	blush(ci, hc + Vector2(0, H * 0.1), H * 0.36, 0.42)
	var cam = O + Vector2(0, -H * 0.45)
	ci.draw_rect(Rect2(cam.x - H * 0.13, cam.y - H * 0.07, H * 0.26, H * 0.15), Color("#4A4E5A"))
	ci.draw_rect(Rect2(cam.x - H * 0.11, cam.y - H * 0.07, H * 0.22, H * 0.035), Color("#C9CED8"))
	ci.draw_circle(cam + Vector2(0, H * 0.015), H * 0.05, Color("#20232A"))
	for k in [-1.0, 1.0]:
		ci.draw_circle(cam + Vector2(k * H * 0.14, H * 0.02), H * 0.045, Color("#B4E6A6"))
	if fposmod(t + e.ph, 3.0) < 0.14:
		Pen.fill(ci, Pen.star(cam + Vector2(0, H * 0.015), H * 0.25, t), Color(1, 1, 1, 0.95))
	flash_fx(ci, e, O - Vector2(0, H * 0.5), H * 0.6)


static func _hair_back(ci: CanvasItem, L: Dictionary, hx: float, hy: float, R: float, sway: float, t: float) -> void:
	var pts = PackedVector2Array()
	match L.hair:
		"bob":
			pts = Pen.ell(Vector2(hx, hy + R * 0.2), R * 1.2, R * 1.15, 0.0, 28)
		"long", "wavy":
			for i in 13:
				var a = PI + PI * i / 12.0
				pts.append(Vector2(hx, hy) + Vector2(cos(a), sin(a)) * R * 1.15)
			var wavy: bool = L.hair == "wavy"
			var ln = 2.6 if wavy else 2.4
			for i in range(1, 7):
				var wob = 0.14 * sin(i * 1.7 + t * 3.0) if wavy else 0.0
				pts.append(Vector2(hx + R * (1.12 + wob) + sway * i / 6.0, hy + i / 6.0 * R * ln))
			pts.append(Vector2(hx + sway, hy + R * (ln + 0.35)))
			for i in range(6, 0, -1):
				var wob = 0.14 * sin(i * 1.7 + t * 3.0 + 1.0) if wavy else 0.0
				pts.append(Vector2(hx - R * (1.12 + wob) + sway * i / 6.0, hy + i / 6.0 * R * ln))
		_:
			pts = Pen.circle_pts(Vector2(hx, hy - R * 0.05), R * 1.1, 28)
	Pen.fill_v(ci, pts, hy - R * 1.2, hy + R * 2.8, Color(L.hc[0]), Color(L.hc[1]))
	Pen.ink(ci, pts, R * 0.04, Color(0.24, 0.12, 0.24, 0.45))


const FRINGE := {
	"bob": [[1.1, 0.25], [0.85, -0.05], [0.55, -0.15], [0.35, 0.0], [0.1, -0.2], [-0.15, 0.0], [-0.4, -0.18], [-0.65, -0.02], [-0.9, -0.12]],
	"spiky": [[0.8, -0.1], [0.55, 0.1], [0.35, -0.25], [0.1, 0.05], [-0.15, -0.25], [-0.4, 0.05], [-0.7, -0.2]],
	"long": [[1.1, 0.4], [0.8, 0.05], [0.45, -0.35], [0.2, -0.05], [-0.1, -0.4], [-0.5, -0.1], [-0.85, 0.1]],
	"swept": [[1.0, 0.1], [0.6, -0.45], [0.3, -0.2], [-0.1, -0.35], [-0.5, -0.05], [-0.85, 0.0]],
	"wavy": [[1.1, 0.4], [0.75, 0.0], [0.5, -0.3], [0.2, -0.1], [-0.05, -0.38], [-0.4, -0.1], [-0.8, 0.05]],
}


static func _hair_front(ci: CanvasItem, L: Dictionary, hx: float, hy: float, R: float, sway: float) -> void:
	var pts = PackedVector2Array([Vector2(hx - R * 1.1, hy + R * 0.25)])
	if L.hair == "spiky":
		for q in [[-1.25, -0.3], [-1.0, -0.75], [-1.2, -1.15], [-0.55, -1.05], [-0.45, -1.6], [0.0, -1.15], [0.35, -1.65], [0.5, -1.1], [1.1, -1.35], [0.95, -0.7], [1.3, -0.4], [1.1, 0.25]]:
			pts.append(Vector2(hx + q[0] * R + (sway * 0.4 if q[1] < -1.0 else 0.0), hy + q[1] * R))
	else:
		for i in 17:
			var a = PI * 0.94 + PI * 1.12 * i / 16.0
			pts.append(Vector2(hx, hy - R * 0.05) + Vector2(cos(a), sin(a)) * R * 1.12)
	for q in FRINGE[L.hair]:
		pts.append(Vector2(hx + q[0] * R, hy + q[1] * R))
	Pen.fill_v(ci, pts, hy - R * 1.5, hy + R * 0.6, Color(L.hc[0]), Color(L.hc[1]))
	Pen.ink(ci, pts, R * 0.04, Color(0.24, 0.12, 0.24, 0.45))
	if L.hair in ["bob", "long", "wavy"]:
		var ln = 0.95 if L.hair == "bob" else 1.5
		for k in [-1.0, 1.0]:
			var lock = PackedVector2Array([Vector2(hx + k * R * 1.12, hy - R * 0.05), Vector2(hx + k * R * 1.06 + sway * 0.6, hy + R * ln), Vector2(hx + k * R * 0.78, hy + R * 0.25)])
			Pen.fill(ci, lock, Color(L.hc[1]).lerp(Color(L.hc[0]), 0.4))
	ci.draw_arc(Vector2(hx - R * 0.15, hy - R * 0.5), R * 0.55, PI * 1.1, PI * 1.45, 10, Color(1, 1, 1, 0.55), maxf(1.0, R * 0.09), true)


static func _draw_person(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var L: Dictionary = e.look
	var sx: float = e.sx
	var base: float = e.base
	var U: float = e.hh
	var R: float = e.head_r
	var hy: float = e.head_y
	var dir: float = e.dir
	var ph: float = e.t * 7.5 + e.ph
	var sw = sin(ph)
	var possessed: bool = e.type == "possessed"
	var hip_y: float = base - U * 0.42 - e.bob
	var sh_y: float = base - U * 0.65 - e.bob
	var leg_l = U * 0.4
	var arm_l = U * 0.24
	var leg_a = sw * 0.38 * dir
	var sway = -dir * sin(ph - 0.6) * R * 0.18
	var ol = Color(0.24, 0.12, 0.24, 0.5)
	var lw = U * 0.01
	var skin = Color(e.skin[0])
	var tc = Color(L.tc)
	_hair_back(ci, L, sx, hy, R, sway, t)
	for k in [-1.0, 1.0]:
		var a: float = leg_a if k < 0 else -leg_a
		var hip = Vector2(sx + k * U * 0.06, hip_y)
		var foot = hip + Vector2(sin(a) * leg_l, cos(a) * leg_l - (U * 0.025 * absf(sw) if a * dir > 0 else 0.0))
		if L.bottom == "skirt":
			ci.draw_line(hip, foot, skin, U * 0.07)
			ci.draw_line(hip.lerp(foot, 0.55), foot, Color("#2C2E3E"), U * 0.072)
		else:
			ci.draw_line(hip, foot, Color(L.bc), U * 0.085)
		Pen.fill(ci, Pen.ell(foot + Vector2(dir * U * 0.015, U * 0.005), U * 0.05, U * 0.024, 0.0, 12), Color("#4A3434"))
	var shoulder = func(k: float) -> Vector2: return Vector2(sx + k * U * 0.15, sh_y + U * 0.02)
	var arm_end = func(k: float, ang: float) -> Vector2: return shoulder.call(k) + Vector2(sin(ang), cos(ang)) * arm_l
	var hold: bool = L.item == "drink" or L.item == "camera"
	var back_hand: Vector2 = arm_end.call(-1.0, -leg_a * 0.9 - 0.12)
	ci.draw_line(shoulder.call(-1.0), back_hand, tc, U * 0.065)
	ci.draw_circle(back_hand, U * 0.028, skin)
	var torso = PackedVector2Array([Vector2(sx - U * 0.14, sh_y)])
	torso.append_array(Pen.quad_pts(Vector2(sx - U * 0.14, sh_y), Vector2(sx, sh_y - U * 0.03), Vector2(sx + U * 0.14, sh_y), 6))
	torso.append(Vector2(sx + U * 0.125, hip_y + U * 0.02))
	torso.append_array(Pen.quad_pts(Vector2(sx + U * 0.125, hip_y + U * 0.02), Vector2(sx, hip_y + U * 0.04), Vector2(sx - U * 0.125, hip_y + U * 0.02), 6))
	Pen.fill_soft(ci, torso, Vector2(sx, (sh_y + hip_y) * 0.5), U * 0.16, tc.lightened(0.35), tc, tc.darkened(0.25))
	Pen.ink(ci, torso, lw, ol)
	match L.top:
		"cardigan":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - U * 0.05, sh_y - U * 0.01), Vector2(sx + U * 0.05, sh_y - U * 0.01), Vector2(sx, sh_y + U * 0.11)]), Color.WHITE)
			for k in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(sx, sh_y + U * 0.02), Vector2(sx + k * U * 0.05, sh_y - U * 0.005), Vector2(sx + k * U * 0.05, sh_y + U * 0.045)]), Color(L.bow))
		"jacket":
			ci.draw_rect(Rect2(sx - U * 0.045, sh_y, U * 0.09, hip_y - sh_y + U * 0.015), Color("#F4F4F6"))
		"shirt":
			ci.draw_rect(Rect2(sx - U * 0.09, sh_y + U * 0.07, U * 0.05, U * 0.05), Color(0.24, 0.24, 0.2, 0.4), false, maxf(1.0, lw))
		"hoodie":
			Pen.fill(ci, Pen.ell(Vector2(sx, sh_y), U * 0.11, U * 0.04, 0.0, 16), tc.darkened(0.25))
			for k in [-1.0, 1.0]:
				ci.draw_line(Vector2(sx + k * U * 0.03, sh_y + U * 0.01), Vector2(sx + k * U * 0.035, sh_y + U * 0.09), Color.WHITE, maxf(1.0, lw))
	if L.bottom == "skirt":
		var fl = sw * U * 0.012
		var sk = PackedVector2Array([Vector2(sx - U * 0.125, hip_y - U * 0.01), Vector2(sx + U * 0.125, hip_y - U * 0.01), Vector2(sx + U * 0.17 + fl, hip_y + U * 0.13), Vector2(sx - U * 0.17 + fl, hip_y + U * 0.13)])
		Pen.fill_v(ci, sk, hip_y, hip_y + U * 0.13, Color("#5C6A8E"), Color(L.bc))
		Pen.ink(ci, sk, lw, ol)
		for i in range(-2, 3):
			ci.draw_line(Vector2(sx + i * U * 0.05, hip_y), Vector2(sx + i * U * 0.068 + fl, hip_y + U * 0.125), Color(1, 1, 1, 0.18), maxf(1.0, lw))
	else:
		ci.draw_rect(Rect2(sx - U * 0.125, hip_y - U * 0.01, U * 0.25, U * 0.02), Color("#3A2E2A"))
	var hand: Vector2
	if L.item == "wave" and not possessed:
		hand = arm_end.call(1.0, PI - 0.5 + sin(e.t * 10.0) * 0.35)
	elif hold:
		hand = Vector2(sx + U * 0.03, sh_y + U * 0.13)
	else:
		hand = arm_end.call(1.0, leg_a * 0.9 + 0.12)
	ci.draw_line(shoulder.call(1.0), hand, tc, U * 0.065)
	ci.draw_circle(hand, U * 0.028, skin)
	if L.item == "drink":
		var cup = PackedVector2Array([hand + Vector2(-U * 0.03, -U * 0.06), hand + Vector2(U * 0.03, -U * 0.06), hand + Vector2(U * 0.022, U * 0.03), hand + Vector2(-U * 0.022, U * 0.03)])
		Pen.fill(ci, cup, Color("#9CCB7E")); Pen.ink(ci, cup, lw, ol)
		ci.draw_line(hand + Vector2(U * 0.005, -U * 0.06), hand + Vector2(U * 0.02, -U * 0.11), Color("#4FA35A"), maxf(1.0, lw * 1.5))
	elif L.item == "camera":
		ci.draw_rect(Rect2(hand.x - U * 0.05, hand.y - U * 0.035, U * 0.1, U * 0.06), Color("#3E4250"))
		ci.draw_circle(hand, U * 0.02, Color("#9AA2B4"))
	ci.draw_rect(Rect2(sx - U * 0.025, hy + R * 0.8, U * 0.05, sh_y - hy - R * 0.8 + U * 0.01), Color(e.skin[1]))
	if L.item == "headphones":
		ci.draw_arc(Vector2(sx, sh_y - U * 0.01), U * 0.075, 0.1 * PI, 0.9 * PI, 12, Color("#C9CED8"), maxf(1.5, U * 0.018), true)
		for k in [-1.0, 1.0]:
			Pen.fill(ci, Pen.ell(Vector2(sx + k * U * 0.075, sh_y), U * 0.03, U * 0.035, 0.0, 12), Color("#8890A2"))
	var head = Pen.ell(Vector2(sx, hy), R, R * 1.02, 0.0, 28)
	Pen.fill_soft(ci, head, Vector2(sx, hy), R, Color("#FFF6EF"), skin, Color(e.skin[1]))
	Pen.ink(ci, head, lw, ol)
	var blinking = not possessed and fposmod(e.t, e.blink_every) < 0.12
	var happy = not possessed and L.item == "wave"
	cute_eyes(ci, Vector2(sx, hy + R * 0.15), R * 1.05, L.eye, "glow" if possessed else ("happy" if happy else "normal"), 0.36, blinking)
	if possessed:
		ci.draw_polyline(PackedVector2Array([Vector2(sx - R * 0.15, hy + R * 0.58), Vector2(sx - R * 0.05, hy + R * 0.53), Vector2(sx, hy + R * 0.58), Vector2(sx + R * 0.05, hy + R * 0.63), Vector2(sx + R * 0.15, hy + R * 0.58)]), INK, maxf(1.0, R * 0.05), true)
	else:
		blush(ci, Vector2(sx, hy + R * 0.48), R, 0.5)
		Pen.fill(ci, Pen.ell(Vector2(sx, hy + R * 0.52), R * 0.14, R * 0.14, 0.0, 12, 0.0, PI), Color("#B8434F"))
		Pen.fill(ci, Pen.ell(Vector2(sx, hy + R * 0.6), R * 0.07, R * 0.04, 0.0, 10), Color("#FF9DAA"))
	_hair_front(ci, L, sx, hy, R, sway)
	if e.flash > 0.0:
		ci.draw_rect(Rect2(sx - U * 0.2, base - U, U * 0.4, U), Color(1, 0.23, 0.36, 0.8 * e.flash))


## Tiyanak: a blue fluffy cat-imp hugging the person's head.
static func _draw_imp(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var r: float = e.spr * (1.0 + sin(t * 5.0) * 0.05)
	var c = Vector2(e.spx, e.spy)
	var lw = r * 0.05
	var ol = Color("#3A5AA8")
	Pen.glow(ci, c, r * 2.5, Color(0.47, 0.67, 1, 0.5))
	for k in [-1.0, 1.0]:
		var paw = Vector2(e.sx + k * e.head_r * 1.0, e.head_y - e.head_r * 0.45)
		ci.draw_line(c + Vector2(k * r * 0.6, r * 0.45), paw, Color("#6E9BEA"), r * 0.4)
		ci.draw_circle(paw, r * 0.26, Color("#A9C8FF"))
	for k in [-1.0, 1.0]:
		var ear = PackedVector2Array([c + Vector2(k * r * 0.3, -r * 0.65), c + Vector2(k * r * 0.85, -r * 1.4), c + Vector2(k * r * 0.92, -r * 0.35)])
		Pen.fill(ci, ear, Color("#6E9BEA")); Pen.ink(ci, ear, lw, ol)
		Pen.fill(ci, PackedVector2Array([c + Vector2(k * r * 0.45, -r * 0.62), c + Vector2(k * r * 0.8, -r * 1.15), c + Vector2(k * r * 0.82, -r * 0.5)]), Color("#FFB3C8"))
	var body = Pen.fluff(c, r, r * 0.9, 14, 0.065)
	Pen.fill_soft(ci, body, c, r, Color("#CFE0FF"), Color("#86AEF2"), Color("#5079D0")); Pen.ink(ci, body, lw, ol)
	cute_eyes(ci, c + Vector2(0, -r * 0.12), r * 1.3, ["#fff", "#000"], "happy", 0.3)
	blush(ci, c + Vector2(0, r * 0.12), r, 0.45)
	fang_grin(ci, c + Vector2(0, r * 0.2), r * 1.4)


static func _draw_lantern(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var c = Vector2(e.sx, e.sy)
	var r: float = e.r
	Pen.glow(ci, c, r * 2.6, Color(1, 0.59, 0.24, 0.45))
	var body = Pen.ell(c, r * 0.8, r, 0.0, 28)
	Pen.fill_soft(ci, body, c, r, Color("#FFC08A"), Color("#FF8A3C"), Color("#C9561C"))
	for k in [-0.45, 0.0, 0.45]:
		Pen.stroke(ci, Pen.ell(c, r * 0.8 * cos(k * 1.2), r, 0.0, 24), Color(0.47, 0.16, 0.04, 0.55), 1.0)
	Pen.ink(ci, body, r * 0.1)
	ci.draw_rect(Rect2(c.x - r * 0.42, c.y - r * 1.12, r * 0.84, r * 0.2), INK)
	ci.draw_rect(Rect2(c.x - r * 0.42, c.y + r * 0.92, r * 0.84, r * 0.2), INK)
	Pen.fill(ci, Pen.star(c + Vector2(-r * 0.35, -r * 0.4), r * 0.35 * (0.7 + 0.3 * sin(t * 4.0)), t), Color(1, 0.94, 0.78, 0.9))
	var R = r * ((1.7 + e.ripple * 0.3) if e.armored else 1.5)
	var hexa = PackedVector2Array()
	for i in 6:
		hexa.append(c + Vector2.from_angle(i / 6.0 * TAU + t * (1.2 if e.armored else 0.6)) * R)
	Pen.stroke(ci, hexa, Color(0.44, 0.95, 1, 0.7 + e.ripple * 0.3) if e.armored else Color(1, 0.84, 0.59, 0.5), (2.5 + e.ripple * 3.0) if e.armored else 1.2)
	flash_fx(ci, e, c, r * 2.0)


static func _draw_orb(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var col = Color(e.col)
	for i in e.trail.size():
		Pen.glow(ci, e.trail[i], e.r * (1.4 - i * 0.18), Color(col, 0.33))
	Pen.glow(ci, Vector2(e.sx, e.sy), e.r * 2.4, Color(col, 0.67))
	Pen.glow(ci, Vector2(e.sx, e.sy), e.r * 0.9, Color(1, 1, 1, 0.95))
	ci.draw_arc(Vector2(e.sx, e.sy), e.r * 1.2, t * 6.0 + e.ph, t * 6.0 + e.ph + 2.0, 12, Color(1, 1, 1, 0.8), 2.0, true)
