class_name SpellCaster
extends Node

# 投射物场景引用
var fireball_scene: PackedScene
var ice_shard_scene: PackedScene

# 投射物管理
var active_projectiles: Array[SpellProjectile] = []

# 信号
signal spell_cast(spell: SpellData, position: Vector2, direction: Vector2)
signal projectile_created(projectile: SpellProjectile)
signal projectile_destroyed(projectile: SpellProjectile)

func _ready():
	# 预加载投射物场景
	load_projectile_scenes()
	print("SpellCaster: 法术投射物管理器已初始化")

func _enter_tree():
	# 当节点进入场景树时加载场景
	load_projectile_scenes()
	print("SpellCaster: 节点已进入场景树，场景已加载")

# 确保场景加载的备用方法
func ensure_scenes_loaded():
	if not fireball_scene:
		load_projectile_scenes()

# 加载投射物场景
func load_projectile_scenes():
	fireball_scene = preload("res://scence/spells/fireball_projectile.tscn")
	ice_shard_scene = preload("res://scence/spells/ice_shard_projectile.tscn")
	
	if fireball_scene:
		print("SpellCaster: 火球场景加载成功")
	else:
		print("SpellCaster: 错误 - 火球场景加载失败")
	
	if ice_shard_scene:
		print("SpellCaster: 冰锥场景加载成功")
	else:
		print("SpellCaster: 错误 - 冰锥场景加载失败")
	
	print("SpellCaster: 投射物场景已加载")

# 释放法术
func cast_spell(spell_data: SpellData, caster_position: Vector2, target_direction: Vector2) -> SpellProjectile:
	if not spell_data:
		print("SpellCaster: 错误 - 法术数据为空")
		return null
	
	print("SpellCaster: 释放法术 - ", spell_data.spell_name)
	
	# 确保场景已加载
	ensure_scenes_loaded()
	
	# 根据法术类型创建对应的投射物
	var projectile_scene = get_projectile_scene(spell_data.spell_id)
	if not projectile_scene:
		print("SpellCaster: 错误 - 未找到法术投射物场景: ", spell_data.spell_id)
		return null
	
	# 创建投射物实例
	var projectile = projectile_scene.instantiate()
	if not projectile:
		print("SpellCaster: 错误 - 无法创建投射物实例")
		return null
	
	# 设置投射物属性
	projectile.setup_projectile(spell_data, caster_position, target_direction)
	
	# 连接信号
	projectile.projectile_hit.connect(_on_projectile_hit)
	projectile.projectile_expired.connect(_on_projectile_expired)
	
	# 添加到场景
	get_tree().current_scene.add_child(projectile)
	
	# 添加到活跃投射物列表
	active_projectiles.append(projectile)
	
	# 发射信号
	spell_cast.emit(spell_data, caster_position, target_direction)
	projectile_created.emit(projectile)
	
	print("SpellCaster: 投射物已创建并添加到场景")
	return projectile

# 获取投射物场景
func get_projectile_scene(spell_id: String) -> PackedScene:
	print("SpellCaster: 查找法术ID: ", spell_id)
	
	match spell_id:
		"fire_ball":
			print("SpellCaster: 找到火球法术，场景: ", fireball_scene)
			return fireball_scene
		"ice_shard":
			print("SpellCaster: 找到冰锥法术，场景: ", ice_shard_scene)
			return ice_shard_scene
		_:
			print("SpellCaster: 警告 - 未知法术ID: ", spell_id)
			return null

# 投射物命中处理
func _on_projectile_hit(target: Node2D, damage: int):
	print("SpellCaster: 投射物命中目标 - ", target.name, " 伤害: ", damage)
	
	# 这里可以添加伤害处理逻辑
	# 例如：减少目标生命值、播放命中效果等

# 投射物过期处理
func _on_projectile_expired(projectile: SpellProjectile):
	print("SpellCaster: 投射物已过期")
	
	# 从活跃列表中移除
	if projectile in active_projectiles:
		active_projectiles.erase(projectile)
	
	# 发射信号
	projectile_destroyed.emit(projectile)

# 清理所有投射物
func clear_all_projectiles():
	print("SpellCaster: 清理所有投射物")
	for projectile in active_projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	active_projectiles.clear()

# 获取活跃投射物数量
func get_active_projectile_count() -> int:
	return active_projectiles.size()

# 获取投射物信息
func get_projectile_info() -> String:
	var info = "活跃投射物数量: " + str(active_projectiles.size()) + "\n"
	for i in range(active_projectiles.size()):
		var projectile = active_projectiles[i]
		if is_instance_valid(projectile):
			info += "投射物 " + str(i + 1) + ": " + projectile.get_projectile_info() + "\n"
	return info
