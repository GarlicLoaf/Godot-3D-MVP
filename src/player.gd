extends CharacterBody3D

@export var WALK_SPEED: float = 6.0
@export var SPRINT_SPEED: float = 10.0
@export var JUMP_VEL: float = 5.0
@export var MOUSE_SENS: float = 0.001
@export var JOY_SENS: float = 0.04
@export var GRAB_INTENSITY: float = 4.0
@export var THROW_MAX: float = 10.0
@export var THROW_INTENSITY: float = 10.0

@onready var head: Node3D = $Head
@onready var hand: Node3D = $Head/EyeCam/Hand
@onready var eye_cam: Camera3D = $Head/EyeCam
@onready var raycast: RayCast3D = $Head/EyeCam/RayCast3D

var is_flying: bool = false
var is_sprinting: bool = false
var is_grabbing: bool = false

var grabbed_object: RigidBody3D
var prev_hand_pos: Vector3

func _ready() -> void:
	prev_hand_pos = hand.global_position

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("sprint"):
		is_sprinting = true
	else:
		is_sprinting = false

	if is_flying:
		if Input.is_action_pressed("space"):
			position.y +=  delta * (SPRINT_SPEED if is_sprinting else WALK_SPEED)
		if Input.is_action_pressed("shift"):
			position.y -=  delta * (SPRINT_SPEED if is_sprinting else WALK_SPEED)
	else:
		# Gravity
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Jump
		if Input.is_action_just_pressed("space") and not is_grabbing and is_on_floor():
			velocity.y = JUMP_VEL

	# Movement
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * (SPRINT_SPEED if is_sprinting else WALK_SPEED)
		velocity.z = direction.z * (SPRINT_SPEED if is_sprinting else WALK_SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPRINT_SPEED if is_sprinting else WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, SPRINT_SPEED if is_sprinting else WALK_SPEED)
	
	var hand_vel = (hand.global_position - prev_hand_pos) / delta
	prev_hand_pos = hand.global_position
	
	# Pickup logic
	if grabbed_object:
		if not Input.is_action_just_released("pickup"):
			# Move the object towards hand
			grabbed_object.global_position = grabbed_object.global_position.lerp(hand.global_position, delta * GRAB_INTENSITY)
			if Input.is_action_just_pressed("interact"):
				# throwing logic
				var throw_dir = raycast.target_position.normalized()
				grabbed_object.apply_impulse(throw_dir * THROW_INTENSITY)
				grabbed_object.release_timer()

				_release_object()
			
		else:
			# Make sure the player never throws faster than THROW_MAX
			var speed = hand_vel.length()
			speed = min(speed, THROW_MAX)
			var throw_vel = hand_vel.normalized() * speed
			grabbed_object.linear_velocity = throw_vel

			_release_object()
	else:
		if Input.is_action_pressed("pickup"):
			var object = raycast.get_collider()
			if object and object.is_in_group("pickable"):
				grabbed_object = object
				# Reset physics
				grabbed_object.angular_velocity = Vector3.ZERO
				grabbed_object.linear_velocity = Vector3.ZERO
				grabbed_object.gravity_scale = 0.0
				grabbed_object.sleeping = true
				is_grabbing = true

	# Joystick input
	var joy_input = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)) * JOY_SENS
	var deadzone = 0.01
	if joy_input.length() > deadzone:
		_apply_look(joy_input)


	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fly"):
		velocity = Vector3(0, 0, 0)
		is_flying = !is_flying

func _unhandled_input(event: InputEvent) -> void: 
	if event is InputEventMouseMotion:
		var look_input = event.relative * MOUSE_SENS
		_apply_look(look_input)
	
func _apply_look(look_input: Vector2) -> void:
	head.rotate_y(-look_input.x)
	eye_cam.rotate_x(-look_input.y)
	eye_cam.rotation.x = clamp(eye_cam.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _release_object() -> void:
	is_grabbing = false

	grabbed_object.gravity_scale = 0.75
	grabbed_object.sleeping = false
	grabbed_object = null
