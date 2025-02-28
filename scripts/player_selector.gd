class_name PlayerSelector extends Control

var bound_player: Player
var color: int
var type: int = 0
var timer := 0
var player_ready := false
var text_to_print: String
var printing_progress: int = -1

enum SELECTOR_MODE {
	LOBBY,
	LOOTBOX,
	INVENTORY
}
var cur_mode := SELECTOR_MODE.LOBBY
const LOOT_MOD_AMOUNT := 2
const LOOT_ACT_AMOUNT := 1
var presented_items: Array[Action]

@export var character_type_descriptions: Array[String]

@onready var game_manager: GameManager = get_parent().get_parent()

@onready var label_of_readiness := $Ready
@onready var player_sprite := $LobbyButtons/Player
@onready var buttons := $LobbyButtons
@onready var other_buttons := $NotLobbyButtons
@onready var inventory_container := $NotLobbyButtons/GridContainer
@onready var lootbox_buttons := $LootboxButtons
@onready var lootbox_container := $LootboxButtons/GridContainer
@onready var button_up := $LobbyButtons/Up
@onready var button_down := $LobbyButtons/Down
@onready var button_left := $LobbyButtons/Left
@onready var button_right := $LobbyButtons/Right
@onready var stat_panel := $Stats
@onready var sound := $PressDoundEmitter

var inventory_panels: Array[WobblyPanel]
var inventory_icons: Array[TextureRect]
var lootbox_panels: Array[Panel]
var lootbox_icons: Array[TextureRect]
var selected_button := Vector2i.ZERO
var selected_slot := Vector2i.ONE * -1

func _ready() -> void:
	button_up.texture = AtlasTexture.new()
	button_down.texture = AtlasTexture.new()
	button_left.texture = AtlasTexture.new()
	button_right.texture = AtlasTexture.new()
	button_up.texture.atlas = load("res://sprites/buppon.png")
	button_down.texture.atlas = load("res://sprites/buppon.png")
	button_left.texture.atlas = load("res://sprites/buppon.png")
	button_right.texture.atlas = load("res://sprites/buppon.png")
	button_up.texture.region = Rect2(96, 0, 32, 32)
	button_down.texture.region = Rect2(64, 0, 32, 32)
	button_left.texture.region = Rect2(0, 0, 32, 32)
	button_right.texture.region = Rect2(32, 0, 32, 32)
	
func yo_wassup(player: Player, is_lobby: bool = true) -> void:
	bound_player = player
	visible = true
	player_ready = false
	label_of_readiness.self_modulate = Color(0.5, 0, 0)
	label_of_readiness.text = "Not ready"
	player_sprite.texture = AtlasTexture.new()
	player_sprite.texture.atlas = load("res://sprites/player.png")
	player_sprite.texture.region = Rect2(bound_player.character_color * 48, bound_player.character_type * 48, 48, 48)
	update_stat_text(character_type_descriptions[bound_player.character_type])
	cur_mode = SELECTOR_MODE.LOBBY
	if position.x > 400:
		label_of_readiness.size_flags_horizontal = SIZE_SHRINK_END
		buttons.size_flags_horizontal = SIZE_SHRINK_END
		other_buttons.size_flags_horizontal = SIZE_SHRINK_END
		lootbox_buttons.size_flags_horizontal = SIZE_SHRINK_END
	else:
		label_of_readiness.size_flags_horizontal = SIZE_SHRINK_BEGIN
		buttons.size_flags_horizontal = SIZE_SHRINK_BEGIN
		other_buttons.size_flags_horizontal = SIZE_SHRINK_BEGIN
		lootbox_buttons.size_flags_horizontal = SIZE_SHRINK_BEGIN
	if is_lobby:
		buttons.visible = true
		other_buttons.visible = false
	else:
		buttons.visible = false
		engage_lootbox_mode()

