extends RigidBody3D

@export var MAX_IMPULSE: float = 9.0

@onready var timer: Timer = $not_grabbable

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	for i in state.get_contact_count():
		var impulse := state.get_contact_impulse(i).length()
		if impulse >= MAX_IMPULSE:
			print("Anguishing breaking and shattering noises!!")
			queue_free()

func release_timer() -> void:
	self.input_ray_pickable = false
	timer.start()


func _on_not_grabbable_timeout() -> void:
	self.input_ray_pickable = true
