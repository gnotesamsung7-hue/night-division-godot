extends Node
## Autoload "Hand": turns the HandTracker camera plugin (or touch) into aim + gesture events.
## Events in Hand.events: shot, charge_start, charge_cancel, blast, swipe, thrust, switch, lost, back.

const CHARGE_DELAY := 0.35
const CHARGE_TIME := 1.3
const PALM_HOLD := 0.6
const SWIPE_SPEED := 1.5
const THRUST_GROWTH := 1.22
const CAMERA_PERMISSION := "android.permission.CAMERA"

signal status_changed(text: String)

var tracker: Object = null
var mode = ""                 # "camera" | "touch" | ""
var active = false            # true while a mission is running (touch input only counts then)
var status = ""
var events: Array = []
var aim = Vector2.ZERO
var seen = false
var present = false
var lost_at = 0.0
var landmarks = PackedVector3Array()
var aspect = 0.75
var trig = {"ratio": 1.0, "cocked": false, "holding": false, "hold_start": 0.0, "charge": 0.0}
var weapon = "gun"
var palm = 0.0
var palm_latched = false
var raw: Array = []
var hist: Array = []
var last_swipe = -10.0
var last_thrust = -10.0
var last_proc = 0.0
var tracking_hz = 0.0
var _updates = 0
var _hz_t = 0.0
var _last_move = {}
var fx = OneEuro.new()
var fy = OneEuro.new()


class OneEuro:
	var min_cutoff = 1.5
	var beta = 0.01
	var d_cutoff = 1.0
	var x = null
	var dx = 0.0
	var t = 0.0
	func reset() -> void:
		x = null
		dx = 0.0
	func _a(c: float, dt: float) -> float:
		var tau = 1.0 / (TAU * c)
		return 1.0 / (1.0 + tau / dt)
	func filter(v: float, now: float) -> float:
		if x == null:
			x = v
			t = now
			return v
		var dt = maxf(now - t, 0.001)
		t = now
		dx += _a(d_cutoff, dt) * ((v - x) / dt - dx)
		x += _a(min_cutoff + beta * absf(dx), dt) * (v - x)
		return x


func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func threshold() -> float:
	return (Store.settings.thumb_t if Store.settings.trigger == "thumb" else Store.settings.pinch_t) / 100.0


func apply_smoothing() -> void:
	fx.min_cutoff = 6.0 - Store.settings.smooth * 0.056
	fy.min_cutoff = fx.min_cutoff


func has_plugin() -> bool:
	return Engine.has_singleton("HandTracker")


func start_camera() -> bool:
	mode = "camera"
	apply_smoothing()
	if not has_plugin():
		_set_status("Hand tracking is only available in the Android app")
		return false
	if tracker == null:
		tracker = Engine.get_singleton("HandTracker")
		tracker.connect("hand_landmarks", _on_landmarks)
		tracker.connect("status", _set_status)
		get_tree().on_request_permissions_result.connect(_on_permission)
	if OS.get_granted_permissions().has(CAMERA_PERMISSION):
		tracker.start()
	else:
		_set_status("asking for camera permission")
		OS.request_permissions()
	present = false
	lost_at = now()
	return true


func use_touch() -> void:
	mode = "touch"
	if tracker != null:
		tracker.stop()


func _on_permission(permission: String, granted: bool) -> void:
	if permission == CAMERA_PERMISSION and granted and tracker != null:
		tracker.start()
	elif permission == CAMERA_PERMISSION:
		_set_status("camera permission denied")


func _set_status(s: String) -> void:
	status = s
	status_changed.emit(s)


func reset_gestures() -> void:
	trig.cocked = false
	trig.holding = false
	trig.charge = 0.0
	events.clear()
	fx.reset()
	fy.reset()


func _on_landmarks(csv: String) -> void:
	_updates += 1
	if mode != "camera":
		return
	var v = csv.split_floats(",")
	var t = now()
	if v.size() < 65:
		if present:
			present = false
			lost_at = t
			landmarks = PackedVector3Array()
			if trig.holding and trig.charge > 0.0:
				events.append({"type": "charge_cancel"})
			trig.holding = false; trig.charge = 0.0; trig.cocked = false
			fx.reset(); fy.reset(); hist.clear(); raw.clear(); palm = 0.0; last_proc = 0.0
			events.append({"type": "lost"})
		return
	aspect = v[0] / maxf(v[1], 1.0)
	landmarks.resize(21)
	for i in 21:
		landmarks[i] = Vector3(v[2 + i * 3], v[3 + i * 3], v[4 + i * 3])
	if not present:
		present = true
		events.append({"type": "back", "away": t - lost_at})
	_process_hand(t)


func _d(a: int, b: int) -> float:
	return Vector2((landmarks[a].x - landmarks[b].x) * aspect, landmarks[a].y - landmarks[b].y).length()


