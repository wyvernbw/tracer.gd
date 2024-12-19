extends Node2D

# Shorthand
const Level = Tracer.Level

func _ready():
	# Build a subscriber with all the bells and whistles
	var subscriber = (
		TraceSubscriber
		.new()
		.with_colored_output(true)
		.with_level(true)
		.with_nicer_colors(true)
		.with_timestamp(true)
	)
	# Initialize the subscriber
	subscriber.init()

	# Open a file for writing
	var logs = FileAccess.open("res://examples/test/logs.txt", FileAccess.WRITE)
	# Build a subscriber that writes to a file
	var file_logger = (
		TraceSubscriber
		.new()
		.barebones()
		.with_writer(
			TraceSubscriber.writer_from_file(logs)
		)
	)
	# Initialize the subscriber
	file_logger.init()

	var filters = Tracer.parse_filters("error,[child{work = texture_loading}]=debug")
	print_debug(filters)
	subscriber.with_filters(filters)

	Tracer.debug("Loading graphics API")
	var span = Tracer.span(Level.Info, "example", {"step": "setup"}).enter()
	var child = Tracer.span(Level.Info, "child", {"work": "texture_loading"}).enter()

	Tracer.info("Game Started!")
	Tracer.debug("Initializing systems... 🧙‍♂️", {"system": "physics"})
	child.exit()
	Tracer.warn("Cannot find file 'data.json' 🤔")
	Tracer.error("Cannot communicate with server 😱")
	# This will not be printed
	Tracer.trace("This is a trace message 🕵️‍♂️")
