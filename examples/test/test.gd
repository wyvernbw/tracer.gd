extends Node2D


func _ready():
	# Build a subscriber with all the bells and whistles
	var subscriber = (
		TraceSubscriber
		. new()
		. with_colored_output(true)
		. with_level(true)
		. with_nicer_colors(false)
		. with_timestamp(true)
	)
	# Initialize the subscriber
	subscriber.init()

	# Open a file for writing
	var logs = FileAccess.open("res://examples/test/logs.txt", FileAccess.WRITE)
	# Build a subscriber that writes to a file
	var file_logger = (
		TraceSubscriber
		. new()
		. barebones()
		. with_writer(
			TraceSubscriber.writer_from_file(logs)
		)
	)
	# Initialize the subscriber
	file_logger.init()

	Tracer.info("Game Started!")
	Tracer.debug("Initializing systems... 🧙‍♂️")
	Tracer.warn("Cannot find file 'data.json' 🤔")
	Tracer.error("Cannot communicate with server 😱")
