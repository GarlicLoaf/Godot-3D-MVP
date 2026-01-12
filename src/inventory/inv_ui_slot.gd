extends Panel

@onready var slot_visual: Sprite2D = $slot_display
@onready var amount_text: Label = $Label

func update(slot: InvSlot):
	if slot.item:
		slot_visual.visible = true
		slot_visual.texture = slot.item.texture
		if slot.amount > 1:
			amount_text.visible = true
			amount_text.text = str(slot.amount)
	else:
		slot_visual.visible = false
		slot_visual.texture = null
		amount_text.visible = false
