extends Area2D

@export_file("*.tscn") var tela_vitoria_player1: String
@export_file("*.tscn") var tela_vitoria_player2: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.name == "player1":
		print("Player 1 venceu!")
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file(tela_vitoria_player1)

	elif body.name == "player2":
		print("Player 2 venceu!")
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file(tela_vitoria_player2)
		
