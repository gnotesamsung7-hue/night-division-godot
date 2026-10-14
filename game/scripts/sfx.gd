extends Node
## Autoload "Sfx": every sound is synthesized once at startup into a short clip, then played from a pool.

const RATE := 22050
var clips := {}
var pool: Array[AudioStreamPlayer] = []
var charge_player: AudioStreamPlayer
var _next := 0

const SOUNDS := {
	"shot": [["tone", 1500, 260, 0.13, "sine", 0.14, 0.0], ["tone", 2600, 900, 0.06, "tri", 0.05, 0.0]],
	"hit": [["tone", 900, 1300, 0.06, "tri", 0.1, 0.0]],
	"kill": [["tone", 1200, 2600, 0.14, "sine", 0.1, 0.0], ["noise", 0.18, 0.12, 5200, 0.0]],
	"phase": [["tone", 320, 160, 0.18, "sine", 0.1, 0.0]],
	"empty": [["noise", 0.05, 0.25, 3000, 0.0]],
	"recharge": [["tone", 523, 528, 0.1, "tri", 0.09, 0.0], ["tone", 659, 665, 0.1, "tri", 0.09, 0.045], ["tone", 784, 790, 0.1, "tri", 0.09, 0.09], ["tone", 1047, 1057, 0.1, "tri", 0.09, 0.135], ["tone", 1319, 1330, 0.1, "tri", 0.09, 0.18]],
	"blast": [["noise", 0.7, 0.55, 700, 0.0], ["tone", 240, 40, 0.8, "saw", 0.22, 0.0], ["tone", 1800, 200, 0.5, "sine", 0.1, 0.0]],
	"hurt": [["tone", 150, 60, 0.35, "square", 0.18, 0.0], ["noise", 0.25, 0.3, 400, 0.0]],
	"foul": [["tone", 210, 120, 0.4, "saw", 0.14, 0.0]],
	"freed": [["tone", 784, 784, 0.12, "sine", 0.11, 0.0], ["tone", 988, 988, 0.12, "sine", 0.11, 0.06], ["tone", 1319, 1319, 0.12, "sine", 0.11, 0.12], ["tone", 1568, 1568, 0.12, "sine", 0.11, 0.18]],
	"radio": [["noise", 0.08, 0.08, 2500, 0.0], ["tone", 1800, 1800, 0.04, "square", 0.04, 0.08]],
	"warn": [["tone", 760, 760, 0.07, "square", 0.08, 0.0], ["tone", 760, 760, 0.07, "square", 0.08, 0.12]],
	"lock": [["tone", 2400, 2900, 0.05, "square", 0.04, 0.0], ["tone", 3200, 3200, 0.04, "square", 0.03, 0.05]],
	"swap": [["tone", 600, 1200, 0.08, "tri", 0.1, 0.0], ["tone", 1200, 1800, 0.08, "tri", 0.08, 0.07]],
	"slash": [["noise", 0.16, 0.35, 4200, 0.0], ["tone", 1800, 600, 0.12, "sine", 0.06, 0.0]],
	"stab": [["noise", 0.07, 0.3, 5200, 0.0], ["tone", 1400, 900, 0.05, "square", 0.04, 0.0]],
	"punch": [["noise", 0.12, 0.45, 300, 0.0], ["tone", 160, 60, 0.18, "sine", 0.3, 0.0]],
	"whoosh": [["noise", 0.12, 0.12, 1500, 0.0]],
	"clear": [["tone", 523, 523, 0.2, "tri", 0.12, 0.0], ["tone", 659, 659, 0.2, "tri", 0.12, 0.09], ["tone", 784, 784, 0.2, "tri", 0.12, 0.18], ["tone", 1047, 1047, 0.2, "tri", 0.12, 0.27], ["tone", 1319, 1319, 0.2, "tri", 0.12, 0.36]],
	"fail": [["tone", 392, 384, 0.3, "tri", 0.14, 0.0], ["tone", 330, 323, 0.3, "tri", 0.14, 0.22], ["tone", 262, 257, 0.3, "tri", 0.14, 0.44], ["tone", 196, 192, 0.3, "tri", 0.14, 0.66]],
	"boss": [["noise", 0.9, 0.5, 500, 0.0], ["tone", 300, 50, 1.0, "saw", 0.2, 0.0], ["tone", 880, 1760, 0.6, "tri", 0.1, 0.3]],
}


func _ready() -> void:
	for k in SOUNDS.keys():
		clips[k] = _render(SOUNDS[k])
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	charge_player = AudioStreamPlayer.new()
	charge_player.stream = _render_loop()
	add_child(charge_player)


func _wave(kind: String, ph: float) -> float:
	var x := fposmod(ph, 1.0)
	match kind:
		"square": return 1.0 if x < 0.5 else -1.0
		"saw": return x * 2.0 - 1.0
		"tri": return 1.0 - 4.0 * absf(x - 0.5)
	return sin(x * TAU)


func _render(layers: Array) -> AudioStreamWAV:
	var length := 0.0
	for L in layers:
		var d: float = L[3] if L[0] == "tone" else L[1]
		var delay: float = L[6] if L[0] == "tone" else L[4]
		length = maxf(length, d + delay + 0.03)
	var n := int(length * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for L in layers:
		if L[0] == "tone":
			var f1: float = L[1]
			var f2: float = L[2]
			var dur: float = L[3]
			var vol: float = L[5]
			var start := int(L[6] * RATE)
			var ph := 0.0
			for i in int(dur * RATE):
				var k := float(i) / (dur * RATE)
				var f := f1 * pow(maxf(f2, 20.0) / f1, k)
				ph += f / RATE
				var env := vol * pow(0.001 / vol, k)
				if start + i < n:
					buf[start + i] += _wave(L[4], ph) * env
		else:
			var dur: float = L[1]
			var vol: float = L[2]
			var a := 1.0 - exp(-TAU * float(L[3]) / RATE)
			var a2 := 1.0 - exp(-TAU * float(L[3]) * 0.4 / RATE)
			var lp := 0.0
			var lp2 := 0.0
			var start := int(L[4] * RATE)
			for i in int(dur * RATE):
				var k := float(i) / (dur * RATE)
				var x := randf() * 2.0 - 1.0
				lp += a * (x - lp)
				lp2 += a2 * (lp - lp2)
				if start + i < n:
					buf[start + i] += (lp - lp2) * 2.5 * vol * pow(1.0 - k, 2)
	return _to_wav(buf, false)


func _render_loop() -> AudioStreamWAV:
	var n := RATE / 4
	var buf := PackedFloat32Array()
	buf.resize(n)
	var ph := 0.0
	for i in n:
		ph += 120.0 / RATE
		buf[i] = _wave("saw", ph) * 0.12
	return _to_wav(buf, true)


func _to_wav(buf: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w


func play(name: String) -> void:
	if not Store.settings.sound or not clips.has(name):
		return
	var p := pool[_next]
	_next = (_next + 1) % pool.size()
	p.stream = clips[name]
	p.play()


func vibrate(ms: int) -> void:
	if Store.settings.sound:
		Input.vibrate_handheld(ms)


func charge_start() -> void:
	if Store.settings.sound and not charge_player.playing:
		charge_player.pitch_scale = 1.0
		charge_player.play()


func charge_level(p: float) -> void:
	if charge_player.playing:
		charge_player.pitch_scale = 1.0 + p * 4.3
		charge_player.volume_db = -6.0 + p * 6.0


func charge_stop() -> void:
	charge_player.stop()
