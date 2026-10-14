extends Node
## Autoload "View": screen size, first-person perspective and every level backdrop.
## World coords: x = left/right (-1..1 playfield), z = depth (0 near .. 1 far), h = height above floor.

const K := 4.0
const S1 := 1.0 / (K + 1.0)
const INK := Color("#120A24")

var W := 720.0
var H := 1280.0
var B := 720.0
var horizon := 460.0
var floor_y := 1254.0
var top := 24.0
var beacon_lit := 0.0


func resize(size: Vector2) -> void:
	W = size.x
	H = size.y
	B = minf(W, H * 0.62)
	horizon = H * 0.36
	floor_y = H * 0.98
	top = 24.0


## Returns (screen x, screen y on the floor, scale).
func proj(x: float, z: float) -> Vector3:
	var s := 1.0 / (maxf(z, -0.15) * K + 1.0)
	var n := (s - S1) / (1.0 - S1)
	return Vector3(W * 0.5 + x * W * 0.5 * s, horizon + (floor_y - horizon) * n, s)


func px(w: float, s: float) -> float:
	return w * B * 0.5 * s


func pt(x: float, h: float, z: float) -> Vector2:
	var p := proj(x, z)
	return Vector2(p.x, p.y - px(h, p.z))


func quad3(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color, edge := Color(0, 0, 0, 0), lw := 1.5) -> void:
	var pts := PackedVector2Array([a, b, c, d])
	Pen.fill(ci, pts, col)
	if edge.a > 0.0:
		Pen.stroke(ci, pts, edge, lw)


func h(n: float) -> float:
	return Pen.hash1(n)


func draw_scene(ci: CanvasItem, scene: String, t: float, scroll: float) -> void:
	match scene:
		"records": _records(ci, t, scroll)
		"market": _market(ci, t, scroll)
		"tunnel": _tunnel(ci, t, scroll)
		"drain": _drain(ci, t, scroll)
		"crypt": _crypt(ci, t, scroll)
		"beacon": _beacon(ci, t, scroll)
		_: _market(ci, t, scroll)


func _dust(ci: CanvasItem, t: float, col: Color) -> void:
	for i in 24:
		var x := fposmod(h(i) * W + sin(t * 0.3 + i) * 20.0, W)
		var y := fposmod(h(i + 50) * H + t * 8.0 * (0.5 + h(i + 9)), H)
		ci.draw_rect(Rect2(x, y, 2, 2), col)


func _rain(ci: CanvasItem, t: float) -> void:
	for i in 60:
		var x := fposmod(h(i) * W * 1.2 + t * 60.0, W * 1.2) - W * 0.1
		var y := fposmod(h(i + 99) * H + t * (600.0 + h(i) * 300.0), H)
		ci.draw_line(Vector2(x, y), Vector2(x - 3, y + 16), Color(0.67, 0.75, 1.0, 0.18), 1.5)


func _sky(ci: CanvasItem, t: float, hy: float) -> void:
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, hy), Vector2(0, hy)]),
		PackedColorArray([Color("#070A26"), Color("#070A26"), Color("#5A2484"), Color("#5A2484")]))
	for i in 50:
		var a := 0.3 + 0.7 * absf(sin(t * (0.5 + h(i) * 2.0) + i))
		ci.draw_rect(Rect2(h(i) * W, h(i + 40) * hy * 0.85, 2, 2), Color(1, 1, 1, a * 0.8))


func _moon(ci: CanvasItem, c: Vector2, r: float) -> void:
	Pen.glow(ci, c, r * 3.2, Color(1, 0.8, 0.98, 0.22))
	ci.draw_circle(c, r, Color("#FFF4E8"))
	Pen.fill(ci, Pen.ell(c + Vector2(r * 0.42, -r * 0.25), r * 0.62, r * 0.75, 0.0, 24), Color(0.75, 0.67, 1.0, 0.25))
	for q in [[-0.35, 0.2, 0.18], [0.05, 0.45, 0.12], [-0.1, -0.35, 0.1]]:
		ci.draw_circle(c + Vector2(q[0], q[1]) * r, q[2] * r, Color(0.78, 0.73, 0.92, 0.4))


