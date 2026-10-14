class_name Missions
extends RefCounted
## Missions are pure data. Each step can have:
##   title (stage banner), say ([[speaker, text], ...]), hint (String or {camera, touch}), advance (walk forward first),
##   energy (set 0-6), spawns ([{type, x, z, delay, ...}]), until ("clear" default, "recharge", "blast", "weapon" + need, "time" + wait, "never").
## Spawn options: x (-1..1), z (0 near..1 far), delay, speed, h, still, drop, tx (slide in to x), dir, armored.
## Bosses: {"type": "boss", "kind": "kapre"|"manananggal"|"ghost_train"|"bakunawa"|"santelmo"|"vex", "x", "z"}.

const L := Story.CAPTAIN
const KIKO := Story.KIKO
const MAYA := Story.MAYA


static func W(x: float, z: float, delay := 0.0, extra := {}) -> Dictionary:
	var d := {"type": "wisp", "x": x, "z": z, "delay": delay}
	d.merge(extra, true)
	return d


static func S(type: String, x: float, z: float, delay := 0.0, extra := {}) -> Dictionary:
	var d := {"type": type, "x": x, "z": z, "delay": delay}
	d.merge(extra, true)
	return d


static func chapter() -> Array:
	return [command_post(), quiapo(), lrt(), pasig(), crypts(), beacon()]


static func command_post() -> Dictionary:
	return {"id": "c1m1", "num": 1, "title": "Command Post", "place": "Beneath Intramuros", "scene": "records", "start_weapon": "gun",
		"case_no": "Case 001", "case_name": "The Restless Archive",
		"brief": "Night Division's command post is hidden in the old tunnels beneath Intramuros. Since the Beacon went dark, something has been rifling through the archive at night. Train with your squad, then clear the intruders out of your own home base.",
		"objectives": ["Train with the Spirit Gun, Spirit Knife and Spirit Punch", "Free a possessed clerk without hurting anyone", "Defeat the Archive Kapre"],
		"steps": [
			{"title": "Command Post", "say": [[L, "Santos here, {name}. Welcome to the Night Division."], [L, "Warm up on these training lanterns first."]],
				"hint": {"camera": "Point your finger gun at a lantern and drop your thumb to shoot", "touch": "Tap a lantern to shoot"},
				"spawns": [S("lantern", -0.45, 0.45), S("lantern", 0, 0.6, 0.3), S("lantern", 0.45, 0.45, 0.6)]},
			{"say": [[L, "Your spirit energy is empty. The bar on the left is your ammo."]], "energy": 0, "until": "recharge",
				"hint": {"camera": "Move your hand out of the camera view, then bring it back", "touch": "Tap Recharge"}},
			{"say": [[L, "These lanterns are warded. Regular shots won't break them. You need a Spirit Blast."]], "energy": 6, "until": "blast",
				"hint": {"camera": "Keep your thumb down until the ring fills, then lift it to fire a Spirit Blast", "touch": "Press and hold until the ring fills, then let go"},
				"spawns": [S("lantern", 0, 0.3, 0, {"armored": true, "h": 0.7}), S("lantern", 0, 0.55, 0, {"armored": true, "h": 1.3}), S("lantern", 0, 0.85, 0, {"armored": true, "h": 2.0})]},
			{"say": [[MAYA, "Maya here. Energy runs out, {name}. When it does, you fight up close."], [MAYA, "Switch to the Spirit Knife."]], "need": "knife", "until": "weapon",
				"hint": {"camera": "Hold your hand up with an open palm until the ring fills to switch weapons", "touch": "Tap the dagger at the top to switch weapons"}},
			{"say": [[MAYA, "Good. The blade only reaches close targets, so let them come to you. Then swipe fast."]],
				"hint": {"camera": "Swipe your hand quickly across the lanterns", "touch": "Swipe your finger quickly across the lanterns"},
				"spawns": [S("lantern", -0.35, 0.32, 0, {"h": 0.9}), S("lantern", 0, 0.34, 0.2, {"h": 1.0}), S("lantern", 0.35, 0.32, 0.4, {"h": 0.9})]},
			{"say": [[KIKO, "Kiko here. Bolos are nice. Fists are better."], [KIKO, "Switch to the Spirit Punch."]], "need": "punch", "until": "weapon",
				"hint": {"camera": "Open your palm and hold it again to switch", "touch": "Tap the fist at the top"}},
			{"say": [[KIKO, "Now throw a punch at the screen. It hits hard and knocks ghouls back."]],
				"hint": {"camera": "Punch toward the camera (or drop your thumb) while aiming at a lantern", "touch": "Tap a lantern to punch it"},
				"spawns": [S("lantern", -0.3, 0.38, 0, {"h": 1.0}), S("lantern", 0.3, 0.38, 0.3, {"h": 1.0})]},
			{"say": [[L, "Use whatever fits the moment. Back to the Spirit Gun for now."]], "need": "gun", "until": "weapon",
				"hint": {"camera": "Open your palm to cycle back to the Spirit Gun", "touch": "Tap the finger gun at the top"}},
			{"say": [[L, "Careful. A Tiyanak has latched onto one of our clerks. Shoot the creature on her head, never the person."]], "energy": 6,
				"hint": "Free the possessed clerk. Do not hit the janitor.",
				"spawns": [S("civilian", 1.3, 0.5, 0, {"dir": -1.0, "speed": 0.17}), S("possessed", -1.3, 0.32, 1.2, {"dir": 1.0, "speed": 0.15})]},
			{"say": [[L, "Here they come. Wakwak dive straight at you. Kapre are only solid part of the time."], [L, "And the cute ones are Aswang in disguise. Two hits."]],
				"hint": "Clear the archive. Switch weapons whenever you like",
				"spawns": [W(-0.3, 0.9), W(0.4, 0.95, 1.5), S("phantom", 0, 0.85, 3), W(-0.5, 0.9, 4.5), W(0.5, 0.9, 5.5), S("dino", 0.2, 0.9, 6.5)]},
			{"title": "BOSS: Archive Kapre", "advance": true, "energy": 6,
				"say": [[L, "Something big is in the deep stacks. A Kapre, and it's smoking up the whole archive."], [KIKO, "Shoot the smoke rings before they reach you!"]],
				"hint": "Shoot its smoke rings out of the air. Use blade or fist when it steps close",
				"spawns": [S("boss", 0, 0.65, 0, {"kind": "kapre"})]},
			{"say": [[L, "Archive is clear. Every file they tore open was about the Beacon."], [L, "Get some air, {name}. Quiapo is crawling with them."]], "until": "time", "wait": 8.0},
		]}


