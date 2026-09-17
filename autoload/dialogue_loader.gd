extends Node

## Dialogue data schema + loader (Lane 1 AC, Kern's slice of the Lane 7
## boundary agreement). Dialogue trees are data-driven JSON files under
## res://data/dialogue/. Schema:
##
##   {
##     "id": "vincent_intro_01",
##     "speaker": "Vincent",
##     "lines": ["...", "..."],
##     "choices": [
##       {
##         "text": "Tell me more.",
##         "next": "vincent_intro_02",
##         "gate": {"reputation": {"track": "SMART_REP", "min": 0}},
##         "effects": {"reputation": {"track": "SMART_REP", "delta": 1}}
##       }
##     ]
##   }
##
## "gate" (optional) is a StoryGate condition -- a choice only appears via
## get_available_choices() when its gate passes against the current save
## state. "effects" (optional) describes what applying the choice changes;
## Lane 7's choice->consequence state machine (Bouw) is the one that
## actually applies effects to save state, this loader only exposes them.

const DIALOGUE_DIR := "res://data/dialogue"

var _trees: Dictionary = {}
var _loaded: bool = false

func _ensure_loaded() -> void:
	if not _loaded:
		_trees = DataLoader.load_directory(DIALOGUE_DIR)
		_loaded = true

func get_dialogue_tree(id: String) -> Dictionary:
	_ensure_loaded()
	return _trees.get(id, {})

## Choices whose "gate" (if any) currently passes against save_state.
func get_available_choices(tree_id: String, save_state: Dictionary) -> Array:
	var tree := get_dialogue_tree(tree_id)
	var choices: Array = tree.get("choices", [])
	var available: Array = []
	for choice in choices:
		var gate: Variant = choice.get("gate", null)
		if gate == null or StoryGate.check(gate, save_state):
			available.append(choice)
	return available

## Forces re-read from disk; useful after adding/editing dialogue files
## without restarting the game (e.g. in the editor).
func reload() -> void:
	_loaded = false
	_ensure_loaded()
