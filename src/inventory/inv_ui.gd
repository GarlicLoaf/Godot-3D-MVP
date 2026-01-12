extends CanvasLayer

@onready var inv: Inv = preload("res://assets/inventory/inventory.tres")
@onready var slots: Array = $Control/GridContainer.get_children()

var is_open = false

func _ready():
	inv.update.connect(update_slots)
	update_slots()
	close()

func _process(delta):
	if Input.is_action_just_pressed("i"):
		close() if is_open else open()

func update_slots():
	for i in range(min(inv.slots.size(), slots.size())):
		print("Updating slot " + str(i))
		slots[i].update(inv.slots[i])

func open():
	visible = true
	is_open = true

func close():
	visible = false
	is_open = false
