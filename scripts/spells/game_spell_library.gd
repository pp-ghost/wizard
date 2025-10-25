class_name SpellLibraryManager
extends Node

# 单例模式
static var instance: SpellLibraryManager

# 法术库
var spell_library: SpellLibrary

# 信号定义
signal spell_equipped(spell: SpellData)
signal spell_unequipped(spell: SpellData)
signal spell_loadout_changed()

func _ready():
	if instance == null:
		instance = self
		initialize_library()
	else:
		queue_free()

# 初始化法术库
func initialize_library():
	spell_library = SpellLibrary.new()
	print("GameSpellLibrary: 全局法术库已初始化")

# 获取法术库
func get_spell_library() -> SpellLibrary:
	return spell_library

# 获取可用法术
func get_available_spells() -> Array[SpellData]:
	return spell_library.get_available_spells()

# 根据按键获取法术
func get_spell_by_key(key: int) -> SpellData:
	var available_spells = spell_library.get_available_spells()
	for spell in available_spells:
		if spell.trigger_key == key and spell.is_unlocked:
			return spell
	return null

# 为未来自定义功能预留的接口
func add_custom_spell(spell: SpellData):
	spell_library.add_custom_spell(spell)

func remove_custom_spell(spell_id: String):
	spell_library.remove_custom_spell(spell_id)

func get_custom_spells() -> Array[SpellData]:
	# 这里可以返回玩家自定义的法术
	return []
