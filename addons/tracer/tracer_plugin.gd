@tool
extends EditorPlugin

const AUTOLOAD_NAME = "Tracer"


func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, "./tracer.gd")
	pass


func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
	pass