func engage_lootbox_mode() -> void:
	lootbox_buttons.visible = true
	other_buttons.visible = false
	presented_items.clear()
	lootbox_container.columns = LOOT_ACT_AMOUNT + LOOT_MOD_AMOUNT
	lootbox_icons.resize(LOOT_ACT_AMOUNT + LOOT_MOD_AMOUNT)
	lootbox_panels.resize(LOOT_ACT_AMOUNT + LOOT_MOD_AMOUNT)
	for old in lootbox_container.get_children():
		old.free()
	for i in range(LOOT_ACT_AMOUNT):
		var loot = game_manager.lootbox_manager.get_random_action()
		presented_items.append(loot)
		var panel = Panel.new()
		lootbox_container.add_child(panel)
		lootbox_panels[i] = panel
		panel.custom_minimum_size = Vector2(48, 48)
		var icon = TextureRect.new()
		panel.add_child(icon)
		lootbox_icons[i] = icon
		icon.texture = load(loot.texture)
		icon.custom_minimum_size = Vector2(48, 48)
	for i in range(LOOT_MOD_AMOUNT):
		var loot = game_manager.lootbox_manager.get_random_modifier()
		presented_items.append(loot)
		var panel = Panel.new()
		lootbox_container.add_child(panel)
		lootbox_panels[i + LOOT_ACT_AMOUNT] = panel
		panel.custom_minimum_size = Vector2(48, 48)
		var icon = TextureRect.new()
		panel.add_child(icon)
		lootbox_icons[i + LOOT_ACT_AMOUNT] = icon
		icon.texture = load(loot.texture)
		icon.custom_minimum_size = Vector2(48, 48)
	await lootbox_container.sort_children
	lootbox_buttons.size = lootbox_container.size
	selected_button = Vector2i.ZERO
	cur_mode = SELECTOR_MODE.LOOTBOX
	update_loot_highlight(selected_button, Color(1.5, 1.5, 1.5))
	update_stat_text(presented_items[selected_button.x].description)

func update_inventory(player: Player) -> void:
	cur_mode = SELECTOR_MODE.INVENTORY
	lootbox_buttons.visible = false
	other_buttons.visible = true
	inventory_container.columns = player.action_stack_size
	inventory_panels.resize(player.action_stack_size * (player.inventory_rows + player.amount_of_stacks))
	inventory_icons.resize(player.action_stack_size * (player.inventory_rows + player.amount_of_stacks))
	for old in inventory_container.get_children():
		old.free()
	for i in range(player.action_stack_size * player.amount_of_stacks):
		var new_slot = WobblyPanel.new()
		new_slot.custom_minimum_size = Vector2(48, 48)
		inventory_container.add_child(new_slot)
		new_slot.z_index = 1
		inventory_panels[i] = new_slot
		new_slot.self_modulate = Color(1.8, 1.8, 1.8)
		var new_slot_sprite = TextureRect.new()
		new_slot_sprite.custom_minimum_size = Vector2(48, 48)
		new_slot.add_child(new_slot_sprite)
		new_slot_sprite.z_index = 2
		inventory_icons[i] = new_slot_sprite
		if player.inventory[i] == null: continue
		new_slot_sprite.texture = load(player.inventory[i].texture)
	for i in range(player.action_stack_size * player.inventory_rows):
		var new_slot = WobblyPanel.new()
		new_slot.custom_minimum_size = Vector2(48, 48)
		inventory_container.add_child(new_slot)
		new_slot.z_index = 1
		inventory_panels[i + (player.action_stack_size * player.amount_of_stacks)] = new_slot
		var new_slot_sprite = TextureRect.new()
		new_slot_sprite.custom_minimum_size = Vector2(48, 48)
		new_slot.add_child(new_slot_sprite)
		new_slot_sprite.z_index = 2
		inventory_icons[i + (player.action_stack_size * player.amount_of_stacks)] = new_slot_sprite
		if player.inventory[i + (player.action_stack_size * player.amount_of_stacks)] == null: continue
		new_slot_sprite.texture = load(player.inventory[i + (player.action_stack_size * player.amount_of_stacks)].texture)
	await inventory_container.sort_children
	other_buttons.custom_minimum_size = inventory_container.size + Vector2(10, 10)
	selected_button = Vector2i.ZERO
	update_inv_highlight(selected_button, Color(1.5, 1.5, 1.5))
	selected_slot = Vector2i.ONE * -1
	if bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)] == null:
		update_stat_text(" ")
		stat_panel.visible = false
	else:
		update_stat_text(bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)].description)
		stat_panel.visible = true

func round_started() -> void:
	bound_player.bound_player_selector = null
	bound_player = null
	visible = false

