extends Node
## Autoload singleton: dados estáticos da cadeia de produção.
## Registre como "ItemData" em Project > Project Settings > Autoload.

# Cada item: key (usado pra montar o caminho da textura), nome de exibição,
# e brand_label opcional (selo que aparece nos itens de marca/caixa final).
const ITEMS := [
	{"key": "cacau",             "name": "Cacau"},
	{"key": "cacau_torrado",     "name": "Cacau Torrado"},
	{"key": "pasta_cacau",       "name": "Pasta de Cacau"},
	{"key": "bombom",            "name": "Bombom"},
	{"key": "barra",             "name": "Barra de Chocolate"},
	{"key": "tablete_premium",   "name": "Tablete Premium"},
	{"key": "caixa_bombom",      "name": "Caixa de Bombom"},
	{"key": "caixa_there",       "name": "Caixa There",             "brand_label": "THERE"},
	{"key": "palete",            "name": "Palete de Distribuição"},
	{"key": "caixa_supermercado","name": "Caixa para Supermercados","brand_label": "SUPERMERCADO"},
]

## Total de estágios da cadeia. Fixo em 10 porque ITEMS.size() é uma chamada
## de método, e o GDScript exige que toda `const` seja uma expressão
## constante em tempo de compilação (não pode chamar métodos, mesmo em
## arrays const). Se adicionar/remover itens de ITEMS, atualize esse número.
const MAX_LEVEL := 10

## Nível é 1-indexado (nível 1 = Cacau) pra bater com o protótipo original.
static func get_item(level: int) -> Dictionary:
	return ITEMS[level - 1]

static func get_texture_path(level: int) -> String:
	return "res://assets/items/%s.png" % ITEMS[level - 1]["key"]

static func get_brand_label(level: int) -> String:
	return ITEMS[level - 1].get("brand_label", "")

## Renda por segundo de um item nesse nível (mesma fórmula do protótipo web).
static func item_income(level: int) -> float:
	return round(pow(level, 1.6) * 1.5 * 10.0) / 10.0


# ================= Cache de texturas =================
# Evita chamar load() toda vez que o tabuleiro redesenha (o que acontece a
# cada fusão, cada spawn, cada frame com o assistente ativo). Sem isso, o
# jogo re-decodifica o PNG do disco repetidamente — ok num desktop potente,
# mas gera engasgos perceptíveis em celular (e é exatamente o tipo de coisa
# que a revisão da App Store nota como app "não responsivo"). Com o cache,
# cada imagem só é carregada uma vez, na primeira vez que é pedida.

var _texture_cache: Dictionary = {}

## Use isto em vez de load(caminho) direto em qualquer script de UI.
func get_cached_texture(path: String) -> Texture2D:
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]

## Atalho pros itens da cadeia especificamente.
func get_item_texture(level: int) -> Texture2D:
	return get_cached_texture(get_texture_path(level))

## Chamado uma vez no início pra deixar tudo pré-carregado antes do primeiro
## desenho do tabuleiro (evita até o pequeno engasgo do "primeiro load").
func preload_all_textures() -> void:
	for level in range(1, MAX_LEVEL + 1):
		get_item_texture(level)
	get_cached_texture("res://assets/golden/caixa_dourada.png")
	get_cached_texture("res://assets/effects/efeito_normal.png")
	get_cached_texture("res://assets/effects/efeito_fornada.png")
	get_cached_texture("res://assets/effects/efeito_lote.png")
	get_cached_texture("res://assets/items/caixa_supermercado.png") # reaproveitada na vitrine


func _ready() -> void:
	preload_all_textures()
