extends Node

## Story-gate check logic (Lane 1 AC, per the Bouw/Kern boundary agreement:
## rank advancement reads save state, so it lives with the state-machine
## owner). Evaluates a gate Dictionary against a save-state Dictionary
## (the shape from SaveManager.default_state()). Used by both dialogue
## choices (Lane 7) and consultant-rank advancement (Lane 3) so they share
## one gate grammar instead of each inventing their own.
##
## Gate grammar (all keys optional, all present keys must pass -- AND):
##   {"reputation": {"track": "SMART_REP", "min": 10, "max": 50}}
##   {"quest": {"id": "q1", "status": "completed"}}   # status defaults to "completed"
##   {"item": {"id": "keycard", "min_qty": 1}}         # min_qty defaults to 1

func check(gate: Dictionary, save_state: Dictionary) -> bool:
	if gate.has("reputation") and not _check_reputation(gate["reputation"], save_state):
		return false
	if gate.has("quest") and not _check_quest(gate["quest"], save_state):
		return false
	if gate.has("item") and not _check_item(gate["item"], save_state):
		return false
	return true

## Rank advancement is gated the same way as a dialogue choice: rank_def
## carries its own "gate" dict (story progress / reputation / quest checks).
func check_rank_advancement(rank_def: Dictionary, save_state: Dictionary) -> bool:
	return check(rank_def.get("gate", {}), save_state)

func _check_reputation(cond: Dictionary, save_state: Dictionary) -> bool:
	var reputation: Dictionary = save_state.get("reputation", {})
	var value: int = reputation.get(cond.get("track", ""), 0)
	if cond.has("min") and value < cond["min"]:
		return false
	if cond.has("max") and value > cond["max"]:
		return false
	return true

func _check_quest(cond: Dictionary, save_state: Dictionary) -> bool:
	var quests: Dictionary = save_state.get("quests", {})
	var quest_id: String = cond.get("id", "")
	var required_status: String = cond.get("status", "completed")
	return quests.get(quest_id, {}).get("status", "") == required_status

func _check_item(cond: Dictionary, save_state: Dictionary) -> bool:
	var inventory: Array = save_state.get("inventory", [])
	var item_id: String = cond.get("id", "")
	var min_qty: int = cond.get("min_qty", 1)
	for entry in inventory:
		if entry.get("id", "") == item_id and entry.get("qty", 0) >= min_qty:
			return true
	return false
