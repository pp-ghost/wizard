class_name SpellLibrary
extends Resource

# 所有可用法术
@export var all_spells: Array[SpellData] = []

func _init():
	initialize_spells()

# 初始化所有法术
func initialize_spells():
	# 创建火球术
	create_fire_ball()
	# 创建冰锥术
	create_ice_shard()
	
	print("SpellLibrary: 法术库已初始化，共有 ", all_spells.size(), " 个法术")

# 创建火球术
func create_fire_ball():
	var fire_ball = SpellData.new()
	fire_ball.spell_id = "fire_ball"
	fire_ball.spell_name = "火球术"
	fire_ball.spell_icon = load("res://asset/magic/fire_ball_icon.png")
	fire_ball.cooldown_time = 1.5
	fire_ball.damage = 25
	fire_ball.speed = 300.0
	fire_ball.range = 200.0
	fire_ball.is_unlocked = true
	
	all_spells.append(fire_ball)


# 创建冰锥术
func create_ice_shard():
	var ice_shard = SpellData.new()
	ice_shard.spell_id = "ice_shard"
	ice_shard.spell_name = "冰锥术"
	ice_shard.spell_icon = load("res://asset/magic/ice_icon.png")
	ice_shard.cooldown_time = 1.2
	ice_shard.damage = 20
	ice_shard.speed = 250.0
	ice_shard.range = 150.0
	ice_shard.is_unlocked = true
	
	all_spells.append(ice_shard)

# 获取法术
func get_spell_by_id(spell_id: String) -> SpellData:
	for spell in all_spells:
		if spell.spell_id == spell_id:
			return spell
	return null

# 获取所有可用法术
func get_available_spells() -> Array[SpellData]:
	return all_spells.duplicate()


# 为未来自定义功能预留的接口
func add_custom_spell(spell: SpellData):
	all_spells.append(spell)

func remove_custom_spell(spell_id: String):
	var spell = get_spell_by_id(spell_id)
	if spell:
		all_spells.erase(spell)
