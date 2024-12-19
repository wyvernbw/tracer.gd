extends Node

signal sent_event

enum Level {
	Error = 1,
	Warn = 2,
	Info = 4,
	Debug = 8,
	Trace = 16,
}

var span_stack := []

class Span:
	extends RefCounted

	var level: Level
	var name: String
	var fields: Dictionary = {}
	var parent: WeakRef = null

	func _init(parent: Span, level: Level, name: String, fields := {}) -> void:
		self.level = level
		self.name = name
		self.fields = fields
		self.parent = weakref(parent)

	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			Tracer.span_stack.pop_front()
			#print_debug(Tracer.span_stack.map(func(s): return s.get_ref().name))

	func enter() -> Span:
		Tracer.span_stack.push_front(weakref(self))
		#print_debug(Tracer.span_stack.map(func(s): return s.get_ref().name))
		return self

	func exit() -> void:
		Tracer.span_stack.pop_front()
		#print_debug(Tracer.span_stack.map(func(s): return s.get_ref().name))

func span(level: Level, name: String, fields := {}) -> Span:
	return Span.new(null if span_stack.is_empty() else span_stack.front().get_ref(), level, name, fields)

class Trace:
	var level: Level
	var msg: String
	var module: String = "unknown"
	var function_name: String = "unknown"
	var timestamp: String = (
		Time.get_datetime_string_from_system()
	)
	var fields := {}
	var thread_id := 1
	var _has_mono: bool = Engine.has_singleton("GodotSharp")

	func _init(
		msg: String, level: Level, new_thread_id := 0, fields := {}
	) -> void:
		self.msg = msg
		self.level = level
		self.fields = fields
		var st = get_stack()
		if st.size() > 2:
			module = st[2].source.trim_prefix("res://")
			function_name = st[2].function
		elif _has_mono:
			# C#-specific stack handling
			var mono_sh_script = load("res://addons/tracer/StackHandler.cs")
			var mono_stack_handler = mono_sh_script.new()
			module = mono_stack_handler.GetModulePath()
			function_name = mono_stack_handler.GetFunctionName()
		else:
			function_name = "unknown"
		thread_id = new_thread_id


var current_event: Trace = null:
	set = set_current_event


func set_current_event(event: Trace) -> void:
	current_event = event
	sent_event.emit()


func info(msg: String, fields := {}) -> void:
	current_event = Trace.new(
		msg, Level.Info, OS.get_thread_caller_id(), fields
	)


func debug(msg: String, fields := {}) -> void:
	current_event = Trace.new(
		msg, Level.Debug, OS.get_thread_caller_id(), fields
	)


func warn(msg: String, fields := {}) -> void:
	current_event = Trace.new(
		msg, Level.Warn, OS.get_thread_caller_id(), fields
	)


func error(msg: String, fields := {}) -> void:
	current_event = Trace.new(
		msg, Level.Error, OS.get_thread_caller_id()
	)

func trace(msg: String, fields := {}) -> void:
	current_event = Trace.new(msg, Level.Trace, OS.get_thread_caller_id(), fields)


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

class Filter:
	extends RefCounted

	var module: String
	var span_name: String
	var fields := {}
	var level: Level

	func _init(module: String, span_name: String, level: Level, fields := {}) -> void:
		self.module = module
		self.span_name = span_name
		self.fields = fields
		self.level = level

	func matches(event: Trace, span: Span) -> bool:
		if module != "" and module != event.module:
			return false
		if span_name != "" and span_name != span.name:
			return false
		if level < event.level:
			return false
		for key in fields:
			if fields[key] != event.fields[key]:
				return false
		return true


var filter_regex := RegEx.new()

var filter_pattern = "([a-zA-Z0-9_]+)?(?:\\[(\\w+)(?:\\{((?:\\w+=\\w+,?\\s*)+)\\})?\\])?=(\\w+)"

func _ready() -> void:
	filter_regex.compile(filter_pattern)

func parse_filters(filter: String) -> Array:
	var results = filter_regex.search_all(filter)
	assert(results != null, "Invalid filter string")
	return results.map(
		func(result):
			var module = result.get_string(1)
			var span_name = result.get_string(2)
			var fields_string = result.get_string(3)
			var fields = {}
			for field in fields_string.split(",", false, 1):
				print_debug(field)
				var key_value = field.split("=")
				fields[key_value[0]] = key_value[1]
			var level = Level[result.get_string(4).capitalize()]
			return Filter.new(module, span_name, level, fields)
	)
