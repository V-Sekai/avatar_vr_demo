# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# background_loader.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const queue_lib = preload("./queue_lib.gd")

class InProgressTask extends RefCounted:
	var path: String
	var _refcount: int = 0
	var progress_value: float = 0.0

	func _init(path_: String):
		path = path_

	func ref():
		_refcount += 1

	signal completed(resource: Resource)

	func wait_for_completed() -> Resource:
		return await completed

	func get_percentage() -> float:
		return progress_value * 100.0

	func cancel():
		_refcount -= 1
		if _refcount == 0:
			completed.emit(null)

	func was_cancelled():
		return _refcount <= 0

var _loading_tasks: Dictionary = {}
var _loading_queue: queue_lib.Queue = queue_lib.Queue.new()
var _in_progress_tasks: Array[InProgressTask]

const CONCURRENT_THREADED_LOADS: int = 8

func _ready() -> void:
	set_process(true)

func _process(_deltatime: float) -> void:
	for i in range(len(_in_progress_tasks) - 1, -1, -1):
		var ipt: InProgressTask = _in_progress_tasks[i]
		var progress_array: Array[float]
		progress_array.append(0.0)
		var stat: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(ipt.path, progress_array)
		ipt.progress_value = progress_array[0]
		match stat:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				pass
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_in_progress_tasks.remove_at(i)
				ipt.completed.emit(null)
			ResourceLoader.THREAD_LOAD_LOADED:
				_in_progress_tasks.remove_at(i)
				ipt.completed.emit(ResourceLoader.load_threaded_get(ipt.path))
	while len(_in_progress_tasks) < CONCURRENT_THREADED_LOADS:
		var ipt: InProgressTask = _loading_queue.pop() as InProgressTask
		if ipt == null:
			break
		if ipt.was_cancelled():
			break
		_in_progress_tasks.append(ipt)
		var x = await ipt.completed

func load(path: String) -> InProgressTask:
	var ipt: InProgressTask = null
	if _loading_tasks.has(path):
		ipt = _loading_tasks[path] as InProgressTask
		if ipt.was_cancelled():
			ipt = null
	if ipt == null:
		ipt = InProgressTask.new(path)
		_loading_tasks[path] = ipt
		if len(_in_progress_tasks) < CONCURRENT_THREADED_LOADS:
			_in_progress_tasks.append(ipt)
		else:
			_loading_queue.push(ipt)
	ipt.ref()
	return ipt

#class ResLoader:
#	extends RefCounted
#
#	var bg_loader_manager: Object # containing class
#	var ipt: InProgressTask # while loading
#
#	func _init(bg_loader_manager_: Object):
#		bg_loader_manager = bg_loader_manager_
#
#	func start_load(disk_path: String):
#		ipt = bg_loader_manager.load(disk_path)
#
#	func wait_to_finish() -> Resource:
#		return await ipt.completed
#
#	func cancel():
#		if ipt != null:
#			ipt.cancel()
#			ipt = null
