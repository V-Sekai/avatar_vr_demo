@tool
extends EditorPlugin

const ugc_loader_manager: GDScript = preload("./ugc_loader_manager.gd")


func _enter_tree():
	add_autoload_singleton("UGCLoaderManager", ugc_loader_manager.resource_path)


func _exit_tree():
	remove_autoload_singleton("UGCLoaderManager")