func _cloud(ci: CanvasItem, c: Vector2, s: float, fill: Color, rim: Color) -> void:
	var blobs := [[0, 0, 1.0], [0.95, 0.18, 0.72], [-0.95, 0.22, 0.68], [0.45, -0.38, 0.7], [-0.4, -0.3, 0.62], [1.7, 0.35, 0.45], [-1.7, 0.38, 0.42]]
	for b in blobs:
		ci.draw_circle(c + Vector2(b[0], b[1]) * s, b[2] * s, rim)
	for b in blobs:
		ci.draw_circle(c + Vector2(b[0], b[1] + 0.12) * s, b[2] * s * 0.96, fill)


## ---------------- Command post archive ----------------
func _records(ci: CanvasItem, t: float, scroll: float) -> void:
	var ZF := 1.25
	var ZN := -0.14
	var WX := 1.1
	var CH := 2.2
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
		PackedColorArray([Color("#080B20"), Color("#080B20"), Color("#131940"), Color("#131940")]))
	quad3(ci, pt(-WX, CH, ZN), pt(WX, CH, ZN), pt(WX, CH, ZF), pt(-WX, CH, ZF), Color("#0A0D27"))
	quad3(ci, pt(-WX, 0, ZN), pt(WX, 0, ZN), pt(WX, 0, ZF), pt(-WX, 0, ZF), Color("#10163C"))
	quad3(ci, pt(-WX, 0, ZN), pt(-WX, 0, ZF), pt(-WX, CH, ZF), pt(-WX, CH, ZN), Color("#141A45"))
	quad3(ci, pt(WX, 0, ZN), pt(WX, 0, ZF), pt(WX, CH, ZF), pt(WX, CH, ZN), Color("#141A45"))
	quad3(ci, pt(-WX, 0, ZF), pt(WX, 0, ZF), pt(WX, CH, ZF), pt(-WX, CH, ZF), Color("#1A2154"))
	var d0 := pt(-0.28, 1.45, ZF)
	var d1 := pt(0.28, 0, ZF)
	ci.draw_polygon(PackedVector2Array([d0, Vector2(d1.x, d0.y), d1, Vector2(d0.x, d1.y)]),
		PackedColorArray([Color("#2B1460"), Color("#2B1460"), Color("#7A3FD0"), Color("#7A3FD0")]))
	Pen.glow(ci, Vector2((d0.x + d1.x) * 0.5, d1.y), (d1.x - d0.x) * 2.2, Color(0.71, 0.36, 1.0, 0.25 + 0.08 * sin(t * 2.0)))
	var step := 0.15
	var off := fposmod(scroll, step)
	for k in 12:
		var z := k * step - off
		if z >= ZN and z <= ZF:
			ci.draw_line(pt(-WX, 0, z), pt(WX, 0, z), Color(0.44, 0.95, 1.0, 0.06), 1.0)
	var x := -WX
	while x <= WX + 0.01:
		ci.draw_line(pt(x, 0, ZN), pt(x, 0, ZF), Color(0.44, 0.95, 1.0, 0.06), 1.0)
		x += 0.55
	for k in range(11, -1, -1):
		var z0 := k * step - off
		var z1 := z0 + step * 0.88
		if z1 < ZN or z0 > ZF:
			continue
		for side in [-1.0, 1.0]:
			var cx: float = side * (WX - 0.02)
			quad3(ci, pt(cx, 0, z0), pt(cx, 0, z1), pt(cx, 1.7, z1), pt(cx, 1.7, z0), Color("#1E2762"), INK, 1.5)
			for hh in [0.42, 0.85, 1.27]:
				ci.draw_line(pt(cx, hh, z0), pt(cx, hh, z1), Color("#2C377D"), 1.0)
	var lstep := 0.5
	var loff := fposmod(scroll, lstep)
	for k in range(3, -1, -1):
		var z := k * lstep - loff + 0.25
		if z < ZN or z > ZF:
			continue
		var id := k + floori(scroll / lstep)
		var flick := 0.15 if h(id + floorf(t * 8.0)) > (0.85 if id % 3 == 0 else 0.97) else 1.0
		var l := pt(0, 2.0, z)
		var f := pt(0, 0, z)
		var s := proj(0, z).z
		ci.draw_polygon(PackedVector2Array([l + Vector2(-px(0.08, s), 0), l + Vector2(px(0.08, s), 0), f + Vector2(px(0.6, s), 0), f - Vector2(px(0.6, s), 0)]),
			PackedColorArray([Color(0.63, 0.78, 1, 0.18 * flick), Color(0.63, 0.78, 1, 0.18 * flick), Color(0.63, 0.78, 1, 0), Color(0.63, 0.78, 1, 0)]))
		Pen.glow(ci, f, px(0.7, s), Color(0.63, 0.78, 1, 0.12 * flick))
		ci.draw_rect(Rect2(l.x - px(0.1, s), l.y - px(0.03, s), px(0.2, s), px(0.05, s)), Color("#2E3880"))
	_dust(ci, t, Color(0.78, 0.86, 1, 0.35))


