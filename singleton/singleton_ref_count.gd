#! namespace Singleton.RefCount
#class_name SingletonRefCount
#extends "res://addons/addon_lib/brohd/singleton/singleton_base.gd"
extends Singleton.Base

var instance_refs = []

static func _get_singleton_type():
	return SingletonType.REF_COUNT



static func _get_instance(script:Script, print_err:=true):
	#var root = Engine.get_main_loop().root
	var instance = _get_singleton_node_or_null(script, script._get_singleton_node_path(), false)
	#var singleton_node = _get_singleton_node_or_null(SINGLETONS_NODE, false)
	if is_instance_valid(instance):
		return instance
	
	if print_err:
		print("Could not get %s instance." % script.get_singleton_name())

#static func register_node(node:Node):
	#pass

static func _register_node(script:Script, node:Node):
	#var singleton_node = _get_singleton_node_or_null(SINGLETONS_NODE, false)
	var instance = _get_singleton_node_or_null(script, script._get_singleton_node_path(), true, node)
	#if not is_instance_valid(instance):
		#instance = script.new(node)
		#instance.name = script.get_singleton_name()
		#singleton_node.add_child(instance)
	
	instance.instance_refs.append(node)
	return instance

#static func unregister_node(script:Script, node:Node):
	#


func unregister_node(node:Node):
	instance_refs.erase(node)
	if instance_refs.is_empty():
		_all_unregistered_callback()
		queue_free()

func _all_unregistered_callback():
	pass

func _init(node:Node):
	
	pass
