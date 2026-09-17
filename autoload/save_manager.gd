extends Node

## Save/load + autosave (Lane 1 AC). Persisted state is a plain Dictionary
## with the shape returned by default_state(), matching spec §23's save
## schema exactly (player, inventory, workmon, quests, reputation,
## story_progress, world_state, settings). Other lanes read/write their own
## top-level key; nobody invents a second save file or nests their data
## somewhere else in the tree.

signal autosave_triggered(reason: String, slot: int)

const SAVE_DIR := "user://saves/"
const SLOT_COUNT := 3
const SAVE_VERSION := 1

## Documented triggers per Lane 1 AC. Callers should pass one of these so
## save files carry a consistent audit trail; unknown reasons still save,
## just with a warning, so a new lane isn't hard-blocked on this list.
const AUTOSAVE_REASONS := [
	"major_battle",
	"new_area",
	"major_quest",
	"recruitment",
	"boss_battle",
]

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func default_state() -> Dictionary:
	return {
		"player": {},
		"inventory": [],
		"workmon": [],
		"quests": {},
		"reputation": {},
		"story_progress": {},
		"world_state": {},
		"settings": {},
	}

func slot_path(slot: int) -> String:
	return "%sslot_%d.json" % [SAVE_DIR, slot]

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func save_game(slot: int, state: Dictionary) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		push_error("SaveManager: slot %d out of range (0-%d)" % [slot, SLOT_COUNT - 1])
		return false
	var payload := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"state": state,
	}
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open slot %d for writing (%s)" % [
			slot, error_string(FileAccess.get_open_error()),
		])
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	return true

func load_game(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var file := FileAccess.open(slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed.get("state", {})

func delete_slot(slot: int) -> bool:
	if not slot_exists(slot):
		return false
	return DirAccess.remove_absolute(slot_path(slot)) == OK

func autosave(reason: String, slot: int, state: Dictionary) -> bool:
	if not AUTOSAVE_REASONS.has(reason):
		push_warning("SaveManager: unrecognized autosave reason '%s'" % reason)
	var ok := save_game(slot, state)
	if ok:
		autosave_triggered.emit(reason, slot)
	return ok
