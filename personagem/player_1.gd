extends CharacterBody2D

@onready var animacao = $AnimatedSprite2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const VOID_Y = 700.0

var spawn_position: Vector2
var ultima_direcao = 1


func _ready() -> void:
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	# Respawn do Player 1
	if global_position.y > VOID_Y:
		global_position = spawn_position
		velocity = Vector2.ZERO

	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pulo
	if Input.is_action_just_pressed("player1_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Direção do movimento
	var direction := Input.get_axis("player1_left", "player1_right")

	# Guarda a última direção
	if direction < 0:
		ultima_direcao = -1
	elif direction > 0:
		ultima_direcao = 1

	# Movimento horizontal
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Animações
	if not is_on_floor():
		if ultima_direcao < 0:
			animacao.play("pular_esquerda")
		else:
			animacao.play("pular_direita")

	elif direction < 0:
		animacao.play("correr_esquerda")

	elif direction > 0:
		animacao.play("correr_direita")

	elif ultima_direcao < 0:
		animacao.play("parado_esquerda")

	else:
		animacao.play("parado_direita")
