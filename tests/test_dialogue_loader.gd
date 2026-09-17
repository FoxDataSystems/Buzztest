extends GutTest

func before_each():
	DialogueLoader.reload()

func test_get_dialogue_tree_returns_dialogue_by_id():
	var tree := DialogueLoader.get_dialogue_tree("vincent_intro_01")
	assert_eq(tree["speaker"], "Vincent")
	assert_eq(tree["lines"].size(), 2)

func test_get_dialogue_tree_missing_id_returns_empty_dict():
	assert_eq(DialogueLoader.get_dialogue_tree("does_not_exist"), {})

func test_ungated_and_low_reputation_choices_available_at_neutral_reputation():
	var save_state := SaveManager.default_state()
	save_state["reputation"] = { "smart_reputation": 0 }
	var available := DialogueLoader.get_available_choices("vincent_intro_01", save_state)
	# "Tell me more" (no gate) and "I don't want trouble" (min: -5) pass at 0;
	# "Report to management" (max: -10) does not.
	assert_eq(available.size(), 2)
	assert_eq(available[0]["text"], "Tell me more about the rebellion.")

func test_report_choice_unlocks_at_low_reputation():
	var save_state := SaveManager.default_state()
	save_state["reputation"] = { "smart_reputation": -15 }
	var available := DialogueLoader.get_available_choices("vincent_intro_01", save_state)
	# At -15: "Tell me more" (no gate) and "Report" (max: -10) pass;
	# "I don't want trouble" (min: -5) no longer passes.
	assert_eq(available.size(), 2)
	var texts := available.map(func(c): return c["text"])
	assert_true(texts.has("Report this to management."))
	assert_false(texts.has("I don't want any trouble."))
