extends Control
## Script da cena principal. Os caminhos abaixo (get_node) esperam a árvore de
## nodes descrita no PORTING_GUIDE.md — ajuste os caminhos se organizar diferente.

@onready var coin_label: Label = %CoinLabel
@onready var gem_label: Label = %GemLabel
@onready var heat_bar: ProgressBar = %HeatBar
@onready var heat_label: Label = %HeatLabel

@onready var oven_button: Button = %OvenButton
@onready var oven_progress: ProgressBar = %OvenProgress

@onready var prestige_panel: Control = %PrestigePanel
@onready var prestige_label: Label = %PrestigeLabel
@onready var prestige_button: Button = %PrestigeButton

@onready var oven_speed_button: Button = %OvenSpeedButton
@onready var income_button: Button = %IncomeButton
@onready var spawn_boost_button: Button = %SpawnBoostButton
@onready var watch_ad_button: Button = %WatchAdButton
@onready var no_ads_button: Button = %NoAdsButton

@onready var offline_modal: Control = %OfflineModal
@onready var offline_away_label: Label = %OfflineAwayLabel
@onready var offline_earned_label: Label = %OfflineEarnedLabel
@onready var offline_double_button: Button = %OfflineDoubleButton
@onready var offline_collect_button: Button = %OfflineCollectButton

@onready var win_modal: Control = %WinModal
@onready var win_fireworks: CPUParticles2D = %WinFireworks
@onready var restart_button: Button = %RestartButton

@onready var pause_button: Button = %PauseButton
@onready var pause_modal: Control = %PauseModal
@onready var sound_toggle: CheckButton = %SoundToggle
@onready var language_button: OptionButton = %LanguageButton

@onready var account_status_label: Label = %AccountStatusLabel
@onready var sign_in_apple_button: Button = %SignInAppleButton
@onready var sign_in_google_button: Button = %SignInGoogleButton
@onready var sign_out_button: Button = %SignOutButton
@onready var delete_account_button: Button = %DeleteAccountButton
@onready var delete_account_confirm_dialog: ConfirmationDialog = %DeleteAccountConfirmDialog
@onready var visit_store_button: Button = %VisitStoreButton
@onready var reset_progress_button: Button = %ResetProgressButton
@onready var resume_button: Button = %ResumeButton
@onready var reset_confirm_dialog: ConfirmationDialog = %ResetConfirmDialog

var _pending_offline_coins: float = 0.0
var _offline_doubled: bool = false


func _ready() -> void:
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.gems_changed.connect(_on_gems_changed)
	GameState.board_changed.connect(_refresh_oven_and_heat)
	GameState.offline_earnings_ready.connect(_show_offline_modal)
	GameState.game_won.connect(_show_win_modal)

	oven_button.pressed.connect(_on_oven_pressed)
	oven_speed_button.pressed.connect(_on_oven_speed_pressed)
	income_button.pressed.connect(_on_income_pressed)
	spawn_boost_button.pressed.connect(_on_spawn_boost_pressed)
	watch_ad_button.pressed.connect(_on_watch_ad_pressed)
	no_ads_button.pressed.connect(_on_no_ads_pressed)

	offline_double_button.pressed.connect(_on_offline_double)
	offline_collect_button.pressed.connect(_on_offline_collect)
	restart_button.pressed.connect(_on_restart)

	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	visit_store_button.pressed.connect(_on_visit_store_pressed)
	reset_progress_button.pressed.connect(_on_reset_progress_pressed)
	reset_confirm_dialog.confirmed.connect(_on_reset_confirmed)
	sound_toggle.toggled.connect(_on_sound_toggled)
	sound_toggle.button_pressed = GameState.sound_enabled

	_setup_language_button()

	sign_in_apple_button.pressed.connect(_on_sign_in_apple_pressed)
	sign_in_google_button.pressed.connect(_on_sign_in_google_pressed)
	sign_out_button.pressed.connect(_on_sign_out_pressed)
	delete_account_button.pressed.connect(_on_delete_account_pressed)
	delete_account_confirm_dialog.confirmed.connect(_on_delete_account_confirmed)
	_refresh_account_ui()

	if prestige_button:
		prestige_button.pressed.connect(_on_prestige_pressed)

	offline_modal.visible = false
	win_modal.visible = false
	pause_modal.visible = false

	_on_coins_changed(GameState.coins)
	_on_gems_changed(GameState.gems)
	_refresh_shop()
	_refresh_oven_and_heat()

	# _process daqui só serve pra atualizar barras/labels que dependem do tempo
	# (o tick real do jogo mora inteiramente em GameState._process).
	set_process(true)


func _process(_delta: float) -> void:
	_refresh_oven_and_heat()
	_refresh_prestige()
	_refresh_shop_dynamic_labels()
	_refresh_account_ui()


# ---------------- Header ----------------

func _on_coins_changed(v: float) -> void:
	coin_label.text = "🪙 %s" % _fmt(v)

