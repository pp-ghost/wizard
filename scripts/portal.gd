extends Area2D

# 玩家是否在交互范围内
var player_in_range: bool = false
var player_node: Node2D = null

# 获取Label节点
@onready var interaction_label: Label = $Label

func _ready():
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 初始时隐藏提示标签
	if interaction_label:
		interaction_label.visible = false
		print("Portal: 提示标签已初始化并隐藏")
	else:
		print("Portal: 警告 - 未找到Label节点")
	
	print("Portal: 传送门已初始化")

func _on_body_entered(body: Node2D):
	if body.name == "player":
		player_in_range = true
		player_node = body
		show_interaction_prompt()
		print("Portal: 玩家进入传送门范围")

func _on_body_exited(body: Node2D):
	if body.name == "player":
		player_in_range = false
		player_node = null
		hide_interaction_prompt()
		print("Portal: 玩家离开传送门范围")

func _input(event):
	# 检测F键或ui_accept
	if (event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_F)) and player_in_range:
		print("Portal: 玩家按下了F键，准备触发传送门交互")
		
		trigger_portal_interaction()

# 触发传送门交互（未来扩展功能）
func trigger_portal_interaction():
	print("Portal: 传送门交互触发！")
	# TODO: 在这里添加具体的传送门功能
	# 例如：切换场景、显示UI、传送玩家等
	
	# 暂时播放一个提示
	show_portal_effect()

# 显示传送门效果（占位函数）
func show_portal_effect():
	print("Portal: 播放传送门效果")
	# TODO: 添加粒子效果、动画等

# 显示交互提示
func show_interaction_prompt():
	if interaction_label:
		interaction_label.visible = true
		print("Portal: 显示交互提示 - 按F进入传送门")
	else:
		print("Portal: 警告 - 未找到Label节点")

# 隐藏交互提示
func hide_interaction_prompt():
	if interaction_label:
		interaction_label.visible = false
		print("Portal: 隐藏交互提示")
	else:
		print("Portal: 警告 - 未找到Label节点")
