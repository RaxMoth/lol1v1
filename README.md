# [GAME_TITLE] — Godot Project Brief

> **1v1 MOBA | Top-Down Isometric | Godot 4.x (latest stable)**

---

## 🎯 Project Vision

A distilled, head-to-head MOBA experience inspired by **League of Legends**, stripped to its purest competitive form: one lane, two players, every decision matters. Matches run **15-20 minutes**, with a pre-game loadout system replacing in-match shopping, champions built around **hard-designed archetypes** for natural counter-play, and dual win conditions (Nexus or 100 minion kills) that keep every second of the game meaningful. Designed to scale from 1v1 to 2v2 on the same map.

---

## 🏗️ Engine & Technical Stack

| Setting                  | Value                                                                                 |
| ------------------------ | ------------------------------------------------------------------------------------- |
| Engine                   | Godot 4.x (latest stable)                                                             |
| Language                 | GDScript (primary)                                                                    |
| Perspective              | Top-down isometric                                                                    |
| Platform Target          | PC (Windows / Linux / macOS) — Mobile (iOS / Android) eventually                      |
| Controls                 | Mouse + Keyboard (LoL-style) — Mobile touch controls planned for later                |
| Multiplayer Architecture | Scalable — Local first → Online (Godot High-Level Multiplayer API / ENet / WebSocket) |

---

## 🗺️ Map Design

### Layout — ARAM-inspired, 1v1 adapted

- Single straight lane, visually and structurally inspired by **ARAM (Howling Abyss)**
- Symmetrical — mirrored for both players
- **No recall** (ARAM-style — you fight in the lane)

### Lane Structures (per side)

| Structure   | Count | Notes                                                       |
| ----------- | ----- | ----------------------------------------------------------- |
| Nexus Tower | 1     | Combined structure — defends the base AND is the win target |

> One structure per side. No sequencing, no "unlock" step — destroy the Nexus Tower and you win. It shoots, it has HP, it's the only thing standing between you and victory.

### Jungle Camps (side areas)

- Small mirrored jungle pockets on **both sides of the lane**
- Not a full jungle — more like alcoves off the main lane
- Each side has a small set of neutral monster camps
- Camps respawn on a timer
- Killing camps grants **flat stacks** (+2–3 depending on camp size)

### Minion Spawn

- Waves spawn from each base on a fixed timer
- Path down the single lane toward the enemy Nexus Tower

---

## 🏆 Win Conditions

A player wins by achieving **either** of the following:

| Condition                   | Description                                            |
| --------------------------- | ------------------------------------------------------ |
| **Nexus Tower Destruction** | Destroy the enemy Nexus Tower                          |
| **Minion Milestone**        | Be the first to reach **100 minion kills** (last hits) |

> Stack count and minion kill count are the **same tracker** — farming feeds your economy _and_ your win condition simultaneously. This creates constant pressure: do you back to spend stacks on your next item, or keep farming toward 100?

> In 2v2 mode, the minion milestone scales to **200 kills** (combined team total).

---

## 🧩 Addons

### StateChart (by derKork)

