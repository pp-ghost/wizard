extends Node

# 主机管理器
@onready var host_network: Node = $HostNetwork
@onready var server_info_ui: Control = $ServerInfoUI

# 网络玩家管理
var network_players: Dictionary = {}  # peer_id -> net_player_instance
var net_player_scene = preload("res://host/scence/net_player.tscn")

# 服务器状态
var is_server_running: bool = false
var server_info: Dictionary = {}

func _ready():
	print("Host: 主机管理器已初始化")
	
	# 连接网络管理器信号
	if host_network:
		host_network.player_connected.connect(_on_player_connected)
		host_network.player_disconnected.connect(_on_player_disconnected)
		host_network.server_started.connect(_on_server_started)
		host_network.server_stopped.connect(_on_server_stopped)
	
	# 启动服务器
	start_server()

# 启动服务器
func start_server(port: int = 7000):
	if host_network:
		if host_network.start_server(port):
			print("Host: 服务器启动成功")
		else:
			print("Host: 服务器启动失败")
	else:
		print("Host: 错误 - 未找到网络管理器")

# 停止服务器
func stop_server():
	if host_network:
		host_network.stop_server()
		print("Host: 服务器已停止")

# 服务器启动成功
func _on_server_started(port: int):
	is_server_running = true
	server_info = host_network.get_server_info()
	
	# 更新服务器信息UI
	if server_info_ui:
		server_info_ui.set_server_info(
			server_info.get("ip", "未知"), 
			port, 
			host_network.max_players
		)
	
	print("Host: ========================================")
	print("Host: 服务器启动成功！")
	print("Host: IP地址: ", server_info.get("ip", "未知"))
	print("Host: 端口: ", port)
	print("Host: ========================================")
	print("Host: 等待玩家连接...")
	print("Host: 请将IP地址告诉其他玩家！")

# 服务器停止
func _on_server_stopped():
	is_server_running = false
	server_info.clear()
	print("Host: 服务器已停止")

# 玩家连接
func _on_player_connected(peer_id: int, player_info: Dictionary):
	print("Host: 玩家连接 - ID: ", peer_id, " 名称: ", player_info.get("name", "未知"))
	
	# 创建网络玩家实例
	create_network_player(peer_id, player_info)
	
	# 更新服务器信息UI
	if server_info_ui:
		server_info_ui.update_player_count(host_network.player_count)

# 玩家断开连接
func _on_player_disconnected(peer_id: int):
	print("Host: 玩家断开连接 - ID: ", peer_id)
	
	# 移除网络玩家实例
	remove_network_player(peer_id)
	
	# 更新服务器信息UI
	if server_info_ui:
		server_info_ui.update_player_count(host_network.player_count)

# 获取服务器信息
func get_server_info() -> Dictionary:
	if host_network:
		return host_network.get_server_info()
	return {}

# 获取当前玩家数
func get_player_count() -> int:
	if host_network:
		return host_network.get_player_count()
	return 0

# 检查服务器状态
func is_server_active() -> bool:
	return is_server_running and host_network and host_network.is_server_running()

# 创建网络玩家
func create_network_player(peer_id: int, player_info: Dictionary):
	print("Host: 创建网络玩家 - ID:", peer_id)
	
	# 实例化网络玩家
	var net_player_instance = net_player_scene.instantiate()
	
	# 设置玩家信息
	net_player_instance.set_player_info(peer_id, player_info.get("name", "Player " + str(peer_id)))
	
	# 设置初始位置（固定位置，避免peer_id过大导致位置异常）
	var spawn_position = Vector2(200, 200)
	net_player_instance.position = spawn_position
	
	# 添加到场景
	add_child(net_player_instance)
	
	# 存储引用
	network_players[peer_id] = net_player_instance
	
	print("Host: 网络玩家已创建 - ID:", peer_id, " 位置:", spawn_position)

# 移除网络玩家
func remove_network_player(peer_id: int):
	print("Host: 移除网络玩家 - ID:", peer_id)
	
	if network_players.has(peer_id):
		var net_player_instance = network_players[peer_id]
		network_players.erase(peer_id)
		
		if net_player_instance and is_instance_valid(net_player_instance):
			net_player_instance.queue_free()
		
		print("Host: 网络玩家已移除 - ID:", peer_id)
	else:
		print("Host: 警告 - 未找到网络玩家 - ID:", peer_id)

# 处理网络玩家数据同步
func _on_player_data_sync(player_id: int, data: Dictionary):
	if network_players.has(player_id):
		var net_player_instance = network_players[player_id]
		
		# 更新位置
		if data.has("position"):
			net_player_instance.sync_position(data["position"])
		
		# 更新动画
		if data.has("animation"):
			net_player_instance.sync_animation(data["animation"])
		
		print("Host: 更新网络玩家数据 - ID:", player_id, " 数据:", data)
