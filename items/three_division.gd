class_name three_division_item extends Action

func _ready() -> void:
	texture = "res://sprites/items/three_division_item.png"
	item_name = "Деление на два"
	description = "Заставляет следующее действие выполнится дважды. Уменьшает урон на четверть."
	item_type = ITEM_TYPE.MODIFIER
	trigger_next_immediately = true
	weight = 1.0

func action(actor: Player) -> int:
	actor.damage_multiplier *= 0.75
	actor.reset_pause += 2
	return use_delay

func compile_into_stack(stack: Array) -> int:
	stack.push_front(self)
	return 2
