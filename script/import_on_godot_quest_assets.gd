# Untested code to test on the Quest ASAP

extends Node

@export var source_relative: String = "Download"
@export var res_relative: String = "import_from_quest/download"
@export var import_at_ready: bool = false
@export var copy_or_delete_files: CopyOrDeleteFiles = CopyOrDeleteFiles.DELETE
@export var apply_to_directory: bool = false
@export var file_pattern: String = "*" # Pattern like "*.txt" or "*" for all files

enum CopyOrDeleteFiles { COPY, DELETE }

func _ready() -> void:
	if import_at_ready:
		copy_files_from_downloads_to_user_import_here(source_relative, res_relative)

func copy_files_from_downloads_to_user_import_here(relative_storage_source: String, project_relative_path: String) -> void:
	var downloads_path: String = "/storage/emulated/0/" + relative_storage_source
	var target_path: String = "res://" + project_relative_path
	
	# Print absolute paths for debugging
	print("Source (Download) path: ", downloads_path)
	print("Target path: ", target_path)
	
	# Create target directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(target_path)):
		var mk_err = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_path))
		if mk_err == OK:
			print("Created target directory: ", target_path)
		else:
			print("Failed to create target directory: ", mk_err)
			return
	
	# Process directory or files based on apply_to_directory
	if apply_to_directory:
		_process_directory(downloads_path, target_path)
	else:
		_process_files(downloads_path, target_path)
	
	# Refresh Godot FileSystem (editor only)
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()
		print("FileSystem refreshed.")

func _process_directory(source_path: String, target_path: String) -> void:
	var dir := DirAccess.open(source_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var source = source_path.path_join(file_name)
			var dest = ProjectSettings.globalize_path(target_path).path_join(file_name)
			
			if dir.current_is_dir():
				# Recursively process subdirectory
				var sub_dir_err = DirAccess.make_dir_recursive_absolute(dest)
				if sub_dir_err == OK:
					print("Created subdirectory: ", dest)
					_process_directory(source, target_path.path_join(file_name))
				else:
					print("Failed to create subdirectory: ", dest, " Error code: ", sub_dir_err)
			else:
				# Process file if it matches the pattern
				if _matches_pattern(file_name, file_pattern):
					_process_file(source, dest)
			
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Could not open directory at: ", source_path)

func _process_files(source_path: String, target_path: String) -> void:
	var dir := DirAccess.open(source_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and _matches_pattern(file_name, file_pattern):
				var source = source_path.path_join(file_name)
				var dest = ProjectSettings.globalize_path(target_path).path_join(file_name)
				_process_file(source, dest)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Could not open directory at: ", source_path)

func _process_file(source: String, dest: String) -> void:
	# Skip .zip files
	if source.to_lower().ends_with(".zip"):
		print("Skipped (.zip file): ", source.get_file())
		return
	
	var size_bytes: int = 0
	var f := FileAccess.open(source, FileAccess.READ)
	if f:
		size_bytes = f.get_length()
		f.close()
	
	if size_bytes > 24 * 1024 * 1024: # 24 MB limit
		print("Skipped (too large): ", source.get_file(), " (", size_bytes / (1024 * 1024.0), " MB )")
		return

	var err = DirAccess.copy_absolute(source, dest)
	if err == OK:
		print("Copied: ", source.get_file(), " (", size_bytes / (1024 * 1024.0), " MB ) → ", dest)
	else:
		print("Failed to copy: ", source.get_file(), " Error code: ", err)
	
	if copy_or_delete_files == CopyOrDeleteFiles.DELETE:
		var del_err = DirAccess.remove_absolute(source)
		if del_err == OK:
			print("Deleted source file: ", source)
		else:
			print("Failed to delete source file: ", source, " Error code: ", del_err)

func _matches_pattern(file_name: String, pattern: String) -> bool:
	if pattern == "*" or pattern.is_empty():
		return true
	if pattern.begins_with("*."):
		var extension = pattern.substr(2).to_lower()
		return file_name.to_lower().ends_with("." + extension)
	return file_name.to_lower().match(pattern.to_lower())
