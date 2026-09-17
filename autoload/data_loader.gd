extends Node

## Generic data-driven content loader (Lane 1 AC: "All content loaded from
## data files, not hardcoded"). Every lane's content -- Workmon, abilities,
## items, quests, dialogue -- is a *.json file with an "id" field, living
## under its own res://data/<kind>/ directory. Lanes call load_directory()
## with their own path; this file owns no lane-specific schema itself
## (dialogue's schema/loader is dialogue_loader.gd, layered on top of this).

func load_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: file not found: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("DataLoader: failed to parse JSON: %s" % path)
	return parsed

## Loads every *.json file in dir_path into a Dictionary keyed by each
## record's "id" field. A file may contain a single record object or an
## array of records.
func load_directory(dir_path: String) -> Dictionary:
	var records: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("DataLoader: directory not found: %s" % dir_path)
		return records
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var parsed = load_file(dir_path.path_join(file_name))
			_index_record(records, parsed)
		file_name = dir.get_next()
	dir.list_dir_end()
	return records

func _index_record(records: Dictionary, parsed: Variant) -> void:
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("id"):
		records[parsed["id"]] = parsed
	elif typeof(parsed) == TYPE_ARRAY:
		for entry in parsed:
			if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
				records[entry["id"]] = entry
