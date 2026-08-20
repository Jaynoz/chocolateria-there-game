extends HBoxContainer
## Anexe a um HBoxContainer. Monta as 5 miniaturas da Vitrine do Supermercado
## e anima a revelação (preto e branco -> colorido) usando assets/shaders/reveal.gdshader.

const THUMB_SIZE := Vector2(52, 52)
const REVEAL_SHADER := preload("res://assets/shaders/reveal.gdshader")
const VITRINE_TEXTURE := "res://assets/items/caixa_supermercado.png"

var _thumbs: Array[TextureRect] = []
var _materials: Array[ShaderMaterial] = []

func _ready() -> void:
	for i in range(GameState.VITRINE_GOAL):
		var thumb := TextureRect.new()
		thumb.texture = ItemData.get_cached_texture(VITRINE_TEXTURE)
		thumb.custom_minimum_size = THUMB_SIZE
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

		var mat := ShaderMaterial.new()
		mat.shader = REVEAL_SHADER
		mat.set_shader_parameter("progress", 0.0)
		thumb.material = mat

		add_child(thumb)
		_thumbs.append(thumb)
		_materials.append(mat)

	GameState.vitrine_progress_changed.connect(_refresh)
	GameState.vitrine_completed.connect(_on_vitrine_completed)
	_refresh()


func _refresh() -> void:
	for i in range(GameState.VITRINE_GOAL):
		var target_progress := 0.0
		if i < GameState.vitrines_completed:
			target_progress = 1.0
		elif i == GameState.vitrines_completed:
			target_progress = float(GameState.super_count) / float(GameState.SUPER_TARGET)
		_materials[i].set_shader_parameter("progress", target_progress)


func _on_vitrine_completed(vitrine_index: int) -> void:
	# Pisca a miniatura que acabou de ficar 100% colorida.
	var i := vitrine_index - 1
	if i < 0 or i >= _thumbs.size():
		return
	var thumb := _thumbs[i]
	var tw := create_tween()
	tw.tween_property(thumb, "scale", Vector2(1.15, 1.15), 0.15)
	tw.tween_property(thumb, "scale", Vector2.ONE, 0.2)
