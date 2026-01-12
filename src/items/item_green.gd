extends RigidBody3D

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var impulse := state.get_contact_impulse(0)
	print(impulse)
