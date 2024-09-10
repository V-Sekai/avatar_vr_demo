extends Node

const ugc_class = preload("./ugc_loader_manager.gd")

const godot_resource_loader_manager_class = preload("./godot_resource_loader_manager.gd")
#const content_resolver_class = preload("./content_resolver_manager.gd")
const download_manager_class = preload("./download_manager.gd")
const http_download_provider_class = preload("./http_download_provider.gd")
const local_download_provider_class = preload("./local_download_provider.gd")
const validator_manager_class = preload("./validator_manager.gd")
const cache_manager_class = preload("./cache_manager.gd")
const http_pool_class = preload("./http_pool.gd")
const validator_class = preload("./base_validator.gd")
const resource_parser = preload("./resource_parser.gd")
const processing_task_class = preload("./processing_task.gd")
const processing_thread_pool_class = preload("./processing_thread_pool.gd")
const scene_validate_task_class = preload("./processing_task_scene_validate.gd")

var _godot_resource_loader_manager: godot_resource_loader_manager_class = godot_resource_loader_manager_class.new()
#var _content_resolver: content_resolver_class = content_resolver_class.new()
var _download_manager: download_manager_class = download_manager_class.new()
var _validator_manager: validator_manager_class = validator_manager_class.new()
var _cache_manager: cache_manager_class = cache_manager_class.new()
var _http_pool: http_pool_class = http_pool_class.new()
var _processing_thread_pool: processing_thread_pool_class = processing_thread_pool_class.new()

# ASSET_OK, ASSET_HTTP_4XX, ASSET_HTTP_5XX, ASSET_HTTP_CONNECTION_ERROR, ASSET_HTTP_INTERRUPTED, ASSET_VALIDATION_ERROR, ASSET_INSTANTIATION_ERROR

const NUM_PROCESSING_THREADS: int = 8

# The amount of space a progress bar should dedicate to the downloading phase
const DOWNLOAD_PROGRESS_BAR_RATIO = 0.9

# Local write access to cache permits executing code.
# May be set to true for debugging, but subject to security risk. See comment below.
const REVALIDATE_LOCAL_CACHE: bool = false

func get_godot_resource_loader_manager() -> godot_resource_loader_manager_class:
	return _godot_resource_loader_manager

#func get_content_resolver() -> content_resolver_class:
#	return _content_resolver
#
func get_download_manager() -> download_manager_class:
	return _download_manager

func get_validator_manager() -> validator_manager_class:
	return _validator_manager

func get_cache_manager() -> cache_manager_class:
	return _cache_manager

func get_http_pool() -> http_pool_class:
	return _http_pool

func get_processing_thread_pool() -> processing_thread_pool_class:
	return _processing_thread_pool

func _init():
	_godot_resource_loader_manager.name = "GodotResourceLoaderManager"
	add_child(_godot_resource_loader_manager)
	#_content_resolver.name = "ContentResolver"
	#add_child(_content_resolver)
	_download_manager.name = "DownloadManager"
	add_child(_download_manager)
	_validator_manager.name = "ValidatorManager"
	add_child(_validator_manager)
	_cache_manager.name = "CacheManager"
	add_child(_cache_manager)
	_http_pool.name = "HttpPool"
	add_child(_http_pool)

	var http_download_provider: http_download_provider_class = http_download_provider_class.new()
	http_download_provider.http_pool = _http_pool
	_download_manager.add_provider(http_download_provider)

	var local_download_provider: local_download_provider_class = local_download_provider_class.new()
	_download_manager.add_provider(local_download_provider)


func _enter_tree():
	_processing_thread_pool.start_threads(NUM_PROCESSING_THREADS)

func _exit_tree():
	_processing_thread_pool.stop_all_threads_and_wait()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func write_dummy_scene(path: String):
	var ps: PackedScene = PackedScene.new()
	var prism: MeshInstance3D = MeshInstance3D.new()
	prism.mesh = PrismMesh.new()
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.47, 0.2, 1.0)
	mat.rim_enabled = true
	mat.rim_tint = 1.0
	mat.rim = 1.0
	prism.material_override = mat
	ps.pack(prism)
	prism.queue_free()
	ResourceSaver.save(ps, path, ResourceSaver.FLAG_BUNDLE_RESOURCES)


class BackgroundLoadRequestBase:

	func start_load(disk_path: String):
		pass

	func wait_to_finish() -> Resource:
		return null

	func cancel():
		pass


