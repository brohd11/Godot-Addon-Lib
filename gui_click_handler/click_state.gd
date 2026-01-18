#! namespace ClickHandlers class ClickState

enum State{
	NONE,
	
	LMB_PRESSED,
	#LMB_PRESSED_CTRL,
	#LMB_PRESSED_SHIFT,
	LMB_DOUBLE_CLICK,
	LMB_RELEASED,
	
	RMB_PRESSED,
	#RMB_PRESSED_CTRL,
	#RMB_PRESSED_SHIFT,
	RMB_DOUBLE_CLICK,
	RMB_RELEASED,
	
	MMB_PRESSED,
	#MMB_PRESSED_CTRL,
	#MMB_PRESSED_SHIFT,
	MMB_DOUBLE_CLICK,
	MMB_RELEASED,
	
	WHEEL_UP,
	WHEEL_DOWN,
	WHEEL_LEFT,
	WHEEL_RIGHT
}

enum Modifier {
	NONE,
	SHIFT,
	CTRL,
}

static func get_click_state(event:InputEvent) -> State:
	if not event is InputEventMouseButton:
		return State.NONE
	event = event as InputEventMouseButton
	
	if event.button_index == 1:
		if event.double_click:
			return State.LMB_DOUBLE_CLICK
		elif event.pressed:
			return State.LMB_PRESSED
			#if event.ctrl_pressed:
				#return State.LMB_PRESSED_CTRL
			#elif event.shift_pressed:
				#return State.LMB_PRESSED_SHIFT
			#else:
				#return State.LMB_PRESSED
		elif not event.pressed:
			return State.LMB_RELEASED
		
	elif event.button_index == 2:
		if event.double_click:
			return State.RMB_DOUBLE_CLICK
		elif event.pressed:
			return State.RMB_PRESSED
			#if event.ctrl_pressed:
				#return State.RMB_PRESSED_CTRL
			#elif event.shift_pressed:
				#return State.RMB_PRESSED_SHIFT
			#else:
				#return State.RMB_PRESSED
		elif not event.pressed:
			return State.RMB_RELEASED
	
	elif event.button_index == 3:
		if event.double_click:
			return State.MMB_DOUBLE_CLICK
		elif event.pressed:
			return State.MMB_PRESSED
			#if event.ctrl_pressed:
				#return State.MMB_PRESSED_CTRL
			#elif event.shift_pressed:
				#return State.MMB_PRESSED_SHIFT
			#else:
				#return State.MMB_PRESSED
		elif not event.pressed:
			return State.MMB_RELEASED
	
	elif event.button_index == 4:
		if event.pressed:
			return State.WHEEL_UP
	elif event.button_index == 5:
		if event.pressed:
			return State.WHEEL_DOWN
	elif event.button_index == 6:
		if event.pressed:
			return State.WHEEL_LEFT
	elif event.button_index == 7:
		if event.pressed:
			return State.WHEEL_RIGHT
	
	return State.NONE

static func get_click_modifier(event:InputEvent) -> Modifier:
	if event.ctrl_pressed:
		return Modifier.CTRL
	elif event.shift_pressed:
		return Modifier.SHIFT
	else:
		return Modifier.NONE
