class_name GameSpellLibrary
extends Node

# 单例模式
static var instance: GameSpellLibrary

# 法术库和玩家装备
var spell_library: SpellLibrary
var player_loadout: PlayerSpellLoadout

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
	player_loadout = PlayerSpellLoadout.new()
	print("GameSpellLibrary: 全局法术库已初始化")

# 获取法术库
func get_spell_library() -> SpellLibrary:
	return spell_library

# 获取玩家装备
func get_player_loadout() -> PlayerSpellLoadout:
	return player_loadout

# 获取可用法术
func get_available_spells() -> Array[SpellData]:
	return spell_library.get_available_spells()

# 装备法术
func equip_spell(spell: SpellData) -> bool:
	var success = player_loadout.equip_spell(spell)
	if success:
		spell_equipped.emit(spell)
		spell_loadout_changed.emit()
	return success

# 卸下法术
func unequip_spell(spell: SpellData) -> bool:
	var success = player_loadout.unequip_spell(spell)
	if success:
		spell_unequipped.emit(spell)
		spell_loadout_changed.emit()
	return success

# 获取装备的法术
func get_equipped_spells() -> Array[SpellData]:
	return player_loadout.get_equipped_spells()

# 为未来自定义功能预留的接口
func add_custom_spell(spell: SpellData):
	spell_library.add_custom_spell(spell)

func remove_custom_spell(spell_id: String):
	spell_library.remove_custom_spell(spell_id)

func get_custom_spells() -> Array[SpellData]:
	# 这里可以返回玩家自定义的法术
	return []
