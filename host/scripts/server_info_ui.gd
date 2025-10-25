extends Control

# 节点引用
@onready var ip_label: Label = $Panel/VBoxContainer/IPLabel
@onready var port_label: Label = $Panel/VBoxContainer/PortLabel
@onready var players_label: Label = $Panel/VBoxContainer/PlayersLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel

# 服务器信息
var server_ip: String = "获取中..."
var server_port: int = 7000
var player_count: int = 0
var max_players: int = 4

func _ready():
	print("ServerInfoUI: 服务器信息UI已初始化")
	update_display()

# 设置服务器信息
func set_server_info(ip: String, port: int, max_players: int = 4):
	server_ip = ip
	server_port = port
	self.max_players = max_players
	update_display()
	print("ServerInfoUI: 服务器信息已更新 - IP:", ip, " 端口:", port)

# 更新玩家数量
func update_player_count(count: int):
	player_count = count
	update_display()

# 更新显示
func update_display():
	if ip_label:
		ip_label.text = "IP地址: " + server_ip
	if port_label:
		port_label.text = "端口: " + str(server_port)
	if players_label:
		players_label.text = "玩家数: " + str(player_count) + "/" + str(max_players)
	if status_label:
		status_label.text = "状态: 运行中"

# 设置状态
func set_status(status: String):
	if status_label:
		status_label.text = "状态: " + status
