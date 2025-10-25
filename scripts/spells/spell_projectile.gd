class_name SpellProjectile
extends Area2D

# 投射物属性
@export var speed: float = 300.0
@export var damage: int = 20
@export var range: float = 200.0
@export var lifetime: float = 3.0

# 投射物状态
var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var is_hitting: bool = false  # 是否正在播放hit动画
var is_flying_left: bool = false  # 是否向左飞行

# 调试开关
@export var debug_show_collision: bool = false  # 是否显示碰撞箱

# 节点引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_right: CollisionShape2D = $CollisionShape_right
@onready var collision_left: CollisionShape2D = $CollisionShape_left

# 信号
signal projectile_hit(target: Node2D, damage: int)
signal projectile_expired()

func _ready():
	# 连接区域进入信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# 设置碰撞层
	collision_layer = 2  # 投射物层
	collision_mask = 1   # 检测玩家和环境层
	
	# 启用碰撞箱可视化
	if debug_show_collision:
		enable_collision_debug()
	
	print("SpellProjectile: 投射物已创建，方向: ", direction)

func _physics_process(delta):
	if is_hitting:
		return
	
	# 计算移动距离
	var movement = direction * speed * delta
	distance_traveled += movement.length()
	
	# 移动投射物
	position += movement
	
	# 检查射程限制
	if distance_traveled >= range:
		expire_projectile("射程限制")
		return
	
	# 检查生命周期
	lifetime -= delta
	if lifetime <= 0:
		expire_projectile("生命周期结束")

# 设置投射物属性
func setup_projectile(spell_data: SpellData, start_pos: Vector2, target_direction: Vector2):
	speed = spell_data.speed
	damage = spell_data.damage
	range = spell_data.range
	direction = target_direction.normalized()
	
	# 设置火球位置
	position = start_pos
	
	# 判断是否向左飞行
	var angle = direction.angle()
	var angle_deg = rad_to_deg(angle)
	is_flying_left = (angle_deg > 90 and angle_deg <= 180) or (angle_deg < -90 and angle_deg >= -180)
	
	# 更新碰撞箱配置
	update_rotation()
	
	print("SpellProjectile: 投射物设置完成 - ", spell_data.spell_name)
	print("SpellProjectile: 设置后的方向: ", direction)
	print("SpellProjectile: 设置后的位置: ", position)
	print("SpellProjectile: 设置后的旋转角度: ", rad_to_deg(rotation), "度")
	
	# 播放生成动画
	play_spawn_animation()

# 碰撞处理
func _on_body_entered(body: Node2D):
	if is_hitting:
		return
	
	# 忽略玩家
	if body.name == "player":
		return
	
	# 忽略其他投射物
	if body is SpellProjectile:
		return
	
	print("SpellProjectile: 碰撞到物体 - ", body.name)
	
	# 播放命中动画
	play_hit_animation()
	
	# 发射命中信号
	projectile_hit.emit(body, damage)
	
	# 等待命中动画播放完成
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		await sprite.animation_finished
		print("SpellProjectile: 命中动画播放完成，准备销毁")
		print("SpellProjectile: 当前状态 - is_hitting:", is_hitting)
		# 动画播放完成后立即销毁
		expire_projectile("碰撞命中")
	else:
		# 如果没有动画节点，直接销毁
		print("SpellProjectile: 没有动画节点，直接销毁")
		expire_projectile("碰撞命中")

func _on_area_entered(area: Area2D):
	if is_hitting:
		return
	
	# 忽略自己的区域
	if area == self:
		return
	
	print("SpellProjectile: 碰撞到区域 - ", area.name)
	
	# 播放命中动画
	play_hit_animation()
	
	# 发射命中信号
	projectile_hit.emit(area, damage)
	
	# 等待命中动画播放完成
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		await sprite.animation_finished
		print("SpellProjectile: 命中动画播放完成，准备销毁")
		print("SpellProjectile: 当前状态 - is_hitting:", is_hitting)
		# 动画播放完成后立即销毁
		expire_projectile("区域碰撞")
	else:
		# 如果没有动画节点，直接销毁
		print("SpellProjectile: 没有动画节点，直接销毁")
		expire_projectile("区域碰撞")

# 销毁投射物
func expire_projectile(reason: String):
	print("SpellProjectile: 投射物销毁 - ", reason)
	
	# 确保状态正确
	is_hitting = false
	
	# 发射过期信号
	projectile_expired.emit()
	
	# 立即销毁
	queue_free()

# 播放生成动画
func play_spawn_animation():
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		var anim_name = "spawn_left" if is_flying_left else "spawn_right"
		print("SpellProjectile: 开始播放", anim_name, "动画")
		sprite.play(anim_name)
		# 等待spawn动画播放完成
		await sprite.animation_finished
		print("SpellProjectile: spawn动画播放完成")
		# 开始播放飞行动画
		play_fly_animation()
	else:
		print("SpellProjectile: 错误 - 未找到AnimatedSprite2D节点")

