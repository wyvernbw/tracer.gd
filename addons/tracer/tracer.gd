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
var default_span = span(Level.Info, "", {})

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

	enum Match {
		False = 0,
		Maybe = 1,
		True = 2
	}

	func match_from_bool(b: bool) -> Match:
		if b:
			return Match.True
		return Match.False

	func matches(event: Trace, span: Span) -> bool:
		var matches = {
			"module": Match.Maybe,
			"span": Match.Maybe,
			"fields": Match.Maybe
		}
		matches.module = (
			Match.Maybe if self.module == "" 
			else match_from_bool(self.module == event.module)
		)
		matches.span = (
			Match.Maybe if self.span_name == "" 
			else match_from_bool(self.span_name == span.name)
		)
		for key in fields:
			if not event.fields.has(key):
				matches.fields = Match.Maybe
				continue
			if fields[key] != event.fields[key]:
				matches.fields = Match.False
		var res = (
			matches.values().all(func(el): return el > Match.False)
			or matches.values().any(func(el): return el == Match.True)
		)
		return res

	func includes(other: Level) -> bool:
		return other <= self.level

	func _to_string() -> String:
		return JSON.stringify({
			"module": module,
			"span": span_name,
			"fields": fields,
			"level": Level.find_key(level),
		})



func parse_filters(filter: String) -> Array:
	var directives = (
		Array(filter.split(","))
			.filter(func(str): return not str.is_empty())
			.map(parse_directive)
			.filter(func(filter): return filter != null)
	)
	return directives

func parse_fields(fields: String) -> Dictionary:
	if not "{" in fields:
		return {}
	if not "}" in fields:
		return {}
	var str = fields.get_slice("{", 1).get_slice("}", 0) 
	var kv_pairs = str.split(",")
	var res = {}
	for kv in kv_pairs:
		if not "=" in kv:
			continue
		var kv_list = kv.split("=", false)
		res[kv_list[0].strip_edges()] = kv_list[1].strip_edges()
	return res

func at(arr: Array, idx: int) -> Variant:
	return arr[idx] if idx < arr.size() else null

func parse_level(str: String) -> Level:
	match str:
		"debug", "DEBUG":
			return Level.Debug
		"info", "INFO":
			return Level.Info
		"warn", "WARN":
			return Level.Warn
		"error", "ERROR":
			return Level.Error
		_:
			return Level.Trace

func parse_directive(str: String) -> Filter:
	var parts = str.rsplit("=", false, 1)
	var part0 = at(parts, 0)
	var part1 = at(parts, 1)
	if part1:
		var inside = part0.get_slice("[", 1).get_slice("]", 0)
		var span
		if "{" in inside:
			span = inside.get_slice("{", 0)
		else:
			span = inside
		var fields = parse_fields(inside)
		var level = parse_level(part1)
		var module = part0.get_slice("[", 0) if "[" in part0 else part0
		return Filter.new(module, span, level, fields)
	else:
		return Filter.new("", "", parse_level(part0), {})
