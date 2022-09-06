tool
extends "base_modifier.gd"


export var iterations : int = 3
export var offset_step : float = 0.01
export var consecutive_step_multiplier : float = 0.5

var index_common = 0
var mutex : Mutex
var running_threads : Semaphore
var transforms_copy
var offset


func _init() -> void:
	display_name = "Relax Position"
	category = "Edit"


func relaxThread(transforms):
	var i
	var t_size = transforms.list.size()
	while true:
		mutex.lock()
		i = index_common
		index_common += 1
		mutex.unlock()
		
		if i >= t_size:
			return i
		
		var min_vector = Vector3.ONE * 99999
		# Find the closest point
		for j in t_size:
			if i == j:
				continue
			var d = transforms.list[i].origin - transforms.list[j].origin
			if d.length() < min_vector.length():
				min_vector = d
		var newpos = transforms_copy[i].origin + min_vector.normalized() * offset
		mutex.lock()
		transforms_copy[i].origin = newpos
		mutex.unlock()


func _process_transforms(transforms, _global_seed) -> void:
	if transforms.list.size() < 2:
		return
	
	var t0 = Time.get_ticks_msec()
	
	offset = offset_step
	mutex = Mutex.new()
	running_threads = Semaphore.new()
	
	# Setup starting conditions
	index_common = 0
	transforms_copy = transforms.list.duplicate()
	
	var number_of_threads = 4#OS.get_processor_count() - 0
	print("Starting threads ", number_of_threads)
	var threads = []
	for thread_n in number_of_threads:
		var thread = Thread.new()
		threads.append(thread)
		thread.start(self, "relaxThread", transforms)
	
	for thread in threads:
		thread.wait_to_finish()
		
	print("Common index: ", index_common)
	print("Time: ", Time.get_ticks_msec() - t0, "ms")
	
#	for iteration in iterations:
#		for i in transforms.list.size():
#			var min_vector = Vector3(99999, 99999, 99999)
#			# Find the closest point
#			for j in transforms.list.size():
#				if i == j:
#					continue
#				var d = transforms.list[i].origin - transforms.list[j].origin
#				if d.length() < min_vector.length():
#					min_vector = d
#
#			# move away from closest point
#			transforms.list[i].origin += min_vector.normalized() * offset
#
#		offset *= consecutive_step_multiplier
