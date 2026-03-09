class_name ImporterFileUtility
extends Node

const QUEST_DRIVER_PATH: String = "/storage/emulated/0/"
const GODOT_PROJECT_PATH: String = "res://"

static func get_android_storage_absolute_path_from_relative(relative_path: String) -> String:
	return QUEST_DRIVER_PATH + relative_path

static func get_godot_project_res_path_from_relative(relative_path: String) -> String:
	return GODOT_PROJECT_PATH + relative_path

static func get_godot_project_absolute_path_from_relative(relative_path: String) -> String:
	return ProjectSettings.globalize_path(get_godot_project_res_path_from_relative(relative_path))

static func create_directory_if_not_existing_from_absolute_path(absolute_path: String) -> void:
	if not DirAccess.dir_exists_absolute(absolute_path):
		var mk_err := DirAccess.make_dir_recursive_absolute(absolute_path)
		if mk_err != OK:
			push_warning("Failed to create target directory: %s" % mk_err)

static func copy_files_from_sd_storage_to_godot_res(
	relative_storage_source: String,
	project_relative_path: String,
	file_pattern: String = "*"
) -> void:
	var source_path: String = get_android_storage_absolute_path_from_relative(relative_storage_source)
	var target_res_path: String = get_godot_project_res_path_from_relative(project_relative_path)
	var target_abs_path: String = get_godot_project_absolute_path_from_relative(project_relative_path)

	create_directory_if_not_existing_from_absolute_path(target_abs_path)

	# Copy recursively from source to target.
	copy_recursively_files_from_to(source_path, target_abs_path, file_pattern)

	# Refresh Godot FileSystem (editor only).
	if Engine.is_editor_hint():
		var fs := EditorInterface.get_resource_filesystem()
		if fs:
			fs.scan()
			print("FileSystem refreshed.")

static func get_all_files_in_absolute_path_directory_non_recursive(absolute_path_directory: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(absolute_path_directory)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name != "." and file_name != "..":
				result.append(absolute_path_directory.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	return result

static func get_all_directory_in_absolute_path_directory_non_recursive(absolute_path_directory: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(absolute_path_directory)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				result.append(absolute_path_directory.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	return result

static func get_all_files_in_absolute_path_directory_recursive(absolute_path_directory: String) -> Array[String]:
	var result: Array[String] = []
	_collect_files_recursive(absolute_path_directory, result)
	return result
	
static func get_all_directories_in_absolute_path_directory_recursive(absolute_path_directory: String) -> Array[String]:
	var result: Array[String] = []
	_collect_directories_recursive(absolute_path_directory, result)
	return result

static func get_all_files_and_directory_in_absolute_path_directory_recursive(absolute_path_directory: String) -> Array[String]:
	var result: Array[String] = []
	_collect_files_recursive(absolute_path_directory, result)
	_collect_directories_recursive(absolute_path_directory, result)
	return result
	
static func _collect_directories_recursive(path: String, out_dirs: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Cannot open directory: " + path)
		return

	var err := dir.list_dir_begin()
	if err != OK:
		push_warning("Cannot list directory: " + path)
		return

	var name := dir.get_next()
	while name != "":
		var full := path.path_join(name)

		if dir.current_is_dir():
			out_dirs.append(full)
			_collect_directories_recursive(full, out_dirs)

		name = dir.get_next()

	dir.list_dir_end()


static func _collect_files_recursive(path: String, out_files: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Cannot open directory: " + path)
		return

	var err := dir.list_dir_begin()
	if err != OK:
		push_warning("Cannot list directory: " + path)
		return

	var name := dir.get_next()
	while name != "":
		var full := path.path_join(name)

		if dir.current_is_dir():
			_collect_files_recursive(full, out_files)
		else:
			out_files.append(full)

		name = dir.get_next()

	dir.list_dir_end()
	
static func copy_file_from_source_to_destination(
	source: String,
	dest: String,
	ignore_end_string_group: Array[String] = [".zip"],
	max_mega_byte: int = 24,
	delete_after_copy: bool = true
) -> String:
	# Skip certain extensions.
	for end in ignore_end_string_group:
		if source.to_lower().ends_with(end.to_lower()):
			return "Skipped (%s file): %s" % [end, source.get_file()]

	var size_bytes := 0
	var f := FileAccess.open(source, FileAccess.READ)
	if f:
		size_bytes = f.get_length()
		f.close()

	if size_bytes > max_mega_byte * 1024 * 1024:
		return "Skipped (too large): %s (%.2f MB)" % [source.get_file(), float(size_bytes) / (1024.0 * 1024.0)]

	var err := DirAccess.copy_absolute(source, dest)
	if err != OK:
		return "Failed to copy: %s Error code: %s" % [source.get_file(), str(err)]

	if delete_after_copy:
		var del_err := DirAccess.remove_absolute(source)
		if del_err == OK:
			return "Deleted source file: %s" % source
		else:
			return "Failed to delete source file: %s Error code: %s" % [source, str(del_err)]
	else:
		return "Copied: %s (%.2f MB) → %s" % [source.get_file(), float(size_bytes) / (1024.0 * 1024.0), dest]

static func is_file_name_match_given_pattern(file_name: String, pattern: String) -> bool:
	if pattern == "*" or pattern.is_empty():
		return true
	if pattern.begins_with("*."):
		var extension := pattern.substr(2).to_lower()
		return file_name.to_lower().ends_with("." + extension)
	# Simple wildcard support using match().
	return file_name.to_lower().match(pattern.to_lower())

static func copy_recursively_files_from_to(
	source_path: String,
	target_abs_path: String,
	file_pattern: String = "*"
) -> void:
	_process_directory(source_path, target_abs_path, file_pattern)

static func _process_directory(source_path: String, target_abs_path: String, file_pattern: String) -> void:
	var dir := DirAccess.open(source_path)
	if not dir:
		push_warning("Could not open directory at: %s" % source_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var source := source_path.path_join(file_name)
			var dest := target_abs_path.path_join(file_name)

			if dir.current_is_dir():
				var sub_dir_err := DirAccess.make_dir_recursive_absolute(dest)
				if sub_dir_err == OK:
					print("Created subdirectory: ", dest)
					_process_directory(source, dest, file_pattern)
				else:
					push_warning("Failed to create subdirectory: %s Error code: %s" % [dest, str(sub_dir_err)])
			else:
				if is_file_name_match_given_pattern(file_name, file_pattern):
					var msg := copy_file_from_source_to_destination(source, dest, [], 24, true)
					print(msg)
		file_name = dir.get_next()
	dir.list_dir_end()

static func _process_files(source_path: String, target_abs_path: String, file_pattern: String) -> void:
	var dir := DirAccess.open(source_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name != "." and file_name != "..":
			if is_file_name_match_given_pattern(file_name, file_pattern):
				var source := source_path.path_join(file_name)
				var dest := target_abs_path.path_join(file_name)
				var msg := copy_file_from_source_to_destination(source, dest, [], 24, true)
				print(msg)
		file_name = dir.get_next()
	dir.list_dir_end()