- **Asset:** [`gdstatechart`](https://github.com/derkork/godot-statecharts) — Godot Statecharts addon by derKork
- Used for **champion state machines** (Idle, Moving, Casting, Stunned, Dead, etc.) and minion/camp AI behavior
- Install via Godot Asset Library or manually into `res://addons/godot_state_charts/`
- All champion controllers and minion AI should be built on top of StateChart nodes

> **Agent note:** Enable the addon in Project Settings after install. Use `StateChart` nodes as the backbone for any entity with meaningful state transitions — do not roll a custom state machine from scratch.

---

## ⚙️ Core Gameplay Systems

### 1. Champion System

**10+ unique champions** targeted for v1, built around **hard-designed archetypes** rather than numerical balancing.

#### Balance Philosophy

- Champions are differentiated by **playstyle archetype**, not stat tuning
- A loose **counter triangle** (e.g. Poke beats Tank, Assassin beats Poke, Tank beats Assassin) guides design
- Skill expression comes from mastering _how_ you play your archetype vs the matchup
- Avoid stat-creep balancing — keep power budgets fixed per champion

#### Archetypes (examples)

| Archetype  | Playstyle                                         |
| ---------- | ------------------------------------------------- |
| Poke       | Harass from range, win through chip damage        |
| Burst      | All-in combo, high risk/reward                    |
| Tank       | Sustain pressure, survive and out-trade over time |
| Assassin   | Gap-close, one-shot, escape                       |
| Sustain    | Heal/regen focused, wins long fights              |
| Skirmisher | Short trades, reset potential                     |

#### Ability Resource

- **Cooldowns only** — no mana, no energy
- Skill expression is purely about ability timing, positioning, and matchup knowledge
- Base cooldown lengths are the primary balancing lever per ability

#### Cooldown Reduction (CDR)

- Cooldowns decrease from **two sources**: leveling up an ability, and equipping items with CDR
- **No cap** — players can stack as much CDR as their loadout allows
- This makes CDR a meaningful build decision, especially on burst or poke archetypes
- Base cooldowns per ability should be designed with heavy CDR investment in mind — i.e. balanced around the possibility of near-zero cooldowns at full build

#### Champion Kit

Each champion has:

- Passive
- 3 active abilities (Q, W, E)
- Ultimate (R)
- Fixed base stats tuned to their archetype

#### Champion Select

- **Free pick** — players choose their champion upfront before the match
- Matchmaking is **random** — no knowledge of opponent's pick beforehand
- **Mirror matchups are allowed** — same champion vs same champion is valid
- No ban phase, no draft system

### 2. Minion Waves

- **6 minions per wave** — 4 melee, 2 ranged (caster)
- Waves spawn every **45 seconds** from each base
- Minions path down the lane, attack enemy minions and structures automatically
- Killing a minion (last hit) grants **+1 stack**
- Waves **scale over time** — increasing HP and damage as the match progresses, creating natural urgency

### 3. Nexus Tower

- **One Nexus Tower per side** — single combined structure, no separate tower and nexus
- Positioned at the back of each side's base
- Acts as both the **defensive turret** (attacks enemies in range) and the **win objective**
- Targeting priority: Minions → Champions
- **Classic LoL tower aggro** — attacking an enemy champion under it causes it to immediately target you
- Diving is **painful but doable** — requires minion cover or burst damage
- **Destroying the Nexus Tower ends the match immediately** — no stacks awarded, game over

### 4. Stack Economy (replaces gold entirely)

Gold and component items are removed. The economy is built around a single resource: **Stacks**.

#### How Stacks Work

| Source                 | Stacks Earned                                     |
| ---------------------- | ------------------------------------------------- |
| Minion kill (last hit) | +1 stack                                          |
| Jungle camp kill       | +2–3 stacks (reward for the risk of leaving lane) |
| Champion kill          | +5 stacks (tentative)                             |

#### Starting Conditions

- Every player starts with **0 stacks, no items** — completely clean slate
- No starter item, no free advantage — pure skill and farming from second one

#### Spending Stacks — Backing

- Players **walk back to base manually** to spend stacks — no teleport, no instant recall
- The walk itself is the cost: lane goes unattended, enemy farms freely, waves push
- On arrival at base, a loadout screen appears to unlock the next item (25 stacks each)
- Items are **complete effects** purchased directly — no components, no build paths

#### Why This Works

- **Stack count = minion kill count** — farming for items and farming toward the 100-kill win condition are the exact same action. Every stack matters twice.
- **Backing is a genuine decision** — the time spent walking back and returning is dead time in lane. Timing your back vs your opponent's stack count is the core tactical loop.
- No build complexity mid-match — items were chosen in the **pre-game loadout**, stacks just unlock them in sequence

#### Deny Mechanic ⚗️ _(Experimental — validate in playtesting)_

- Players can **attack their own minions** to deny stacks from the enemy
- A denied minion grants **0 stacks** on death
- Only possible once the minion drops below **50% HP** — prevents trivially clearing full waves
- Adds a third micro-skill layer: last-hitting enemies, denying your own, and trading with the opponent simultaneously

> **Agent note:** Minions need a `team_id` flag. Deny attack is only valid when `attacker.team_id == minion.team_id` AND minion HP is below threshold. Award 0 stacks on death if killing blow came from a friendly.

#### Pre-Game Loadout

- Before each match, players configure a **loadout of 4 items** (saved per champion)
- During the match, items unlock one-by-one by spending 25 stacks each
- **Full build = 100 stacks = minion win condition threshold** — this is intentional. Reaching your final item slot means you've simultaneously hit the stack win condition. The race to full build _is_ the race to win.
- New players get **recommended loadouts** per champion out of the box
- Advanced players customise and save their own builds

### 5. Experience, Leveling & Combat Scaling

- **Level cap: 8** (tuned for 15-20 min matches)
- Champions gain XP from nearby minion deaths and champion kills
- Every level-up choice is meaningful — ability rank upgrades directly increase damage, range, or effect strength
- **Both levels and items scale ability damage** — no fixed flat damage values; everything scales

| Level | Unlock                                  |
| ----- | --------------------------------------- |
| 1     | All abilities unlocked at base level    |
| 2–4   | Upgrade priority: Q or W                |
| 5–6   | Upgrade second ability                  |
| 7     | Ultimate upgrade                        |
| 8     | Final ability rank — full power reached |

> **Agent note:** Each ability should expose a `level` property (1–5). Damage, cooldown, and effect values should be defined as arrays indexed by level, e.g. `damage = [80, 110, 140, 170, 200]`. Items modify a champion's base stats (AD, AP, CDR etc.) which feed into ability calculations.

### 7. Death & Respawn

- On death, the champion enters a **respawn timer** (ARAM-style)
- Respawn time scales with match progression — longer timers as the game goes on
- Suggested base timer: **5 seconds** early game, scaling up to ~12 seconds by late game
- During respawn: the enemy has a free window to farm, push, or attack the tower — death has meaningful consequences without being punishing enough to end the match
- Champion respawns at their **base (Nexus end)** and must walk back to lane

> **StateChart usage:** Death state → Respawn countdown state → Spawn state is a clean StateChart flow. Timer is server-authoritative in multiplayer.

### 8. Jungle Camps

- **4 camps per side** — mirrored, tucked into pockets alongside the lane
- All camps are the **same tier** — identical stats and stack reward (+2 stacks each)
- Camps respawn every **30 seconds**
- No buffs on kill — flat stacks only, simple and clean
- Camp states (alive, dead, respawning) managed via **StateChart**

> Leaving lane for all 4 camps = +8 stacks but significant lane exposure — a meaningful risk/reward tradeoff.

### 10. Rune System

Runes are **pre-game configured per match** — set in the lobby alongside champion and loadout, locked in for the match.

#### What Runes Do

- Passive bonuses and minor effects — distinct from items (in-match stack unlocks)
- Examples: bonus CDR, movement speed on kill, damage amp at low HP, increased jungle camp stacks
- Runes = **baseline playstyle modifier** / Items = **in-match power progression**

#### Key Rules

- Locked before match starts — no mid-game changes
- Rune slot count: **TBD** — to be determined during playtesting
- Defined and saved in the pre-game lobby screen alongside the item loadout

> **Agent note:** Implement runes as `Resource` objects applied at match start, modifying base stats or registering passive signal listeners. Keep slot count as an exported variable so it can be tuned easily.

---

## 🏆 Ranked System

Two separate ranked queues — **1v1** and **2v2**.

| Rule                  | Detail                                            |
| --------------------- | ------------------------------------------------- |
| Win                   | Gain a fixed amount of points                     |
| Loss                  | Lose a fixed amount of points                     |
| Queue separation      | 1v1 and 2v2 rankings are tracked independently    |
| No tiers or divisions | Pure running point total — simple and transparent |

> Point amounts per win/loss are a balance tuning decision — to be set during playtesting.

---

## 🔓 Meta Progression

Players unlock content by playing ranked matches.

| Content       | Unlock Method              |
| ------------- | -------------------------- |
| New champions | Earned through ranked play |
| New items     | Earned through ranked play |
| New runes     | Earned through ranked play |

- **Starting state:** Players begin with a limited starter set — enough to play but with clear progression ahead
- No pay-to-win — all gameplay-affecting content (champions, items, runes) is earned through play
- Cosmetics (skins, effects) can be a separate unlock/purchase layer later

> **Agent note:** Each unlockable should have an `unlocked: bool` flag on its `Resource`. The meta progression system reads and writes these flags to a persistent save file. The lobby screen filters to only show unlocked content.

---

## 🎨 Art Style

- **Stylized / cartoon** — LoL-inspired visual direction
- Clean readable silhouettes for champions (critical for top-down isometric readability)
- Ability VFX should be visually distinct per archetype — not just recoloured versions of each other
- UI should be minimal in-match — HUD only shows what's essential (HP, ability cooldowns, stack count, kill counter)

---

## 👥 Game Modes & Scalability

### 1v1 (Default)

- One player per side on the standard map
- All systems tuned for 15-20 minute matches

### 2v2 (Same Map — Scalable)

The map and systems should be built with **2v2 as a first-class mode from day one**, not a retrofit.

| Parameter                 | 1v1        | 2v2        |
| ------------------------- | ---------- | ---------- |
| Players per side          | 1          | 2          |
| Lane width                | Standard   | Wider      |
| Minions per wave          | Standard   | +50%       |
| Jungle camps              | 2 per side | 3 per side |
| Minion kill win threshold | 100        | 200        |
| Nexus Tower HP            | Standard   | +30%       |
| Match length target       | 15-20 min  | 15-25 min  |

> **Agent note:** Player count should be a **match config variable** passed at game start. All systems (minion spawner, win condition tracker, jungle camps) should read from this config rather than hardcoded 1v1 assumptions. The map scene should expose lane width and camp count as exported parameters.

---

## 🌐 Multiplayer Architecture (Scalable Design)

### Phase 1 — Local (MVP)

- Two players on the same machine (shared input)
- **Shared screen camera** — both champions always visible, camera zooms/pans to keep both players in frame
- Used for testing all systems end-to-end

> **Agent note:** Camera should track the bounding box of all active players with padding, zooming out dynamically as they spread apart. A `Camera2D` with lerp to a midpoint + dynamic zoom is the standard approach for this in Godot.

### Phase 2 — Online (End Goal)

- Godot's built-in High-Level Multiplayer API (RPC-based)
- Authoritative server model (dedicated server or host-client)
- State sync: champion positions, ability casts, minion states, Nexus Tower HP, stack counts, respawn timers
- Lobby system: matchmaking or invite-by-code

> **Design note for agent:** All gameplay logic should be written **multiplayer-aware from day one** — avoid local-only assumptions. Use `is_multiplayer_authority()` checks and RPC decorators even during local testing phase.

---

## 📁 Suggested Project Structure

```
res://
├── scenes/
│   ├── game/
│   │   ├── map/           # Lane, towers, base structures, jungle pockets
│   │   ├── minions/       # Minion scenes & AI (with wave scaling)
│   │   ├── camps/         # Jungle camp scenes & respawn logic
│   │   └── hud/           # In-game UI (HP, cooldowns, stack counter, kill tracker)
│   ├── champions/         # One folder per champion
│   ├── lobby/             # Pre-game: champion select, item loadout, rune config
│   ├── ranked/            # Ranked queue, point tracking, matchmaking
│   └── menus/             # Main menu, settings, progression
├── scripts/
│   ├── core/              # Game manager, match config, multiplayer manager
│   ├── systems/           # Stack economy, win condition, wave spawner, respawn
│   └── utils/             # Helpers, constants, math
├── resources/
│   ├── champion_data/     # Champion stats & archetypes (.tres)
│   ├── item_data/         # Item definitions (25 stacks each)
│   ├── rune_data/         # Rune definitions (passive effects)
│   └── ability_data/      # Ability configs (cooldowns, damage, effects)
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── vfx/
└── addons/
    └── godot_state_charts/ # derKork StateChart addon
```

---

## 🧠 Agent Instructions

When working on this project, the agent should:

1. **Prioritize systems over content** — get stack economy, wave spawner, respawn, and tower logic solid before adding more champions.
2. **Build multiplayer-safe from the start** — no hardcoded player references; always use player IDs and authority checks.
3. **Use Resources for data** — champion stats, items, runes, and ability configs should be `Resource` classes, not hardcoded values.
4. **Separate logic from presentation** — game logic in scripts, visual feedback via signals.
5. **Signal-driven architecture** — systems communicate via Godot signals, not direct node references where avoidable.
6. **One champion first, fully functional** — implement one complete champion as the template before building 10+.
7. **Match config drives everything** — mode (1v1/2v2), lane width, wave size, and win thresholds all read from a single `MatchConfig` resource passed at game start.
8. **StateChart for all stateful entities** — champions, minions, jungle camps, and towers all use derKork's StateChart addon for state management.
9. **No gold, no shop** — the economy is stacks only. Never reference a gold or currency variable anywhere in code.

---

## ✅ Milestone Roadmap (Suggested)

| Milestone | Deliverable                                                              |
| --------- | ------------------------------------------------------------------------ |
| M1        | ARAM-style map — lane, single tower per side, Nexus, jungle pockets      |
| M2        | StateChart addon integrated — champion & entity state machine template   |
| M3        | One fully playable champion with all 4 abilities (local, cooldowns only) |
| M4        | Minion wave spawner + pathfinding + last-hit stack system + kill counter |
| M5        | Wave scaling over time                                                   |
| M6        | Nexus Tower AI — aggro rules, dive mechanic, destruction = win condition |
| M7        | Jungle camps — flat stacks, respawn timer, StateChart states             |
| M8        | Death & respawn timer system                                             |
| M9        | Dual win condition logic (Nexus destroy OR 100 minion kills)             |
| M10       | Pre-game lobby — champion select, 4-item loadout, rune config            |
| M11       | Stack → item unlock flow (25 stacks per item, back-to-base trigger)      |
| M12       | Rune system — passive effects applied at match start                     |
| M13       | 10 champions implemented                                                 |
| M14       | 2v2 mode — match config scaling                                          |
| M15       | Ranked system — point tracking per mode (1v1 / 2v2)                      |
| M16       | Meta progression — champion/item/rune unlock system                      |
| M17       | Online multiplayer (host/join, authoritative server)                     |
| M18       | Mobile controls (touch input layer)                                      |
| M19       | Polish — VFX, SFX, UI, art pass, balance                                 |

---

_Last updated: March 2026 | Engine: Godot 4.x latest_
