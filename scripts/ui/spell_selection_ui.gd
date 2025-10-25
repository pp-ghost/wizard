extends Control

# UI节点引用
@onready var spell_list: VBoxContainer = $MainPanel/SpellList/VBoxContainer
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
	
	# 延迟初始化，确保法术库已加载
	call_deferred("_deferred_initialize")

func _deferred_initialize():
	# 获取法术库 - 安全访问
	game_library = _get_spell_library()
	if game_library:
		load_available_spells()
		create_spell_buttons()
		initialize_input_handling()
	else:
		print("SpellSelectionUI: 错误 - 未找到法术库")

# 安全获取法术库的辅助函数
func _get_spell_library() -> GameSpellLibrary:
	# 首先尝试从静态实例获取
	if GameSpellLibrary.instance:
		return GameSpellLibrary.instance
	
	# 如果静态实例还没初始化，尝试从玩家节点查找
	var player = get_tree().current_scene.get_node_or_null("player")
	if player:
		var library = player.get_node_or_null("GameSpellLibrary")
		if library:
			print("SpellSelectionUI: 从玩家节点找到法术库")
			return library
	
	print("SpellSelectionUI: 警告 - 无法找到法术库")
	return null

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
		_on_spell_edit(selected_spell)

# 通过索引选择法术
func select_spell_by_index(index: int):
	if index >= 0 and index < available_spells.size():
		current_selected_index = index
		update_selection_visual()
		select_current_spell()

# 更新选择视觉效果
func update_selection_visual():
	for i in range(spell_list.get_child_count()):
		var spell_container = spell_list.get_child(i)
		if not spell_container:
			continue
		
		if i == current_selected_index:
			# 高亮当前选择
			spell_container.modulate = Color(1.2, 1.2, 1.0, 1.0)  # 黄色高亮
		else:
			# 恢复正常颜色
			spell_container.modulate = Color.WHITE

# 加载可用法术
func load_available_spells():
	if not game_library:
		print("SpellSelectionUI: 错误 - game_library 为空，无法加载法术")
		return
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
	# 创建主容器
	var spell_container = HBoxContainer.new()
	spell_container.custom_minimum_size = Vector2(350, 60)
	
	# 创建图标
	var icon_texture = TextureRect.new()
	icon_texture.custom_minimum_size = Vector2(48, 48)
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if spell.spell_icon:
		icon_texture.texture = spell.spell_icon
	else:
		# 如果没有图标，显示占位符
		icon_texture.modulate = Color.GRAY
	
	# 创建文本容器
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 创建法术名称标签
	var name_label = Label.new()
	name_label.text = spell.spell_name
	name_label.add_theme_font_size_override("font_size", 16)
	
	# 创建法术信息标签
	var info_label = Label.new()
	info_label.text = "伤害: " + str(spell.damage) + " | 速度: " + str(spell.speed) + " | 射程: " + str(spell.range)
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.modulate = Color(0.8, 0.8, 0.8)
	
	# 创建按键标签
	var key_label = Label.new()
	key_label.text = "按键: " + OS.get_keycode_string(spell.trigger_key)
	key_label.add_theme_font_size_override("font_size", 12)
	key_label.modulate = Color(0.6, 0.8, 1.0)  # 蓝色
	
	# 创建按钮
	var button = Button.new()
	button.text = "编辑"
	button.custom_minimum_size = Vector2(80, 40)
	button.pressed.connect(_on_spell_edit.bind(spell))
	
	# 组装UI
	text_container.add_child(name_label)
	text_container.add_child(info_label)
	text_container.add_child(key_label)
	
	spell_container.add_child(icon_texture)
	spell_container.add_child(text_container)
	spell_container.add_child(button)
	
	# 添加到列表
	spell_list.add_child(spell_container)
	
	print("SpellSelectionUI: 创建法术按钮 - ", spell.spell_name)

# 法术编辑处理
func _on_spell_edit(spell: SpellData):
	print("SpellSelectionUI: 玩家要编辑法术 - ", spell.spell_name)
	
	# 打开法术编辑界面
	open_spell_edit_ui(spell)

