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
	
	# 调试输出：Altar已初始化
	print("SpellSelectionAltar: 法术选择祭坛已初始化")

func _input(event):
	# 检测E键按下
	if event.is_action_pressed("ui_accept") and player_in_range:
		print("SpellSelectionAltar: 玩家按下了E键，准备打开法术选择界面")
		open_spell_selection()

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

func open_spell_selection():
	# 打开法术选择界面
	print("SpellSelectionAltar: 正在打开法术选择界面...")
	# 这里将添加打开法术选择界面的逻辑
	print("SpellSelectionAltar: 法术选择界面已打开")
