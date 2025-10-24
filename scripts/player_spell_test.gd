extends Node

# 测试脚本：临时法术释放系统
# 功能：鼠标左键释放火球，参数从全局法术库读取

# 节点引用
var player_node: Node2D
var spell_caster: SpellCaster
var game_library: GameSpellLibrary

# 火球法术数据
var fireball_spell: SpellData

func _ready():
	print("PlayerSpellTest: 临时法术测试系统已启动")
	
	# 获取玩家节点
	find_player()
	
	# 初始化法术系统
	initialize_spell_system()

# 查找玩家节点
func find_player():
	player_node = get_tree().current_scene.get_node_or_null("player")
	if player_node:
		print("PlayerSpellTest: 找到玩家节点")
	else:
		print("PlayerSpellTest: 警告 - 未找到玩家节点")

# 初始化法术系统
func initialize_spell_system():
	# 等待一帧确保场景完全加载
	await get_tree().process_frame
	
	# 创建法术投射物管理器
	spell_caster = SpellCaster.new()
	get_tree().current_scene.add_child(spell_caster)
	
	# 等待一帧确保SpellCaster完全初始化
	await get_tree().process_frame
	
	# 获取全局法术库
	game_library = GameSpellLibrary.instance
	if game_library:
		# 获取火球法术数据
		fireball_spell = game_library.get_spell_library().get_spell_by_id("fire_ball")
		if fireball_spell:
			print("PlayerSpellTest: 成功获取火球法术数据")
			print("PlayerSpellTest: 火球属性 - ", fireball_spell.get_info_string())
			print("PlayerSpellTest: 火球ID - ", fireball_spell.spell_id)
		else:
			print("PlayerSpellTest: 错误 - 未找到火球法术数据")
	else:
		print("PlayerSpellTest: 错误 - 未找到全局法术库")
	
	# 测试场景加载
	test_scene_loading()

# 处理输入
func _input(event):
	# 检查鼠标左键点击
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cast_fireball_to_mouse()
	
	# 检查空格键测试
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			test_simple_fireball()

# 向鼠标位置释放火球
func cast_fireball_to_mouse():
	if not player_node or not fireball_spell or not spell_caster:
		print("PlayerSpellTest: 错误 - 缺少必要组件")
		return
	
	# 获取鼠标屏幕坐标
	var mouse_screen_pos = get_viewport().get_mouse_position()
	
	# 获取相机
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("PlayerSpellTest: 错误 - 未找到相机")
		return
	
	# 将屏幕坐标转换为世界坐标
	var mouse_world_pos = camera.to_global(mouse_screen_pos - get_viewport().get_visible_rect().size / 2)
	
	# 计算火球释放方向
	var direction_vector = mouse_world_pos - player_node.global_position
	var fireball_direction = direction_vector.normalized()
	
	# 火球直接在玩家位置生成
	var fireball_start_pos = player_node.global_position
	
	print("PlayerSpellTest: 释放火球")
	print("PlayerSpellTest: 玩家位置: ", player_node.global_position)
	print("PlayerSpellTest: 鼠标屏幕位置: ", mouse_screen_pos)
	print("PlayerSpellTest: 鼠标世界位置: ", mouse_world_pos)
	print("PlayerSpellTest: 方向向量: ", direction_vector)
	print("PlayerSpellTest: 火球方向: ", fireball_direction)
	print("PlayerSpellTest: 火球起始位置: ", fireball_start_pos)
	
	# 释放火球
	var projectile = spell_caster.cast_spell(fireball_spell, fireball_start_pos, fireball_direction)
	
	if projectile:
		print("PlayerSpellTest: 火球释放成功")
		# 连接投射物信号
		projectile.projectile_hit.connect(_on_projectile_hit)
		projectile.projectile_expired.connect(_on_projectile_expired)
	else:
		print("PlayerSpellTest: 火球释放失败")

# 投射物命中处理
func _on_projectile_hit(target: Node2D, damage: int):
	print("PlayerSpellTest: 火球命中目标 - ", target.name, " 造成伤害: ", damage)

# 投射物过期处理
func _on_projectile_expired(projectile: SpellProjectile):
	print("PlayerSpellTest: 火球已过期")

# 测试场景加载
func test_scene_loading():
	print("PlayerSpellTest: 开始测试场景加载...")
	
	# 直接测试场景加载
	var test_scene = preload("res://scence/spells/fireball_projectile.tscn")
	if test_scene:
		print("PlayerSpellTest: 场景加载成功")
		
		# 尝试实例化
		var test_instance = test_scene.instantiate()
		if test_instance:
			print("PlayerSpellTest: 场景实例化成功")
			test_instance.queue_free()
		else:
			print("PlayerSpellTest: 场景实例化失败")
	else:
		print("PlayerSpellTest: 场景加载失败")

# 简单测试火球（向右发射）
func test_simple_fireball():
	if not player_node or not fireball_spell or not spell_caster:
		print("PlayerSpellTest: 错误 - 缺少必要组件")
		return
	
	print("PlayerSpellTest: 简单测试火球（向右发射）")
	
	# 简单的向右方向
	var simple_direction = Vector2.RIGHT
	var simple_start_pos = player_node.global_position
	
	print("PlayerSpellTest: 简单测试 - 起始位置: ", simple_start_pos)
	print("PlayerSpellTest: 简单测试 - 方向: ", simple_direction)
	
	# 释放火球
	var projectile = spell_caster.cast_spell(fireball_spell, simple_start_pos, simple_direction)
	
	if projectile:
		print("PlayerSpellTest: 简单测试火球释放成功")
		# 连接投射物信号
		projectile.projectile_hit.connect(_on_projectile_hit)
		projectile.projectile_expired.connect(_on_projectile_expired)
	else:
		print("PlayerSpellTest: 简单测试火球释放失败")

# 获取测试信息
func get_test_info() -> String:
	var info = "=== 临时法术测试系统 ===\n"
	info += "玩家节点: " + (player_node.name if player_node else "未找到") + "\n"
	info += "法术投射物管理器: " + ("已创建" if spell_caster else "未创建") + "\n"
	info += "全局法术库: " + ("已连接" if game_library else "未连接") + "\n"
	
	if fireball_spell:
		info += "火球法术: " + fireball_spell.spell_name + "\n"
		info += "火球属性:\n" + fireball_spell.get_info_string()
	else:
		info += "火球法术: 未找到\n"
	
	if spell_caster:
		info += "\n活跃投射物数量: " + str(spell_caster.get_active_projectile_count())
	
	info += "\n操作说明: 鼠标左键释放火球"
	return info
