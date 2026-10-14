class_name Story
extends RefCounted
## Prologue and epilogue, shown as visual-novel pages. {name} becomes the officer name from Settings.
## scene: "keyart" (title art) or any level backdrop name (records, market, tunnel, drain, crypt, beacon).

const CAPTAIN := "Capt. Lira Santos"
const KIKO := "Kiko"
const MAYA := "Maya"

const PROLOGUE := [
	{"scene": "keyart", "who": "", "text": "For centuries, Manila has lived in a delicate balance."},
	{"scene": "market", "who": "", "text": "Above is the Overworld, Maynila: a dense, noisy sprawl of concrete, jeepneys, neon and millions of lives."},
	{"scene": "records", "who": "", "text": "Below lies the Ilalim, a parallel world of shadow. It holds the oldest fears of Philippine folklore, creatures that grew up alongside us until they were pushed out of the light."},
	{"scene": "keyart", "who": "", "text": "To keep the peace, a vast spiritual-engineering grid was built deep in the old foundations of the city: the Lumen Beacon. For a hundred years its light held the Veil tight, and the monsters of old became urban legends."},
	{"scene": "keyart", "who": "", "text": "In a mountain barangay in Quezon province, a boy named {name} was born with strange spirit-sight. His spirit energy gathered in one place: the tip of his index finger."},
	{"scene": "keyart", "who": "", "text": "At twelve, a kapre reached for him under a sacred balete tree. He pointed in pure terror, and a beam of spirit fire burned through the creature's core."},
	{"scene": "keyart", "who": CAPTAIN, "text": "Word of a boy with a natural spirit gun reached me in Manila. I command the Night Division, a classified unit that handles what ordinary soldiers can't."},
	{"scene": "records", "who": CAPTAIN, "text": "Three nights ago, the Lumen Beacon went dark. Sabotaged from inside. A choking fog rolled over the city, and the Ilalim broke through."},
	{"scene": "market", "who": CAPTAIN, "text": "Tiyanak riding on innocent people. Wakwak swarms on the power lines. Kapre in the alleys. Some say there are manananggal sitting in city hall."},
	{"scene": "records", "who": KIKO, "text": "Kiko. Heavy weapons, crowd control. You point at it, I make it go away. Welcome to the squad, rookie."},
	{"scene": "records", "who": MAYA, "text": "Maya. I work up close with spirit-forged bolos. Your finger gun won't always be charged, {name}. I'll teach you to fight without it."},
	{"scene": "keyart", "who": CAPTAIN, "text": "{name}, you have the strongest spirit-sight this division has seen in thirty years. Someone turned off the light over Manila. Find out who."},
	{"scene": "records", "who": CAPTAIN, "text": "Start right here. Something has broken into the command post archive beneath Intramuros. Let's see what you can do."},
]

const EPILOGUE := [
	{"scene": "beacon", "who": "", "text": "Beneath Intramuros, the Lumen Beacon shudders. A crack of white light. Then another. Then the whole crystal roars back to life."},
	{"scene": "beacon", "who": "", "text": "A wave of brilliant energy rolls out through the tunnels, the drains and the old streets, driving every last creature back into the Ilalim. The Veil seals tight."},
	{"scene": "keyart", "who": "", "text": "Dawn breaks over Maynila. Jeepneys honk, vendors open their stalls, and the city wakes up noisy and alive, with no idea how close it came to the end."},
	{"scene": "keyart", "who": KIKO, "text": "Rookie went and saved the whole city on his first week. I'm never living this down."},
	{"scene": "keyart", "who": MAYA, "text": "Not bad, {name}. Next time, try not to need a building-sized flashlight to win."},
	{"scene": "keyart", "who": CAPTAIN, "text": "The watch is over, for now. Get some sleep, all of you. As long as night falls, Night Division will be ready."},
	{"scene": "beacon", "who": "", "text": "Deep in the Ilalim, a lone figure watches the light return. He smiles, and fades back into the dark. Who was he?"},
]