static func quiapo() -> Dictionary:
	return {"id": "c1m2", "num": 2, "title": "Quiapo Night Market", "place": "Quiapo", "scene": "market",
		"case_no": "Case 002", "case_name": "Fog Over Quiapo",
		"brief": "The night market around Quiapo never really closes, not even in the fog. Wakwak are circling the power lines, and shoppers are wandering off with Tiyanak clinging to their heads. Kiko and Maya are holding the perimeter. You go in.",
		"objectives": ["Clear the Wakwak without hitting civilians", "Free every shopper ridden by a Tiyanak", "Bring down the Manananggal"],
		"steps": [
			{"title": "Quiapo", "say": [[L, "Wakwak in the market, {name}. Civilians are still out. Watch your fire."], [KIKO, "Perimeter's locked. Nothing gets out of the market past me."]],
				"spawns": [W(-0.4, 0.95, 1), W(0.3, 0.95, 2.2), W(0, 0.9, 3.5), W(-0.6, 0.85, 4.2), W(0.6, 0.9, 5.5)]},
			{"title": "Food Stalls", "advance": true, "say": [[MAYA, "Shoppers ahead with Tiyanak on their heads. Free them. And that cute little dino isn't cute. It's an Aswang."]],
				"spawns": [S("civilian", -1.3, 0.55, 0, {"dir": 1.0}), S("possessed", 1.3, 0.4, 0.8, {"dir": -1.0}), W(-0.5, 0.5, 2, {"drop": true}), W(0.5, 0.55, 3.2, {"drop": true}),
					S("possessed", -1.3, 0.3, 4.5, {"dir": 1.0}), S("civilian", 1.3, 0.35, 5.5, {"dir": -1.0}), W(0, 0.6, 6.5, {"drop": true}), S("dino", -0.3, 0.95, 7.5)]},
			{"title": "Alley of Lanterns", "advance": true, "say": [[L, "Kapre in the alley. Wait for them to turn solid, then hit them twice."], [KIKO, "That caterpillar with the camera is an Aswang too. Three hits."]],
				"spawns": [S("phantom", -0.35, 0.9), W(-1.4, 0.45, 1.5, {"tx": -0.5}), S("phantom", 0.35, 0.95, 3), W(1.4, 0.45, 4, {"tx": 0.5}), S("phantom", 0, 0.9, 6), W(-1.4, 0.35, 7, {"tx": -0.3}), S("grub", 0.3, 0.95, 8)]},
			{"title": "BOSS: Manananggal", "advance": true, "energy": 6,
				"say": [[L, "Plaza Miranda. The fog is thickest here. Something's up on the rooftops."], [MAYA, "Manananggal! When she dives, hit her before she lands!"]],
				"hint": "Hit her during her dive to knock her back. Shoot down the Wakwak she sends",
				"spawns": [S("boss", 0, 0.62, 0, {"kind": "manananggal"}), S("civilian", -1.3, 0.4, 3, {"dir": 1.0})]},
			{"say": [[L, "Quiapo is quiet. Good work, {name}."], [MAYA, "Captain, she dropped this. A Katipunero insignia. Real, and more than a hundred years old."], [L, "Then this is bigger than ghouls. The fog is sinking into the LRT tunnels. That's where we go next."]], "until": "time", "wait": 10.0},
		]}


