extends Area2D

signal jogador_entrou(body: Node2D)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		jogador_entrou.emit(body)
