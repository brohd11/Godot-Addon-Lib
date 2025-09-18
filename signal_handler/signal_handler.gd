class_name SignalHandler

class _NoArg: pass

static func create_signal_adapter(core_logic:Callable, callback=null, pass_args:=false) -> Callable:
	var no_arg = _NoArg.new()
	var handler = func(
		a = no_arg, b = no_arg, c = no_arg,
		d = no_arg, e = no_arg, f = no_arg
		):
		
		if core_logic.is_valid():
			core_logic.call()
		
		if callback == null:
			return
		if not callback.is_valid():
			return
		
		if pass_args:
			var all_args = [a, b, c, d, e, f]
			var actual_args = []
			for arg in all_args:
				if arg is not _NoArg:
					actual_args.append(arg)
				else:
					break
			
			callback.callv(actual_args)
		else:
			callback.call()
	
	return handler
