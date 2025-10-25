extends Control

# UI节点引用
@onready var spell_name_label: Label = $MainPanel/SpellName
@onready var damage_spinbox: SpinBox = $MainPanel/Parameters/DamageContainer/DamageSpinBox
@onready var speed_spinbox: SpinBox = $MainPanel/Parameters/SpeedContainer/SpeedSpinBox
@onready var range_spinbox: SpinBox = $MainPanel/Parameters/RangeContainer/RangeSpinBox
@onready var cooldown_spinbox: SpinBox = $MainPanel/Parameters/CooldownContainer/CooldownSpinBox
@onready var key_option: OptionButton = $MainPanel/Parameters/KeyContainer/KeyOptionButton
@onready var save_button: Button = $MainPanel/Buttons/SaveButton
@onready var cancel_button: Button = $MainPanel/Buttons/CancelButton

# 特殊效果UI节点
@onready var slow_effect_container: HBoxContainer = $MainPanel/Parameters/SlowEffectContainer
@onready var slow_effect_spinbox: SpinBox = $MainPanel/Parameters/SlowEffectContainer/SlowEffectSpinBox
@onready var slow_duration_container: HBoxContainer = $MainPanel/Parameters/SlowDurationContainer
@onready var slow_duration_spinbox: SpinBox = $MainPanel/Parameters/SlowDurationContainer/SlowDurationSpinBox

# 当前编辑的法术
var current_spell: SpellData = null

# 按键选项
var key_options = [
	{"text": "Q键", "key": KEY_Q},
	{"text": "E键", "key": KEY_E},
	{"text": "鼠标左键", "key": MOUSE_BUTTON_LEFT},
	{"text": "鼠标右键", "key": MOUSE_BUTTON_RIGHT}
]

func _ready():
	# 连接按钮信号
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# 初始化按键选项
	initialize_key_options()
	
	# 设置输入处理
	set_process_input(true)

func _input(event):
	if not visible:
		return
	
	# ESC键关闭界面
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()

# 设置要编辑的法术
func set_spell_to_edit(spell: SpellData):
	current_spell = spell
	# 延迟加载数据，确保UI节点已准备好
	call_deferred("load_spell_data")

# 加载法术数据到UI
func load_spell_data():
	if not current_spell:
		return
	
	# 安全检查所有UI节点
	if not spell_name_label:
		print("SpellEditUI: 错误 - spell_name_label 为空")
		return
	
	# 设置法术名称
	spell_name_label.text = current_spell.spell_name
	
	# 设置参数值
	if damage_spinbox:
		damage_spinbox.value = current_spell.damage
	if speed_spinbox:
		speed_spinbox.value = current_spell.speed
	if range_spinbox:
		range_spinbox.value = current_spell.range
	if cooldown_spinbox:
		cooldown_spinbox.value = current_spell.cooldown_time
	
	# 设置按键选择
	if key_option:
		var key_index = find_key_index(current_spell.trigger_key)
		if key_index >= 0:
			key_option.selected = key_index
		else:
			key_option.selected = 0  # 默认选择第一个
	
	# 根据法术类型显示特定参数
	update_parameter_visibility()

# 初始化按键选项
func initialize_key_options():
	if not key_option:
		print("SpellEditUI: 错误 - key_option 为空")
		return
	
	key_option.clear()
	for option in key_options:
		key_option.add_item(option.text)

# 查找按键索引
func find_key_index(key: int) -> int:
	for i in range(key_options.size()):
		if key_options[i].key == key:
			return i
	return -1

# 更新参数可见性
func update_parameter_visibility():
	if not current_spell:
		return
	
	# 冰锥术显示减速参数
	if current_spell.spell_id == "ice_shard":
		slow_effect_container.visible = true
		slow_duration_container.visible = true
		if slow_effect_spinbox:
			slow_effect_spinbox.value = current_spell.slow_effect
		if slow_duration_spinbox:
			slow_duration_spinbox.value = current_spell.slow_duration
	else:
		slow_effect_container.visible = false
		slow_duration_container.visible = false

# 保存按钮处理
func _on_save_pressed():
	if not current_spell:
		print("SpellEditUI: 错误 - 没有要保存的法术")
		return
	
	# 安全检查UI节点
	if not damage_spinbox or not speed_spinbox or not range_spinbox or not cooldown_spinbox or not key_option:
		print("SpellEditUI: 错误 - UI节点未准备好")
		return
	
	# 更新法术数据
	current_spell.damage = int(damage_spinbox.value)
	current_spell.speed = speed_spinbox.value
	current_spell.range = range_spinbox.value
	current_spell.cooldown_time = cooldown_spinbox.value
	
	# 更新按键
	var selected_index = key_option.selected
	if selected_index >= 0 and selected_index < key_options.size():
		current_spell.trigger_key = key_options[selected_index].key
	
	# 更新特殊效果参数（仅对冰锥术）
	if current_spell.spell_id == "ice_shard":
		if slow_effect_spinbox:
			current_spell.slow_effect = slow_effect_spinbox.value
		if slow_duration_spinbox:
			current_spell.slow_duration = slow_duration_spinbox.value
	
	# 确保法术已解锁
	current_spell.is_unlocked = true
	
	print("SpellEditUI: 法术参数已保存 - ", current_spell.spell_name)
	print("SpellEditUI: 伤害: ", current_spell.damage)
	print("SpellEditUI: 速度: ", current_spell.speed)
	print("SpellEditUI: 射程: ", current_spell.range)
	print("SpellEditUI: 冷却: ", current_spell.cooldown_time)
	print("SpellEditUI: 按键: ", OS.get_keycode_string(current_spell.trigger_key))
	
	# 关闭界面
	close_ui()

# 取消按钮处理
func _on_cancel_pressed():
	print("SpellEditUI: 取消编辑")
	close_ui()

# 显示UI
func show_ui():
	visible = true
	# 暂停玩家输入
	pause_player_input()

# 关闭UI
func close_ui():
	# 恢复玩家输入
	resume_player_input()
	queue_free()

# 暂停玩家输入
func pause_player_input():
	var player = get_tree().current_scene.get_node_or_null("player")
	if not player:
		print("SpellEditUI: 警告 - 未找到玩家节点")
		return
	
	# 使用 set_input_enabled 方法
	if player.has_method("set_input_enabled"):
		player.set_input_enabled(false)
		print("SpellEditUI: 已暂停玩家输入 (set_input_enabled)")
	
	# 同时设置 meta 标志作为备份
	player.set_meta("input_paused", true)
	print("SpellEditUI: 已设置玩家输入暂停标志")

# 恢复玩家输入
func resume_player_input():
	var player = get_tree().current_scene.get_node_or_null("player")
	if not player:
		print("SpellEditUI: 警告 - 未找到玩家节点")
		return
	
	# 使用 set_input_enabled 方法
	if player.has_method("set_input_enabled"):
		player.set_input_enabled(true)
		print("SpellEditUI: 已恢复玩家输入 (set_input_enabled)")
	
	# 同时清除 meta 标志（确保完全恢复）
	if player.has_meta("input_paused"):
		player.remove_meta("input_paused")
		print("SpellEditUI: 已移除玩家输入暂停标志")
