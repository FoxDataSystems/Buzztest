# Lane 1: Core Engine & Architecture

Godot 4.7.2 (pinned). Autoloads are global singletons; call them by name
directly (`GameState.transition_to(...)`), no `preload`/`get_node` needed.

## Game state machine — `autoload/game_state.gd` (`GameState`)

States: `MAIN_MENU`, `CHARACTER_CREATION`, `WORLD_LOADED`, `IN_GAME`, `GAME_OVER`.

- `GameState.current_state` — read-only from outside the autoload.
- `GameState.transition_to(next_state) -> bool` — returns false and does
  nothing if the transition isn't in `ALLOWED_TRANSITIONS`.
- `GameState.state_changed(previous, current)` signal — UI (Lane 8) drives
  which screen is visible off this signal, not its own state tracking.

## Save/load — `autoload/save_manager.gd` (`SaveManager`)

3 overwritable slots (0-2), plain JSON on disk under `user://saves/`.

- `SaveManager.default_state() -> Dictionary` — canonical empty save shape,
  matching spec §23's save schema exactly:
  `{"player": {}, "inventory": [], "workmon": [], "quests": {}, "reputation": {},
  "story_progress": {}, "world_state": {}, "settings": {}}`.
  Every lane writes into its own top-level key of this dict; nobody invents
  a second save file or nests their data under `player`. `reputation` is a
  flat `{track_name: int}` dict (e.g. `smart_reputation`, `corporate_reputation`,
  `hr_reputation` per spec §21) — `StoryGate` reads it from the top level, not
  from inside `player`. `settings` is Lane 8's: audio/accessibility toggles
  go there directly, there's no separate SettingsManager autoload — same
  pattern as Bouw writing quest data into `quests`.
- `SaveManager.save_game(slot, state)` / `load_game(slot)` — full overwrite,
  full read. Slot out of range or missing returns `false` / `{}`, never
  throws.
- `SaveManager.autosave(reason, slot, state)` — same as `save_game` plus an
  `autosave_triggered(reason, slot)` signal. `reason` should be one of
  `major_battle`, `new_area`, `major_quest`, `recruitment`, `boss_battle`
  (AC's autosave trigger list) but isn't enforced — unknown reasons still
  save, just log a warning, so no lane is blocked waiting on this list.

## Data-driven content — `autoload/data_loader.gd` (`DataLoader`)

Convention for **all** content (Workmon, abilities, items, quests, dialogue):
one `*.json` file per record (or an array of records in one file), each with
an `"id"` field, under its own `res://data/<kind>/` directory.

- `DataLoader.load_directory(dir_path) -> Dictionary` — every record in the
  directory, keyed by `id`.
- `DataLoader.load_file(path) -> Variant` — one file, parsed.

Bouw: put Workmon/Abilities/Items/Quests under `res://data/workmon/`,
`res://data/abilities/`, `res://data/items/`, `res://data/quests/` and call
`DataLoader.load_directory(...)` — no need to write your own JSON loader.

## Dialogue schema + loader — `autoload/dialogue_loader.gd` (`DialogueLoader`)

Files under `res://data/dialogue/`, one tree per file. Schema:

```json
{
  "id": "vincent_intro_01",
  "speaker": "Vincent",
  "lines": ["...", "..."],
  "choices": [
    {
      "text": "Tell me more.",
      "next": "vincent_intro_02",
      "gate": { "reputation": { "track": "smart_reputation", "min": 0 } },
      "effects": { "reputation": { "track": "smart_reputation", "delta": 1 } }
    }
  ]
}
```

- `DialogueLoader.get_dialogue_tree(id) -> Dictionary` (named to avoid
  colliding with `Node.get_tree()`)
- `DialogueLoader.get_available_choices(tree_id, save_state) -> Array` —
  choices whose `gate` (if any) currently passes.
- `gate` is optional and evaluated by `StoryGate` (see below). `effects` is
  descriptive only — Lane 7's choice→consequence state machine (Bouw) is
  what actually applies an effect to save state; this loader just exposes it.

## Story gates — `autoload/story_gate.gd` (`StoryGate`)

Shared gate grammar for both dialogue choices and consultant-rank
advancement, since both read save state:

```json
{"reputation": {"track": "smart_reputation", "min": 10, "max": 50}}
{"quest": {"id": "q1", "status": "completed"}}
{"item": {"id": "keycard", "min_qty": 1}}
```

`reputation` in a gate reads `save_state["reputation"][track]` (top level,
not `save_state["player"]["reputation"]`).

- `StoryGate.check(gate, save_state) -> bool` — all present keys AND together.
- `StoryGate.check_rank_advancement(rank_def, save_state) -> bool` — same
  logic, `rank_def` carries its own `"gate"` key.

## Entity lifecycle — `entities/game_entity.gd` (`GameEntity`)

Base class for anything spawned into a running session (NPCs, Workmon
instances, interactables). Extend it with `class_name` and call
`spawn(id)` / `despawn()` rather than hand-rolling spawn bookkeeping per lane.

## Tests

`addons/gut/` (GUT, vendored) + `tests/*.gd`, run headless:

```
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

28 tests across state machine, save/load, data loader, dialogue loader, and
story gates — all currently green (see PR for the run output).

## Export

`export_presets.cfg` has `Web` and `Linux` presets — **scaffolded, not yet
verified**: I don't have Godot export templates installed in this
environment, so I haven't run an actual `--export-release` locally. Basis,
adjust paths/options as needed when you pilot the Lane 10 CI workflow
against this.
