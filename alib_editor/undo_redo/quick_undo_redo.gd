#! namespace ALibEditor class QuickUndoRedo

static func property(action_name:String, object, property_name:StringName, new_val, prev_val):
	var undo = EditorInterface.get_editor_undo_redo()
	undo.create_action(action_name)
	
	undo.add_do_property(object, property_name, new_val)
	undo.add_undo_property(object, property_name, prev_val)
	undo.commit_action()
