extends Node2D


func _ready():
	var subscriber = (
		TraceSubscriber
		. new()
		. with_colored_output(true)
		. with_level(true)
		. with_time(true)
	)
	subscriber.init()

	Tracer.info("Game Started!")