class AssetLoadRequest:
	extends RefCounted

	enum State {
		STATE_NEW,
		STATE_URI_RESOLVE,
		STATE_DOWNLOADING,
		STATE_PROCESSING,
		STATE_LOADING,
		STATE_INSTANTIATING,
		STATE_DONE,
		STATE_MAX,
	}

	var source_uri: String
	var resolved_uri: String
	var cache_key: String
	var processor_file_ext: String # Includes "."
	var load_file_ext: String # Includes "."
	var processor: processing_task_class = null
	var validator: validator_class

	var _cancelled: bool = false
	var state: State = State.STATE_NEW
	var download_request: download_manager_class.DownloadRequestBase
	var godot_resource_load_request: godot_resource_loader_manager_class.InProgressTask
	var disk_cache_path: String
	var disk_tmp_path: String # Only set while loading.
	var scene_load_processor: scene_validate_task_class

	func cancel():
		_cancelled = true
		match state:
			State.STATE_URI_RESOLVE:
				pass
			State.STATE_DOWNLOADING:
				download_request.cancel()
			State.STATE_PROCESSING:
				processor.cancel()
			State.STATE_LOADING:
				godot_resource_load_request.cancel()
			State.STATE_INSTANTIATING:
				scene_load_processor.cancel()
			_:
				pass

	func get_percentage():
		match state:
			State.STATE_URI_RESOLVE:
				pass
			State.STATE_DOWNLOADING:
				DOWNLOAD_PROGRESS_BAR_RATIO * download_request.get_percentage()
			State.STATE_PROCESSING:
				return 100.0 * DOWNLOAD_PROGRESS_BAR_RATIO + (1.0 - DOWNLOAD_PROGRESS_BAR_RATIO) * 0.25 * processor.get_percentage()
			State.STATE_LOADING:
				return 100.0 * DOWNLOAD_PROGRESS_BAR_RATIO + (1.0 - DOWNLOAD_PROGRESS_BAR_RATIO) * (0.25 + 0.5 * godot_resource_load_request.get_percentage())
			State.STATE_INSTANTIATING:
				return 100.0 * DOWNLOAD_PROGRESS_BAR_RATIO + (1.0 - DOWNLOAD_PROGRESS_BAR_RATIO) * (0.75 + 0.25 * scene_load_processor.get_percentage())
			State.STATE_DONE:
				return 100.0
			_:
				pass
		return 0.0

	func perform_download(ugc: ugc_class) -> bool:
		state = State.STATE_DOWNLOADING
		var is_godot_resource: bool = (processor == null)
		if is_godot_resource:
			processor_file_ext = "" # Should this be an assert instead?
		download_request = ugc.get_download_manager().create_download_request(resolved_uri, disk_tmp_path + processor_file_ext, is_godot_resource)
		var success: bool = await download_request.perform()
		if _cancelled:
			success = false
		# download_request.get_content_type()
		if not success:
			delete_tmp_from_cache(ugc, not _cancelled and download_request.is_permanent_failure())
		return success

	func perform_processor(ugc: ugc_class) -> Object:
		if processor == null:
			return self
		state = State.STATE_PROCESSING
		processor.input_disk_path = disk_tmp_path + processor_file_ext
		processor.output_res_path = disk_tmp_path
		ugc.get_processing_thread_pool().push_work_obj(processor)
		var success: bool = await processor.wait_to_finish()
		if _cancelled:
			success = false
		if !success:
			delete_tmp_from_cache(ugc, not _cancelled)
			return null
		if processor.output_resource != null:
			return processor.output_resource
		return self # Success, but no Resource in memory.

	func perform_godot_resource_load(ugc: ugc_class, disk_tmp_path: String) -> Resource:
		state = State.STATE_LOADING
		godot_resource_load_request = ugc.get_godot_resource_loader_manager().load(disk_cache_path)
		var ret: Resource = await godot_resource_load_request.wait_for_completed()
		if _cancelled:
			return null
		return ret

	func perform_instantiate(ugc: ugc_class, validator: validator_class, packed_scene: PackedScene) -> Node3D:
		state = State.STATE_INSTANTIATING
		scene_load_processor = scene_validate_task_class.new(ugc.get_validator_manager(), validator, packed_scene)
		ugc.get_processing_thread_pool().push_work_obj(scene_load_processor)
		var success: bool = await scene_load_processor.wait_to_finish()
		if !success:
			return null
		if scene_load_processor.output_node != null:
			if _cancelled:
				# We have to avoid memory leaks
				scene_load_processor.output_node.queue_free()
				return null
			state = State.STATE_DONE
			return scene_load_processor.output_node
		return null

	func create_tmp_cache(ugc: ugc_class):
		disk_tmp_path = ugc.get_cache_manager().create_tmp_path(cache_key)

	func delete_tmp_from_cache(ugc: ugc_class, is_permanent: bool):
		ugc.get_cache_manager().delete_tmp_file(disk_tmp_path)
		if is_permanent:
			ugc.get_cache_manager().taint_cache(cache_key) # Permanent failure.
		disk_tmp_path = ""

	func save_tmp_to_cache(ugc: ugc_class):
		ugc.get_cache_manager().save_tmp_file_to_cache(cache_key, disk_tmp_path)
		# TODO: Do we need to delete disk_tmp_path?
		disk_tmp_path = ""


