# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_asset_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const URO_AVATAR_PREFIX = "avatar_"
const URO_MAP_PREFIX = "map_"
const URO_PROP_PREFIX = "prop_"
const URO_GAME_MODE_PREFIX = "game_mode_"

const ASSET_CACHE_PATH = "user://asset_cache"
const CACHE_FILE_EXTENSION = "scn"
const ETAG_FILE_EXTENSION = "etag"

const HTTP_DOWNLOAD_CHUNK_SIZE = 65536

const INVALID_REQUEST = 0
const HTTP_REQUEST = 1
const LOCAL_FILE_REQUEST = 2
const URO_REQUEST = 3

var avatar_forbidden_path: String = "res://addons/vsk_avatar/avatars/error_handlers/avatar_forbidden.tscn"
var avatar_not_found_path: String = "res://addons/vsk_avatar/avatars/error_handlers/avatar_not_found.tscn"
var avatar_error_path: String = "res://addons/vsk_avatar/avatars/error_handlers/avatar_error.tscn"
var teapot_path: String = "res://addons/vsk_avatar/avatars/error_handlers/teapot.tscn"
var loading_avatar_path: String = "res://addons/vsk_avatar/avatars/loading/loading_orb.tscn"

var avatar_whitelist: PackedStringArray = []
var map_whitelist: PackedStringArray = []
var prop_whitelist: PackedStringArray = []
var game_mode_whitelist: PackedStringArray = []


enum { ASSET_OK, ASSET_UNKNOWN_FAILURE, ASSET_UNAUTHORIZED, ASSET_FORBIDDEN, ASSET_NOT_FOUND, ASSET_INVALID, ASSET_I_AM_A_TEAPOT, ASSET_UNAVAILABLE_FOR_LEGAL_REASONS, ASSET_NOT_WHITELISTED, ASSET_FAILED_VALIDATION_CHECK, ASSET_RESOURCE_LOAD_FAILED }

enum { STAGE_PENDING, STAGE_DOWNLOADING, STAGE_BACKGROUND_LOADING, STAGE_VALIDATING, STAGE_INSTANCING, STAGE_DONE, STAGE_CANCELLING }

enum user_content_type { USER_CONTENT_AVATAR, USER_CONTENT_MAP, USER_CONTENT_PROP, USER_CONTENT_GAME_MODE, USER_CONTENT_UNKNOWN }

signal request_started(p_url)
signal request_complete(p_url, request_object, p_response_code)
signal request_cancelled(p_url)

var request_objects: Dictionary = {}

var always_add_extension: String = ".bin" # Avoids risk of peppering of .zip / .exe / .dll on disk.
var tmp_add_extension: String = ".tmp"

var dir_access: DirAccess


func _get_relative_disk_cache_path(cache_key: String, ignore_taint_flag: bool=false) -> String:
	# dir_access.cr
	if not cache_key.is_valid_filename(): # also checks for path separators such as / or \ or :
		return ""
	var ret: String = cache_key + always_add_extension
	if not ignore_taint_flag and dir_access.dir_exists(ret):
		# taint_cache was called.
		return ""
	return ret


func get_disk_cache_path(cache_key: String) -> String:
	var relative_path: String = _get_relative_disk_cache_path(cache_key)
	if relative_path.is_empty():
		return ""
	return ASSET_CACHE_PATH.path_join(relative_path)


func has_cache(cache_key: String) -> bool:
	var disk_cache_path: String = _get_relative_disk_cache_path(cache_key)
	if disk_cache_path.is_empty(): # Could be invalid or tainted.
		return false
	return dir_access.file_exists(disk_cache_path)


func taint_cache(cache_key: String) -> Error: # Permanent failure.
	return dir_access.make_dir(_get_relative_disk_cache_path(cache_key))


func create_tmp_path(cache_key: String) -> String:
	var disk_cache_path: String = get_disk_cache_path(cache_key)
	if disk_cache_path.is_empty():
		push_error("Attempt to create_tmp_path for " + str(cache_key) + " without checking get_disk_cache_path().is_empty()")
		return ""
	return get_disk_cache_path(cache_key) + tmp_add_extension


func delete_tmp_file(disk_tmp_path: String) -> Error:
	if not disk_tmp_path.begins_with(ASSET_CACHE_PATH) or not disk_tmp_path.ends_with(tmp_add_extension):
		push_error("Invalid call to delete_tmp_file: " + str(disk_tmp_path))
		return FAILED
	return dir_access.remove_absolute(disk_tmp_path)


# Currently unused
func delete_cache_file(cache_key: String, ignore_taint_flag: bool) -> Error:
	var disk_cache_path: String = _get_relative_disk_cache_path(cache_key, ignore_taint_flag)
	return dir_access.remove(disk_cache_path)


