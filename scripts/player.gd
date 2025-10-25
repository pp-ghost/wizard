extends CharacterBody2D

# 玩家移动速度
@export var speed: float = 150.0
# 翻滚速度
@export var roll_speed: float = 300.0

# 获取动画节点
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 法术系统节点引用
@onready var spell_caster: SpellCaster = $SpellCaster
@onready var game_library: GameSpellLibrary = $GameSpellLibrary

# 翻滚状态
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 0.5  # 翻滚持续时间
var roll_cooldown: float = 0.0
var roll_cooldown_duration: float = 2.0  # 翻滚冷却时间

# 输入控制
var input_enabled: bool = true

# 施法相关
var available_spells: Array[SpellData] = []  # 可用法术列表

func _ready():
	# 设置玩家初始位置为 (150, 150)
	position = Vector2(150, 150)
	# 设置初始动画为idle
	animated_sprite.play("idle")
	
	# 初始化法术系统
	call_deferred("_initialize_spell_system")

func _initialize_spell_system():
	# 等待一帧，确保所有节点都已初始化
	await get_tree().process_frame
	
	# 获取法术库
	if not game_library:
		game_library = get_node_or_null("GameSpellLibrary")
	
	if not spell_caster:
		spell_caster = get_node_or_null("SpellCaster")
	
	# 加载可用法术并自动解锁
	if game_library:
		available_spells = game_library.get_available_spells()
		print("Player: 加载了 ", available_spells.size(), " 个可用法术")
		for spell in available_spells:
			# 自动解锁所有法术
			spell.is_unlocked = true
			print("Player: 法术 - ", spell.spell_name, " 按键: ", OS.get_keycode_string(spell.trigger_key), " (已解锁)")
	else:
		print("Player: 警告 - 未找到法术库")
	
	if spell_caster:
		print("Player: 法术施放系统已就绪")
	else:
		print("Player: 警告 - 未找到法术施放器")

# 处理输入（施法）
func _input(event):
	# 检查输入是否被暂停
	if not input_enabled or has_meta("input_paused"):
		return
	
	# 按键施法
	if event is InputEventKey and event.pressed:
		var spell = game_library.get_spell_by_key(event.keycode)
		if spell:
			cast_spell_to_mouse(spell)
	
	# 鼠标按键施法
	if event is InputEventMouseButton and event.pressed:
		var spell = game_library.get_spell_by_key(event.button_index)
		if spell:
			cast_spell_to_mouse(spell)

# 向鼠标位置施法
func cast_spell_to_mouse(spell: SpellData):
	if not spell or not spell_caster:
		print("Player: 无法施法 - 缺少法术或施法器")
		return
	
	# 获取鼠标屏幕坐标
	var mouse_screen_pos = get_viewport().get_mouse_position()
	
	# 获取相机
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("Player: 错误 - 未找到相机")
		return
	
	# 将屏幕坐标转换为世界坐标
	var mouse_world_pos = camera.to_global(mouse_screen_pos - get_viewport().get_visible_rect().size / 2)
	
	# 计算施法方向
	var direction_vector = mouse_world_pos - global_position
	var spell_direction = direction_vector.normalized()
	
	# 施法
	print("Player: 施放 ", spell.spell_name)
	var projectile = spell_caster.cast_spell(spell, global_position, spell_direction)
	
	if projectile:
		print("Player: 法术施放成功")
	else:
		print("Player: 法术施放失败")

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
