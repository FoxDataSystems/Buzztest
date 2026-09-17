extends GutTest

var _test_slot := 2

func before_each():
	if SaveManager.slot_exists(_test_slot):
		SaveManager.delete_slot(_test_slot)

func after_each():
	if SaveManager.slot_exists(_test_slot):
		SaveManager.delete_slot(_test_slot)

func test_save_and_load_round_trip_preserves_nested_data():
	var state := SaveManager.default_state()
	state["player"] = { "name": "Rookie", "rank": "Junior Consultant" }
	state["workmon"] = [{ "id": "workmon_01", "level": 3 }]
	state["reputation"] = { "smart_reputation": 5 }
	assert_true(SaveManager.save_game(_test_slot, state))
	var loaded := SaveManager.load_game(_test_slot)
	assert_eq(loaded["player"]["name"], "Rookie")
	assert_eq(loaded["workmon"][0]["id"], "workmon_01")
	assert_eq(loaded["reputation"]["smart_reputation"], 5)

func test_default_state_matches_spec_23_save_schema():
	var state := SaveManager.default_state()
	var expected_keys := [
		"player", "inventory", "workmon", "quests",
		"reputation", "story_progress", "world_state", "settings",
	]
	for key in expected_keys:
		assert_true(state.has(key), "default_state() missing spec §23 key '%s'" % key)

func test_slot_can_be_overwritten():
	SaveManager.save_game(_test_slot, { "player": { "name": "First" } })
	SaveManager.save_game(_test_slot, { "player": { "name": "Second" } })
	var loaded := SaveManager.load_game(_test_slot)
	assert_eq(loaded["player"]["name"], "Second")

func test_slot_out_of_range_is_rejected():
	assert_false(SaveManager.save_game(SaveManager.SLOT_COUNT, {}))
	assert_false(SaveManager.save_game(-1, {}))

func test_loading_missing_slot_returns_empty_dict():
	assert_eq(SaveManager.load_game(_test_slot), {})

func test_three_slots_are_independent():
	for slot in range(SaveManager.SLOT_COUNT):
		SaveManager.save_game(slot, { "player": { "name": "slot_%d" % slot } })
	for slot in range(SaveManager.SLOT_COUNT):
		assert_eq(SaveManager.load_game(slot)["player"]["name"], "slot_%d" % slot)
	for slot in range(SaveManager.SLOT_COUNT):
		SaveManager.delete_slot(slot)

func test_autosave_emits_signal_and_persists():
	watch_signals(SaveManager)
	SaveManager.autosave("boss_battle", _test_slot, { "player": { "name": "Boss Fight" } })
	assert_signal_emitted(SaveManager, "autosave_triggered")
	assert_eq(SaveManager.load_game(_test_slot)["player"]["name"], "Boss Fight")
