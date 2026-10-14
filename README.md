# Mark Dave's Night Division: Dilim ng Maynila (Godot)

The Godot 4.5 version of Night Division. It's a phone rail shooter played with your hand: stand the phone upright, and the front camera tracks your hand natively through a small Android plugin running MediaPipe.

## Controls

| Action | Camera | Touch |
|---|---|---|
| Aim | Point your index finger | Touch the screen |
| Spirit Gun shot | Drop your thumb | Tap |
| Spirit Blast | Keep your thumb down until the ring fills, then lift | Press and hold, then let go |
| Recharge | Move your hand out of view | Tap Recharge |
| Switch weapon | Hold up an open palm until the ring fills | Tap GUN / KNIFE / FIST |
| Spirit Knife | Swipe your hand fast across ghouls (thumb drop stabs) | Swipe, or tap to stab |
| Spirit Punch | Punch toward the camera (or drop your thumb) | Tap |

## Chapter 1: The Blackout

| # | Mission | Boss |
|---|---|---|
| 1 | Command Post (tutorial) | Archive Kapre |
| 2 | Quiapo Night Market | Manananggal |
| 3 | LRT Tunnels | Ghost Train |
| 4 | Pasig Drainage | Bakunawa Spawn |
| 5 | Colonial Crypts | Santelmo Knight |
| 6 | The Lumen Beacon | General Vex (final) |

There's also a Practice Range with endless ghouls or a boss rush.

## Project layout

```
android-plugin/          native HandTracker plugin (Kotlin, MediaPipe + CameraX)
game/project.godot       Godot project (autoloads: View, Store, Sfx, Hand)
game/scripts/main.gd     menus, story player, case map, briefings, results, settings
game/scripts/game.gd     mission runner: weapons, target lock, scoring, effects, HUD
game/scripts/ents.gd     ghouls, students, training targets, boss projectiles
game/scripts/bosses.gd   the six bosses
game/scripts/missions.gd mission scripts (data)
game/scripts/story.gd    prologue and epilogue
game/scripts/view.gd     perspective and level backdrops
game/scripts/hand.gd     hand gestures and touch input
game/scripts/sfx.gd      synthesized sound effects
game/scripts/pen.gd      drawing helpers
.github/workflows/build-apk.yml   builds the plugin and APK, publishes the apk-latest release
```
