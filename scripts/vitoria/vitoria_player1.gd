extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$fogos.emitting = true
	_centralizar_cenario()
	get_viewport().size_changed.connect(_centralizar_cenario)


func _centralizar_cenario() -> void:
	var centro_x := get_viewport_rect().size.x * 0.5
	var deslocamento_x := centro_x - 410.0
	$chao.position.x = deslocamento_x
	$arvore.position.x = deslocamento_x
	$fogos.position.x = centro_x
	$VictoryCamera.position = Vector2(centro_x, 225.0)
