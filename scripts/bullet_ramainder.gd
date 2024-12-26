extends Node2D

var timer := 20

func _ready() -> void:
	$AudioStreamPlayer.play()
	$GPUParticles2D.emitting = true

func _process(_delta: float) -> void:
	if timer == 0: queue_free()
	timer -= 1
