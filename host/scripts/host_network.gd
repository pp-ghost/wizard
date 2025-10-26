extends Node

# 服务端网络管理器
var peer: ENetMultiplayerPeer
var server_port: int = 7000
var max_players: int = 4

# 玩家管理
var connected_players: Dictionary = {}
var player_count: int = 0

# 信号
signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)
signal server_started(port: int)
signal server_stopped()

func _ready():
	print("HostNetwork: 服务端网络管理器已初始化")
	
	# 检查运行模式
	if is_client_mode():
		print("HostNetwork: 检测到客户端模式，跳过服务端初始化")
		return
	
	print("HostNetwork: 服务端模式，开始初始化")

# 检查是否为客户端模式
func is_client_mode() -> bool:
	# 如果multiplayer.get_unique_id() != 1，说明是客户端
	return multiplayer.has_multiplayer_peer() and multiplayer.get_unique_id() != 1

# 启动服务端
func start_server(port: int = 7000) -> bool:
	# 检查运行模式
	if is_client_mode():
		print("HostNetwork: 客户端模式，跳过服务端启动")
		return false
	
	server_port = port
	
	# 创建ENet对等体
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, max_players)
	
	if result != OK:
		print("HostNetwork: 服务端启动失败，错误代码: ", result)
		return false
	
	# 设置多玩家API
	multiplayer.multiplayer_peer = peer
	
	# 连接信号
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("HostNetwork: 服务器已启动 - IP:", get_local_ip(), " 端口:", port)
	server_started.emit(port)
	return true

# 停止服务端
func stop_server():
	if peer:
		peer.close()
		peer = null
	
	multiplayer.multiplayer_peer = null
	connected_players.clear()
	player_count = 0
	
	print("HostNetwork: 服务端已停止")
	server_stopped.emit()

# 获取本地IP地址
func get_local_ip() -> String:
	var ip_addresses = IP.get_local_addresses()
	for ip in ip_addresses:
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"

# 玩家连接事件
func _on_peer_connected(peer_id: int):
	print("HostNetwork: 玩家连接 - ID:", peer_id)
	
	var player_info = {
		"peer_id": peer_id,
		"name": "Player_" + str(peer_id),
		"connected_time": Time.get_unix_time_from_system()
	}
	
	connected_players[peer_id] = player_info
	player_count += 1
	
	print("HostNetwork: 当前在线玩家数:", player_count)
	player_connected.emit(peer_id, player_info)
	
	# 发送测试RPC给新连接的客户端
	print("HostNetwork: 发送测试RPC给客户端 - ID:", peer_id)
	rpc_id(peer_id, "test_simple_rpc", "Welcome from server!")

# 玩家断开连接事件
func _on_peer_disconnected(peer_id: int):
	print("HostNetwork: 玩家断开连接 - ID:", peer_id)
	
	if connected_players.has(peer_id):
		connected_players.erase(peer_id)
		player_count -= 1
	
	print("HostNetwork: 当前在线玩家数:", player_count)
	player_disconnected.emit(peer_id)

# 获取服务器信息
func get_server_info() -> Dictionary:
	return {
		"ip": get_local_ip(),
		"port": server_port,
		"max_players": max_players,
		"current_players": player_count
	}

# 获取当前玩家数
func get_player_count() -> int:
	return player_count

# 获取连接状态
func is_server_running() -> bool:
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

# 简单的测试RPC
@rpc("any_peer", "unreliable")
func test_simple_rpc(message: String):
	# 检查运行模式
	if is_client_mode():
		print("HostNetwork: 客户端模式，跳过测试RPC处理")
		return
	
	print("HostNetwork: ===== 收到测试RPC =====")
	print("HostNetwork: 消息:", message)
	print("HostNetwork: 发送者ID:", multiplayer.get_remote_sender_id())
	print("HostNetwork: ===== 测试RPC完成 =====")

