extends Camera2D

# 相机跟随的目标（玩家）
var target: Node2D

func _ready():
	# 查找玩家节点
	target = get_node("../player")
	
	# 设置相机平滑跟随
	enabled = true
	# 可以调整这些参数来改变跟随效果
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0
	#放大
	zoom = Vector2(2.0, 2.0)  # 显示0.5倍大的区域（放大

func _process(delta):
	# 如果找到目标，让相机跟随目标位置
	if target:
		global_position = target.global_position