func save_tmp_file_to_cache(cache_key: String, disk_tmp_path: String) -> Error:
	if not disk_tmp_path.begins_with(ASSET_CACHE_PATH) or not disk_tmp_path.ends_with(tmp_add_extension):
		push_error("Invalid call to save_tmp_to_cache for " + str(cache_key) + " from tmp " + str(disk_tmp_path))
		return FAILED
	var disk_cache_path: String = get_disk_cache_path(cache_key)
	if disk_cache_path.is_empty():
		push_error("Attempt to save_tmp_to_cache for " + str(cache_key) + " without checking get_disk_cache_path().is_empty()")
		return FAILED
	return dir_access.rename_absolute(disk_tmp_path, disk_cache_path)


# Currently unused
func clear_cache() -> Error:
	if dir_access.list_dir_begin() != OK:
		printerr("Failed to list directory.")
		return FAILED

	var current_file_name: String = dir_access.get_next()
	var all_deleted: int = OK

	while not current_file_name.is_empty():
		if current_file_name != "." and current_file_name != "..":
			if dir_access.remove(current_file_name) != OK:
				all_deleted = FAILED
		current_file_name = dir_access.get_next()

	return all_deleted


func _ready():
	# if !Engine.is_editor_hint():
	if not DirAccess.dir_exists_absolute(ASSET_CACHE_PATH):
		if DirAccess.make_dir_absolute(ASSET_CACHE_PATH) != OK:
			if !Engine.is_editor_hint():
				printerr("Could not create asset cache directory!")
	dir_access = DirAccess.open(ASSET_CACHE_PATH)

'''
	#var etag_path: String = "%s/%s.%s" % [ASSET_CACHE_PATH, String(url).md5_text(), ETAG_FILE_EXTENSION]
	#if FileAccess.file_exists(etag_path):
	#var etag_file = FileAccess.open(etag_path, FileAccess.READ)
	#var resource_path: String = "%s/%s.%s" % [ASSET_CACHE_PATH, String(url).md5_text(), CACHE_FILE_EXTENSION]

func _complete_request(p_request_object: Dictionary, p_response_code: int) -> void:
	_destroy_request(p_request_object["request_path"])
	request_complete.emit(p_request_object["request_path"], p_request_object, p_response_code)


func cancel_request(p_request_path: String) -> void:
	if request_objects.has(p_request_path):
		var request_object: Dictionary = request_objects[p_request_path]
		_destroy_request(p_request_path)
		request_cancelled.emit(request_object["request_path"])


func _get_request_data_progress_internal(p_request_object: Dictionary) -> Dictionary:
	var object = p_request_object.get("object")
	if typeof(object) != TYPE_NIL and object is HTTPRequest:
		return {"body_size": p_request_object["object"].get_body_size(), "downloaded_bytes": p_request_object["object"].get_downloaded_bytes()}
	else:
		return {"body_size": 0, "downloaded_bytes": 0}


func get_request_data_progress(p_request_path: String) -> Dictionary:
	var ret: Dictionary = {}
	if request_objects.has(p_request_path):
		var request_object: Dictionary = request_objects[p_request_path]
		match request_object["request_id"]:
			HTTP_REQUEST:
				ret = _get_request_data_progress_internal(request_object)
			URO_REQUEST:
				ret = _get_request_data_progress_internal(request_object)
		#print("Request " + str(p_request_path) + ": " + str(request_object) + " is still going: " + str(ret))
	return ret


static func get_download_progress_string(p_downloaded_bytes: int, p_body_size: int) -> String:
	var downloaded_bytes_data_block: Dictionary = data_storage_units_const.convert_bytes_to_data_unit_block(p_downloaded_bytes)
	var body_size_data_block: Dictionary = data_storage_units_const.convert_bytes_to_data_unit_block(p_body_size)

	var downloaded_bytes_largest_unit: int = data_storage_units_const.get_largest_unit_type(downloaded_bytes_data_block)
	var body_size_largest_unit: int = data_storage_units_const.get_largest_unit_type(body_size_data_block)

	var downloaded_bytes_string: String = "%s%s" % [data_storage_units_const.get_string_for_unit_data_block(downloaded_bytes_data_block, downloaded_bytes_largest_unit), data_storage_units_const.get_string_for_unit_type(downloaded_bytes_largest_unit)]

	var body_size_string: String = "%s%s" % [data_storage_units_const.get_string_for_unit_data_block(body_size_data_block, body_size_largest_unit), data_storage_units_const.get_string_for_unit_type(body_size_largest_unit)]

	return "%s/%s" % [downloaded_bytes_string, body_size_string]


func setup() -> void:
	if !Engine.is_editor_hint():
		if not DirAccess.dir_exists_absolute(ASSET_CACHE_PATH):
			if DirAccess.make_dir_absolute(ASSET_CACHE_PATH) != OK:
				printerr("Could not create asset cache directory!")
'''
