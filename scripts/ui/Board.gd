extends GridContainer
## Anexe este script a um GridContainer com columns = 5.
## Ele monta as 25 células sozinho — não precisa criar nada a mão no editor
## além do próprio GridContainer (e configurar seu tamanho/tema).

const CELL_SIZE := Vector2(64, 64)

var _cell_buttons: Array[TextureButton] = []
var _level_labels: Array[Label] = []
var _brand_labels: Array[Label] = []

func _ready() -> void:
	columns = 5
	for i in range(GameState.BOARD_SIZE):
		var btn := TextureButton.new()
		btn.custom_minimum_size = CELL_SIZE
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.pressed.connect(_on_cell_pressed.bind(i))

		var level_label := Label.new()
		level_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		level_label.add_theme_font_size_override("font_size", 10)
		btn.add_child(level_label)

		var brand_label := Label.new()
		brand_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		brand_label.add_theme_font_size_override("font_size", 8)
		brand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		brand_label.visible = false
		btn.add_child(brand_label)

		add_child(btn)
		_cell_buttons.append(btn)
		_level_labels.append(level_label)
		_brand_labels.append(brand_label)

	GameState.board_changed.connect(_refresh)
	GameState.item_merged.connect(_on_item_merged)
	GameState.item_shipped.connect(_on_item_shipped)
	GameState.golden_collected.connect(_on_golden_collected)
	_refresh()


func _on_cell_pressed(idx: int) -> void:
	GameState.on_cell_tapped(idx)


func _refresh() -> void:
	for i in range(GameState.BOARD_SIZE):
		var cell = GameState.board[i]
		var btn := _cell_buttons[i]
		var level_label := _level_labels[i]
		var brand_label := _brand_labels[i]

		if cell is Dictionary:
			var level: int = cell["level"]
			btn.texture_normal = ItemData.get_item_texture(level)
			level_label.text = tr("Nv%d") % level
			var brand := ItemData.get_brand_label(level)
			brand_label.text = brand
			brand_label.visible = brand != ""
		elif cell is String and cell == "golden":
			btn.texture_normal = ItemData.get_cached_texture("res://assets/golden/caixa_dourada.png")
			level_label.text = ""
			brand_label.visible = false
		else:
			btn.texture_normal = null
			level_label.text = ""
			brand_label.visible = false

		# destaca a célula selecionada (ajuste a cor/estilo como preferir)
		btn.modulate = Color(1.3, 1.15, 0.7) if i == GameState.selected_index else Color.WHITE


func _on_item_merged(cell_index: int, tag: String) -> void:
	var btn := _cell_buttons[cell_index]
	# Troque isso por uma animação de verdade (AnimationPlayer/Tween) —
	# aqui é só um "pulinho" simples pra ter feedback imediato.
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(1.25, 1.25), 0.1)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.15)

	if tag == "jump":
		_flash_effect(cell_index, "res://assets/effects/efeito_lote.png")
	elif tag == "bonus":
		_flash_effect(cell_index, "res://assets/effects/efeito_fornada.png")
	else:
		_flash_effect(cell_index, "res://assets/effects/efeito_normal.png")


func _on_item_shipped(cell_index: int, bonus: float) -> void:
	# O item saiu pra entrega — dá pra tocar um "caminhãozinho" saindo aqui.
	pass


func _on_golden_collected(cell_index: int) -> void:
	pass


func _flash_effect(cell_index: int, texture_path: String) -> void:
	var fx := TextureRect.new()
	fx.texture = ItemData.get_cached_texture(texture_path)
	fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cell_buttons[cell_index].add_child(fx)

	var tw := create_tween()
	tw.tween_property(fx, "scale", Vector2(1.4, 1.4), 0.7).from(Vector2(0.3, 0.3))
	tw.parallel().tween_property(fx, "modulate:a", 0.0, 0.7).from(1.0)
	tw.tween_callback(fx.queue_free)
