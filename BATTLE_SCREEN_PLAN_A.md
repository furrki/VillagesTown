# Battle Screen — Plan A ("Watch the Report")

**Project:** VillagesTown (`/Users/appgea/Desktop/projects/appgea-apps/VillagesTown`)
**Status of this doc:** next-step implementation plan. Phase 0 below is DONE. Phases 1+ are TODO.
**For the executing agent:** read this whole file first. The combat engine is the single
source of truth — do NOT build a second combat system or let the screen decide outcomes.

---

## Direction (the rule that governs every decision)

The screen is a **cinematic replay of an already-decided battle**, ending on a **result card**.
This is camp **A** ("watch the report", like Rise of Kingdoms / Clash of Clans replay), chosen
deliberately over camp B ("you command", like Total War).

Consequences — keep these true:
- The winner and all casualties come from `BattleRecord` (produced by the engine). The screen
  only *visualizes* them. `record.attackerWon` is law.
- No in-battle lever may change the result. Formation choice etc. happens **before** the march,
  as input to the engine, never as live control during the replay.
- AI-vs-AI battles resolve through the same engine and are never shown — don't add screen-only
  logic that the engine doesn't also apply.

---

## Phase 0 — DONE (already shipped, analyzer-clean)

Real two-phase combat + stat-driven visuals + flag raise. Files touched:

- `lib/data/models/combat_log.dart` — added `BattleEngagement` (per-phase start/survivor/winner)
  and `BattleRecord.engagements` + getters `fieldEngagement`, `cityEngagement`, `hasCityAssault`.
- `lib/engines/combat_engine.dart` — `resolveCombat` now resolves **field battle** (army vs
  mobile defenders) then, if attackers survive, **city assault** (survivors vs garrison +
  fortress). Fortress bonus now applies to garrison only. Populates `engagements`.
- `lib/ui/screens/battle/battle_simulation.dart` — REWRITTEN. New `BattlePhase` enum
  (`formationSelect, setup, field, advance, cityAssault, flagRaise, victory, defeat`). Deaths are
  now chosen by **front-line proximity** (front rank dies first, rear archers survive), converging
  to the engine's per-phase survivor counts. Drives `cityProgress` (scene morph) and
  `flagRaiseProgress`.
- `lib/ui/screens/battle/battlefield_painter.dart` — city-interior morph (houses close in) + gate
  flagpole that lowers the defender banner and raises the conqueror's.
- `lib/ui/screens/battle/battle_painter.dart` — phase refs updated to `simulation.isFighting`.
- `lib/ui/screens/battle/countryball_battle_screen.dart` — builds 3 unit pools (attacker / field
  defenders / garrison), passes phase progress to painters, phase-aware HUD, and `_endBattle` now
  applies the FULL result on a watched battle (so conquest fires).
- `lib/ui/components/owner_flag_view.dart` — animates the map flag swap on ownership change.

### Key facts the next agent MUST know (gotchas)
- `record.initialDefenderCount` **already includes** the garrison. Field defenders =
  `initialDefenderCount - initialGarrisonCount`. (The old screen double-counted; fixed.)
- `BattleRecord.rounds` / `phases` carry TOTAL casualties (used by `GameManager.finalizeBattle`).
  `engagements` carries the field/city split used by the visual layer.
- `finalizeBattle(record, roundsPlayed, retreated)` in `lib/engines/game_manager.dart` applies
  casualties + triggers `_conquerVillage` (which changes `village.owner` → drives the map flag).
  `_endBattle` passes `record.rounds.length` on a completed battle, `currentRound` on retreat.
- The live screen is `CountryballBattleScreen`, mounted from
  `lib/ui/screens/game_view_mobile.dart` (~line 196, `_getPlayerBattle`). The old dice
  `BattleScreen` (`lib/ui/screens/battle_screen.dart`) is DEAD — ignore it.
- `lib/ui/screens/battle/battle_test_screen.dart` is a dev harness that drives the sim directly;
  keep it compiling when you change `BattlePhase` or the `BattleSimulation` constructor.

---

## Phase 1 — Must-have (makes it feel like a familiar mobile battle)

### 1.1 Result card (highest value — the payoff screen)
**Goal:** the replay ends on a stat card, not a bare button. This is what RoK/CoC users wait for.
**Where:** new widget, shown when `simulation.phase == victory || defeat` inside
`CountryballBattleScreen` (replace/augment the current `_buildControls` end state).
**Content:**
- Big outcome banner: `CITY CAPTURED` / `ATTACK REPELLED` / `VICTORY` / `DEFEAT` (player POV).
- Per-side casualties: started → survived (use `record.engagements` for field vs city breakdown,
  or totals via `record.totalAttackerLosses` / `totalDefenderLosses`).