func left_pressed():
	sound.play()
	match cur_mode:
		SELECTOR_MODE.LOBBY:
			timer = 6
			button_left.texture.region.position.y = 32
			var prev_color = bound_player.character_color
			for i in range(4):
				bound_player.character_color += 1
				if bound_player.character_color > 3: bound_player.character_color = 0
				if bound_player.game_manager.player_color_numbers[bound_player.character_color]:
					bound_player.game_manager.player_color_numbers[prev_color] = true
					break
			bound_player.game_manager.player_color_numbers[bound_player.character_color] = false
			bound_player.change_appearence()
			player_sprite.texture.region = Rect2(bound_player.character_color * 48, bound_player.character_type * 48, 48, 48)
		SELECTOR_MODE.INVENTORY:
			update_inv_highlight(selected_button, Color(1.0, 1.0, 1.0))
			selected_button.x -= 1
			if selected_button.x < 0: selected_button.x = bound_player.action_stack_size - 1
			update_inv_highlight(selected_button, Color(1.5, 1.5, 1.5))
			if bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)] == null:
				update_stat_text(" ")
				stat_panel.visible = false
			else:
				update_stat_text(bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)].description)
				stat_panel.visible = true
		SELECTOR_MODE.LOOTBOX:
			update_loot_highlight(selected_button, Color(1.0, 1.0, 1.0))
			selected_button.x -= 1
			if selected_button.x < 0: selected_button.x = LOOT_ACT_AMOUNT + LOOT_MOD_AMOUNT - 1
			update_loot_highlight(selected_button, Color(1.5, 1.5, 1.5))
			update_stat_text(presented_items[selected_button.x].description)
			stat_panel.visible = true

func right_pressed():
	sound.play()
	match cur_mode:
		SELECTOR_MODE.LOBBY:
			timer = 6
			button_right.texture.region.position.y = 32
			var prev_color = bound_player.character_color
			for i in range(4):
				bound_player.character_color -= 1
				if bound_player.character_color < 0: bound_player.character_color = 3
				if bound_player.game_manager.player_color_numbers[bound_player.character_color]:
					bound_player.game_manager.player_color_numbers[prev_color] = true
					break
			bound_player.game_manager.player_color_numbers[bound_player.character_color] = false
			bound_player.change_appearence()
			player_sprite.texture.region = Rect2(bound_player.character_color * 48, bound_player.character_type * 48, 48, 48)
		SELECTOR_MODE.INVENTORY:
			update_inv_highlight(selected_button, Color(1.0, 1.0, 1.0))
			selected_button.x += 1
			if selected_button.x > bound_player.action_stack_size - 1: selected_button.x = 0
			update_inv_highlight(selected_button, Color(1.5, 1.5, 1.5))
			if bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)] == null:
				update_stat_text(" ")
				stat_panel.visible = false
			else:
				update_stat_text(bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)].description)
				stat_panel.visible = true
		SELECTOR_MODE.LOOTBOX:
			update_loot_highlight(selected_button, Color(1.0, 1.0, 1.0))
			selected_button.x += 1
			if selected_button.x > LOOT_ACT_AMOUNT + LOOT_MOD_AMOUNT - 1: selected_button.x = 0
			update_loot_highlight(selected_button, Color(1.5, 1.5, 1.5))
			update_stat_text(presented_items[selected_button.x].description)
			stat_panel.visible = true

func up_pressed():
	sound.play()
	match cur_mode:
		SELECTOR_MODE.LOBBY:
			timer = 6
			button_up.texture.region.position.y = 32
			bound_player.character_type += 1
			if bound_player.character_type > 3: bound_player.character_type = 0
			update_stat_text(character_type_descriptions[bound_player.character_type])
			bound_player.change_appearence()
			bound_player.change_player_type(bound_player.character_type)
			player_sprite.texture.region = Rect2(bound_player.character_color * 48, bound_player.character_type * 48, 48, 48)
		SELECTOR_MODE.INVENTORY:
			update_inv_highlight(selected_button, Color(1.0, 1.0, 1.0))
			selected_button.y -= 1
			if selected_button.y < -1: selected_button.y = bound_player.inventory_rows + bound_player.amount_of_stacks - 1
			update_inv_highlight(selected_button, Color(1.5, 1.5, 1.5))
			if bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)] == null:
				update_stat_text(" ")
				stat_panel.visible = false
			else:
				update_stat_text(bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)].description)
				stat_panel.visible = true

