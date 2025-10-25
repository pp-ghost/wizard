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

# 启动服务端
func start_server(port: int = 7000):
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

# RPC：接收客户端数据并广播
@rpc("any_peer", "unreliable")
func receive_player_data(player_id: int, data: Dictionary):
	print("HostNetwork: 接收玩家数据 - ID:", player_id, " 数据:", data)
	
	# 广播给所有其他客户端
	rpc("sync_player_data", player_id, data)
	print("HostNetwork: 已广播数据给其他客户端")

# RPC：广播玩家数据给客户端
@rpc("authority", "unreliable")
func sync_player_data(player_id: int, data: Dictionary):
	print("HostNetwork: 广播玩家数据 - ID:", player_id, " 数据:", data)
