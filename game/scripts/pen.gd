class_name Pen
extends RefCounted
## Small drawing toolkit: paths, soft glows, gradient fills and outlines on top of CanvasItem.

const INK := Color("#3A2440")
static var _glow: Texture2D


static func glow_tex() -> Texture2D:
	if _glow == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_glow = t
	return _glow


static func glow(ci: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	if r < 0.5:
		return
	ci.draw_texture_rect(glow_tex(), Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


static func clean(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		if out.size() == 0 or out[out.size() - 1].distance_squared_to(p) > 0.01:
			out.append(p)
	if out.size() > 2 and out[0].distance_squared_to(out[out.size() - 1]) < 0.01:
		out.remove_at(out.size() - 1)
	return out


static func fill(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	var p := clean(pts)
	if p.size() >= 3:
		ci.draw_colored_polygon(p, col)


## Radial "light from top-left" gradient, like a soft anime shading.
static func fill_soft(ci: CanvasItem, pts: PackedVector2Array, c: Vector2, r: float, light: Color, mid: Color, dark: Color) -> void:
	var p := clean(pts)
	if p.size() < 3:
		return
	var lp := c + Vector2(-0.35, -0.4) * r
	var cols := PackedColorArray()
	for q in p:
		var k := clampf(q.distance_to(lp) / (r * 1.6), 0.0, 1.0)
		cols.append(light.lerp(mid, k * 1.6) if k < 0.6 else mid.lerp(dark, (k - 0.6) / 0.4))
	ci.draw_polygon(p, cols)


static func fill_v(ci: CanvasItem, pts: PackedVector2Array, y0: float, y1: float, top: Color, bottom: Color) -> void:
	var p := clean(pts)
	if p.size() < 3:
		return
	var cols := PackedColorArray()
	for q in p:
		cols.append(top.lerp(bottom, clampf((q.y - y0) / maxf(y1 - y0, 0.001), 0.0, 1.0)))
	ci.draw_polygon(p, cols)


static func stroke(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, closed := true) -> void:
	var p := clean(pts)
	if p.size() < 2:
		return
	if closed:
		p.append(p[0])
	ci.draw_polyline(p, col, maxf(w, 1.0), true)


static func ink(ci: CanvasItem, pts: PackedVector2Array, w: float, col := INK) -> void:
	stroke(ci, pts, col, w, true)


static func line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(a, b, col, maxf(w, 1.0), true)


static func ell(c: Vector2, rx: float, ry: float, rot := 0.0, n := 24, a0 := 0.0, a1 := TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var full := absf(a1 - a0) >= TAU - 0.001
	var count := n if full else n + 1
	for i in count:
		var a := lerpf(a0, a1, float(i) / n)
		var v := Vector2(cos(a) * rx, sin(a) * ry).rotated(rot)
		pts.append(c + v)
	return pts


static func circle_pts(c: Vector2, r: float, n := 24) -> PackedVector2Array:
	return ell(c, r, r, 0.0, n)


static func star(c: Vector2, r: float, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 8:
		var a := rot + i * PI / 4.0
		var rr := r * 0.3 if i % 2 == 1 else r
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return pts


## Scalloped fluffy outline (fur, clouds).
static func fluff(c: Vector2, rx: float, ry: float, n: int, puff: float, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a0 := rot + float(i) / n * TAU
		var a1 := rot + float(i + 1) / n * TAU
		var m := (a0 + a1) * 0.5
		var p0 := c + Vector2(cos(a0) * rx, sin(a0) * ry)
		var p1 := c + Vector2(cos(a1) * rx, sin(a1) * ry)
		var cp := c + Vector2(cos(m) * rx * (1.0 + puff * 2.0), sin(m) * ry * (1.0 + puff * 2.0))
		for k in 4:
			var t := float(k) / 4.0
			pts.append(p0.lerp(cp, t).lerp(cp.lerp(p1, t), t))
	return pts


static func quad_pts(a: Vector2, c: Vector2, b: Vector2, n := 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		pts.append(a.lerp(c, t).lerp(c.lerp(b, t), t))
	return pts


static func hash1(n: float) -> float:
	var x := sin(n * 127.1 + 311.7) * 43758.5453
	return x - floorf(x)


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 0) -> void:
	var f := ThemeDB.fallback_font
	var x := pos.x
	if align == HORIZONTAL_ALIGNMENT_CENTER and width < 0:
		x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT and width < 0:
		x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if outline > 0:
		ci.draw_string_outline(f, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, width, size, outline, Color(0.06, 0.05, 0.16, 0.9))
	ci.draw_string(f, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, width, size, col)


static func wrap(s: String, size: int, max_w: float) -> PackedStringArray:
	var f := ThemeDB.fallback_font
	var lines := PackedStringArray()
	var cur := ""
	for w in s.split(" "):
		var test := w if cur == "" else cur + " " + w
		if f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w and cur != "":
			lines.append(cur)
			cur = w
		else:
			cur = test
	if cur != "":
		lines.append(cur)
	return lines
