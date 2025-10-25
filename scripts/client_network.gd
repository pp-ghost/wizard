extends Node

# 客户端网络管理器
var local_player_id: int = 0
var is_connected: bool = false

# 网络玩家管理
var network_players: Dictionary = {}  # player_id -> net_player_instance
var net_player_scene = preload("res://host/scence/net_player.tscn")

# 信号
signal connected_to_server()
signal connection_failed()
signal server_disconnected()

func _ready():
	print("ClientNetwork: 客户端网络管理器已初始化")
	print("ClientNetwork: 检查现有网络连接...")
	
	# 检查是否已经有网络连接
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer:
		print("ClientNetwork: 发现现有网络连接，接管连接")
		local_player_id = multiplayer.get_unique_id()
		is_connected = true
		print("ClientNetwork: 本地玩家ID:", local_player_id)
	else:
		print("ClientNetwork: 没有现有网络连接")
	
	# 连接网络信号
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# 连接到服务器
func connect_to_server(ip: String, port: int) -> bool:
	print("ClientNetwork: 尝试连接到服务器 - IP:", ip, " 端口:", port)
	
	# 创建ENet对等体
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip, port)
	
	if result != OK:
		print("ClientNetwork: 创建客户端失败，错误代码: ", result)
		return false
	
	# 设置多玩家API
	multiplayer.multiplayer_peer = peer
	
	print("ClientNetwork: 正在连接到服务器...")
	return true

# 断开连接
func disconnect_from_server():
	print("ClientNetwork: 断开与服务器的连接")
	
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	is_connected = false
	local_player_id = 0

# 连接成功
func _on_connected_to_server():
	print("ClientNetwork: 已连接到服务器")
	local_player_id = multiplayer.get_unique_id()
	is_connected = true
	print("ClientNetwork: 本地玩家ID:", local_player_id)
	connected_to_server.emit()

# 连接失败
func _on_connection_failed():
	print("ClientNetwork: 连接服务器失败")
	is_connected = false
	connection_failed.emit()

# 服务器断开
func _on_server_disconnected():
	print("ClientNetwork: 服务器断开连接")
	is_connected = false
	local_player_id = 0
	clear_all_network_players()
	server_disconnected.emit()

# 获取连接状态
func is_connected_to_server() -> bool:
	return is_connected and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer

# 获取本地玩家ID
func get_local_player_id() -> int:
	return local_player_id

# 创建网络玩家
func create_network_player(player_id: int, player_name: String = ""):
	if player_id == local_player_id:
		print("ClientNetwork: 跳过创建本地玩家 - ID:", player_id)
		return
	
	if network_players.has(player_id):
		print("ClientNetwork: 网络玩家已存在 - ID:", player_id)
		return
	
	print("ClientNetwork: 创建网络玩家 - ID:", player_id, " 名称:", player_name)
	
	var net_player_instance = net_player_scene.instantiate()
	net_player_instance.set_player_info(player_id, player_name if player_name != "" else "Player " + str(player_id))
	
	# 设置初始位置
	var spawn_position = Vector2(200 + (player_id % 10) * 30, 200)
	net_player_instance.position = spawn_position
	
	# 添加到场景
	get_tree().current_scene.add_child(net_player_instance)
	network_players[player_id] = net_player_instance
	
	print("ClientNetwork: 网络玩家已创建 - ID:", player_id, " 位置:", spawn_position)

# 移除网络玩家
func remove_network_player(player_id: int):
	print("ClientNetwork: 移除网络玩家 - ID:", player_id)
	
	if network_players.has(player_id):
		var net_player_instance = network_players[player_id]
		network_players.erase(player_id)
		
		if net_player_instance and is_instance_valid(net_player_instance):
			net_player_instance.queue_free()
		
		print("ClientNetwork: 网络玩家已移除 - ID:", player_id)
	else:
		print("ClientNetwork: 警告 - 未找到网络玩家 - ID:", player_id)

