class_name mine_item extends Action


func _ready() -> void:
	texture = "res://sprites/items/mine_item.png"
	item_name = "Мина"
	description = "Мина с датчиком движения. Взорвётся, если кто-нибудь приблизится к ней. 30 урона."
	use_delay = 120
	weight = 1.0

func action(actor: Player) -> int:
	var mine: Mine = actor.idle_projectile_manager.get_idle_mine()
	mine.init()
	@warning_ignore("narrowing_conversion")
	mine.damage *= actor.damage_multiplier
	mine.visible = true
	mine.process_mode = Node.PROCESS_MODE_PAUSABLE
	mine.position = actor.position + (Vector2(cos(actor.rotation), sin(actor.rotation)) * 50).rotated(actor.angle_offset)
	mine.linear_velocity = (Vector2(cos(actor.rotation), sin(actor.rotation)) * 250).rotated(actor.angle_offset) * actor.projectile_velocity_multiplier + actor.linear_velocity
	actor.linear_velocity += Vector2(cos(actor.rotation), sin(actor.rotation)).rotated(actor.angle_offset + PI) * 80.0 * actor.recoil_multiplier
	for component in components:
		mine.components.append(component)
		mine.add_child(component)
	components.clear()
	component_classes.clear()
	return use_delay