## ---------------- Quiapo night market ----------------
const STALL := ["#FF4FB0", "#FFB547", "#6FF3FF", "#B65CFF", "#FF6B6B"]
func _market(ci: CanvasItem, t: float, scroll: float) -> void:
	var ZF := 1.4
	var ZN := -0.14
	var RX := 1.0
	ci.draw_rect(Rect2(0, 0, W, H), Color("#0F0B2E"))
	_sky(ci, t, horizon + 20)
	_moon(ci, Vector2(W * 0.7, horizon * 0.42), minf(W, H) * 0.15)
	for i in 3:
		var cx := fposmod(h(i + 7) * W + t * (6.0 + i * 4.0), W * 1.6) - W * 0.3
		_cloud(ci, Vector2(cx, horizon * (0.3 + i * 0.22)), minf(W, H) * (0.05 + h(i) * 0.03), Color("#1F1552"), Color("#5B44A8"))
	for i in 9:
		var x0 := -1.4 + i * 0.32
		var hgt := 1.4 + h(i) * 2.2
		var a := pt(x0, hgt, ZF)
		var b := pt(x0 + 0.3, 0, ZF)
		ci.draw_rect(Rect2(a, b - a), Color("#120F33"))
		for r in 8:
			for c in 3:
				if h(i * 31 + r * 7 + c) > 0.55:
					continue
				var wp := pt(x0 + 0.05 + c * 0.09, hgt - 0.25 - r * 0.28, ZF)
				if wp.y < b.y - 2:
					ci.draw_rect(Rect2(wp, Vector2(2, 3)), Color(1, 0.71, 0.28, 0.55) if h(i + r + c) > 0.5 else Color(0.44, 0.95, 1, 0.4))
	quad3(ci, pt(-1.8, 0, ZN), pt(1.8, 0, ZN), pt(1.8, 0, ZF), pt(-1.8, 0, ZF), Color("#151236"))
	quad3(ci, pt(-RX, 0, ZN), pt(RX, 0, ZN), pt(RX, 0, ZF), pt(-RX, 0, ZF), Color("#0F1030"))
	var doff := fposmod(scroll, 0.2)
	for k in 8:
		var z0 := k * 0.2 - doff
		var z1 := z0 + 0.08
		if z1 >= ZN and z0 <= ZF:
			quad3(ci, pt(-0.02, 0, z0), pt(0.02, 0, z0), pt(0.02, 0, z1), pt(-0.02, 0, z1), Color(0.95, 0.94, 1, 0.18))
	var P := 0.28
	var off := fposmod(scroll, P)
	var base := floori(scroll / P)
	for k in range(6, -1, -1):
		var z0 := k * P - off + 0.05
		var z1 := z0 + P * 0.9
		if z1 < ZN or z0 > ZF:
			continue
		for side in [-1.0, 1.0]:
			var id := (k + base) * 2 + (1 if side > 0 else 0)
			var col := Color(STALL[int(h(id) * STALL.size()) % STALL.size()])
			var X: float = side * 1.05
			var s := proj(X, (z0 + z1) * 0.5).z
			quad3(ci, pt(X * 1.25, 0, z0), pt(X * 1.25, 0, z1), pt(X * 1.25, 1.8, z1), pt(X * 1.25, 1.8, z0), Color("#1C1846"))
			quad3(ci, pt(X, 0.6, z0), pt(X, 0.6, z1), pt(X, 1.4, z1), pt(X, 1.4, z0), Color(1, 0.71, 0.28, 0.16))
			quad3(ci, pt(X, 0, z0), pt(X, 0, z1), pt(X, 0.6, z1), pt(X, 0.6, z0), Color("#2A2160"), INK, 1.5)
			for i in 4:
				var a := z0 + (z1 - z0) * i / 4.0
				var b := z0 + (z1 - z0) * (i + 1) / 4.0
				quad3(ci, pt(X * 1.25, 1.75, a), pt(X * 1.25, 1.75, b), pt(X * 0.82, 1.42, b), pt(X * 0.82, 1.42, a), Color("#F3F0FF") if i % 2 == 1 else col, INK, 1.2)
			var lp := pt(X * 0.84, 1.28, (z0 + z1) * 0.5) + Vector2(sin(t * 1.6 + id) * px(0.02, s), 0)
			Pen.glow(ci, lp, px(0.45, s), Color(1, 0.55, 0.24, 0.35))
			var rp := pt(X * 0.75, 0, (z0 + z1) * 0.5)
			ci.draw_polygon(PackedVector2Array([rp + Vector2(-px(0.05, s), 0), rp + Vector2(px(0.05, s), 0), rp + Vector2(px(0.05, s), px(0.9, s)), rp + Vector2(-px(0.05, s), px(0.9, s))]),
				PackedColorArray([Color(1, 0.55, 0.24, 0.18), Color(1, 0.55, 0.24, 0.18), Color(1, 0.55, 0.24, 0), Color(1, 0.55, 0.24, 0)]))
			var lpts := Pen.ell(lp, px(0.07, s), px(0.09, s), 0.0, 16)
			Pen.fill(ci, lpts, Color("#FF7A3C"))
			Pen.stroke(ci, lpts, INK, 1.2)
	var L := 0.56
	var loff := fposmod(scroll, L)
	for k in range(2, -1, -1):
		var z := k * L - loff + 0.32
		if z < ZN or z > ZF:
			continue
		var s := proj(0, z).z
		for i in 11:
			var bp := pt(-1.05 + i * 0.21, 2.15 - sin(i / 10.0 * PI) * 0.3, z)
			Pen.glow(ci, bp, px(0.09, s), Color(0.44, 0.95, 1, 0.6) if i % 2 == 1 else Color(1, 0.31, 0.69, 0.6))
	_rain(ci, t)