# 清理所有网络玩家
func clear_all_network_players():
	print("ClientNetwork: 清理所有网络玩家")
	for player_id in network_players.keys():
		remove_network_player(player_id)
	network_players.clear()

# RPC：接收服务端转发的玩家事件
@rpc("authority", "unreliable")
func sync_player_event(event_data: Dictionary):
	var player_id = event_data.get("player_id", 0)
	var event_type = event_data.get("event_type", "unknown")
	
	print("ClientNetwork: 接收玩家事件 - ID:", player_id, " 类型:", event_type)
	
	# 跳过本地玩家的事件
	if player_id == local_player_id:
		print("ClientNetwork: 跳过本地玩家事件")
		return
	
	# 根据事件类型处理
	match event_type:
		"movement":
			handle_movement_event(player_id, event_data)
		"animation":
			handle_animation_event(player_id, event_data)
		"state":
			handle_state_event(player_id, event_data)
		"spell":
			handle_spell_event(player_id, event_data)
		_:
			print("ClientNetwork: 未知事件类型:", event_type)

# 处理移动事件
func handle_movement_event(player_id: int, event_data: Dictionary):
	print("ClientNetwork: 处理移动事件 - ID:", player_id)
	
	# 如果网络玩家不存在，创建它
	if not network_players.has(player_id):
		print("ClientNetwork: 网络玩家不存在，创建新玩家 - ID:", player_id)
		create_network_player(player_id, "Player " + str(player_id))
	
	# 更新网络玩家位置
	if network_players.has(player_id):
		var net_player_instance = network_players[player_id]
		var position = event_data.get("position", Vector2.ZERO)
		var velocity = event_data.get("velocity", Vector2.ZERO)
		
		net_player_instance.sync_position(position)
		print("ClientNetwork: 更新玩家位置 - ID:", player_id, " 位置:", position)

# 处理动画事件
func handle_animation_event(player_id: int, event_data: Dictionary):
	print("ClientNetwork: 处理动画事件 - ID:", player_id)
	
	# 如果网络玩家不存在，创建它
	if not network_players.has(player_id):
		print("ClientNetwork: 网络玩家不存在，创建新玩家 - ID:", player_id)
		create_network_player(player_id, "Player " + str(player_id))
	
	# 更新网络玩家动画
	if network_players.has(player_id):
		var net_player_instance = network_players[player_id]
		var animation = event_data.get("animation", "idle")
		var facing_direction = event_data.get("facing_direction", 1)
		
		net_player_instance.sync_animation(animation)
		print("ClientNetwork: 更新玩家动画 - ID:", player_id, " 动画:", animation)

# 处理状态事件
func handle_state_event(player_id: int, event_data: Dictionary):
	print("ClientNetwork: 处理状态事件 - ID:", player_id)
	
	var state_type = event_data.get("state_type", "")
	var state_value = event_data.get("state_value", false)
	print("ClientNetwork: 更新玩家状态 - ID:", player_id, " 类型:", state_type, " 值:", state_value)
	
	# 这里可以根据状态类型更新net_player的相应状态
	# 例如：翻滚状态、攻击状态等

# 处理法术事件
func handle_spell_event(player_id: int, event_data: Dictionary):
	print("ClientNetwork: 处理法术事件 - ID:", player_id)
	
	var spell_data = event_data.get("spell_data", {})
	print("ClientNetwork: 执行法术 - ID:", player_id, " 法术:", spell_data)
	
	# 如果网络玩家不存在，创建它
	if not network_players.has(player_id):
		print("ClientNetwork: 网络玩家不存在，创建新玩家 - ID:", player_id)
		create_network_player(player_id, "Player " + str(player_id))
	
	# 执行网络玩家的法术
	if network_players.has(player_id):
		var net_player_instance = network_players[player_id]
		net_player_instance.sync_spell_cast(spell_data)
