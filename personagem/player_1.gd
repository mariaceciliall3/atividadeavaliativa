
extends CharacterBody2D

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var sincronizador: MultiplayerSynchronizer = $MultiplayerSynchronizer

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const VOID_Y = 700.0

var spawn_position: Vector2
var ultima_direcao = 1

# Posicao que vai pela rede (o outro jogador desliza ate ela)
var posicao_rede: Vector2


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int(), true)


func _ready() -> void:
	spawn_position = global_position
	posicao_rede = position
	configurar_sincronizacao()


func configurar_sincronizacao() -> void:
	var configuracao := SceneReplicationConfig.new()

	var propriedades = [
		NodePath(".:posicao_rede"),
		NodePath(".:velocity"),
		NodePath("AnimatedSprite2D:animation")
	]

	for propriedade in propriedades:
		configuracao.add_property(propriedade)

	configuracao.property_set_replication_mode(
		NodePath(".:posicao_rede"),
		SceneReplicationConfig.REPLICATION_MODE_ALWAYS
	)

	configuracao.property_set_replication_mode(
		NodePath(".:velocity"),
		SceneReplicationConfig.REPLICATION_MODE_ALWAYS
	)

	configuracao.property_set_replication_mode(
		NodePath("AnimatedSprite2D:animation"),
		SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE
	)

	sincronizador.replication_config = configuracao


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		# Jogador do outro: so desliza ate a posicao que chegou pela rede
		if position.distance_to(posicao_rede) > 100:
			position = posicao_rede
		else:
			position = position.lerp(posicao_rede, 0.3)
		return

	# Respawn do Player 1
	if global_position.y > VOID_Y:
		global_position = spawn_position
		velocity = Vector2.ZERO

	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pulo
	var janela_com_foco := DisplayServer.window_is_focused()
	if janela_com_foco and Input.is_action_just_pressed("player1_jump") and is_on_floor() and Global.pode_mexer == true:
		velocity.y = JUMP_VELOCITY

	# Direção do movimento
	var direction := 0.0
	if janela_com_foco and Global.pode_mexer == true:
		direction = Input.get_axis("player1_left", "player1_right")

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

	# Manda a posicao pela rede
	posicao_rede = position

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
