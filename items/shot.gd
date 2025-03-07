class_name shot_item extends Action

func _ready() -> void:
	texture = "res://sprites/items/shot_item.png"
	item_name = "Снаряд"
	description = "Самый обычный снаряд. 20 урона при попадании."
	use_delay = 10
	weight = 1.0

func action(actor: Player) -> int:
	if actor.idle_projectile_manager == null: return use_delay
	var spread := Vector2(randf_range(-10, 10), randf_range(-10, 10)) * actor.spread_multiplier
	var proj: projectile = actor.idle_projectile_manager.get_idle_projectile()
	proj.init()
	proj.add_collision_exception_with(actor)
	proj.damage *= actor.damage_multiplier
	proj.visible = true
	proj.process_mode = Node.PROCESS_MODE_PAUSABLE
	proj.position = actor.position + (Vector2(cos(actor.rotation), sin(actor.rotation)) * 20).rotated(actor.angle_offset)
	proj.velocity = (Vector2(cos(actor.rotation), sin(actor.rotation)) * randf_range(550, 650)).rotated(actor.angle_offset) * actor.projectile_velocity_multiplier + spread
	actor.linear_velocity += Vector2(cos(actor.rotation), sin(actor.rotation)).rotated(actor.angle_offset + PI) * 50.0 * actor.recoil_multiplier
	for component in components:
		proj.components.append(component)
		proj.add_child(component)
	components.clear()
	component_classes.clear()
	return use_delay
