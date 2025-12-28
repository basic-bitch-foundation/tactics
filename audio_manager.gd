extends Node

var is_muted = false

func toggle_mute():
	is_muted = !is_muted
	AudioServer.set_bus_mute(0, is_muted)
	return is_muted

func set_mute(muted: bool):
	is_muted = muted
	AudioServer.set_bus_mute(0, is_muted)