func _process_hand(t: float) -> void:
	var vp = View
	var size = maxf(_d(0, 9), 0.001)
	var thumb_mode: bool = Store.settings.trigger == "thumb"
	var p = landmarks[8] if thumb_mode else (landmarks[4] + landmarks[8]) * 0.5
	var m: float = Store.settings.reach / 100.0
	var nx = clampf(((1.0 - p.x) - m) / (1.0 - 2.0 * m), 0.0, 1.0)
	var ny = clampf((p.y - m) / (1.0 - 2.0 * m), 0.0, 1.0)
	aim = Vector2(fx.filter(nx * vp.W, t), fy.filter(ny * vp.H, t))
	seen = true
	hist.append({"t": t, "p": aim})
	if hist.size() > 12: hist.pop_front()
	var rp = Vector2(nx * vp.W, ny * vp.H)
	raw.append({"t": t, "p": rp, "size": size})
	while raw.size() > 0 and t - raw[0].t > 0.4:
		raw.pop_front()
	var dt = minf(0.1, t - last_proc) if last_proc > 0.0 else 0.0
	last_proc = t
	# open palm held still = switch weapon
	var ext = func(tip: int, pip: int) -> bool: return _d(0, tip) > _d(0, pip) * 1.12
	var is_palm: bool = ext.call(8, 6) and ext.call(12, 10) and ext.call(16, 14) and ext.call(20, 18)
	if is_palm and not palm_latched:
		palm = minf(1.0, palm + dt / PALM_HOLD)
		if palm >= 1.0:
			events.append({"type": "switch"})
			palm_latched = true
			palm = 0.0
	else:
		palm = maxf(0.0, palm - dt * 4.0)
		if not is_palm:
			palm_latched = false
	# fast sweep = knife slash
	var old = null
	for r in raw:
		if t - r.t <= 0.14:
			old = r
			break
	if old != null and t - old.t > 0.05 and t - last_swipe > 0.25:
		var speed: float = rp.distance_to(old.p) / (t - old.t) / minf(vp.W, vp.H)
		if speed > SWIPE_SPEED:
			last_swipe = t
			events.append({"type": "swipe", "a": old.p, "b": rp})
	# hand jabbing toward the camera = punch
	var min_size = 99.0
	var count = 0
	for r in raw:
		if t - r.t <= 0.26:
			min_size = minf(min_size, r.size)
			count += 1
	if count > 2 and size / min_size > THRUST_GROWTH and t - last_thrust > 0.5:
		last_thrust = t
		for r in raw:
			r.size = size
		events.append({"type": "thrust", "x": aim.x, "y": aim.y})
	# thumb trigger with hold-to-charge
	var T = threshold()
	trig.ratio = (minf(_d(4, 5), _d(4, 6)) if thumb_mode else _d(4, 8)) / size
	if not trig.cocked and not trig.holding and trig.ratio > T * 1.45:
		trig.cocked = true
	if trig.cocked and trig.ratio < T:
		trig.cocked = false
		trig.holding = true
		trig.hold_start = t
		trig.charge = 0.0
		var back: Dictionary = hist[0]
		for hh in hist:
			if t - hh.t <= 0.13:
				back = hh
				break
		events.append({"type": "shot", "x": back.p.x, "y": back.p.y})
	elif trig.holding and trig.ratio > T * 1.45:
		_release()
		trig.cocked = true


func _release() -> void:
	if trig.charge >= 1.0:
		events.append({"type": "blast", "x": aim.x, "y": aim.y})
	elif trig.charge > 0.0:
		events.append({"type": "charge_cancel"})
	trig.holding = false
	trig.charge = 0.0


func _process(delta: float) -> void:
	_hz_t += delta
	if _hz_t >= 1.0:
		tracking_hz = _updates / _hz_t
		_updates = 0
		_hz_t = 0.0
	if not trig.holding:
		return
	if weapon != "gun":
		trig.charge = 0.0
		return
	var h: float = now() - trig.hold_start
	var c = 0.0 if h < CHARGE_DELAY else minf(1.0, (h - CHARGE_DELAY) / CHARGE_TIME)
	if c > 0.0 and trig.charge == 0.0:
		events.append({"type": "charge_start"})
	trig.charge = c


func _unhandled_input(event: InputEvent) -> void:
	if mode != "touch" or not active:
		return
	var pos = Vector2(-1, -1)
	var down = false
	var up = false
	if event is InputEventScreenTouch:
		pos = event.position
		down = event.pressed
		up = not event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		down = event.pressed
		up = not event.pressed
	if down:
		aim = pos
		seen = true
		trig.holding = true
		trig.hold_start = now()
		trig.charge = 0.0
		_last_move = {"t": now(), "p": pos}
		events.append({"type": "shot", "x": pos.x, "y": pos.y})
	elif up and trig.holding:
		_release()
	elif (event is InputEventScreenDrag or (event is InputEventMouseMotion and trig.holding)) and trig.holding:
		var t = now()
		if not _last_move.is_empty():
			var dtm = maxf(t - _last_move.t, 0.001)
			var sp: float = event.position.distance_to(_last_move.p) / dtm / minf(View.W, View.H)
			if sp > SWIPE_SPEED and t - last_swipe > 0.2:
				last_swipe = t
				events.append({"type": "swipe", "a": _last_move.p, "b": event.position})
		_last_move = {"t": t, "p": event.position}
		aim = event.position
