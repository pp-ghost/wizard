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

# 局域网服务器发现
var udp: PacketPeerUDP
var discovered_servers: Array = []  # [{ip, port, name, response_time}]
var is_scanning: bool = false
var scan_timer: Timer

func _ready():
	print("NetworkJoinUI: 联机界面已初始化")
	
	# 创建扫描定时器
	scan_timer = Timer.new()
	scan_timer.wait_time = 2.0  # 扫描2秒
	scan_timer.timeout.connect(_on_scan_timeout)
	scan_timer.one_shot = true
	add_child(scan_timer)
	
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
	ip_input.placeholder_text = "例如: 127.0.0.1 或 点击下方搜索"
	port_input.text = "7000"
	
	# 自动开始扫描局域网服务器
	print("NetworkJoinUI: 开始扫描局域网服务器...")
	start_scanning()

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

# 开始扫描局域网
func start_scanning():
	if is_scanning:
		return
	
	print("NetworkJoinUI: 开始扫描局域网服务器...")
	is_scanning = true
	discovered_servers.clear()
	
	# 创建UDP socket
	udp = PacketPeerUDP.new()
	var error = udp.bind(0)  # 随机端口
	
	if error != OK:
		print("NetworkJoinUI: 无法绑定UDP端口:", error)
		is_scanning = false
		return
	
	# 设置为非阻塞模式
	udp.set_broadcast_enabled(true)
	
	# 扫描常用端口
	scan_port_range(7000, 7010)
	
	# 广播扫描包
	broadcast_scan()
	
	# 启动定时器
	scan_timer.start()

# 扫描端口范围
func scan_port_range(start_port: int, end_port: int):
	print("NetworkJoinUI: 扫描端口范围:", start_port, "-", end_port)
	
	# 获取本地IP
	var local_ip = get_local_ip()
	print("NetworkJoinUI: 本地IP:", local_ip)
	
	# 扫描同一子网的所有IP
	var subnet = get_subnet(local_ip)
	print("NetworkJoinUI: 子网:", subnet)
	
	# 扫描子网中的所有IP
	for i in range(1, 255):
		var ip = subnet + "." + str(i)
		for port in range(start_port, end_port + 1):
			test_server_connection(ip, port)

# 广播扫描
func broadcast_scan():
	print("NetworkJoinUI: 发送广播包...")
	
	# 广播到255.255.255.255
	var message = "GODOT_SERVER_DISCOVERY"
	var broadcast_ip = "255.255.255.255"
	
	for port in range(7000, 7011):
		udp.set_dest_address(broadcast_ip, port)
		udp.put_packet(message.to_utf8_buffer())

# 测试服务器连接
func test_server_connection(ip: String, port: int):
	# 创建临时ENet peer进行快速连接测试
	var test_peer = ENetMultiplayerPeer.new()
	test_peer.create_client(ip, port)
	
	# 快速检查连接状态
	for i in range(5):  # 尝试5次
		test_peer.poll()
		if test_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			# 发现服务器！
			print("NetworkJoinUI: 发现服务器! IP:", ip, " 端口:", port)
			
			# 添加到服务器列表
			var server_info = {
				"ip": ip,
				"port": port,
				"name": "服务器 " + ip,
				"response_time": i * 10  # 伪延迟
			}
			
			# 避免重复
			var exists = false
			for existing in discovered_servers:
				if existing.ip == ip and existing.port == port:
					exists = true
					break
			
			if not exists:
				discovered_servers.append(server_info)
				update_server_list()
			
			test_peer.close()
			return
		
		await get_tree().create_timer(0.01).timeout  # 等待10ms
	
	# 清理
	test_peer.close()

# 扫描超时
func _on_scan_timeout():
	print("NetworkJoinUI: 扫描完成，发现", discovered_servers.size(), "个服务器")
	is_scanning = false
	
	if udp:
		udp.close()
	
	# 更新状态
	if discovered_servers.size() > 0:
		update_status("发现 " + str(discovered_servers.size()) + " 个服务器，点击上方IP快速填入", Color.GREEN)
		# 自动填入第一个服务器
		ip_input.text = discovered_servers[0].ip
		port_input.text = str(discovered_servers[0].port)
	else:
		update_status("未发现服务器，请手动输入IP", Color.YELLOW)

# 更新服务器列表（在UI中显示）
func update_server_list():
	# 这里可以更新UI显示服务器列表
	# 现在只是更新状态
	if discovered_servers.size() > 0:
		update_status("已发现 " + str(discovered_servers.size()) + " 个服务器", Color.CYAN)

# 获取本地IP
func get_local_ip() -> String:
	var ip_addresses = IP.get_local_addresses()
	for ip in ip_addresses:
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172.16.") or ip.begins_with("172.17.") or ip.begins_with("172.18.") or ip.begins_with("172.19.") or ip.begins_with("172.20.") or ip.begins_with("172.21.") or ip.begins_with("172.22.") or ip.begins_with("172.23.") or ip.begins_with("172.24.") or ip.begins_with("172.25.") or ip.begins_with("172.26.") or ip.begins_with("172.27.") or ip.begins_with("172.28.") or ip.begins_with("172.29.") or ip.begins_with("172.30.") or ip.begins_with("172.31."):
			return ip
	return "127.0.0.1"

# 获取子网
func get_subnet(ip: String) -> String:
	var parts = ip.split(".")
	if parts.size() >= 3:
		return parts[0] + "." + parts[1] + "." + parts[2]
	return "192.168.1"

# 处理ESC键关闭
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		close_ui()
	
	# 确保输入框能正常接收输入
	if event is InputEventKey:
		if ip_input.has_focus() or port_input.has_focus():
			# 让输入框处理键盘输入
			pass

# 关闭界面
func close_ui():
	print("NetworkJoinUI: 关闭联机界面")
	
	# 停止扫描
	if is_scanning:
		is_scanning = false
		if scan_timer:
			scan_timer.stop()
	
	if udp:
		udp.close()
	
	# 断开所有连接
	disconnect_existing_connection()
	
	# 清理资源
	queue_free()
