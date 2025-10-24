class_name PlayerSpellLoadout
extends Resource

# 装备的法术
@export var equipped_spells: Array[SpellData] = []
# 最大装备数量
@export var max_spells: int = 4

# 装备法术
func equip_spell(spell: SpellData) -> bool:
	if can_equip_spell(spell):
		equipped_spells.append(spell)
		print("PlayerSpellLoadout: 装备法术 - ", spell.spell_name)
		return true
	return false

# 卸下法术
func unequip_spell(spell: SpellData) -> bool:
	var index = equipped_spells.find(spell)
	if index != -1:
		equipped_spells.remove_at(index)
		print("PlayerSpellLoadout: 卸下法术 - ", spell.spell_name)
		return true
	return false

# 检查是否可以装备
func can_equip_spell(spell: SpellData) -> bool:
	return equipped_spells.size() < max_spells and not is_spell_equipped(spell)

# 检查法术是否已装备
func is_spell_equipped(spell: SpellData) -> bool:
	return spell in equipped_spells

# 获取装备的法术
func get_equipped_spells() -> Array[SpellData]:
	return equipped_spells.duplicate()

# 清空装备
func clear_equipped():
	equipped_spells.clear()
	print("PlayerSpellLoadout: 清空所有装备法术")

# 为未来自定义功能预留的接口
func set_max_spells(new_max: int):
	max_spells = new_max

func get_available_slots() -> int:
	return max_spells - equipped_spells.size()
