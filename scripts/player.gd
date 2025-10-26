extends CharacterBody2D

# 玩家移动速度
@export var speed: float = 150.0
# 翻滚速度
@export var roll_speed: float = 300.0

# 获取动画节点
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 法术系统节点引用
@onready var spell_caster: SpellCaster = $SpellCaster
# 使用全局单例，不需要 @onready
var game_library: SpellLibraryManager = GameSpellLibrary

# 翻滚状态
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 0.5  # 翻滚持续时间
var roll_cooldown: float = 0.0
var roll_cooldown_duration: float = 2.0  # 翻滚冷却时间

# 输入控制
var input_enabled: bool = true

# 面向方向 (1 = 右, -1 = 左)
var facing_direction: int = 1

# 施法相关
var available_spells: Array[SpellData] = []  # 可用法术列表
var spell_cooldowns: Dictionary = {}  # 法术冷却时间记录
var spell_input_states: Dictionary = {}  # 法术按键状态记录
var is_attacking: bool = false  # 是否正在攻击

func _ready():
	print("Player: ===== 玩家初始化 =====")
	print("Player: 初始化时的玩家ID:", multiplayer.get_unique_id())
	print("Player: 网络状态:", multiplayer.has_multiplayer_peer())
	print("Player: 是否为服务器:", multiplayer.is_server())
	
	# 使用随机生成系统设置玩家位置
	set_spawn_position()
	# 设置初始动画为idle
	animated_sprite.play("idle")
	
	# 初始化法术系统
	call_deferred("_initialize_spell_system")

func _initialize_spell_system():
	# 等待一帧，确保所有节点都已初始化
	await get_tree().process_frame
	
	# 获取法术库
	if not game_library:
		game_library = GameSpellLibrary
	
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
	
	# 处理按键按下
	if event is InputEventKey and event.pressed:
		var spell = game_library.get_spell_by_key(event.keycode)
		if spell:
			# 检查是否在翻滚期间
			if is_rolling:
				print("Player: 翻滚期间无法施法 - ", spell.spell_name)
				return
			
			# 只有在法术可用时才记录按键状态和施法
			if can_cast_spell(spell):
				spell_input_states[spell.spell_id] = true
				cast_spell_to_mouse(spell)
			else:
				# 法术不可用时，不记录按键状态
				print("Player: 法术不可用 - ", spell.spell_name)
	
	# 处理按键释放
	if event is InputEventKey and not event.pressed:
		var spell = game_library.get_spell_by_key(event.keycode)
		if spell and spell_input_states.has(spell.spell_id) and spell_input_states[spell.spell_id]:
			spell_input_states[spell.spell_id] = false
			start_spell_cooldown(spell)
	
	# 处理鼠标按键按下
	if event is InputEventMouseButton and event.pressed:
		var spell = game_library.get_spell_by_key(event.button_index)
		if spell:
			# 检查是否在翻滚期间
			if is_rolling:
				print("Player: 翻滚期间无法施法 - ", spell.spell_name)
				return
			
			# 只有在法术可用时才记录按键状态和施法
			if can_cast_spell(spell):
				spell_input_states[spell.spell_id] = true
				cast_spell_to_mouse(spell)
			else:
				# 法术不可用时，不记录按键状态
				print("Player: 法术不可用 - ", spell.spell_name)
	
	# 处理鼠标按键释放
	if event is InputEventMouseButton and not event.pressed:
		var spell = game_library.get_spell_by_key(event.button_index)
		if spell and spell_input_states.has(spell.spell_id) and spell_input_states[spell.spell_id]:
			spell_input_states[spell.spell_id] = false
			start_spell_cooldown(spell)

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
	
	# 设置攻击状态并播放攻击动画
	is_attacking = true
	animated_sprite.play("attack")
	
	# 等待攻击动画播放到第4帧
	await get_tree().create_timer(0.05).timeout  # 假设每帧0.1秒，第4帧是0.4秒
	
	# 在第4帧生成法术
	var projectile = spell_caster.cast_spell(spell, global_position, spell_direction)
	
	# 继续等待动画完成
	await animated_sprite.animation_finished
	is_attacking = false
	
	if projectile:
		print("Player: 法术施放成功")
	else:
		print("Player: 法术施放失败")

# 设置玩家生成位置
func set_spawn_position():
	var player_id = multiplayer.get_unique_id()
	
	# 获取生成点管理器
	var spawn_manager = get_node_or_null("../SpawnManager")
	if spawn_manager:
		var spawn_position = spawn_manager.get_available_spawn_point(player_id)
		position = spawn_position
		print("Player: 玩家", player_id, "生成在位置:", spawn_position)
	else:
		# 如果没有找到生成点管理器，使用默认位置
		position = Vector2(150, 150)
		print("Player: 警告 - 未找到生成点管理器，使用默认位置:", position)

# 检查法术是否可以施放（冷却时间检查）
func can_cast_spell(spell: SpellData) -> bool:
	if not spell:
		return false
	
	# 检查法术是否解锁
	if not spell.is_unlocked:
		print("Player: 法术未解锁 - ", spell.spell_name)
		return false
	
	# 检查冷却时间
	if spell_cooldowns.has(spell.spell_id) and spell_cooldowns[spell.spell_id] > 0:
		print("Player: 法术冷却中 - ", spell.spell_name, " 剩余时间: ", spell_cooldowns[spell.spell_id])
		return false
	
	return true

