extends Node

# 生成点管理器 - 单例模式
static var instance: Node

# 预定义的生成点坐标
var spawn_points: Array[Vector2] = [
	Vector2(150, 150),   # 原始位置
	Vector2(300, 200),   # 右侧
	Vector2(100, 300),   # 下方
	Vector2(400, 100),   # 右上
	Vector2(200, 400),   # 右下
	Vector2(50, 200),    # 左侧
	Vector2(350, 350),   # 右下角
	Vector2(250, 50)     # 上方
]

# 已使用的生成点（记录玩家ID和对应的生成点）
var used_spawn_points: Dictionary = {}

func _ready():
	# 设置单例
	instance = self
	print("SpawnManager: 生成点管理器已初始化")
	print("SpawnManager: 可用生成点数量:", spawn_points.size())

# 获取一个可用的生成点
func get_available_spawn_point(player_id: int) -> Vector2:
	# 如果玩家已经有生成点，返回原来的位置
	if used_spawn_points.has(player_id):
		return used_spawn_points[player_id]
	
	# 获取所有未使用的生成点
	var available_points = []
	for point in spawn_points:
		if not point in used_spawn_points.values():
			available_points.append(point)
	
	# 如果没有可用点，随机选择一个（所有点都被占用的情况）
	if available_points.is_empty():
		print("SpawnManager: 警告 - 所有生成点都被占用，随机选择一个")
		var random_index = randi() % spawn_points.size()
		var selected_point = spawn_points[random_index]
		used_spawn_points[player_id] = selected_point
		return selected_point
	
	# 从可用点中随机选择一个
	var random_index = randi() % available_points.size()
	var selected_point = available_points[random_index]
	
	# 记录这个生成点已被使用
	used_spawn_points[player_id] = selected_point
	
	print("SpawnManager: 为玩家", player_id, "分配生成点:", selected_point)
	print("SpawnManager: 已使用生成点数量:", used_spawn_points.size(), "/", spawn_points.size())
	
	return selected_point

# 释放玩家的生成点（当玩家断开连接时调用）
func release_spawn_point(player_id: int):
	if used_spawn_points.has(player_id):
		var released_point = used_spawn_points[player_id]
		used_spawn_points.erase(player_id)
		print("SpawnManager: 释放玩家", player_id, "的生成点:", released_point)
		print("SpawnManager: 剩余已使用生成点数量:", used_spawn_points.size(), "/", spawn_points.size())

# 获取所有生成点信息（用于调试）
func get_spawn_info() -> Dictionary:
	return {
		"total_points": spawn_points.size(),
		"used_points": used_spawn_points.size(),
		"available_points": spawn_points.size() - used_spawn_points.size(),
		"spawn_points": spawn_points,
		"used_spawn_points": used_spawn_points
	}

# 重置所有生成点（用于测试或重新开始游戏）
func reset_all_spawn_points():
	used_spawn_points.clear()
	print("SpawnManager: 已重置所有生成点")
