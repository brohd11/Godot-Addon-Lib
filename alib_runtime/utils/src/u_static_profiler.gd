class_name UStaticProfiler

static var _desired_iterations = 0
static var _iteration_count = 0
static var _iteration_time = 0


static func set_iteration_amount(count:int):
	_desired_iterations = count
	_iteration_count = 0
	_iteration_time = 0

static func increment_profiler(time):
	_iteration_count += 1
	_iteration_time += time
	if _iteration_count == _desired_iterations:
		print("Avg time: %s, %s iterations." % [_iteration_time / _iteration_count, _iteration_count])
		_iteration_count = 0
		_iteration_time = 0