# RPC：接收服务端转发的玩家事件（客户端模式）
@rpc("any_peer", "unreliable")
func sync_player_event(event_data: Dictionary):
	# 检查运行模式
	if not is_client_mode():
		print("HostNetwork: 服务端模式，跳过客户端RPC处理")
		return
	
	print("HostNetwork: ===== 客户端收到服务端转发的RPC =====")
	print("HostNetwork: 事件数据:", event_data)
	print("HostNetwork: 发送者ID:", multiplayer.get_remote_sender_id())
	
	var player_id = event_data.get("player_id", 0)
	var event_type = event_data.get("event_type", "unknown")
	
	print("HostNetwork: 接收玩家事件 - ID:", player_id, " 类型:", event_type)
	print("HostNetwork: 本地玩家ID:", multiplayer.get_unique_id())
	
	# 跳过本地玩家的事件
	if player_id == multiplayer.get_unique_id():
		print("HostNetwork: 跳过本地玩家事件")
		return
	
	print("HostNetwork: 开始处理事件 - 类型:", event_type)
	
	# 根据事件类型处理
	match event_type:
		"movement":
			print("HostNetwork: 匹配到movement事件，调用handle_movement_event")
			handle_movement_event(player_id, event_data)
		"animation":
			print("HostNetwork: 匹配到animation事件，调用handle_animation_event")
			handle_animation_event(player_id, event_data)
		"state":
			print("HostNetwork: 匹配到state事件，调用handle_state_event")
			handle_state_event(player_id, event_data)
		"spell":
			print("HostNetwork: 匹配到spell事件，调用handle_spell_event")
			handle_spell_event(player_id, event_data)
		_:
			print("HostNetwork: 未知事件类型:", event_type)
	
	print("HostNetwork: ===== 客户端RPC处理完成 =====")

# 处理移动事件（客户端模式）
func handle_movement_event(player_id: int, event_data: Dictionary):
	print("HostNetwork: ===== 处理移动事件 =====")
	print("HostNetwork: 玩家ID:", player_id)
	print("HostNetwork: 事件数据:", event_data)
	
	# 这里需要创建网络玩家，但我们需要访问ClientNetworkManager
	var client_network = get_node("../ClientNetworkManager")
	if client_network:
		client_network.handle_movement_event(player_id, event_data)
	else:
		print("HostNetwork: 错误 - 未找到ClientNetworkManager节点")

# 处理动画事件（客户端模式）
func handle_animation_event(player_id: int, event_data: Dictionary):
	print("HostNetwork: 处理动画事件 - ID:", player_id)
	var client_network = get_node("../ClientNetworkManager")
	if client_network:
		client_network.handle_animation_event(player_id, event_data)

# 处理状态事件（客户端模式）
func handle_state_event(player_id: int, event_data: Dictionary):
	print("HostNetwork: 处理状态事件 - ID:", player_id)
	var client_network = get_node("../ClientNetworkManager")
	if client_network:
		client_network.handle_state_event(player_id, event_data)

# 处理法术事件（客户端模式）
func handle_spell_event(player_id: int, event_data: Dictionary):
	print("HostNetwork: 处理法术事件 - ID:", player_id)
	var client_network = get_node("../ClientNetworkManager")
	if client_network:
		client_network.handle_spell_event(player_id, event_data)

# RPC：接收客户端事件并转发
@rpc("any_peer", "unreliable")
func receive_player_event(event_data: Dictionary):
	# 检查运行模式
	if is_client_mode():
		print("HostNetwork: 客户端模式，跳过RPC处理")
		return
	
	print("HostNetwork: ===== 收到RPC调用 =====")
	print("HostNetwork: 事件数据:", event_data)
	
	var player_id = event_data.get("player_id", 0)
	var event_type = event_data.get("event_type", "unknown")
	
	print("HostNetwork: 接收玩家事件 - ID:", player_id, " 类型:", event_type)
	print("HostNetwork: 当前连接玩家:", connected_players.keys())
	
	# 验证玩家是否已连接
	if not connected_players.has(player_id):
		print("HostNetwork: 警告 - 未连接的玩家发送事件 - ID:", player_id)
		print("HostNetwork: 已连接玩家列表:", connected_players.keys())
		return
	
	# 验证事件数据
	if not validate_event_data(event_data):
		print("HostNetwork: 事件数据验证失败 - ID:", player_id)
		return
	
	# 转发事件给所有其他客户端
	print("HostNetwork: 转发事件给其他客户端")
	rpc("sync_player_event", event_data)
	print("HostNetwork: ===== RPC处理完成 =====")

# 验证事件数据
func validate_event_data(event_data: Dictionary) -> bool:
	# 检查必需字段
	if not event_data.has("player_id") or not event_data.has("event_type"):
		return false
	
	var event_type = event_data.get("event_type", "")
	
	# 根据事件类型验证数据
	match event_type:
		"movement":
			return event_data.has("position") and event_data.has("velocity")
		"animation":
			return event_data.has("animation")
		"state":
			return event_data.has("state_type") and event_data.has("state_value")
		"spell":
			return event_data.has("spell_data")
		_:
			print("HostNetwork: 未知事件类型:", event_type)
			return false