func down_pressed():
	sound.play()
	match cur_mode:
		SELECTOR_MODE.LOBBY:
			timer = 6
			button_down.texture.region.position.y = 32
			bound_player.character_type -= 1
			if bound_player.character_type < 0: bound_player.character_type = 3
			update_stat_text(character_type_descriptions[bound_player.character_type])
			bound_player.change_appearence()
			bound_player.change_player_type(bound_player.character_type)
			player_sprite.texture.region = Rect2(bound_player.character_color * 48, bound_player.character_type * 48, 48, 48)
		SELECTOR_MODE.INVENTORY:
			update_inv_highlight(selected_button, Color(1.0, 1.0, 1.0))
			selected_button.y += 1
			if selected_button.y > bound_player.inventory_rows + bound_player.amount_of_stacks - 1: selected_button.y = -1
			update_inv_highlight(selected_button, Color(1.5, 1.5, 1.5))
			if bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)] == null:
				update_stat_text(" ")
				stat_panel.visible = false
			else:
				update_stat_text(bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)].description)
				stat_panel.visible = true

func fire_pressed():
	sound.play()
	if cur_mode == SELECTOR_MODE.LOBBY or selected_button.y == -1:
		toggle_ready()
		selected_slot = Vector2i.ONE * -1
	elif cur_mode == SELECTOR_MODE.INVENTORY:
		if selected_slot != Vector2i.ONE * -1:
			var first_slot: int = selected_slot.x + (selected_slot.y * bound_player.action_stack_size)
			var second_slot: int = selected_button.x + (selected_button.y * bound_player.action_stack_size)
			var temp: Action = bound_player.inventory[first_slot]
			inventory_panels[first_slot].wobbliness = 1.0
			bound_player.inventory[first_slot] = bound_player.inventory[second_slot]
			bound_player.inventory[second_slot] = temp
			if bound_player.inventory[first_slot] == null:
				inventory_icons[first_slot].texture = null
			else:
				inventory_icons[first_slot].texture = load(bound_player.inventory[first_slot].texture)
			if bound_player.inventory[second_slot] == null:
				inventory_icons[second_slot].texture = null
			else:
				inventory_icons[second_slot].texture = load(bound_player.inventory[second_slot].texture)
			selected_slot = Vector2i.ONE * -1
			update_stat_text(bound_player.inventory[second_slot].description)
		elif bound_player.inventory[selected_button.x + (selected_button.y * bound_player.action_stack_size)] != null:
			selected_slot = selected_button
			inventory_panels[selected_slot.x + (selected_slot.y * bound_player.action_stack_size)].wobbliness = 2.0
	elif cur_mode == SELECTOR_MODE.LOOTBOX:
		var loot = presented_items[selected_button.x]
		var inventory = range(bound_player.action_stack_size * bound_player.inventory_rows).map(func(value): return value + (bound_player.action_stack_size * bound_player.amount_of_stacks))
		for i in inventory:
			if bound_player.inventory[i] == null:
				bound_player.inventory[i] = loot.duplicate()
				bound_player.inventory[i]._ready()
				break
		update_inventory(bound_player)

func toggle_ready() -> void:
		player_ready = not player_ready
		bound_player.compile_action_stacks()
		bound_player.game_manager.set_ready(player_ready)
		if player_ready:
			label_of_readiness.self_modulate = Color(0.2, 1, 0.2)
			label_of_readiness.text = "Ready"
		else:
			label_of_readiness.self_modulate = Color(0.5, 0, 0)
			label_of_readiness.text = "Not ready"
	
func update_inv_highlight(pos: Vector2i, mod: Color):
	if pos.y == -1:
		label_of_readiness.modulate = mod
	else:
		inventory_panels[pos.x + (pos.y * bound_player.action_stack_size)].modulate = mod

func update_loot_highlight(pos: Vector2i, mod: Color):
	lootbox_panels[pos.x].modulate = mod

func update_stat_text(text: String) -> void:
	stat_panel.text = ""
	text_to_print = text
	printing_progress = 0

func update_stat_text_process() -> void:
	for i in range(2):
		if printing_progress == -1: return
		stat_panel.text += text_to_print[printing_progress]
		if text_to_print[printing_progress] == ".":
			stat_panel.text += "\r\n"
		printing_progress += 1
		if printing_progress == text_to_print.length():
			printing_progress = -1

func _physics_process(_delta: float) -> void:
	update_stat_text_process()
	if timer > 0:
		timer -= 1
	if timer == 1:
		button_up.texture.region.position.y = 0
		button_down.texture.region.position.y = 0
		button_left.texture.region.position.y = 0
		button_right.texture.region.position.y = 0
