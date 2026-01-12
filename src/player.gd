extends CharacterBody3D

@export var WALK_SPEED: float = 6.0
@export var SPRINT_SPEED: float = 10.0
@export var JUMP_VEL: float = 7.0
@export var MOUSE_SENS: float = 0.001
@export var GRAB_INTENSITY: float = 4.0
@export var THROW_MAX: float = 10.0
@export var inv: Inv

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
		if Input.is_action_just_pressed("space") and is_on_floor():
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
	
	# Pickup
	if is_grabbing and not Input.is_action_just_released("pickup"):
		grabbed_object.global_position = grabbed_object.global_position.lerp(hand.global_position, delta * GRAB_INTENSITY)
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

	if Input.is_action_just_released("pickup") and grabbed_object:
		is_grabbing = false

		grabbed_object.gravity_scale = 0.75
		grabbed_object.sleeping = false

		# Make sure the player never throws faster than THROW_MAX
		var speed = hand_vel.length()
		speed = min(speed, THROW_MAX)
		var throw_vel = hand_vel.normalized() * speed
		grabbed_object.linear_velocity = throw_vel
		grabbed_object = null
	move_and_slide()



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fly"):
		velocity = Vector3(0, 0, 0)
		is_flying = !is_flying

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var relative = event.relative * MOUSE_SENS
		head.rotate_y(-relative.x)
		eye_cam.rotate_x(-relative.y)
		eye_cam.rotation.x = clamp(eye_cam.rotation.x, deg_to_rad(-90), deg_to_rad(90))
