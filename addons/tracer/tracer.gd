extends Node

signal entered_span

enum Level {
	Error,
	Warn,
	Info,
	Debug,
	Trace,
}


class Trace:
	var level: Level
	var msg: String
	var module: String = "unknown"
	var function_name: String = "unknown"
	var timestamp: String = (
		Time.get_datetime_string_from_system()
	)
	var thread_id := 1

	func _init(
		msg: String, level: Level, new_thread_id := 0
	) -> void:
		self.msg = msg
		self.level = level
		var st = get_stack()
		if st.size() > 2:
			module = st[2].source.trim_prefix("res://")
			function_name = st[2].function
		else:
			function_name = "unknown"
		thread_id = new_thread_id


var current_span: Trace = null:
	set = set_current_span


func set_current_span(span: Trace) -> void:
	current_span = span
	entered_span.emit()


func info(msg: String) -> void:
	current_span = Trace.new(
		msg, Level.Info, OS.get_thread_caller_id()
	)


func debug(msg: String) -> void:
	current_span = Trace.new(
		msg, Level.Debug, OS.get_thread_caller_id()
	)


func warn(msg: String) -> void:
	current_span = Trace.new(
		msg, Level.Warn, OS.get_thread_caller_id()
	)


func error(msg: String) -> void:
	current_span = Trace.new(
		msg, Level.Error, OS.get_thread_caller_id()
	)


func trace(msg: String) -> void:
	current_span = Trace.new(msg, Level.Trace)


static func level_string(level: Level) -> String:
	return Level.keys()[level].to_upper()


static func level_colored(level: Level) -> String:
	var color = ""
	match level:
		Level.Info:
			color = "[color=green]%s[/color]"
		_:
			color = "[color=white]%s[/color]"
	return color % level_string(level)