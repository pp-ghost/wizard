extends CharacterBody2D

# 玩家移动速度
@export var speed: float = 200.0

# 获取动画节点
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# 设置玩家初始位置为 (64, 64)
	position = Vector2(64, 64)
	# 设置初始动画为idle
	animated_sprite.play("idle")

func _physics_process(delta):
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
		# 播放移动动画
		animated_sprite.play("move")
		
		# 根据水平移动方向翻转精灵
		if input_vector.x > 0:
			animated_sprite.flip_h = false  # 向右移动，不翻转
		elif input_vector.x < 0:
			animated_sprite.flip_h = true   # 向左移动，翻转
	else:
		# 播放待机动画
		animated_sprite.play("idle")
	
	# 设置速度
	velocity = input_vector * speed
	
	# 移动并处理碰撞
	move_and_slide()
