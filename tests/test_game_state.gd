extends GutTest

func before_each():
	GameState._reset_for_tests()

func test_initial_state_is_main_menu():
	assert_eq(GameState.current_state, GameState.State.MAIN_MENU)

func test_legal_transition_main_menu_to_character_creation():
	assert_true(GameState.transition_to(GameState.State.CHARACTER_CREATION))
	assert_eq(GameState.current_state, GameState.State.CHARACTER_CREATION)

func test_full_happy_path_menu_to_game_over():
	assert_true(GameState.transition_to(GameState.State.CHARACTER_CREATION))
	assert_true(GameState.transition_to(GameState.State.WORLD_LOADED))
	assert_true(GameState.transition_to(GameState.State.IN_GAME))
	assert_true(GameState.transition_to(GameState.State.GAME_OVER))
	assert_eq(GameState.current_state, GameState.State.GAME_OVER)

func test_load_game_skips_character_creation():
	assert_true(GameState.transition_to(GameState.State.WORLD_LOADED))
	assert_eq(GameState.current_state, GameState.State.WORLD_LOADED)

func test_illegal_transition_is_rejected_and_state_unchanged():
	assert_false(GameState.transition_to(GameState.State.GAME_OVER))
	assert_eq(GameState.current_state, GameState.State.MAIN_MENU)

func test_state_changed_signal_emitted_on_legal_transition():
	watch_signals(GameState)
	GameState.transition_to(GameState.State.CHARACTER_CREATION)
	assert_signal_emitted(GameState, "state_changed")

func test_state_changed_signal_not_emitted_on_illegal_transition():
	watch_signals(GameState)
	GameState.transition_to(GameState.State.GAME_OVER)
	assert_signal_not_emitted(GameState, "state_changed")
