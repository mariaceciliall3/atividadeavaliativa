extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const VOID_Y = 700.0
var spawn_position: Vector2

func _ready() -> void:
	spawn_position = global_position


func _physics_process(delta: float) -> void:
		#respawn of player 1
	if global_position.y > VOID_Y:
		global_position = spawn_position
		velocity = Vector2.ZERO
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("player1_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("player1_left", "player1_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
