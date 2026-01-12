extends RigidBody3D

@export var MAX_IMPULSE: float = 9.0

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var impulse := state.get_contact_impulse(0).length()
	if impulse >= MAX_IMPULSE:
		print("Anguishing breaking and shattering noises!!")
		queue_free()
