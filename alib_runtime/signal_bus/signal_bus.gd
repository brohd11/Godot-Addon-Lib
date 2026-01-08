
var _signal_instances:= {}

func signal_emit(signal_name:StringName, data:Dictionary={}):
	var bus = get_signal(signal_name)
	bus.emit(data)

func signal_emitv(signal_name:StringName, arg_array:Array=[]):
	var bus = get_signal(signal_name)
	bus.emitv(arg_array)

func subscribe(signal_name:StringName, callable:Callable):
	var wrapper = create_or_get_signal(signal_name)
	wrapper.subscribe(callable)

func unsubscribe(signal_name:StringName, callable:Callable):
	var wrapper = create_or_get_signal(signal_name)
	wrapper.unsubscribe(callable)
	if not wrapper.has_subscribers():
		_signal_instances.erase(signal_name)

func get_signal_names():
	return _signal_instances.keys()

func get_signal(signal_name:StringName):
	return create_or_get_signal(signal_name)

func create_or_get_signal(signal_name:StringName) -> SignalWrapper:
	if _signal_instances.has(signal_name):
		return _signal_instances[signal_name]
	var new_signal = SignalWrapper.new()
	_signal_instances[signal_name] = new_signal
	return new_signal

func has_signals():
	return _signal_instances.size() > 0

class SignalWrapper:
	
	signal _std_signal
	signal _data_signal(data:Dictionary)
	
	var _callables:= []
	
	func emit(data:Dictionary={}):
		if data.is_empty():
			_std_signal.emit()
		else:
			_data_signal.emit(data)
	
	func emitv(arg_array:Array=[]):
		if arg_array.is_empty():
			for c:Callable in _callables:
				c.call()
		else:
			for c:Callable in _callables:
				c.callv(arg_array)
	
	func subscribe(callable:Callable):
		_connect_signal(_std_signal, callable)
		_connect_signal(_data_signal, callable)
	
	func unsubscribe(callable:Callable):
		_disconnect_signal(_std_signal, callable)
		_disconnect_signal(_data_signal, callable)
	
	func _connect_signal(_signal:Signal, callable:Callable):
		if not _signal.is_connected(callable):
			_signal.connect(callable)
		if not _callables.has(callable):
			_callables.append(callable)
	
	func _disconnect_signal(_signal:Signal, callable:Callable):
		if _signal.is_connected(callable):
			_signal.disconnect(callable)
		_callables.erase(callable)
	
	func has_subscribers():
		return _callables.size() > 0