static func lrt() -> Dictionary:
	return {"id": "c1m3", "num": 3, "title": "LRT Tunnels", "place": "Underground line", "scene": "tunnel",
		"case_no": "Case 003", "case_name": "The Last Trip",
		"brief": "The trains stopped running at midnight. One of them did not get the message. Commuters were stranded underground when the fog rolled in, and something is riding the rails toward Intramuros.",
		"objectives": ["Escort stranded commuters out safely", "Clear the Kapre from the tunnels", "Stop the Ghost Train"],
		"steps": [
			{"title": "Station Platform", "say": [[L, "Stranded commuters on the platform, {name}. Some of them have riders."], [KIKO, "I'll get the free ones to the exit. You handle the Tiyanak."]],
				"spawns": [S("civilian", -1.3, 0.45, 0, {"dir": 1.0}), S("possessed", 1.3, 0.35, 1, {"dir": -1.0}), W(-0.3, 0.95, 2), S("possessed", -1.3, 0.5, 3.5, {"dir": 1.0}), W(0.4, 0.9, 4.5), S("civilian", 1.3, 0.3, 5, {"dir": -1.0}), S("dino", 0, 0.95, 6.5)]},
			{"title": "Into the Tunnel", "advance": true, "say": [[MAYA, "Kapre in the dark. They blend into the walls, so watch for the eyes."]],
				"spawns": [S("phantom", -0.3, 0.9), S("phantom", 0.35, 0.95, 2), W(0, 0.6, 3, {"drop": true}), S("grub", -0.3, 0.95, 4.5), W(0.5, 0.9, 5.5), S("phantom", 0, 0.9, 7), W(-0.5, 0.9, 8)]},
			{"title": "Junction", "advance": true, "say": [[L, "Junction ahead. Swarm incoming from both lines."]],
				"spawns": [W(-1.4, 0.45, 0, {"tx": -0.5}), W(1.4, 0.45, 0.6, {"tx": 0.5}), S("dino", -0.3, 0.95, 1.5), S("dino", 0.3, 0.95, 3), W(0, 0.95, 4), W(-0.4, 0.95, 4.6), W(0.4, 0.95, 5.2), S("grub", 0, 0.95, 6.5)]},
			{"title": "BOSS: Ghost Train", "advance": true, "energy": 6,
				"say": [[KIKO, "Lights in the tunnel. That's not a normal train!"], [L, "Shoot out both headlights before it reaches you. It will come back faster each time."]],
				"hint": "Destroy both headlights to derail it. A Spirit Blast takes out both at once",
				"spawns": [S("boss", 0, 1.15, 0, {"kind": "ghost_train"})]},
			{"say": [[L, "The train is gone. And look where the rails lead: straight under the Pasig."], [MAYA, "Into the old drainage tunnels. Something is moving toward Intramuros through the water."]], "until": "time", "wait": 9.0},
		]}


