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
	print("NetworkJoinUI: 联机界面已初始化")
	
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
	
	# 设置默认值
	ip_input.placeholder_text = "例如: 127.0.0.1"
	port_input.text = "7000"

# 连接按钮按下
func _on_connect_button_pressed():
	print("NetworkJoinUI: 连接按钮被按下")
	attempt_connection()

# 取消按钮按下
func _on_cancel_button_pressed():
	print("NetworkJoinUI: 取消按钮被按下")
	close_ui()

# IP输入框回车
func _on_ip_text_submitted(text: String):
	print("NetworkJoinUI: IP输入框回车")
	attempt_connection()

# 端口输入框回车
func _on_port_text_submitted(text: String):
	print("NetworkJoinUI: 端口输入框回车")
	attempt_connection()

# 尝试连接
func attempt_connection():
	print("NetworkJoinUI: 开始尝试连接...")
	
	if is_connecting:
		print("NetworkJoinUI: 已经在连接中，跳过")
		update_status("正在连接中...", Color.YELLOW)
		return
	
	# 检查是否已经有连接
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer:
		print("NetworkJoinUI: 已存在网络连接，先断开")
		disconnect_existing_connection()
	
	var ip = ip_input.text.strip_edges()
	var port_text = port_input.text.strip_edges()
	
	print("NetworkJoinUI: 输入IP:", ip, " 端口:", port_text)
	
	# 验证输入
	if ip.is_empty():
		print("NetworkJoinUI: IP地址为空")
		update_status("请输入IP地址", Color.RED)
		ip_input.grab_focus()
		return
	
	if port_text.is_empty():
		port_text = "7000"
	
	var port = port_text.to_int()
	if port <= 0 or port > 65535:
		print("NetworkJoinUI: 端口号无效:", port)
		update_status("端口号无效 (1-65535)", Color.RED)
		port_input.grab_focus()
		return
	
	# 开始连接
	print("NetworkJoinUI: 开始连接流程...")
	update_status("正在连接...", Color.YELLOW)
	is_connecting = true
	connect_button.disabled = true
	connect_button.text = "连接中..."
	
	# 清理旧的peer对象
	if peer:
		peer.close()
		peer = null
	
	# 创建新的ENet对等体
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip, port)
	
	print("NetworkJoinUI: 创建客户端结果:", result)
	
	if result != OK:
		print("NetworkJoinUI: 创建客户端失败，错误代码:", result)
		update_status("连接失败: " + str(result), Color.RED)
		reset_connection_state()
		return
	
	# 设置多玩家API
	multiplayer.multiplayer_peer = peer
	
	print("NetworkJoinUI: 正在连接到 ", ip, ":", port)
	update_status("正在连接到 " + ip + ":" + str(port), Color.YELLOW)

# 连接成功
func _on_connected_to_server():
	print("NetworkJoinUI: 连接成功！")
	print("NetworkJoinUI: 连接时的玩家ID:", multiplayer.get_unique_id())
	print("NetworkJoinUI: 网络状态:", multiplayer.has_multiplayer_peer())
	print("NetworkJoinUI: 是否为服务器:", multiplayer.is_server())
	update_status("连接成功！", Color.GREEN)
	
	# 延迟一下再切换场景，让用户看到成功消息
	await get_tree().create_timer(1.5).timeout
	
	# 切换到服务器场景
	print("NetworkJoinUI: 场景切换前的玩家ID:", multiplayer.get_unique_id())
	print("NetworkJoinUI: 切换到服务器场景")
	get_tree().change_scene_to_file("res://host/scence/host.tscn")

# 连接失败
func _on_connection_failed():
	print("NetworkJoinUI: 连接失败")
	update_status("连接失败，请检查IP和端口", Color.RED)
	reset_connection_state()

# 服务器断开连接
func _on_server_disconnected():
	print("NetworkJoinUI: 服务器断开连接")
	update_status("服务器断开连接", Color.RED)
	reset_connection_state()

# 断开现有连接
func disconnect_existing_connection():
	print("NetworkJoinUI: 断开现有连接")
	
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	if peer:
		peer.close()
		peer = null
	
	is_connecting = false
	print("NetworkJoinUI: 现有连接已断开")

# 重置连接状态
func reset_connection_state():
	is_connecting = false
	connect_button.disabled = false
	connect_button.text = "连接"

# 更新状态标签
func update_status(text: String, color: Color = Color.WHITE):
	status_label.text = text
	status_label.modulate = color
	print("NetworkJoinUI: ", text)

# 关闭界面
func close_ui():
	print("NetworkJoinUI: 关闭联机界面")
	
	# 断开所有连接
	disconnect_existing_connection()
	
	# 清理资源
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
