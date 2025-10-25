extends Control

# 节点引用
@onready var ip_input: LineEdit = $Panel/VBoxContainer/IPInput
@onready var port_input: LineEdit = $Panel/VBoxContainer/PortInput
@onready var connect_button: Button = $Panel/VBoxContainer/ButtonContainer/ConnectButton
@onready var cancel_button: Button = $Panel/VBoxContainer/ButtonContainer/CancelButton
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel

# 网络相关
var peer: ENetMultiplayerPeer
var is_connecting: bool = false

func _ready():
	# 连接按钮信号
	connect_button.pressed.connect(_on_connect_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# 连接输入框信号
	ip_input.text_submitted.connect(_on_ip_text_submitted)
	port_input.text_submitted.connect(_on_port_text_submitted)
	
	# 连接网络信号
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# 确保输入框可以获得焦点
	ip_input.grab_focus()
	
	print("NetworkJoinUI: 联机界面已初始化")

# 连接按钮按下
func _on_connect_button_pressed():
	attempt_connection()

# 取消按钮按下
func _on_cancel_button_pressed():
	close_ui()

# IP输入框回车
func _on_ip_text_submitted(text: String):
	attempt_connection()

# 端口输入框回车
func _on_port_text_submitted(text: String):
	attempt_connection()

# 尝试连接
func attempt_connection():
	if is_connecting:
		return
	
	var ip = ip_input.text.strip_edges()
	var port_text = port_input.text.strip_edges()
	
	# 验证输入
	if ip.is_empty():
		update_status("请输入IP地址", Color.RED)
		return
	
	if port_text.is_empty():
		port_text = "7000"
	
	var port = port_text.to_int()
	if port <= 0 or port > 65535:
		update_status("端口号无效 (1-65535)", Color.RED)
		return
	
	# 开始连接
	update_status("正在连接...", Color.YELLOW)
	is_connecting = true
	connect_button.disabled = true
	
	# 创建ENet对等体
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip, port)
	
	if result != OK:
		update_status("连接失败: " + str(result), Color.RED)
		is_connecting = false
		connect_button.disabled = false
		return
	
	# 设置多玩家API
	multiplayer.multiplayer_peer = peer
	
	print("NetworkJoinUI: 正在连接到 ", ip, ":", port)

# 连接成功
func _on_connected_to_server():
	print("NetworkJoinUI: 连接成功！")
	update_status("连接成功！", Color.GREEN)
	
	# 延迟一下再切换场景，让用户看到成功消息
	await get_tree().create_timer(1.0).timeout
	
	# 切换到战斗场景
	get_tree().change_scene_to_file("res://scence/fight.tscn")

# 连接失败
func _on_connection_failed():
	print("NetworkJoinUI: 连接失败")
	update_status("连接失败，请检查IP和端口", Color.RED)
	is_connecting = false
	connect_button.disabled = false

# 服务器断开连接
func _on_server_disconnected():
	print("NetworkJoinUI: 服务器断开连接")
	update_status("服务器断开连接", Color.RED)
	is_connecting = false
	connect_button.disabled = false

# 更新状态标签
func update_status(text: String, color: Color = Color.WHITE):
	status_label.text = text
	status_label.modulate = color
	print("NetworkJoinUI: ", text)

# 关闭界面
func close_ui():
	print("NetworkJoinUI: 关闭联机界面")
	queue_free()

# 处理ESC键关闭
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		close_ui()
	
	# 确保输入框能正常接收输入
	if event is InputEventKey:
		if ip_input.has_focus() or port_input.has_focus():
			# 让输入框处理键盘输入
			pass
