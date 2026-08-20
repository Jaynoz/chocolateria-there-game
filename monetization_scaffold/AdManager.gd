extends Node
## SCAFFOLD — não está registrado como autoload ainda.
##
## Isso é um ponto de partida pra quando você instalar o plugin AdMob da
## Poing Studios (veja MONETIZATION_GUIDE.md). As classes MobileAds,
## RewardedAd, RewardedAdLoadCallback etc. só existem DEPOIS de instalar
## o plugin pelo AssetLib — enquanto ele não estiver instalado, este
## arquivo vai dar erro de "classe não encontrada" se for registrado como
## autoload. Por isso ele mora fora de scripts/autoload/ por enquanto.
##
## Depois de instalar o plugin:
##   1. mova este arquivo pra res://scripts/autoload/AdManager.gd
##   2. registre como autoload "AdManager" (depois de GameState)
##   3. confirme os nomes exatos das classes/métodos na doc do plugin —
##      a API pode ter mudado desde que este scaffold foi escrito
##
## Troque os IDs de unidade de anúncio de teste abaixo pelos seus reais
## do AdMob antes de publicar (os de teste só funcionam em builds de
## depuração / dispositivos de teste).

const TEST_REWARDED_AD_UNIT_ANDROID := "ca-app-pub-3940256099942544/5224354917"

var _rewarded_ad = null
var _ad_load_callback = null
var _pending_reward_type := "" # "offline_double" | "spawn_boost"

signal rewarded_ad_ready(ready: bool)
signal rewarded_ad_failed(reason: String)


func _ready() -> void:
	# _ad_load_callback = RewardedAdLoadCallback.new()
	# _ad_load_callback.on_ad_failed_to_load = func(err):
	# 	_rewarded_ad = null
	# 	rewarded_ad_failed.emit(err.message)
	# _ad_load_callback.on_ad_loaded = func(ad):
	# 	_rewarded_ad = ad
	# 	rewarded_ad_ready.emit(true)
	#
	# MobileAds.initialize(func(status): _load_rewarded_ad())
	pass


func _load_rewarded_ad() -> void:
	# var unit_id := TEST_REWARDED_AD_UNIT_ANDROID # troque pelo real antes de publicar
	# RewardedAdLoader.new().load(unit_id, AdRequest.new(), _ad_load_callback)
	pass


## Chame isso pelo botão "Assistir anúncio: dobrar renda offline" da UI.
## SÓ chama GameState quando o anúncio de fato terminar (on_user_earned_reward).
func show_rewarded_income_double(pending_offline_coins: float) -> void:
	_pending_reward_type = "offline_double"
	_show_current_ad()


## Chame isso pelo botão do "Assistente (cacau rápido, 30s)" se vocês
## decidirem trocar esse upgrade de "custa gemas" pra "assiste anúncio".
func show_rewarded_spawn_boost() -> void:
	_pending_reward_type = "spawn_boost"
	_show_current_ad()


func _show_current_ad() -> void:
	# if _rewarded_ad == null:
	# 	rewarded_ad_failed.emit("Anúncio ainda não carregou")
	# 	return
	#
	# var full_screen_callback = FullScreenContentCallback.new()
	# full_screen_callback.on_ad_dismissed_full_screen_content = func():
	# 	_rewarded_ad = null
	# 	_load_rewarded_ad() # já deixa o próximo carregando
	#
	# _rewarded_ad.full_screen_content_callback = full_screen_callback
	# _rewarded_ad.show(func(reward_item):
	# 	_on_reward_earned(reward_item)
	# )
	pass


func _on_reward_earned(_reward_item) -> void:
	match _pending_reward_type:
		"offline_double":
			# Chamado só agora, depois do anúncio de verdade ter sido assistido.
			pass # a UI (Main.gd) trata a duplicação; aqui só confirma que valeu.
		"spawn_boost":
			GameState.spawn_boost_until_ms = Time.get_ticks_msec() + 30_000
	_pending_reward_type = ""