static func pasig() -> Dictionary:
	return {"id": "c1m4", "num": 4, "title": "Pasig Drainage", "place": "Flooded tunnels", "scene": "drain",
		"case_no": "Case 004", "case_name": "Under the River",
		"brief": "The colonial-era drainage tunnels under the Pasig River are flooding with water that glows faintly green. Aswang are nesting in the pipes, and something big is swimming upstream toward Intramuros.",
		"objectives": ["Wade through the flooded tunnels", "Clear the Aswang nests", "Defeat the Bakunawa Spawn"],
		"steps": [
			{"title": "Flooded Entrance", "say": [[MAYA, "Water is up to our knees. Stay sharp, {name}. Things fall from the pipes."]],
				"spawns": [W(-0.4, 0.5, 0.5, {"drop": true}), W(0.4, 0.55, 1.5, {"drop": true}), S("grub", 0, 0.95, 2.5), W(-0.2, 0.6, 4, {"drop": true}), W(0.3, 0.6, 5, {"drop": true}), S("dino", 0.4, 0.95, 6)]},
			{"title": "Aswang Nest", "advance": true, "say": [[KIKO, "Nest up ahead. Lots of them. This is punching territory."], [L, "Don't let them swarm you."]],
				"spawns": [S("dino", -0.4, 0.9), S("dino", 0.4, 0.95, 1), S("grub", 0, 0.95, 2.5), S("dino", -0.2, 0.95, 4), S("grub", 0.4, 0.95, 5.5), W(-0.5, 0.9, 6), W(0.5, 0.9, 6.5), S("dino", 0.1, 0.95, 8)]},
			{"title": "Spillway", "advance": true, "say": [[L, "Kapre in the spillway. And a trapped maintenance worker. Get him out clean."]],
				"spawns": [S("phantom", -0.3, 0.9), S("possessed", 1.3, 0.4, 1, {"dir": -1.0}), S("phantom", 0.4, 0.95, 3), W(0, 0.55, 4, {"drop": true}), S("grub", -0.3, 0.95, 5.5), S("phantom", 0, 0.9, 7)]},
			{"title": "BOSS: Bakunawa Spawn", "advance": true, "energy": 6,
				"say": [[MAYA, "The water's moving. Something huge is under there."], [L, "A Bakunawa hatchling. The old moon-eater's young. Hit it when it surfaces!"]],
				"hint": "Watch the ripples. Hit its head while it is above the water",
				"spawns": [S("boss", 0, 0.55, 0, {"kind": "bakunawa"})]},
			{"say": [[L, "It is down. The tunnels end at the old church crypts."], [KIKO, "Captain, there's writing on the crypt walls. Same name, over and over: Vex."]], "until": "time", "wait": 9.0},
		]}


static func crypts() -> Dictionary:
	return {"id": "c1m5", "num": 5, "title": "Colonial Crypts", "place": "Beneath the old churches", "scene": "crypt",
		"case_no": "Case 005", "case_name": "The Name on the Walls",
		"brief": "Under Intramuros lie centuries-old Spanish crypts. Someone has been carving one name on every wall: Vex. General Apolinario \"Pule\" Vex was a revolutionary-era commander who should have died over a century ago. Find out what he wants.",
		"objectives": ["Search the crypts", "Survive the guardians of the dead", "Defeat the Santelmo Knight"],
		"steps": [
			{"title": "Ossuary", "say": [[L, "Candles are lit down here. Nobody has been in these crypts for a hundred years."], [MAYA, "Someone has now."]],
				"spawns": [S("phantom", -0.3, 0.9), W(0.3, 0.95, 1.5), W(-0.4, 0.9, 2.5), S("phantom", 0.35, 0.95, 4), S("dino", 0, 0.95, 5.5), W(0.5, 0.9, 6.5)]},
			{"title": "Hall of Names", "advance": true, "say": [[KIKO, "Vex, Vex, Vex. Carved into every stone."], [L, "Vex believes the Ilalim and our world were split by a colonial mistake. He wants to merge them. A Philippines full of monsters, under his command."]],
				"spawns": [S("grub", -0.35, 0.95), S("grub", 0.35, 0.95, 2), W(0, 0.6, 3, {"drop": true}), S("phantom", 0, 0.9, 4.5), S("dino", -0.4, 0.95, 6), S("dino", 0.4, 0.95, 7)]},
			{"title": "Chapel of Candles", "advance": true, "say": [[MAYA, "A caretaker is down here. With a rider. And the whole room is moving."]],
				"spawns": [S("possessed", -1.3, 0.4, 0, {"dir": 1.0}), W(-0.5, 0.9, 1), W(0.5, 0.9, 1.6), S("phantom", 0, 0.95, 3), S("grub", 0.3, 0.95, 4.5), W(-1.4, 0.4, 5.5, {"tx": -0.5}), W(1.4, 0.4, 6, {"tx": 0.5}), S("dino", 0, 0.95, 7.5)]},
			{"title": "BOSS: Santelmo Knight", "advance": true, "energy": 6,
				"say": [[L, "Empty armor, held together by santelmo flames. Vex left a guard."], [KIKO, "Put out the flames and the shell falls apart!"]],
				"hint": "Shoot the orbiting flames, then hit the armor while he kneels",
				"spawns": [S("boss", 0, 0.55, 0, {"kind": "santelmo"})]},
			{"say": [[L, "The crypts open into the Beacon chamber."], [L, "This is it, {name}. Vex is down there, and dawn is less than an hour away."]], "until": "time", "wait": 8.0},
		]}


