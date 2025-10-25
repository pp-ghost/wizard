extends Control

# 节点引用
@onready var server_button: Button = $VBoxContainer/ServerButton
@onready var client_button: Button = $VBoxContainer/ClientButton

func _ready():
	# 连接按钮信号
	server_button.pressed.connect(_on_server_button_pressed)
	client_button.pressed.connect(_on_client_button_pressed)
	
	print("StartupMenu: 启动菜单已加载")

# 服务端按钮按下
func _on_server_button_pressed():
	print("StartupMenu: 选择服务端模式")
	get_tree().change_scene_to_file("res://host/scence/host.tscn")

# 客户端按钮按下
func _on_client_button_pressed():
	print("StartupMenu: 选择客户端模式")
	get_tree().change_scene_to_file("res://scence/house.tscn")
