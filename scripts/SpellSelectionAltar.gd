extends Area2D

# 玩家进入范围标志
var player_in_range: bool = false
var player_node: Node2D = null

# 获取Label节点
@onready var interaction_label: Label = $Label


func _ready():
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interaction_label.visible = false
	
	# 连接法术库信号
	connect_to_spell_library()
	
	# 调试输出：Altar已初始化
	print("SpellSelectionAltar: 法术选择祭坛已初始化")

# 连接到法术库信号
func connect_to_spell_library():
	var game_library = GameSpellLibrary.instance
	if game_library:
		# 连接法术装备信号
		game_library.spell_equipped.connect(_on_spell_equipped)
		game_library.spell_unequipped.connect(_on_spell_unequipped)
		game_library.spell_loadout_changed.connect(_on_spell_loadout_changed)
		print("SpellSelectionAltar: 已连接到法术库信号")
	else:
		print("SpellSelectionAltar: 警告 - 未找到法术库，将在下次尝试连接")

# 断开法术库信号连接
func disconnect_from_spell_library():
	var game_library = GameSpellLibrary.instance
	if game_library:
		game_library.spell_equipped.disconnect(_on_spell_equipped)
		game_library.spell_unequipped.disconnect(_on_spell_unequipped)
		game_library.spell_loadout_changed.disconnect(_on_spell_loadout_changed)
		print("SpellSelectionAltar: 已断开法术库信号连接")

func _input(event):
	# 调试：显示所有按键输入
	if event is InputEventKey and event.pressed:
		print("SpellSelectionAltar: 检测到按键 - ", event.keycode, " 玩家在范围内: ", player_in_range)
	
	# 检测E键按下
	if (event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_E)) and player_in_range:
		# 检查是否已经有法术选择界面打开
		var existing_ui = get_tree().current_scene.get_node_or_null("SpellSelectionUI")
		if existing_ui:
			print("SpellSelectionAltar: 关闭已打开的法术选择界面")
			existing_ui.queue_free()
		else:
			print("SpellSelectionAltar: 玩家按下了E键，准备打开法术选择界面")
			open_spell_selection()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_E:
		print("SpellSelectionAltar: 检测到E键，但玩家不在范围内")
	elif player_in_range:
		print("SpellSelectionAltar: 玩家在范围内，等待E键输入...")

func _on_body_entered(body):
	# 检查进入的是否是玩家
	if body.name == "player":
		player_in_range = true
		player_node = body
		print("SpellSelectionAltar: 玩家进入了法术选择祭坛范围")
		print("SpellSelectionAltar: 玩家位置: ", body.global_position)
		show_interaction_prompt()

func _on_body_exited(body):
	# 检查离开的是否是玩家
	if body.name == "player":
		player_in_range = false
		player_node = null
		print("SpellSelectionAltar: 玩家离开了法术选择祭坛范围")
		hide_interaction_prompt()

func show_interaction_prompt():
	# 显示交互提示
	if interaction_label:
		interaction_label.visible = true
		print("SpellSelectionAltar: 显示交互提示 - 按E选择法术")
	else:
		print("SpellSelectionAltar: 警告 - 未找到Label节点")

func hide_interaction_prompt():
	# 隐藏交互提示
	if interaction_label:
		interaction_label.visible = false
		print("SpellSelectionAltar: 隐藏交互提示")
	else:
		print("SpellSelectionAltar: 警告 - 未找到Label节点")

# 信号处理函数
func _on_spell_equipped(spell: SpellData):
	print("SpellSelectionAltar: 法术已装备 - ", spell.spell_name)

func _on_spell_unequipped(spell: SpellData):
	print("SpellSelectionAltar: 法术已卸下 - ", spell.spell_name)

func _on_spell_loadout_changed():
	print("SpellSelectionAltar: 法术装备配置已更改")

func open_spell_selection():
	# 打开法术选择界面
	print("SpellSelectionAltar: 正在打开法术选择界面...")
	
	# 获取全局法术库
	var game_library = GameSpellLibrary.instance
	if game_library:
		# 创建法术选择UI
		var ui_scene = preload("res://scence/spell_selection_ui.tscn")
		var ui_instance = ui_scene.instantiate()
		
		# 设置节点名称，方便后续查找
		ui_instance.name = "SpellSelectionUI"
		
		# 添加到场景
		get_tree().current_scene.add_child(ui_instance)
		
		# 显示UI
		ui_instance.show_ui()
		
		print("SpellSelectionAltar: 法术选择界面已打开")
	else:
		print("SpellSelectionAltar: 错误 - 未找到全局法术库")
