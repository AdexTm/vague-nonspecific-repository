class_name Action extends Node

enum ITEM_TYPE {
	ACTION,
	MODIFIER
}
var item_type := ITEM_TYPE.ACTION
var weight := 0.0
var trigger_next_immediately := false
var components: Array[Node]

var texture:= ""
var item_name := ""
var description := ""
var use_delay := 0

func action(_actor: Player) -> int:
	return 0

func compile_into_stack(stack: Array) -> void:
	stack.push_front(self)

func add_component(component) -> void:
	if trigger_next_immediately or item_type == ITEM_TYPE.MODIFIER: return
	components.append(component.new())
