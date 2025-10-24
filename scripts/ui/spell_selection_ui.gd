extends Control

# UI节点引用
@onready var spell_list: VBoxContainer = $MainPanel/SpellList
@onready var close_button: Button = $MainPanel/CloseButton

# 法术库引用
var game_library: GameSpellLibrary
var available_spells: Array[SpellData] = []

# 输入处理
var current_selected_index: int = 0
var max_selected_index: int = 0

func _ready():
	# 连接按钮信号
	close_button.pressed.connect(_on_close_pressed)
	
	# 获取法术库
	game_library = GameSpellLibrary.instance
	if game_library:
		load_available_spells()
		create_spell_buttons()
		initialize_input_handling()
	else:
		print("SpellSelectionUI: 错误 - 未找到法术库")

# 初始化输入处理
func initialize_input_handling():
	max_selected_index = available_spells.size() - 1
	current_selected_index = 0
	update_selection_visual()

# 输入处理
func _input(event):
	if not visible:
		return
	
	# ESC键关闭界面
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		return
	
	# 方向键导航
	if event.is_action_pressed("ui_up"):
		navigate_up()
	elif event.is_action_pressed("ui_down"):
		navigate_down()
	
	# 确认键选择法术
	if event.is_action_pressed("ui_accept"):
		select_current_spell()
	
	# 数字键快速选择
	if event is InputEventKey and event.pressed:
		var key_num = event.keycode - KEY_0
		if key_num >= 1 and key_num <= available_spells.size():
			select_spell_by_index(key_num - 1)

# 向上导航
func navigate_up():
	current_selected_index = max(0, current_selected_index - 1)
	update_selection_visual()
	print("SpellSelectionUI: 选择上一个法术，索引: ", current_selected_index)

# 向下导航
func navigate_down():
	current_selected_index = min(max_selected_index, current_selected_index + 1)
	update_selection_visual()
	print("SpellSelectionUI: 选择下一个法术，索引: ", current_selected_index)

# 选择当前法术
func select_current_spell():
	if current_selected_index >= 0 and current_selected_index < available_spells.size():
		var selected_spell = available_spells[current_selected_index]
		_on_spell_selected(selected_spell)

# 通过索引选择法术
func select_spell_by_index(index: int):
	if index >= 0 and index < available_spells.size():
		current_selected_index = index
		update_selection_visual()
		select_current_spell()

# 更新选择视觉效果
func update_selection_visual():
	for i in range(spell_list.get_child_count()):
		var button = spell_list.get_child(i)
		if i == current_selected_index:
			# 高亮当前选择
			button.modulate = Color(1.2, 1.2, 1.0, 1.0)  # 黄色高亮
		else:
			# 恢复正常颜色
			button.modulate = Color.WHITE

# 加载可用法术
func load_available_spells():
	available_spells = game_library.get_available_spells()
	print("SpellSelectionUI: 加载了 ", available_spells.size(), " 个可用法术")

# 创建法术按钮
func create_spell_buttons():
	# 清空现有按钮
	for child in spell_list.get_children():
		child.queue_free()
	
	# 为每个法术创建按钮
	for spell in available_spells:
		create_spell_button(spell)

# 创建单个法术按钮
func create_spell_button(spell: SpellData):
	var button = Button.new()
	button.text = spell.spell_name + " (法力: " + str(spell.mana_cost) + ")"
	button.custom_minimum_size = Vector2(300, 50)
	
	# 连接按钮信号
	button.pressed.connect(_on_spell_selected.bind(spell))
	
	# 添加到列表
	spell_list.add_child(button)
	
	print("SpellSelectionUI: 创建法术按钮 - ", spell.spell_name)

# 法术选择处理
func _on_spell_selected(spell: SpellData):
	print("SpellSelectionUI: 玩家选择了法术 - ", spell.spell_name)
	
	# 尝试装备法术
	if game_library:
		var success = game_library.equip_spell(spell)
		if success:
			print("SpellSelectionUI: 法术装备成功 - ", spell.spell_name)
			# 更新按钮状态
			update_spell_buttons()
		else:
			print("SpellSelectionUI: 法术装备失败 - ", spell.spell_name)

# 更新法术按钮状态
func update_spell_buttons():
	var equipped_spells = game_library.get_equipped_spells()
	
	for i in range(spell_list.get_child_count()):
		var button = spell_list.get_child(i)
		var spell = available_spells[i]
		
		if spell in equipped_spells:
			button.text = spell.spell_name + " (已装备)"
			button.disabled = true
		else:
			button.text = spell.spell_name + " (法力: " + str(spell.mana_cost) + ")"
			button.disabled = false
	
	# 更新选择视觉效果
	update_selection_visual()

# 关闭UI
func _on_close_pressed():
	print("SpellSelectionUI: 关闭法术选择界面")
	queue_free()

# 显示UI
func show_ui():
	visible = true
	update_spell_buttons()
	show_instructions()

# 隐藏UI
func hide_ui():
	visible = false

# 显示操作说明
func show_instructions():
	print("=== 法术选择界面操作说明 ===")
	print("↑↓ 方向键: 选择法术")
	print("Enter/E键: 装备选中的法术")
	print("1-9数字键: 快速选择法术")
	print("ESC键: 关闭界面")
	print("================================")
