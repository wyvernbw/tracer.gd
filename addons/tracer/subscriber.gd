class_name TraceSubscriber
extends Node

var print_level := true
var use_colored_output := true
var use_nicer_colors := false
var print_module := true
var print_function := true
var print_timestamp := true
var print_thread_id := false
var writer: Callable = print_stump


func init() -> void:
	Tracer.add_child(self)
	Tracer.entered_span.connect(on_entered_span)


func print_stump(text: String) -> void:
	print_rich(text)


func on_entered_span() -> void:
	var span: Tracer.Trace = Tracer.current_span
	var text = span.msg
	var level_str = (
		Tracer.level_colored
		if use_colored_output
		else Tracer.level_string
	)
	if use_nicer_colors and use_colored_output:
		level_str = Tracer.level_colored_nice
	var gray = (
		"[color=dimgray]%s[/color]"
		if use_nicer_colors
		else "[color=gray]%s[/color]"
	)
	if not use_colored_output:
		gray = "%s"
	if print_function:
		var function_name = span.function_name
		if use_colored_output:
			function_name = (gray % function_name)
		text = function_name + ": " + text
	if print_module:
		var module_name = span.module
		if use_colored_output:
			module_name = (gray % module_name)
		var separator = (gray % "::") if print_function else ": "
		text = module_name + separator + text
	if print_level:
		var separator = ": " if not (print_module or print_function) else " "
		text = level_str.call(span.level) + separator + text
	if print_timestamp:
		text = "[%s] " % span.timestamp + text
	if print_thread_id:
		text = "ThreadId(%s) " % span.thread_id + text
	writer.call(text)


func with_level(displayed: bool) -> TraceSubscriber:
	print_level = displayed
	return self


func with_colored_output(displayed: bool) -> TraceSubscriber:
	use_colored_output = displayed
	return self


func with_module(displayed: bool) -> TraceSubscriber:
	print_module = displayed
	return self


func with_function(displayed: bool) -> TraceSubscriber:
	print_function = displayed
	return self


func with_timestamp(displayed: bool) -> TraceSubscriber:
	print_timestamp = displayed
	return self


func with_thread_id(displayed: bool) -> TraceSubscriber:
	print_thread_id = displayed
	return self


func with_nicer_colors(displayed: bool) -> TraceSubscriber:
	use_nicer_colors = displayed
	return self


func barebones() -> TraceSubscriber:
	return (
		self
		. with_level(true)
		. with_colored_output(false)
		. with_module(true)
		. with_function(true)
		. with_timestamp(true)
		. with_thread_id(false)
	)


func with_writer(writer: Callable) -> TraceSubscriber:
	self.writer = writer
	return self


static func writer_from_file(file: FileAccess) -> Callable:
	return func(text: String) -> void:
		file.store_string(text + "\n")