## ---------------- shared arch for tunnels ----------------
func _arch(ci: CanvasItem, z: float, WX: float, HH: float, col: Color, lw: float) -> void:
	var l := pt(-WX, 0, z)
	var lt := pt(-WX, HH, z)
	var r := pt(WX, 0, z)
	var rt := pt(WX, HH, z)
	var c := Vector2((l.x + r.x) * 0.5, lt.y)
	var rad := (r.x - l.x) * 0.5
	var pts := PackedVector2Array([l, lt])
	for i in 17:
		var a := PI + PI * i / 16.0
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	pts.append(rt)
	pts.append(r)
	ci.draw_polyline(pts, col, maxf(lw, 1.0), true)


func _fog(ci: CanvasItem, col: Color) -> void:
	var y0 := horizon - H * 0.15
	var y1 := horizon + H * 0.12
	var ym := (y0 + y1) * 0.5
	var clear := Color(col, 0)
	ci.draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(W, y0), Vector2(W, ym), Vector2(0, ym)]), PackedColorArray([clear, clear, col, col]))
	ci.draw_polygon(PackedVector2Array([Vector2(0, ym), Vector2(W, ym), Vector2(W, y1), Vector2(0, y1)]), PackedColorArray([col, col, clear, clear]))


func _tunnel(ci: CanvasItem, t: float, scroll: float) -> void:
	var ZF := 1.4
	var WX := 1.05
	var HH := 1.3
	ci.draw_rect(Rect2(0, 0, W, H), Color("#07081A"))
	Pen.glow(ci, pt(0, 0.9, ZF), W * 0.25, Color(0.5, 0.97, 0.9, 0.12))
	quad3(ci, pt(-WX, 0, -0.14), pt(WX, 0, -0.14), pt(WX, 0, ZF), pt(-WX, 0, ZF), Color("#121226"))
	var step := 0.18
	var off := fposmod(scroll, step)
	for k in range(9, -1, -1):
		var z := k * step - off
		if z >= -0.14 and z <= ZF:
			quad3(ci, pt(-0.5, 0, z), pt(0.5, 0, z), pt(0.5, 0, z + 0.04), pt(-0.5, 0, z + 0.04), Color("#2A2238"))
	for x in [-0.35, 0.35]:
		ci.draw_line(pt(x, 0.02, -0.14), pt(x, 0.02, ZF), Color("#8A8FB0"), 2.0)
	for k in range(9, -1, -1):
		var z := k * step - off + 0.05
		if z < -0.1 or z > ZF:
			continue
		var f := maxf(0.15, 1.0 - z / ZF)
		_arch(ci, z, WX, HH, Color(0.27, 0.29, 0.47, f), 10.0 * proj(0, z).z)
		var id := k + floori(scroll / step)
		if id % 3 == 0:
			var sp := pt(-WX + 0.05, 0.9, z)
			var s := proj(0, z).z
			var on := sin(t * 3.0 + id) > -0.3
			Pen.glow(ci, sp, px(0.25, s), Color(1, 0.24, 0.31, 0.6) if on else Color(0.24, 1, 0.55, 0.4))
			ci.draw_circle(sp, maxf(1.5, px(0.04, s)), Color("#FF5A6E") if on else Color("#5AFF9A"))
	for hh in [1.0, 1.1]:
		ci.draw_line(pt(WX - 0.03, hh, -0.14), pt(WX - 0.03, hh, ZF), Color(0.12, 0.12, 0.2, 0.9), 3.0)
	_fog(ci, Color(0.5, 0.97, 0.9, 0.07))
	_dust(ci, t, Color(0.7, 0.86, 1, 0.25))