# 更新法术按钮状态
func update_spell_buttons():
	# 安全检查
	if not game_library:
		print("SpellSelectionUI: 错误 - game_library 为空，无法更新按钮状态")
		return
	
	for i in range(spell_list.get_child_count()):
		var spell_container = spell_list.get_child(i)
		if not spell_container:
			print("SpellSelectionUI: 警告 - 法术容器为空，索引: ", i)
			continue
		
		# 安全获取按钮（最后一个子节点）
		var button = spell_container.get_child(spell_container.get_child_count() - 1)
		if not button:
			print("SpellSelectionUI: 警告 - 按钮为空，索引: ", i)
			continue
		
		var spell = available_spells[i]
		if not spell:
			print("SpellSelectionUI: 警告 - 法术数据为空，索引: ", i)
			continue
		
		# 所有法术都可以编辑
		button.text = "编辑"
		button.disabled = false
		button.modulate = Color.WHITE
	
	# 更新选择视觉效果
	update_selection_visual()

# 关闭UI
func _on_close_pressed():
	print("SpellSelectionUI: 关闭法术选择界面")
	# 恢复玩家输入
	resume_player_input()
	queue_free()

# 显示UI
func show_ui():
	visible = true
	# 暂停玩家输入
	pause_player_input()
	# 等待初始化完成后再更新按钮
	if game_library:
		update_spell_buttons()
	else:
		# 如果还没初始化完成，等待下一帧
		call_deferred("_deferred_update_buttons")
	show_instructions()

# 延迟更新按钮
func _deferred_update_buttons():
	if game_library:
		update_spell_buttons()
	else:
		print("SpellSelectionUI: 警告 - 法术库未初始化，无法更新按钮")

# 隐藏UI
func hide_ui():
	visible = false

# 暂停玩家输入
func pause_player_input():
	var player = get_tree().current_scene.get_node_or_null("player")
	if not player:
		print("SpellSelectionUI: 警告 - 未找到玩家节点")
		return
	
	# 使用 set_input_enabled 方法
	if player.has_method("set_input_enabled"):
		player.set_input_enabled(false)
		print("SpellSelectionUI: 已暂停玩家输入 (set_input_enabled)")
	
	# 同时设置 meta 标志作为备份
	player.set_meta("input_paused", true)
	print("SpellSelectionUI: 已设置玩家输入暂停标志")

# 恢复玩家输入
func resume_player_input():
	var player = get_tree().current_scene.get_node_or_null("player")
	if not player:
		print("SpellSelectionUI: 警告 - 未找到玩家节点")
		return
	
	# 使用 set_input_enabled 方法
	if player.has_method("set_input_enabled"):
		player.set_input_enabled(true)
		print("SpellSelectionUI: 已恢复玩家输入 (set_input_enabled)")
	
	# 同时清除 meta 标志（确保完全恢复）
	if player.has_meta("input_paused"):
		player.remove_meta("input_paused")
		print("SpellSelectionUI: 已移除玩家输入暂停标志")

# 显示操作说明
func show_instructions():
	print("=== 法术选择界面操作说明 ===")
	print("↑↓ 方向键: 选择法术")
	print("Enter/E键: 编辑选中的法术")
	print("1-9数字键: 快速选择法术")
	print("ESC键: 关闭界面")
	print("按对应按键施放法术")
	print("================================")

# 打开法术编辑界面
func open_spell_edit_ui(spell: SpellData):
	print("SpellSelectionUI: 打开法术编辑界面 - ", spell.spell_name)
	
	# 创建法术编辑UI
	var edit_ui = preload("res://scence/spell_edit_ui.tscn").instantiate()
	edit_ui.name = "SpellEditUI"
	
	# 设置要编辑的法术
	edit_ui.set_spell_to_edit(spell)
	
	# 添加到场景
	get_tree().current_scene.add_child(edit_ui)
	
	# 显示编辑UI
	edit_ui.show_ui()
	
	# 关闭当前UI
	_on_close_pressed()
