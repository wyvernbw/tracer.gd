extends Node

signal entered_span

enum Level {
	Error = 1,
	Warn = 2,
	Info = 4,
	Debug = 8,
	Trace = 16,
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
	match level:
		Level.Info:
			return "INFO"
		Level.Debug:
			return "DEBUG"
		Level.Warn:
			return "WARN"
		Level.Error:
			return "ERROR"
		Level.Trace:
			return "TRACE"
		_:
			return "UNKNOWN"


static func level_colored(level: Level) -> String:
	var color = ""
	match level:
		Level.Info:
			color = "[color=green]%s[/color]"
		Level.Debug:
			color = "[color=blue]%s[/color]"
		Level.Warn:
			color = "[color=yellow]%s[/color]"
		Level.Error:
			color = "[color=red]%s[/color]"
		Level.Trace:
			color = "[color=magenta]%s[/color]"
		_:
			color = "[color=white]%s[/color]"
	return color % level_string(level)


static func level_colored_nice(level: Level) -> String:
	var color = ""
	match level:
		Level.Info:
			color = "[color=greenyellow]%s[/color]"
		Level.Debug:
			color = "[color=dodgerblue]%s[/color]"
		Level.Warn:
			color = "[color=gold]%s[/color]"
		Level.Error:
			color = "[color=orangered]%s[/color]"
		Level.Trace:
			color = "[color=maroon]%s[/color]"
		_:
			color = "[color=white]%s[/color]"
	return color % level_string(level)