func create_load_request(source_uri: String, resolved_uri: String, cache_key: String, file_ext: String, validator: validator_class, processor: processing_task_class = null) -> AssetLoadRequest:
	var ret := AssetLoadRequest.new()
	ret.source_uri = source_uri
	ret.resolved_uri = resolved_uri
	ret.cache_key = cache_key
	ret.validator = validator
	ret.processor_file_ext = file_ext
	ret.processor = processor
	return ret


func load_asset(alr: AssetLoadRequest) -> Node3D:
	#alr.state = AssetLoadRequest.State.STATE_URI_RESOLVE
	#if alr.resolved_uri.is_empty():
	#	alr.resolved_uri = await get_content_resolver().resolve(alr.source_uri)
	if alr.resolved_uri.is_empty() or alr._cancelled:
		return null # Failed.

	# If disk cache becomes async, introduce a state for it
	#var dir_access: DirAccess = _cache_manager.get_dir_access() # return dir_access.open("user://")
	alr.disk_cache_path = _cache_manager.get_disk_cache_path(alr.cache_key)
	if alr.disk_cache_path.is_empty() or alr._cancelled:
		return null # Failed (could be tainted)

	var skipped_validation_result_resource: PackedScene

	if not _cache_manager.has_cache(alr.cache_key):
		alr.create_tmp_cache(self)
		var success: bool = await alr.perform_download(self)
		if not success:
			return null # Failed.
		var out_obj: Object = await alr.perform_processor(self)
		if out_obj == null:
			return null # Failed.
		if out_obj != alr:
			skipped_validation_result_resource = out_obj as PackedScene
		else:
			if not resource_parser.validate_resource(alr.disk_tmp_path, alr.validator.get_resource_class_whitelist(), alr.validator.get_external_path_whitelist(), false):
				alr.delete_tmp_from_cache(self, true)
				return null # Failed.
		alr.save_tmp_to_cache(self)

	# Note: It is possible for a malicious user with disk access to embed executable code into the cache.
	if REVALIDATE_LOCAL_CACHE:
		skipped_validation_result_resource = null
		# WARNING: This branch is only useful if a malicious local user has had write access to the disk in the past.
		# (If this is necessary, you have already been pwned)
		# If such a malicious user still has write access to the disk, this codepath is subject to TOCTTOU attacks.
		# Storing cache on a remote disk is unsafe, due to the TOCTTOU risk.
		if not resource_parser.validate_resource(alr.disk_cache_path, alr.validator.get_resource_class_whitelist(), alr.validator.get_external_path_whitelist(), true):
			_cache_manager.taint_cache(alr.cache_key) # Permanent failure.
			return null

	var ps: PackedScene
	if skipped_validation_result_resource != null:
		ps = skipped_validation_result_resource
	else:
		alr.godot_resource_load_request = _godot_resource_loader_manager.load(alr.disk_cache_path)
		ps = await alr.godot_resource_load_request.wait_for_completed() as PackedScene
	if alr._cancelled:
		return null
	if ps == null:
		_cache_manager.taint_cache(alr.cache_key) # Permanent failure????
		return null # Failed.
	var out_node: Node3D = await alr.perform_instantiate(self, alr.validator, ps)
	if out_node == null:
		_cache_manager.taint_cache(alr.cache_key) # Permanent failure????
		return null # Failed.
	return out_node
