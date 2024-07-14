@tool
extends RefCounted

const queue_lib: GDScript = preload("./queue_lib.gd")
const processing_task_class = preload("./processing_task.gd")


var thread_queue: queue_lib.BlockingQueue
var thread_count: int
var threads: Array[Thread]
var disable_threads: bool = false


func _init():
	thread_queue = queue_lib.BlockingQueue.new()
	thread_count = 0


func start_thread():
	thread_count += 1
	print("Starting thread")
	var thread: Thread = Thread.new()
	# Third argument is optional userdata, it can be any variable.
	thread.start(self._thread_function)
	threads.push_back(thread)
	return thread


func start_threads(count: int):
	disable_threads = (count == 0)
	for i in range(count):
		start_thread()


func tell_all_threads_to_stop():
	for i in range(thread_count):
		thread_queue.push(self) # self = shutdown
	thread_count = 0


func stop_all_threads_and_wait():
	tell_all_threads_to_stop()
	for thread in threads:
		thread.wait_to_finish()
	thread_queue = queue_lib.BlockingQueue.new()
	threads.clear()


func push_work_obj(tw: processing_task_class):
	if disable_threads:
		_run_single_item_delayed.call_deferred(tw)
	else:
		self.thread_queue.push(tw)


func _run_single_item_delayed(tw: processing_task_class):
	tw._run_single_item.call_deferred()


# Run here and exit.
# The argument is the userdata passed from start().
# If no argument was passed, this one still needs to
# be here and it will be null.
func _thread_function():
	# Print the userdata ("Wafflecopter")
	print("I'm a thread!")
	while true:
		var tw_or_self: Object = thread_queue.pop()
		#print(tw)
		if tw_or_self == self:
			print("I was told to shutdown")
			break
		var tw: processing_task_class = tw_or_self as processing_task_class
		tw._run_single_item()
