extends Node

# 客户端网络管理器
var network_players: Dictionary = {}
var net_player_scene = preload("res://host/scence/net_player.tscn")
var local_player_id: int = 0

func _ready():
	print("ClientNetwork: 客户端网络管理器已初始化")
	
	# 连接网络信号
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# 连接成功
func _on_connected_to_server():
	print("ClientNetwork: 已连接到服务器")
	local_player_id = multiplayer.get_unique_id()
	print("ClientNetwork: 本地玩家ID:", local_player_id)

# 连接失败
func _on_connection_failed():
	print("ClientNetwork: 连接服务器失败")

# 服务器断开
func _on_server_disconnected():
	print("ClientNetwork: 服务器断开连接")
	clear_all_network_players()

# 发送玩家数据到服务器
func send_player_data(player_id: int, data: Dictionary):
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer:
		print("ClientNetwork: 发送玩家数据 - ID:", player_id, " 数据:", data)
		rpc("receive_player_data", player_id, data)
	else:
		print("ClientNetwork: 网络未连接，无法发送数据")

# 创建网络玩家
func create_network_player(peer_id: int, player_name: String):
	if peer_id == local_player_id:
		print("ClientNetwork: 跳过创建本地玩家 - ID:", peer_id)
		return
	
	print("ClientNetwork: 创建网络玩家 - ID:", peer_id, " 名称:", player_name)
	
	var net_player_instance = net_player_scene.instantiate()
	net_player_instance.set_player_info(peer_id, player_name)
	
	var spawn_position = Vector2(200 + (peer_id % 10) * 30, 200)
	net_player_instance.position = spawn_position
	
	get_tree().current_scene.add_child(net_player_instance)
	network_players[peer_id] = net_player_instance
	
	print("ClientNetwork: 网络玩家已创建 - ID:", peer_id, " 位置:", spawn_position)

# 移除网络玩家
func remove_network_player(peer_id: int):
	print("ClientNetwork: 移除网络玩家 - ID:", peer_id)
	
	if network_players.has(peer_id):
		var net_player_instance = network_players[peer_id]
		network_players.erase(peer_id)
		
		if net_player_instance and is_instance_valid(net_player_instance):
			net_player_instance.queue_free()
		
		print("ClientNetwork: 网络玩家已移除 - ID:", peer_id)

# 更新网络玩家数据
func update_network_player(peer_id: int, data: Dictionary):
	if network_players.has(peer_id):
		var net_player_instance = network_players[peer_id]
		
		if data.has("position"):
			net_player_instance.sync_position(data["position"])
		
		if data.has("animation"):
			net_player_instance.sync_animation(data["animation"])
		
		print("ClientNetwork: 更新网络玩家 - ID:", peer_id, " 数据:", data)
	else:
		print("ClientNetwork: 警告 - 未找到网络玩家 - ID:", peer_id)

# 清理所有网络玩家
func clear_all_network_players():
	print("ClientNetwork: 清理所有网络玩家")
	for peer_id in network_players.keys():
		remove_network_player(peer_id)
	network_players.clear()

# RPC：接收服务器广播的玩家数据
@rpc("authority", "unreliable")
func sync_player_data(player_id: int, data: Dictionary):
	print("ClientNetwork: 接收玩家数据 - ID:", player_id, " 数据:", data)
	
	# 跳过本地玩家
	if player_id == local_player_id:
		print("ClientNetwork: 跳过本地玩家数据更新")
		return
	
	# 如果网络玩家不存在，创建它
	if not network_players.has(player_id):
		print("ClientNetwork: 网络玩家不存在，创建新玩家 - ID:", player_id)
		create_network_player(player_id, "Player " + str(player_id))
	
	# 更新网络玩家数据
	update_network_player(player_id, data)
