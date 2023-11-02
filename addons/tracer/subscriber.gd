class_name TraceSubscriber
extends Node

var print_level := true
var use_colored_output := true
var print_module := true
var print_function := true
var print_timestamp := true
var print_thread_id := false


func init() -> void:
	Tracer.add_child(self)
	Tracer.entered_span.connect(on_entered_span)


func on_entered_span() -> void:
	var span: Tracer.Trace = Tracer.current_span
	var text = span.msg
	var level_str = (
		Tracer.level_colored
		if use_colored_output
		else Tracer.level_string
	)
	if print_function:
		var function_name = span.function_name
		if use_colored_output:
			function_name = (
				"[color=gray]%s[/color]" % function_name
			)
		text = function_name + ": " + text
	if print_module:
		var module_name = span.module
		if use_colored_output:
			module_name = (
				"[color=gray]%s[/color]" % module_name
			)
		var separator = (
			"[color=gray]::[/color]" if print_function else ""
		)
		text = module_name + separator + text
	if print_level:
		text = level_str.call(span.level) + ": " + text
	if print_timestamp:
		text = "[%s] " % span.timestamp + text
	if print_thread_id:
		text = "ThreadId(%s) " % span.thread_id + text
	print_rich(text)


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
