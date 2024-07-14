extends Node

const base_validator = preload("res://addons/ugc_asset_loader/base_validator.gd")
const gltf_processor = preload("res://addons/ugc_asset_loader/processing_task_gltf_load.gd")
const scene_processor = preload("res://addons/ugc_asset_loader/processing_task_scene_validate.gd")

@export var uri: String = "res://addons/renik/sample_models/godette.glb"
@export var cache_key: String = "godette"

@export var unload_before_load: bool = false
@export var failure_placeholder: PackedScene


var loading_cache_key: String 
var asset_load_request: Object
var previous_cache_key: String

var previous_loaded_node: Node
var loading_placeholder_node: NodePath

# Called when the node enters the scene tree for the first time.
func _ready():
	if uri != null:
		await load_next_asset()

func load_next_asset():
	if cache_key == loading_cache_key:
		return
	if uri == "":
		clear_currently_loaded_node()
	if asset_load_request != null:
		hide_placeholder()
		asset_load_request.cancel()
		asset_load_request = null
		loading_cache_key = ""
	if cache_key == previous_cache_key:
		return
	if unload_before_load:
		clear_currently_loaded_node()
	var this_cache_key := cache_key
	var alr := create_load_request(this_cache_key)
	asset_load_request = alr
	loading_cache_key = this_cache_key
	show_placeholder(loading_cache_key, asset_load_request)
	var loaded_node: Node = await UGCLoaderManager.load_asset(alr)
	if asset_load_request != alr:
		if loaded_node != null:
			loaded_node.queue_free()
		# laoding_* will already have been cleared, so return early
		return
	asset_load_request = null
	var loaded_cache_key := loading_cache_key
	var loading_cache_key := ""
	if loaded_node != null:
		self.node_completed(loaded_node, loaded_cache_key)
	else:
		node_failed(loaded_cache_key)


func show_placeholder(cache_key: String, asset_load_request: Object):
	var placeholder_node: Node = null if loading_placeholder_node == NodePath() else get_node_or_null(loading_placeholder_node)
	if placeholder_node != null:
		placeholder_node.visible = true


func hide_placeholder():
	var placeholder_node: Node = null if loading_placeholder_node == NodePath() else get_node_or_null(loading_placeholder_node)
	if placeholder_node != null:
		placeholder_node.visible = false


func create_load_request(new_cache_key: String) -> Object:
	var validator := base_validator.new()
	var alr := UGCLoaderManager.create_load_request(uri, uri, cache_key, ".glb", validator, gltf_processor.new())
	return alr


func clear_currently_loaded_node():
	if previous_loaded_node != null:
		#if previous_loaded_node.get_parent() == get_parent():
		if previous_loaded_node.get_parent() != null:
			previous_loaded_node.get_parent().remove_child(previous_loaded_node)
		previous_loaded_node.queue_free()
	previous_loaded_node = null
	previous_cache_key = ""
	hide_placeholder()


func node_completed(loaded_node: Node, loaded_cache_key: String):
	clear_currently_loaded_node()
	previous_loaded_node = loaded_node
	previous_cache_key = loaded_cache_key
	get_parent().add_child(loaded_node)


func node_failed(failed_cache_key: String):
	clear_currently_loaded_node()
	previous_loaded_node = null
	previous_cache_key = ""
	if failure_placeholder != null:
		var loaded_node: Node = failure_placeholder.instantiate()
		previous_loaded_node = loaded_node
		previous_cache_key = failed_cache_key
		get_parent().add_child(loaded_node)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if loading_cache_key.is_empty():
		if cache_key != previous_cache_key:
			load_next_asset()
	else:
		if cache_key != loading_cache_key:
			load_next_asset()