func _on_gems_changed(v: int) -> void:
	gem_label.text = "💎 %d" % v

func _fmt(n: float) -> String:
	if n >= 1_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1000:
		return "%.1fk" % (n / 1000.0)
	return str(int(n))


# ---------------- Forno / calor de produção ----------------

func _on_oven_pressed() -> void:
	if GameState.is_board_full():
		return
	GameState.spawn_base()
	GameState.oven_timer_ms = max(0.0, GameState.oven_timer_ms - GameState.oven_interval_ms * 0.4)

func _on_oven_speed_pressed() -> void:
	GameState.buy_oven_speed()
	_refresh_shop()

func _on_income_pressed() -> void:
	GameState.buy_income_upgrade()
	_refresh_shop()

func _on_spawn_boost_pressed() -> void:
	GameState.buy_spawn_boost()
	_refresh_shop()

func _on_watch_ad_pressed() -> void:
	GameState.watch_ad_for_income_boost()
	_refresh_shop()

func _on_no_ads_pressed() -> void:
	GameState.buy_no_ads()
	_refresh_shop()

func _on_prestige_pressed() -> void:
	GameState.do_prestige()

func _refresh_oven_and_heat() -> void:
	var full := GameState.is_board_full()
	oven_button.disabled = full
	oven_button.text = tr("🍫 Tabuleiro cheio") if full else tr("🍫 Produzir Cacau")

	var boosted := Time.get_ticks_msec() < GameState.spawn_boost_until_ms
	var effective_interval: float = GameState.oven_interval_ms / 2.0 if boosted else GameState.oven_interval_ms
	oven_progress.value = clamp((GameState.oven_timer_ms / effective_interval) * 100.0, 0.0, 100.0)

	var rate := GameState.total_income()
	heat_label.text = "+%s/s" % _fmt(rate)
	heat_bar.value = clamp(8.0 + rate * 2.2, 0.0, 100.0)


# ---------------- Prestígio ----------------

func _refresh_prestige() -> void:
	var threshold := GameState.prestige_threshold()
	var panel_visible := GameState.prestige_count > 0 or GameState.lifetime_coins >= threshold * 0.5
	prestige_panel.visible = panel_visible
	if not panel_visible:
		return
	var gain := 0.15 + GameState.prestige_count * 0.05
	var can := GameState.can_prestige()
	prestige_label.text = (
		tr("Resete e ganhe +%.2fx de renda permanente. %s")
		% [gain, (tr("Disponível agora!") if can else tr("Precisa de %s moedas (%s/%s)") % [_fmt(threshold), _fmt(GameState.lifetime_coins), _fmt(threshold)])]
	)
	prestige_button.disabled = not can
	prestige_button.text = tr("Renascer (x%.2f)") % (GameState.prestige_mult + gain)


# ---------------- Loja ----------------

func _refresh_shop() -> void:
	oven_speed_button.text = "🪙 %d" % GameState.oven_speed_cost()
	oven_speed_button.disabled = GameState.coins < GameState.oven_speed_cost()

	income_button.text = "🪙 %d" % GameState.income_cost()
	income_button.disabled = GameState.coins < GameState.income_cost()

	spawn_boost_button.disabled = GameState.gems < 8

	no_ads_button.disabled = GameState.no_ads

func _refresh_shop_dynamic_labels() -> void:
	var boosted := Time.get_ticks_msec() < GameState.spawn_boost_until_ms
	if boosted:
		var secs := int(ceil((GameState.spawn_boost_until_ms - Time.get_ticks_msec()) / 1000.0))
		spawn_boost_button.text = tr("Ativo (%ds)") % secs
	else:
		spawn_boost_button.text = "💎 8"

	var ad_on_cooldown := Time.get_ticks_msec() < GameState.ad_cooldown_until_ms
	watch_ad_button.disabled = ad_on_cooldown or GameState.no_ads
	watch_ad_button.text = tr("Ativo (sem anúncios)") if GameState.no_ads else (tr("Aguarde…") if ad_on_cooldown else tr("Assistir"))


# ---------------- Renda offline ----------------

func _show_offline_modal(seconds_away: float, coins_earned: float) -> void:
	_pending_offline_coins = coins_earned
	_offline_doubled = false
	var h := int(seconds_away / 3600)
	var m := int((int(seconds_away) % 3600) / 60)
	offline_away_label.text = (
		tr("Sua chocolateria trabalhou sozinha por %dh %dmin") % [h, m] if h > 0
		else tr("Sua chocolateria trabalhou sozinha por %d minutos") % m
	)
	offline_earned_label.text = "🪙 %s" % _fmt(_pending_offline_coins)
	offline_double_button.disabled = false
	offline_double_button.text = tr("🎬 Assistir anúncio: dobrar (demo)")
	offline_modal.visible = true

func _on_offline_double() -> void:
	if _offline_doubled:
		return
	_offline_doubled = true
	_pending_offline_coins *= 2.0
	offline_earned_label.text = "🪙 %s" % _fmt(_pending_offline_coins)
	offline_double_button.disabled = true
	offline_double_button.text = tr("✓ Renda dobrada")