func _drain(ci: CanvasItem, t: float, scroll: float) -> void:
	var ZF := 1.4
	var WX := 1.1
	var HH := 1.2
	ci.draw_rect(Rect2(0, 0, W, H), Color("#081414"))
	var step := 0.22
	var off := fposmod(scroll, step)
	for k in range(8, -1, -1):
		var z := k * step - off + 0.05
		if z < -0.1 or z > ZF:
			continue
		var f := maxf(0.15, 1.0 - z / ZF)
		_arch(ci, z, WX, HH, Color(0.47, 0.31, 0.24, f), 14.0 * proj(0, z).z)
		_arch(ci, z + 0.11, WX, HH, Color(0.35, 0.24, 0.18, f * 0.7), 8.0 * proj(0, z).z)
		var id := k + floori(scroll / step)
		if id % 2 == 0:
			var pp := pt(WX - 0.05, 1.0, z)
			var s := proj(0, z).z
			ci.draw_rect(Rect2(pp.x - px(0.12, s), pp.y, px(0.12, s), px(0.07, s)), Color("#3A4A44"))
			var dy := fposmod(t * 0.9 + id * 0.3, 1.0) * px(1.0, s)
			ci.draw_rect(Rect2(pp.x - px(0.06, s), pp.y + dy, 2, 4), Color(0.59, 1, 0.67, 0.7))
			Pen.glow(ci, Vector2(pp.x - px(0.06, s), pp.y + px(1.0, s)), px(0.3, s), Color(0.47, 1, 0.59, 0.18))
	var wp := PackedVector2Array([pt(-WX, 0, -0.14), pt(WX, 0, -0.14), pt(WX, 0, ZF), pt(-WX, 0, ZF)])
	ci.draw_polygon(wp, PackedColorArray([Color("#14454E"), Color("#14454E"), Color("#0E2A30"), Color("#0E2A30")]))
	for i in 18:
		var z := fposmod(i * 0.08 - scroll * 0.6 + t * 0.05, 1.4)
		var s := proj(0, z).z
		var c := pt(sin(i * 2.3) * 0.7, 0, z)
		Pen.stroke(ci, Pen.ell(c, px(0.25, s) * (1.0 + 0.2 * sin(t * 2.0 + i)), px(0.03, s), 0.0, 20), Color(0.63, 0.9, 1, 0.25), 1.5)
	_fog(ci, Color(0.47, 1, 0.67, 0.06))