# 开始法术冷却
func start_spell_cooldown(spell: SpellData):
	if not spell:
		return
	
	# 设置冷却时间
	spell_cooldowns[spell.spell_id] = spell.cooldown_time
	print("Player: 开始法术冷却 - ", spell.spell_name, " 冷却时间: ", spell.cooldown_time, "秒")

# 更新法术冷却时间
func _process(delta):
	# 更新所有法术的冷却时间
	for spell_id in spell_cooldowns.keys():
		if spell_cooldowns[spell_id] > 0:
			spell_cooldowns[spell_id] -= delta
			if spell_cooldowns[spell_id] <= 0:
				spell_cooldowns[spell_id] = 0
				print("Player: 法术冷却完成 - ", spell_id)

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
		
		# 根据水平移动方向翻转精灵和更新面向方向
		if input_vector.x > 0:
			animated_sprite.flip_h = false  # 向右移动，不翻转
			facing_direction = 1
		elif input_vector.x < 0:
			animated_sprite.flip_h = true   # 向左移动，翻转
			facing_direction = -1
		
		# 播放动画（攻击时不被覆盖）
		if is_attacking:
			# 攻击动画正在播放，不覆盖
			pass
		elif is_rolling:
			animated_sprite.play("roll")
		else:
			animated_sprite.play("move")
	else:
		# 播放待机动画（攻击时不被覆盖）
		if is_attacking:
			# 攻击动画正在播放，不覆盖
			pass
		elif not is_rolling:
			animated_sprite.play("idle")
	
	# 设置速度
	var current_speed = roll_speed if is_rolling else speed
	velocity = input_vector * current_speed
	
	# 移动并处理碰撞 - 墙体会自动阻挡玩家
	move_and_slide()
	
	# 事件驱动网络同步
	send_movement_event()
	
	# 发送动画事件
	send_animation_event(animated_sprite.animation)

# 开始翻滚
func start_roll():
	is_rolling = true
	roll_timer = roll_duration
	animated_sprite.play("roll")

# 设置输入状态
func set_input_enabled(enabled: bool):
	input_enabled = enabled
	print("Player: 输入状态设置为 ", "启用" if enabled else "禁用")

# 事件驱动网络同步
var last_position: Vector2 = Vector2.ZERO
var last_animation: String = ""
var last_facing_direction: int = 1
var position_threshold: float = 2.5  # 位置变化阈值

# 发送玩家移动事件
func send_movement_event():
	if not is_network_connected():
		return
	
	var current_position = position
	var position_changed = current_position.distance_to(last_position) > position_threshold
	
	if position_changed:
		var current_player_id = multiplayer.get_unique_id()
		var event_data = {
			"event_type": "movement",
			"player_id": current_player_id,
			"position": current_position,
			"velocity": velocity,
			"timestamp": Time.get_unix_time_from_system()
		}
		
		# 发送移动事件到服务器
		var network_manager = get_node_or_null("../NetworkManager")
		if network_manager:
			network_manager.rpc("receive_player_event", event_data)
		
		last_position = current_position

# 发送动画变化事件
func send_animation_event(animation_name: String):
	if not is_network_connected():
		return
	
	# 简化逻辑：每次都发送动画事件，不检查是否变化
	var event_data = {
		"event_type": "animation",
		"player_id": multiplayer.get_unique_id(),
		"animation": animation_name,
		"facing_direction": facing_direction,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# 发送动画事件（调试输出已关闭）
	var network_manager = get_node_or_null("../NetworkManager")
	if network_manager:
		network_manager.rpc("receive_player_event", event_data)

# 发送状态变化事件
func send_state_event(state_type: String, state_value: bool):
	if not is_network_connected():
		return
	
	var event_data = {
		"event_type": "state",
		"player_id": multiplayer.get_unique_id(),
		"state_type": state_type,
		"state_value": state_value,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	print("Player: 发送状态事件 - 类型:", state_type, " 值:", state_value)
	var network_manager = get_node_or_null("../NetworkManager")
	if network_manager:
		network_manager.rpc("receive_player_event", event_data)

# 发送法术施放事件
func send_spell_event(spell_data: Dictionary):
	if not is_network_connected():
		return
	
	var event_data = {
		"event_type": "spell",
		"player_id": multiplayer.get_unique_id(),
		"spell_data": spell_data,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	print("Player: 发送法术事件 - 法术:", spell_data)
	var network_manager = get_node_or_null("../NetworkManager")
	if network_manager:
		network_manager.rpc("receive_player_event", event_data)

# 检查网络连接状态
func is_network_connected() -> bool:
	return multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer != null

# 播放动画并发送网络事件
func play_animation(animation_name: String):
	animated_sprite.play(animation_name)
	send_animation_event(animation_name)

# 简单的动画播放函数（不发送网络事件）
func play_animation_local(animation_name: String):
	animated_sprite.play(animation_name)

# 测试RPC函数 - 用于验证RPC通信
@rpc("any_peer", "unreliable")
func test_simple_rpc(message: String):
	print("Player: ===== 收到测试RPC =====")
	print("Player: 消息:", message)
	print("Player: 发送者ID:", multiplayer.get_remote_sender_id())
	print("Player: ===== 测试RPC完成 =====")
