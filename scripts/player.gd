extends CharacterBody2D

# 玩家移动速度
@export var speed: float = 150.0
# 翻滚速度
@export var roll_speed: float = 300.0

# 获取动画节点
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 翻滚状态
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 0.5  # 翻滚持续时间
var roll_cooldown: float = 0.0
var roll_cooldown_duration: float = 2.0  # 翻滚冷却时间

# 输入控制
var input_enabled: bool = true

func _ready():
	# 设置玩家初始位置为 (150, 150)
	position = Vector2(150, 150)
	# 设置初始动画为idle
	animated_sprite.play("idle")

func _physics_process(delta):
	# 检查输入是否被暂停
	if not input_enabled or has_meta("input_paused"):
		# 输入被暂停，只处理动画和物理
		if is_rolling:
			roll_timer -= delta
			if roll_timer <= 0:
				is_rolling = false
				roll_cooldown = roll_cooldown_duration
				animated_sprite.play("idle")
		
		# 停止移动
		velocity = Vector2.ZERO
		if not is_rolling:
			animated_sprite.play("idle")
		
		move_and_slide()
		return
	
	# 处理翻滚状态
	if is_rolling:
		roll_timer -= delta
		if roll_timer <= 0:
			is_rolling = false
			roll_cooldown = roll_cooldown_duration  # 开始冷却
			animated_sprite.play("idle")
	
	# 处理冷却时间
	if roll_cooldown > 0:
		roll_cooldown -= delta
	
	# 检查shift输入
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SHIFT):
		if not is_rolling and roll_cooldown <= 0:
			start_roll()
	
	# 获取输入
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	
	# 标准化输入向量，防止对角线移动过快
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		
		# 根据水平移动方向翻转精灵
		if input_vector.x > 0:
			animated_sprite.flip_h = false  # 向右移动，不翻转
		elif input_vector.x < 0:
			animated_sprite.flip_h = true   # 向左移动，翻转
		
		# 播放动画
		if is_rolling:
			animated_sprite.play("roll")
		else:
			animated_sprite.play("move")
	else:
		# 播放待机动画
		if not is_rolling:
			animated_sprite.play("idle")
	
	# 设置速度
	var current_speed = roll_speed if is_rolling else speed
	velocity = input_vector * current_speed
	
	# 移动并处理碰撞 - 墙体会自动阻挡玩家
	move_and_slide()

# 开始翻滚
func start_roll():
	is_rolling = true
	roll_timer = roll_duration
	animated_sprite.play("roll")

# 设置输入状态
func set_input_enabled(enabled: bool):
	input_enabled = enabled
	print("Player: 输入状态设置为 ", "启用" if enabled else "禁用")