static func beacon() -> Dictionary:
	return {"id": "c1m6", "num": 6, "title": "The Lumen Beacon", "place": "Beneath Intramuros", "scene": "beacon", "epilogue": true,
		"case_no": "Case 006", "case_name": "Dawn Over Maynila",
		"brief": "General Vex has begun the final ritual to merge the Overworld and the Ilalim at the base of the dead Beacon. Kiko and Maya will hold the entrance. You go to the crystal. Standard weapons shatter against his shadow armor, but a Spirit Blast might not.",
		"objectives": ["Fight through to the Beacon", "Break Vex's shadow armor with Spirit Blasts", "Relight the Lumen Beacon before dawn"],
		"steps": [
			{"title": "The Outer Ring", "say": [[KIKO, "We'll hold the doors. Go!"], [MAYA, "Come back in one piece, {name}."]],
				"spawns": [W(-0.5, 0.95), W(0.5, 0.95, 0.5), S("dino", 0, 0.95, 1.5), S("phantom", -0.35, 0.9, 3), S("grub", 0.35, 0.95, 4), W(-1.4, 0.4, 5, {"tx": -0.5}), W(1.4, 0.4, 5.5, {"tx": 0.5}), S("phantom", 0.3, 0.9, 7)]},
			{"title": "The Ritual Circle", "advance": true, "say": [[L, "He has bound people to the ritual. Free them and the merging slows down."]],
				"spawns": [S("possessed", -1.3, 0.45, 0, {"dir": 1.0}), S("possessed", 1.3, 0.35, 1.5, {"dir": -1.0}), S("dino", -0.3, 0.95, 2.5), S("dino", 0.3, 0.95, 3.5), S("possessed", -1.3, 0.3, 5, {"dir": 1.0}),
					S("grub", 0, 0.95, 6), W(0, 0.6, 7, {"drop": true}), W(-0.4, 0.6, 7.5, {"drop": true}), W(0.4, 0.6, 8, {"drop": true})]},
			{"title": "FINAL BOSS: General Vex", "advance": true, "energy": 6,
				"say": [[L, "There he is. General Apolinario \"Pule\" Vex."], [L, "Your shots will shatter on that armor. Charge a Spirit Blast, {name}. Everything you have."]],
				"hint": "Spirit Blast to break his armor, then hit him with everything while it is down",
				"spawns": [S("boss", 0, 0.6, 0, {"kind": "vex"})]},
			{"say": [[L, "He is gone. The Beacon is answering you, {name}."], [L, "Look at it. The light is coming back."]], "until": "time", "wait": 7.0},
		]}


static func practice(mode: String) -> Dictionary:
	return {"id": "practice", "num": 0, "title": "Practice Range", "place": "Training hall", "scene": "records", "practice": mode,
		"case_no": "Training", "case_name": "Practice Range",
		"brief": "No lives, no score pressure. Endless ghouls to practice aiming, recharging and switching weapons, or a boss rush through every boss you will face. Pause and quit when you are done.",
		"objectives": ["Try every weapon", "Practice the Spirit Blast and weapon switching", "Stay as long as you like"],
		"steps": [{"title": "Practice Range", "say": [[L, "Take your time, {name}. Nothing here can hurt you for real."]], "until": "never"}]}
