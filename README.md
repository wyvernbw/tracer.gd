![image](https://github.com/wyvernbw/tracer.gd/assets/50150016/d21f8f04-c907-41a5-a1a2-50d020e54190)
# ![image](https://github.com/wyvernbw/tracer.gd/assets/50150016/652804f5-df97-4624-ae21-df08cdb13fb3) tracer.gd
**Tracer** is an addon for godot 4 for structured, customizable traces, heavily inspired by [tracing](https://github.com/tokio-rs/tracing).

## ✨ Features
* Multiple log levels and filtering
* Colored output
* Useful information such as the script a span is located in, the current thread id and timestamps
* Modular design
* [Support for custom writers](https://github.com/wyvernbw/tracer.gd/wiki/Saving-logs-to-a-file)

## 🧙‍♂️ How it works
The `Tracer` autoload stores traces that are then consumed by subscribers. This addond includes a default subscriber in the form of `TraceSubscriber`. Users are free to implement their own subscribers. Multiple subscribers can run in parallel to log spans with different settings. 
### Getting Started
You can find this example in [examples/test](https://github.com/wyvernbw/tracer.gd/tree/main/examples/test)

During initialization of your game (the ready function for example), start by building a subscriber
```gdscript
	# Build a subscriber with all the bells and whistles
	var subscriber = (
		TraceSubscriber
		. new()
		. with_nicer_colors(false)
	) # default options omitted for simplicity
```
After which, simply initialize the subscriber by calling it's `init` method
```gdscript
	subscriber.init()
```
And that's it. This will add the subscriber as a child to the `Tracer` autoload and will hook it up to consume the traces. Now you can use the provided functions to create these traces.
```gdscript
	Tracer.info("Game Started!")
	Tracer.debug("Initializing systems... 🧙‍♂️")
	Tracer.warn("Cannot find file 'data.json' 🤔")
	Tracer.error("Cannot communicate with server 😱")
```
This will result in this output:
```
[2023-11-02T12:02:36] INFO examples/test/test.gd::_ready: Game Started!
[2023-11-02T12:02:36] DEBUG examples/test/test.gd::_ready: Initializing systems...
[2023-11-02T12:02:36] WARN examples/test/test.gd::_ready: Cannot find file 'data.json' 
[2023-11-02T12:02:36] ERROR examples/test/test.gd::_ready: Cannot communicate with server
```

## 🛠️ Installing
1. clone this repo
2. move the `addons/tracer` folder into your own `addons` folder.
3. enable the plugin in project settings