- If a city was taken: garrison before→after, and **your flag now flying** (reuse `OwnerFlagView`
  / the gate banner art).
- Score/loot line if available (check `GameManager` for battle rewards; if none, omit — don't invent).
- Single CTA: `CLAIM` → calls existing `_endBattle()`.
**Acceptance:** every battle (field win/loss, siege win/loss, retreat) ends on a correct card;
numbers match the engine; `flutter analyze` clean.

### 1.2 Speed controls (1× / 2× / Skip)
**Goal:** standard auto-battler pacing controls.
**Where:** `CountryballBattleScreen` controls row + a speed multiplier consumed in `_tick`
(scale `dt`). `Skip` already exists (`simulation.skipToEnd()`) — keep it; jump straight to the
result card. Default the replay faster than today (current fighting phase ≈11s each; aim ~6s at 1×).
**Acceptance:** 1×/2× visibly change pace; Skip lands on the result card with correct state.

### 1.3 Pre-battle Scout / Confirm screen
**Goal:** decide BEFORE marching. Move formation/terrain/engagement pickers here (they're engine
inputs, not live controls). Familiar "march confirm" pattern.
**Where:** the existing `formationSelect` phase UI in `CountryballBattleScreen`
(`_buildFormationSelection`) is most of this already — reframe it as a "Scout Report": power bar,
enemy composition (respect current fog rules — enemy comp is hidden until in battle), then
`MARCH` / `CANCEL`. `CANCEL` should abort without resolving (needs a path back; check how the
battle is queued in `pendingBattles` / `travel_panel.dart`).
**Acceptance:** player can back out before committing; pickers no longer appear mid-replay.

### 1.4 Drop dice/round vocabulary
**Goal:** mobile users expect troop counts ticking down + a moving power bar, not dice.
**Where:** remove leftover dice getters/labels in `battle_simulation.dart` (`currentRound`,
`attackerLossesThisRound`, etc. — keep only what the HUD needs) and any "round" text in the screen.
Make the **power-balance bar move live** during the replay (it's currently mostly static).
**Acceptance:** no dice/round wording on screen; power bar shifts as troops fall.

---

## Phase 2 — High-value (sells the fantasy)

### 2.1 Top-down city assault
**Goal:** switch camera for the `cityAssault` phase to a top-down street grid (Clash-of-Clans
mental model) — troops pour through the gate, defenders on the walls fire down before the breach.
Different framing = brain instantly knows "we're inside now" and hard-sells the two-phase split.
**Where:** a second painter / layout mode keyed off `phase == cityAssault`. Field phase stays
side-on. Reuse `BattleCircle` positions but remap to a top-down arena; gate at one edge.
**Acceptance:** field looks side-on; city looks top-down; transition (`advance` phase) reads as
moving through the gate.

### 2.2 Cinematic juice (3 beats + slow-mo)
**Goal:** camera punch-ins on **cavalry charge**, **gate breach**, **flag raise**; slow-mo the
flag raise (it's the money shot — make it big). Use the existing `_zoomController` / shake.
**Acceptance:** the three beats land; flag raise is the visual climax.

### 2.3 Sound (use the `elevenlabs-audio` CLI tool)
**Goal:** clash loop, charge horn, gate boom, crowd cheer on flag raise, defeat sting. Audio is a
huge familiarity multiplier for cheap.
**Where:** generate SFX → `assets/audio/`, wire an audio player at phase transitions.
**Acceptance:** each phase/beat has a cue; respects a mute setting if one exists.

---

## Phase 3 — Polish (memorable identity)

### 3.1 Countryball faces = morale
Give the balls a face whose expression tracks `morale` (confident → nervous → routing). Leans into
the Polandball familiarity; cheap and memorable. Edit `battle_painter.dart` `_drawCircle`.

### 3.2 Defender framing
When `isPlayerAttacker == false`, open with "⚔️ [City] is under siege!" and a defender-POV HUD
instead of the neutral watch view.

---

## Suggested execution order
1.4 (cleanup) → 1.1 (result card) → 1.2 (speed) → 1.3 (scout) → 2.1 (top-down city) →
2.2 (juice) → 2.3 (sound) → 3.1 (faces) → 3.2 (defender framing).

Ship 1.x first — that alone makes it feel familiar. 2.x/3.x are the "wow".

## Definition of done (per item)
- `flutter analyze` clean (don't add new warnings; 11 pre-existing in `polygon_editor`/`game_loop`
  are not yours).
- Manually verify: a field win, a field loss, a siege that wins on the field then the city, a siege
  lost at the walls, and a retreat — all show correct numbers and the right end card.
- Don't run `pod install` / device builds; ask the human to run those.
