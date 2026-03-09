
extends Node

@export var relative_in_android:LineEdit
@export var relative_in_godot:LineEdit
@export var absolute_in_android:LineEdit
@export var absolute_in_godot:LineEdit
@export var files_in_android:TextEdit
@export var files_in_godot:TextEdit


func copy_files_dont_delete():
	pass
func copy_files_and_delete():
	pass

func _ready() -> void:
	relative_in_android.text_changed.connect(refresh_android_storage_directory)
	relative_in_godot.text_changed.connect(refresh_godot_directory)

func refresh_android_storage_directory(text:String):
	var android_relative= relative_in_android.text
	var godot_relative= relative_in_godot.text
	var android_abs:= ImporterFileUtility.get_android_storage_absolute_path_from_relative(android_relative)
	var godot_abs := ImporterFileUtility.get_godot_project_absolute_path_from_relative(godot_relative)
	absolute_in_android.text= android_abs
	absolute_in_godot.text = godot_abs
	var files :Array[String] = ImporterFileUtility.get_all_files_and_directory_in_absolute_path_directory_recursive(android_abs)
	files_in_android.text ="\n".join(files)
	files = ImporterFileUtility.get_all_files_and_directory_in_absolute_path_directory_recursive(godot_abs)
	files_in_godot.text ="\n".join(files)

func refresh_godot_directory(text:String):
	var android_relative= relative_in_android.text
	var godot_relative= relative_in_godot.text
	var android_abs:= ImporterFileUtility.get_android_storage_absolute_path_from_relative(android_relative)
	var godot_abs := ImporterFileUtility.get_godot_project_absolute_path_from_relative(godot_relative)
	absolute_in_android.text= android_abs
	absolute_in_godot.text = godot_abs
	var files :Array[String] = ImporterFileUtility.get_all_files_and_directory_in_absolute_path_directory_recursive(android_abs)
	files_in_android.text ="\n".join(files)
	files = ImporterFileUtility.get_all_files_and_directory_in_absolute_path_directory_recursive(godot_abs)
	files_in_godot.text ="\n".join(files)
