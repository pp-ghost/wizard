extends CharacterBody2D

# 网络玩家ID
var player_id: int = 0
# 玩家名称
var player_name: String = "Player"

# 获取动画节点
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var net_spell_caster: Node = $net_SpellCaster

# 玩家数据
var player_data: Dictionary = {
	"position": Vector2.ZERO,
	"velocity": Vector2.ZERO,
	"animation": "idle",
	"is_rolling": false,
	"is_attacking": false
}

# 网络同步
var sync_timer: float = 0.0
var sync_interval: float = 1.0 / 60.0  # 60 FPS同步

# 平滑移动相关
var target_position: Vector2 = Vector2.ZERO
var target_velocity: Vector2 = Vector2.ZERO
var move_speed: float = 5.0  # 移动插值速度
var is_moving: bool = false

# 动画状态同步
var target_animation: String = "idle"
var target_facing_direction: int = 1

func _ready():
	print("NetPlayer: 网络玩家已初始化 - ID:", player_id, " 名称:", player_name)
	# 设置初始动画
	animated_sprite.play("idle")

func _physics_process(delta):
	# 更新同步计时器
	sync_timer += delta
	
	# 定期同步数据
	if sync_timer >= sync_interval:
		sync_timer = 0.0
		update_player_data()
	
	# 始终更新动画状态（不管是否在移动）
	if animated_sprite.animation != target_animation:
		animated_sprite.play(target_animation)
	
	# 根据目标面向方向翻转精灵
	if target_facing_direction > 0:
		animated_sprite.flip_h = false
	elif target_facing_direction < 0:
		animated_sprite.flip_h = true
	
	# 平滑移动到目标位置
	if is_moving:
		# 计算移动方向
		var direction = (target_position - position).normalized()
		var distance = position.distance_to(target_position)
		
		# 根据距离调整移动速度
		var current_speed = move_speed
		if distance < 10.0:
			current_speed = move_speed * (distance / 10.0)
		
		# 设置速度进行物理移动
		velocity = direction * current_speed * 100.0  # 转换为像素/秒
		
		# 检查是否接近目标位置
		if distance < 2.0:
			position = target_position
			velocity = Vector2.ZERO
			is_moving = false
		
		# 使用物理移动
		move_and_slide()

# 设置玩家信息
func set_player_info(id: int, name: String):
	player_id = id
	player_name = name
	print("NetPlayer: 设置玩家信息 - ID:", id, " 名称:", name)

# 更新玩家数据
func update_player_data():
	player_data["position"] = position
	player_data["velocity"] = velocity
	player_data["animation"] = animated_sprite.animation
	player_data["is_rolling"] = false  # 网络玩家不处理翻滚
	player_data["is_attacking"] = false  # 网络玩家不处理攻击

# 同步位置（平滑移动）
func sync_position(new_position: Vector2):
	target_position = new_position
	is_moving = true
	print("NetPlayer: 设置目标位置 - ID:", player_id, " 目标:", target_position)

# 同步速度
func sync_velocity(new_velocity: Vector2):
	target_velocity = new_velocity
	print("NetPlayer: 设置目标速度 - ID:", player_id, " 速度:", target_velocity)

# 同步动画
func sync_animation(animation_name: String):
	target_animation = animation_name

# 同步面向方向
func sync_facing_direction(direction: int):
	target_facing_direction = direction
	# 设置面向方向

# 同步法术施放
func sync_spell_cast(spell_data: Dictionary):
	if net_spell_caster:
		net_spell_caster.cast_spell(spell_data)

# 获取玩家数据
func get_player_data() -> Dictionary:
	return player_data
