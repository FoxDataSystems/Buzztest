extends GutTest

func test_reputation_min_gate():
	var save_state := { "reputation": { "smart_reputation": 5 } }
	assert_true(StoryGate.check({ "reputation": { "track": "smart_reputation", "min": 3 } }, save_state))
	assert_false(StoryGate.check({ "reputation": { "track": "smart_reputation", "min": 10 } }, save_state))

func test_reputation_max_gate():
	var save_state := { "reputation": { "smart_reputation": -15 } }
	assert_true(StoryGate.check({ "reputation": { "track": "smart_reputation", "max": -10 } }, save_state))
	assert_false(StoryGate.check({ "reputation": { "track": "smart_reputation", "max": -20 } }, save_state))

func test_quest_status_gate_defaults_to_completed():
	var save_state := { "quests": { "q1": { "status": "completed" } } }
	assert_true(StoryGate.check({ "quest": { "id": "q1" } }, save_state))
	assert_false(StoryGate.check({ "quest": { "id": "q1", "status": "active" } }, save_state))

func test_item_gate_checks_quantity():
	var save_state := { "inventory": [{ "id": "keycard", "qty": 1 }] }
	assert_true(StoryGate.check({ "item": { "id": "keycard", "min_qty": 1 } }, save_state))
	assert_false(StoryGate.check({ "item": { "id": "keycard", "min_qty": 2 } }, save_state))

func test_empty_gate_always_passes():
	assert_true(StoryGate.check({}, {}))

func test_rank_advancement_reuses_gate_grammar():
	var save_state := { "reputation": { "smart_reputation": 20 } }
	var rank_def := { "gate": { "reputation": { "track": "smart_reputation", "min": 15 } } }
	assert_true(StoryGate.check_rank_advancement(rank_def, save_state))
	rank_def["gate"]["reputation"]["min"] = 25
	assert_false(StoryGate.check_rank_advancement(rank_def, save_state))
