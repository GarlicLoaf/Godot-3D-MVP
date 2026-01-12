extends RigidBody3D

@export var item: InvItem

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var impulse := state.get_contact_impulse(0)
	print(impulse)
