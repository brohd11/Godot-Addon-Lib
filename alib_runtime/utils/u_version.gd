#! namespace ALibRuntime.Utils class UVersion

static var _version_info:= {}

static func get_major_version():
	if not _version_info.is_empty():
		return _version_info.major
	_version_info = Engine.get_version_info()
	return _version_info.major

static func get_minor_version():
	if not _version_info.is_empty():
		return _version_info.minor
	_version_info = Engine.get_version_info()
	return _version_info.minor

static func get_patch():
	if not _version_info.is_empty():
		return _version_info.patch
	_version_info = Engine.get_version_info()
	return _version_info.patch