func _crypt(ci: CanvasItem, t: float, scroll: float) -> void:
	var ZF := 1.3
	var WX := 1.05
	var HH := 1.4
	ci.draw_rect(Rect2(0, 0, W, H), Color("#0C0814"))
	quad3(ci, pt(-WX, 0, -0.14), pt(WX, 0, -0.14), pt(WX, 0, ZF), pt(-WX, 0, ZF), Color("#1A1420"))
	var step := 0.26
	var off := fposmod(scroll, step)
	for k in range(6, -1, -1):
		var z := k * step - off + 0.05
		if z < -0.1 or z > ZF:
			continue
		var f := maxf(0.15, 1.0 - z / ZF)
		var s := proj(0, z).z
		_arch(ci, z, WX, HH, Color(0.59, 0.51, 0.63, f), 18.0 * s)
		var zm := z + step * 0.5
		var sm := proj(0, zm).z
		for side in [-1.0, 1.0]:
			var n := pt(side * (WX - 0.02), 0.55, zm)
			var w := px(0.25, sm)
			ci.draw_rect(Rect2(n.x - w * 0.5, n.y - w * 1.4, w, w * 1.4), Color("#07050C"))
			var cp := pt(side * (WX - 0.12), 0.35, zm)
			ci.draw_rect(Rect2(cp.x - px(0.02, sm), cp.y, px(0.04, sm), px(0.12, sm)), Color("#EDE2C8"))
			var fl := 1.0 + 0.25 * sin(t * 12.0 + k * 3 + side)
			Pen.glow(ci, cp - Vector2(0, 2), px(0.35, sm) * fl, Color(1, 0.67, 0.31, 0.35))
			Pen.glow(ci, cp - Vector2(0, 2), px(0.06, sm) * fl, Color(1, 0.94, 0.78, 1))
	Pen.glow(ci, pt(0, 0.6, ZF), W * 0.2, Color(0.69, 0.49, 1, 0.15))
	_fog(ci, Color(0.69, 0.49, 1, 0.08))
	_dust(ci, t, Color(0.86, 0.78, 1, 0.25))


func _beacon(ci: CanvasItem, t: float, scroll: float) -> void:
	var lit := beacon_lit
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
		PackedColorArray([Color("#0A0620"), Color("#0A0620"), Color("#1A1030"), Color("#1A1030")]))
	var fp := pt(0, 0, 0.7)
	var fs := proj(0, 0.7).z
	for i in range(1, 5):
		Pen.stroke(ci, Pen.ell(fp, px(0.4 * i, fs) * 2.0, px(0.08 * i, fs) * 2.0, 0.0, 40), Color(0.44, 0.95, 1, 0.12 + lit * 0.5), 2.0)
	for k in range(5, -1, -1):
		var z := k * 0.28 - fposmod(scroll, 0.28) + 0.1
		if z < -0.1 or z > 1.4:
			continue
		for side in [-1.0, 1.0]:
			quad3(ci, pt(side * 1.0, 0, z), pt(side * 1.15, 0, z), pt(side * 1.15, 3, z), pt(side * 1.0, 3, z), Color("#2A2040"), INK, 1.5)
	var bp := pt(0, 0, 1.2)
	var bs := proj(0, 1.2).z
	var bh := px(3.2, bs)
	var bw := px(0.45, bs)
	Pen.glow(ci, bp - Vector2(0, bh * 0.5), bh * (0.6 + lit), Color(0.63, 0.98, 1, 0.4 + lit * 0.4) if lit > 0.0 else Color(0.47, 0.24, 0.78, 0.2))
	if lit > 0.0:
		ci.draw_colored_polygon(PackedVector2Array([bp + Vector2(-bw * 0.3, -bh), bp + Vector2(bw * 0.3, -bh), Vector2(bp.x + bw * 3.0, 0), Vector2(bp.x - bw * 3.0, 0)]), Color(0.78, 1, 1, 0.25 * lit))
	var crystal := PackedVector2Array([bp + Vector2(0, -bh), bp + Vector2(bw, -bh * 0.35), bp + Vector2(bw * 0.6, 0), bp + Vector2(-bw * 0.6, 0), bp + Vector2(-bw, -bh * 0.35)])
	var cA := Color("#9FF8FF") if lit > 0.0 else Color("#2A1E48")
	var cB := Color("#FFFFFF") if lit > 0.0 else Color("#4A3A72")
	ci.draw_polygon(crystal, PackedColorArray([cB, cA, cA, cB, cA]))
	Pen.stroke(ci, crystal, INK, 2.0)
	if lit <= 0.0:
		ci.draw_polyline(PackedVector2Array([bp + Vector2(-bw * 0.2, -bh * 0.8), bp + Vector2(bw * 0.1, -bh * 0.55), bp + Vector2(-bw * 0.15, -bh * 0.3)]), Color(0.69, 0.49, 1, 0.6), 1.5)
	for i in 10:
		var x := fposmod(h(i) * W + t * 15.0 * (1.0 if i % 2 == 1 else -1.0), W)
		var y := horizon + h(i + 5) * H * 0.4
		Pen.fill(ci, Pen.ell(Vector2(x, y), 40, 10, 0.0, 16), Color(0.31, 0.12, 0.51, 0.25 - lit * 0.2))
	_dust(ci, t, Color(0.86, 1, 1, 0.5) if lit > 0.0 else Color(0.78, 0.67, 1, 0.3))


