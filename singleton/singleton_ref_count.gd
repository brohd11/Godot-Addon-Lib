#! namespace Singleton.RefCount
extends Singleton.Base


static func _get_singleton_type() -> SingletonType:
	return SingletonType.REF_COUNT

static func _get_instance(script:Script, print_err:=true):
	var instance = _get_singleton_node_or_null(script, script._get_singleton_node_path(), false)
	if is_instance_valid(instance):
		return instance
	
	if print_err:
		print("Could not get %s instance." % script.get_singleton_name())

static func _register_node(script:Script, node):
	var instance = _get_singleton_node_or_null(script, script._get_singleton_node_path(), true, node)
	instance.instance_refs.append(node)
	return instance

## Instance members

var instance_refs = []

func unregister_node(node):
	instance_refs.erase(node)
	if instance_refs.is_empty():
		_all_unregistered_callback()
		queue_free()

func _all_unregistered_callback():
	pass

func _init(node):
	pass


## Implement in extended classes
# Use 'PE_STRIP_CAST_SCRIPT' to auto strip type casts with plugin exporter, if the class is not a global name
#static func register_node(node:Node):
	#pass _register(PE_STRIP_CAST_SCRIPT, node) # pass the preloaded script of self

#static func unregister_node(node:Node):
	#_unregister(PE_STRIP_CAST_SCRIPT, node) # pass the preloaded script of self
