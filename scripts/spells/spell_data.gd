class_name SpellData
extends Resource

# 法术基本信息
@export var spell_id: String
@export var spell_name: String
@export var spell_icon: Texture2D

# 法术属性
@export var cooldown_time: float = 1.0
@export var damage: int = 20
@export var speed: float = 200.0
@export var range: float = 100.0
@export var is_unlocked: bool = true



# 构造函数
func _init():
	pass

# 检查是否可以施放
func can_cast() -> bool:
	return is_unlocked

# 获取法术信息字符串
func get_info_string() -> String:
	var info = "名称: " + spell_name + "\n"
	info += "冷却时间: " + str(cooldown_time) + "秒\n"
	info += "伤害: " + str(damage) + "\n"
	info += "速度: " + str(speed) + "\n"
	info += "射程: " + str(range) + "\n"
	return info