## ---------------- Title key art: the officer on a rooftop under the moon ----------------
func draw_keyart(ci: CanvasItem, t: float) -> void:
	var m := minf(W, H)
	var hz := H * 0.7
	ci.draw_rect(Rect2(0, 0, W, H), Color("#0B0824"))
	var sky := PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, hz * 0.55), Vector2(0, hz * 0.55)])
	ci.draw_polygon(sky, PackedColorArray([Color("#060824"), Color("#060824"), Color("#23125A"), Color("#23125A")]))
	ci.draw_polygon(PackedVector2Array([Vector2(0, hz * 0.55), Vector2(W, hz * 0.55), Vector2(W, hz), Vector2(0, hz)]),
		PackedColorArray([Color("#23125A"), Color("#23125A"), Color("#C8478F"), Color("#C8478F")]))
	for i in 70:
		var a := 0.3 + 0.7 * absf(sin(t * (0.4 + h(i) * 2.0) + i))
		ci.draw_rect(Rect2(h(i) * W, h(i + 70) * hz * 0.7, 2, 2), Color(1, 1, 1, a * 0.85))
	_moon(ci, Vector2(W * 0.66, H * 0.2), m * 0.22)
	for i in 4:
		var cx := fposmod(h(i + 3) * W + t * (8.0 + i * 5.0), W * 1.7) - W * 0.35
		_cloud(ci, Vector2(cx, H * (0.1 + i * 0.1)), m * (0.06 + h(i + 9) * 0.05), Color("#1C1450"), Color("#5B44A8"))
	var n := 13
	for i in n:
		var w := W / (n - 2)
		var x0 := i * w - w * 0.6
		var hh := H * (0.1 + h(i + 20) * 0.22)
		var y0 := hz - hh
		ci.draw_rect(Rect2(x0, y0, w * 0.92, hh + 4), Color("#0D0A26"))
		for r in 14:
			for c in 4:
				if h(i * 50 + r * 9 + c) > 0.32:
					continue
				var wy := y0 + 12 + r * 16
				if wy > hz - 8:
					continue
				var on := h(i + r + c + floorf(t / 3.0)) > 0.15
				var col := (Color(0.44, 0.95, 1, 0.7) if h(i + c) > 0.5 else Color(1, 0.31, 0.69, 0.6)) if on else Color(1, 1, 1, 0.06)
				ci.draw_rect(Rect2(x0 + 6 + c * (w * 0.2), wy, 4, 6), col)
	ci.draw_polygon(PackedVector2Array([Vector2(0, H * 0.86), Vector2(W, H * 0.83), Vector2(W, H), Vector2(0, H)]), PackedColorArray([Color("#05041A"), Color("#05041A"), Color("#05041A"), Color("#05041A")]))
	ci.draw_line(Vector2(0, H * 0.81), Vector2(W, H * 0.78), Color("#1D1A48"), 3.0)
	for i in 9:
		var x := i * W / 8.0
		var y := H * 0.81 - H * 0.03 * (i / 8.0)
		ci.draw_line(Vector2(x, y), Vector2(x, y + H * 0.05), Color("#1D1A48"), 3.0)
	for i in 3:
		var wp := Vector2(W * (0.12 + i * 0.13) + sin(t * 1.3 + i * 2) * 14.0, H * (0.36 + (i % 2) * 0.09) + cos(t * 1.7 + i) * 10.0)
		Pen.glow(ci, wp, 40, Color(0.63, 0.31, 1, 0.55))
		Pen.glow(ci, wp, 14, Color(1, 0.86, 1, 0.95))
	_officer(ci, W * 0.7, H * 0.885, minf(H * 0.36, W * 0.85), Vector2(W * 0.28, H * 0.38), t)