func _on_offline_collect() -> void:
	GameState.collect_offline_earnings(_pending_offline_coins)
	_pending_offline_coins = 0.0
	offline_modal.visible = false


# ---------------- Vitória (5 vitrines) + fogos de artifício ----------------

func _show_win_modal() -> void:
	win_modal.visible = true
	win_fireworks.restart()
	win_fireworks.emitting = true

func _on_restart() -> void:
	win_modal.visible = false
	GameState.hard_reset()


# ---------------- Pausa + menu ----------------

func _on_pause_pressed() -> void:
	get_tree().paused = true
	pause_modal.visible = true

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_modal.visible = false

func _on_visit_store_pressed() -> void:
	OS.shell_open("https://therechocolates.com.br/")

func _on_reset_progress_pressed() -> void:
	reset_confirm_dialog.popup_centered()

func _on_reset_confirmed() -> void:
	GameState.hard_reset()
	get_tree().paused = false
	pause_modal.visible = false

func _on_sound_toggled(pressed: bool) -> void:
	GameState.sound_enabled = pressed
	GameState.save_game()


# ---------------- Conta (login com Apple/Google) ----------------
# Usa get_node_or_null("/root/AuthManager") em vez de referenciar o
# identificador "AuthManager" direto — assim o jogo continua rodando
# normalmente mesmo antes do plugin de login estar instalado (veja
# AUTH_GUIDE.md). Depois que vocês registrarem o AuthManager de verdade
# como autoload, esses botões passam a funcionar sem precisar mexer em
# mais nada aqui.

func _get_auth_manager() -> Node:
	return get_node_or_null("/root/AuthManager")

func _on_sign_in_apple_pressed() -> void:
	var am := _get_auth_manager()
	if am and am.has_method("sign_in_with_apple"):
		am.sign_in_with_apple()
	else:
		account_status_label.text = "Login ainda não configurado neste build (veja AUTH_GUIDE.md)"

func _on_sign_in_google_pressed() -> void:
	var am := _get_auth_manager()
	if am and am.has_method("sign_in_with_google"):
		am.sign_in_with_google()
	else:
		account_status_label.text = "Login ainda não configurado neste build (veja AUTH_GUIDE.md)"

func _on_sign_out_pressed() -> void:
	var am := _get_auth_manager()
	if am and am.has_method("sign_out"):
		am.sign_out()

func _on_delete_account_pressed() -> void:
	delete_account_confirm_dialog.popup_centered()

func _on_delete_account_confirmed() -> void:
	var am := _get_auth_manager()
	if am and am.has_method("delete_account"):
		am.delete_account()

## Mostra "Entrar" enquanto não há conta, ou o nome + "Sair"/"Excluir
## conta" depois que a pessoa loga de verdade. Sem o AuthManager instalado,
## fica sempre no estado "convidado" — nunca quebra, só fica inativo.
func _refresh_account_ui() -> void:
	var am := _get_auth_manager()
	var signed_in: bool = am != null and am.get("is_signed_in") == true

	sign_in_apple_button.visible = not signed_in
	sign_in_google_button.visible = not signed_in
	sign_out_button.visible = signed_in
	delete_account_button.visible = signed_in

	if signed_in:
		var display_name: String = str(am.get("current_display_name"))
		account_status_label.text = (
			"Conectado como %s" % display_name if display_name != ""
			else "Conta conectada"
		)
	elif am == null:
		account_status_label.text = "Jogando como convidado"


# ---------------- Idioma ----------------

## code = código de locale do Godot, label = como aparece no seletor
## (escrito no próprio idioma, pra ser reconhecível mesmo sem entender
## o idioma atual — é assim que a maioria dos apps faz).
const LANGUAGES := [
	["", "🌐 Automático"],
	["pt_BR", "Português (BR)"],
	["en", "English"],
	["es", "Español"],
	["fr", "Français"],
	["de", "Deutsch"],
	["it", "Italiano"],
	["nl", "Nederlands"],
]

func _setup_language_button() -> void:
	language_button.clear()
	var current_index := 0
	for i in range(LANGUAGES.size()):
		var entry: Array = LANGUAGES[i]
		language_button.add_item(entry[1])
		if entry[0] == GameState.locale:
			current_index = i
	language_button.selected = current_index
	language_button.item_selected.connect(_on_language_selected)

func _on_language_selected(index: int) -> void:
	var code: String = LANGUAGES[index][0]
	GameState.locale = code
	if code == "":
		TranslationServer.set_locale(OS.get_locale())
	else:
		TranslationServer.set_locale(code)
	GameState.save_game()
	# Textos estáticos (definidos na cena) se retraduzem sozinhos ao trocar
	# o locale. Os que são montados na hora (loja, forno, prestígio) já se
	# atualizam no próximo _process(), então não precisa forçar nada aqui.
