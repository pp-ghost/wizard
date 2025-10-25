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
var sync_interval: float = 1.0 / 20.0  # 20 FPS同步

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

# 同步位置
func sync_position(new_position: Vector2):
	position = new_position

# 同步动画
func sync_animation(animation_name: String):
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

# 同步法术施放
func sync_spell_cast(spell_data: Dictionary):
	if net_spell_caster:
		net_spell_caster.cast_spell(spell_data)

# 获取玩家数据
func get_player_data() -> Dictionary:
	return player_data