func _officer(ci: CanvasItem, fx: float, fy: float, hh: float, target: Vector2, t: float) -> void:
	var col := Color("#04030E")
	var wind := sin(t * 2.2) * 0.03
	var P := func(x: float, y: float) -> Vector2: return Vector2(fx + x * hh, fy + y * hh)
	Pen.glow(ci, Vector2(fx, fy - hh * 0.55), hh * 0.6, Color(0.44, 0.95, 1, 0.16))
	ci.draw_line(P.call(0.11, -0.76), P.call(0.17, -0.5), col, hh * 0.055)
	ci.draw_line(P.call(-0.06, -0.25), P.call(-0.09, -0.01), col, hh * 0.07)
	ci.draw_line(P.call(0.06, -0.25), P.call(0.1, -0.01), col, hh * 0.07)
	var coat := PackedVector2Array()
	for q in [[-0.13, -0.78], [0.14, -0.79], [0.2, -0.5], [0.38 + wind, -0.16], [0.26, -0.2], [0.12, -0.22], [-0.02, -0.2], [-0.17, -0.22], [-0.14, -0.5]]:
		coat.append(P.call(q[0], q[1]))
	Pen.fill(ci, coat, col)
	Pen.fill(ci, PackedVector2Array([P.call(-0.07, -0.85), P.call(0.08, -0.86), P.call(0.12, -0.77), P.call(-0.1, -0.76)]), col)
	ci.draw_circle(P.call(0.01, -0.9), hh * 0.062, col)
	var hair := PackedVector2Array()
	for q in [[-0.06, -0.9], [-0.11, -0.97], [-0.04, -0.955], [-0.03, -1.03], [0.03, -0.975], [0.09, -1.02 + wind * 0.5], [0.085, -0.95], [0.16, -0.94 + wind], [0.075, -0.875]]:
		hair.append(P.call(q[0], q[1]))
	Pen.fill(ci, hair, col)
	var sh: Vector2 = P.call(-0.1, -0.76)
	var ang := (target - sh).angle()
	var e := sh + Vector2.from_angle(ang) * hh * 0.36
	ci.draw_line(sh, e, col, hh * 0.06)
	ci.draw_circle(e, hh * 0.032, col)
	var tip := e + Vector2.from_angle(ang) * hh * 0.07
	ci.draw_line(e, tip, col, hh * 0.018)
	ci.draw_line(e, e + Vector2.from_angle(ang - 1.5) * hh * 0.045, col, hh * 0.016)
	ci.draw_line(sh - Vector2(0, hh * 0.02), e - Vector2(0, hh * 0.02), Color(0.44, 0.95, 1, 0.45), 1.5)
	var pulse := 1.0 + 0.12 * sin(t * 6.0)
	Pen.glow(ci, tip, hh * 0.28 * pulse, Color(0.44, 0.95, 1, 0.45))
	Pen.glow(ci, tip, hh * 0.08 * pulse, Color(0.94, 1, 1, 1))
	ci.draw_arc(tip, hh * 0.12, t * 2.0, t * 2.0 + PI * 1.5, 32, Color(0.44, 0.95, 1, 0.8), 2.0, true)
	for i in 8:
		var a := t * 2.0 + i * 0.8
		var d := hh * 0.25 * (1.0 - fposmod(t * 0.8 + i / 8.0, 1.0))
		ci.draw_rect(Rect2(tip + Vector2(cos(a), sin(a)) * d, Vector2(3, 3)), Color(0.94, 1, 1, 0.9))


## Manga focus lines closing in from the edges.
func focus_lines(ci: CanvasItem, strength: float, t: float) -> void:
	if strength <= 0.0:
		return
	var c := Vector2(W, H) * 0.5
	var R := Vector2(W, H).length() * 0.6
	var inner := R * (1.0 - 0.45 * strength)
	for i in 48:
		var a := i / 48.0 * TAU + h(i + floorf(t * 12.0)) * 0.08
		var w := 0.012 + h(i * 7) * 0.02
		var r0 := inner + h(i * 3 + floorf(t * 12.0)) * R * 0.2
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2.from_angle(a) * r0, c + Vector2.from_angle(a - w) * R * 1.6, c + Vector2.from_angle(a + w) * R * 1.6]), Color(0.02, 0.016, 0.08, 0.55 * strength))


func speed_lines(ci: CanvasItem, strength: float, t: float) -> void:
	var c := Vector2(W * 0.5, horizon)
	var R := Vector2(W, H).length()
	for i in 36:
		var a := h(i + floorf(t * 20.0)) * TAU
		var r0 := R * (0.25 + h(i * 3) * 0.2)
		ci.draw_line(c + Vector2.from_angle(a) * r0, c + Vector2.from_angle(a) * R, Color(0.94, 1, 1, 0.35 * strength), 2.0)
