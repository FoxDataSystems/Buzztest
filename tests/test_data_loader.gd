extends GutTest

func test_load_directory_indexes_records_by_id():
	var records := DataLoader.load_directory("res://tests/fixtures/items")
	assert_eq(records.size(), 2)
	assert_true(records.has("potion"))
	assert_eq(records["potion"]["name"], "Potion")
	assert_eq(records["elixir"]["heal"], 999)

func test_load_directory_missing_path_returns_empty_dict():
	var records := DataLoader.load_directory("res://tests/fixtures/does_not_exist")
	assert_eq(records, {})

func test_load_file_returns_single_record():
	var parsed = DataLoader.load_file("res://tests/fixtures/items/potion.json")
	assert_eq(parsed["name"], "Potion")

func test_load_file_missing_path_returns_null():
	assert_null(DataLoader.load_file("res://tests/fixtures/does_not_exist.json"))