# 播放飞行动画
func play_fly_animation():
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		var anim_name = "fly_left" if is_flying_left else "fly_right"
		sprite.play(anim_name)
		print("SpellProjectile: 开始播放", anim_name, "动画")
	else:
		print("SpellProjectile: 错误 - 未找到AnimatedSprite2D节点")

# 播放命中动画
func play_hit_animation():
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		var anim_name = "hit_left" if is_flying_left else "hit_right"
		sprite.play(anim_name)
		print("SpellProjectile: 播放", anim_name, "动画")
		# 停止移动和所有物理处理
		is_hitting = true
		# 不隐藏投射物，让hit动画完整播放
	else:
		print("SpellProjectile: 错误 - 未找到AnimatedSprite2D节点")

# 更新旋转角度和碰撞箱
func update_rotation():
	# 根据方向向量计算旋转角度
	var angle = direction.angle()
	
	# 如果向左飞行，需要额外旋转180度来修正动画方向
	if is_flying_left:
		rotation = angle + PI  # 向左飞时额外旋转180度
	else:
		rotation = angle  # 向右飞时直接使用角度
	
	# 根据飞行方向启用对应的碰撞箱
	if is_flying_left:
		# 向左飞行 - 启用左碰撞箱，禁用右碰撞箱
		if collision_left:
			collision_left.disabled = false
		if collision_right:
			collision_right.disabled = true
		print("SpellProjectile: 向左飞行 - 使用左碰撞箱，旋转角度: ", rad_to_deg(rotation), "度")
	else:
		# 向右飞行 - 启用右碰撞箱，禁用左碰撞箱
		if collision_right:
			collision_right.disabled = false
		if collision_left:
			collision_left.disabled = true
		print("SpellProjectile: 向右飞行 - 使用右碰撞箱，旋转角度: ", rad_to_deg(rotation), "度")
	
	print("SpellProjectile: 碰撞箱和旋转设置完成")

# 启用碰撞箱调试可视化
func enable_collision_debug():
	# 标记需要重绘
	set_process(true)
	print("SpellProjectile: 碰撞箱可视化已启用")

# 自定义绘制函数
func _draw():
	if not debug_show_collision:
		return
	
	# 选择当前激活的碰撞箱
	var collision = collision_right if not is_flying_left else collision_left
	if not collision or not collision.shape or collision.disabled:
		return
	
	var shape = collision.shape
	var col_pos = collision.position
	var col_rot = collision.rotation
	var col_scale = collision.scale
	
	# 绘制不同类型的碰撞形状
	if shape is CircleShape2D:
		# 绘制圆形
		var radius = shape.radius * col_scale.x
		draw_circle(col_pos, radius, Color(1, 0, 0, 0.3))
		draw_arc(col_pos, radius, 0, TAU, 32, Color(1, 0, 0, 1), 2.0)
		
	elif shape is CapsuleShape2D:
		# 绘制胶囊形
		var radius = shape.radius
		var height = shape.height
		
		# 应用变换
		var transform = Transform2D()
		transform = transform.translated(col_pos)
		transform = transform.rotated(col_rot)
		transform = transform.scaled(col_scale)
		
		# 绘制胶囊的两个圆形端点
		var half_height = height / 2.0 - radius
		var top = Vector2(0, -half_height)
		var bottom = Vector2(0, half_height)
		
		# 变换顶部和底部位置
		top = transform * top
		bottom = transform * bottom
		
		# 绘制两个圆
		draw_circle(top, radius * abs(col_scale.x), Color(1, 0, 0, 0.3))
		draw_circle(bottom, radius * abs(col_scale.x), Color(1, 0, 0, 0.3))
		
		# 绘制连接线
		var perpendicular = Vector2(-radius, 0).rotated(col_rot) * col_scale.x
		draw_line(top + perpendicular, bottom + perpendicular, Color(1, 0, 0, 1), 2.0)
		draw_line(top - perpendicular, bottom - perpendicular, Color(1, 0, 0, 1), 2.0)
		
	elif shape is RectangleShape2D:
		# 绘制矩形
		var size = shape.size * col_scale
		var rect = Rect2(-size / 2, size)
		draw_rect(rect.translated(col_pos), Color(1, 0, 0, 0.3))
		draw_rect(rect.translated(col_pos), Color(1, 0, 0, 1), false, 2.0)

# 更新绘制
func _process(delta):
	if debug_show_collision:
		queue_redraw()  # 每帧重绘以跟随碰撞箱变化

# 获取投射物信息
func get_projectile_info() -> String:
	return "投射物信息:\n速度: " + str(speed) + "\n伤害: " + str(damage) + "\n射程: " + str(range) + "\n已飞行距离: " + str(distance_traveled)
