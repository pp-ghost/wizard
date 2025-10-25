extends Node

# 主机管理器
@onready var host_network: Node = $NetworkManager
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
	
	# 检查是否为服务端运行，如果是则移除player节点
	if is_server_mode():
		print("Host: 服务端模式 - 移除player节点")
		remove_player_node()
	else:
		print("Host: 客户端模式 - 保留player节点")
	
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
	
	# 更新服务器信息UI
	if server_info_ui:
		server_info_ui.update_player_count(host_network.player_count)

# 玩家断开连接
func _on_player_disconnected(peer_id: int):
	print("Host: 玩家断开连接 - ID: ", peer_id)
	
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

# 检查是否为服务端模式
func is_server_mode() -> bool:
	# 检查是否是通过网络连接进入的场景
	# 如果multiplayer.get_unique_id() > 1，说明是客户端连接过来的
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer:
		var player_id = multiplayer.get_unique_id()
		print("Host: 当前玩家ID:", player_id)
		# ID为1表示服务端，大于1表示客户端
		return player_id == 1
	else:
		# 没有网络连接，说明是服务端启动
		return true

# 移除player节点
func remove_player_node():
	var player_node = get_node_or_null("player")
	if player_node:
		print("Host: 移除player节点")
		player_node.queue_free()
	else:
		print("Host: 未找到player节点")
