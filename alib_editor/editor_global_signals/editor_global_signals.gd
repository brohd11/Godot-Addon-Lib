class_name EditorGlobalSignals

const SignalBus = preload("res://addons/addon_lib/brohd/alib_runtime/signal_bus/signal_bus.gd")

const BUS_NAME = &"EditorGlobalSignals"

static func get_signal_bus() -> SignalBus:
	return SignalBusSingleton.get_bus(BUS_NAME)

static func subscribe(signal_name:StringName, callable:Callable):
	SignalBusSingleton.subscribe(BUS_NAME, signal_name, callable)

static func unsubscribe(signal_name:StringName, callable:Callable):
	SignalBusSingleton.unsubscribe(BUS_NAME, signal_name, callable)

static func signal_emit(signal_name:StringName, data:Dictionary={}):
	SignalBusSingleton.signal_emit(BUS_NAME, signal_name, data)

static func signal_emitv(signal_name:StringName, arg_array:Array=[]):
	SignalBusSingleton.signal_emitv(BUS_NAME, signal_name, arg_array)
