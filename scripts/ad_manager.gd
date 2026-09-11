extends Node

# AdManager: Central controller for Google AdMob mobile ads & Remove Ads Paywall
# STRICT POLICY:
# - ZERO ads during gameplay or hops. The game is never interrupted mid-action.
# - ONLY triggered on the Game Over screen after the run is finished.
# - Frequency capped (e.g. only every 3-4 game overs, never spamming).
# - Bypassed 100% permanently if player buys 'Stop Ads (.99)'.

# Live Production AdMob IDs
const LIVE_APP_ID: String = "ca-app-pub-3382349314599719~5296716751"
const LIVE_INTERSTITIAL_ID: String = "ca-app-pub-3382349314599719/4608119910"
const LIVE_APP_OPEN_ID: String = "ca-app-pub-3382349314599719/5468303262"

# Google Official Test Ad IDs (Guaranteed 100% fill rate during development / while under review)
const TEST_INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"
const TEST_APP_OPEN_ID: String = "ca-app-pub-3940256099942544/9257395921"

# Set to false for live production revenue (automatically starts showing once Google approves)
@export var use_test_ads: bool = false

var deaths_since_last_ad: int = 0
const DEATHS_BETWEEN_ADS: int = 3 # Only show an ad every 3 game overs
var has_shown_app_open_ad: bool = false
var is_sdk_initialized: bool = false

var app_open_ad: AppOpenAd = null
var app_open_loader: AppOpenAdLoader = null
var is_loading_app_open: bool = false

var interstitial_ad: InterstitialAd = null
var interstitial_loader: InterstitialAdLoader = null
var is_loading_interstitial: bool = false

func _ready() -> void:
	GameState.ads_status_changed.connect(_on_ads_status_changed)
	app_open_loader = AppOpenAdLoader.new()
	interstitial_loader = InterstitialAdLoader.new()
	
	_initialize_admob()

func get_interstitial_id() -> String:
	return TEST_INTERSTITIAL_ID if use_test_ads else LIVE_INTERSTITIAL_ID

func get_app_open_id() -> String:
	return TEST_APP_OPEN_ID if use_test_ads else LIVE_APP_OPEN_ID

func _initialize_admob() -> void:
	var on_init_listener := OnInitializationCompleteListener.new()
	on_init_listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		is_sdk_initialized = true
		print("[AdManager] Google Mobile Ads SDK initialized successfully!")
		load_app_open_ad()
		load_interstitial()
		
	var request_config := RequestConfiguration.new()
	MobileAds.set_request_configuration(request_config)
	MobileAds.initialize(on_init_listener)

func load_app_open_ad() -> void:
	if GameState.ads_removed or is_loading_app_open or app_open_ad != null:
		return
	is_loading_app_open = true
	var callback := AppOpenAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: AppOpenAd) -> void:
		is_loading_app_open = false
		app_open_ad = ad
		print("[AdManager] App Open Ad loaded successfully.")
		_setup_app_open_callbacks()
		if not has_shown_app_open_ad and not GameState.ads_removed:
			show_app_open_ad()
			
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		is_loading_app_open = false
		print("[AdManager] App Open Ad failed to load (code %d): %s" % [error.code, error.message])
		
	app_open_loader.load(get_app_open_id(), AdRequest.new(), callback)

func _setup_app_open_callbacks() -> void:
	if not app_open_ad:
		return
	var callbacks := FullScreenContentCallback.new()
	callbacks.on_ad_dismissed_full_screen_content = func() -> void:
		print("[AdManager] App Open Ad dismissed.")
		if app_open_ad:
			app_open_ad.destroy()
			app_open_ad = null
	callbacks.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
		print("[AdManager] App Open Ad failed to show: ", err.message)
		if app_open_ad:
			app_open_ad.destroy()
			app_open_ad = null
	app_open_ad.full_screen_content_callback = callbacks

func show_app_open_ad() -> void:
	if GameState.ads_removed or has_shown_app_open_ad:
		return
	if app_open_ad:
		has_shown_app_open_ad = true
		print("[AdManager] Showing App Open Ad...")
		app_open_ad.show()
	else:
		load_app_open_ad()

func load_interstitial() -> void:
	if GameState.ads_removed or is_loading_interstitial or interstitial_ad != null:
		return
	is_loading_interstitial = true
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		is_loading_interstitial = false
		interstitial_ad = ad
		print("[AdManager] Interstitial Ad loaded and ready.")
		_setup_interstitial_callbacks()
		
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		is_loading_interstitial = false
		print("[AdManager] Interstitial failed to load (code %d): %s" % [error.code, error.message])
		
	interstitial_loader.load(get_interstitial_id(), AdRequest.new(), callback)

func _setup_interstitial_callbacks() -> void:
	if not interstitial_ad:
		return
	var callbacks := FullScreenContentCallback.new()
	callbacks.on_ad_dismissed_full_screen_content = func() -> void:
		print("[AdManager] Interstitial dismissed by user.")
		if interstitial_ad:
			interstitial_ad.destroy()
			interstitial_ad = null
		load_interstitial()
	callbacks.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
		print("[AdManager] Interstitial failed to show: ", err.message)
		if interstitial_ad:
			interstitial_ad.destroy()
			interstitial_ad = null
		load_interstitial()
	interstitial_ad.full_screen_content_callback = callbacks

func on_game_over() -> void:
	if GameState.ads_removed:
		return
	deaths_since_last_ad += 1
	if deaths_since_last_ad >= DEATHS_BETWEEN_ADS:
		show_interstitial()
		deaths_since_last_ad = 0

func show_interstitial() -> void:
	if GameState.ads_removed:
		return
	if interstitial_ad:
		print("[AdManager] Showing Interstitial Ad on Game Over...")
		interstitial_ad.show()
	else:
		load_interstitial()

func _on_ads_status_changed(has_removed: bool) -> void:
	if has_removed:
		print("[AdManager] 'Stop Ads (.99)' purchased! All ads permanently disabled.")
		if interstitial_ad:
			interstitial_ad.destroy()
			interstitial_ad = null
		if app_open_ad:
			app_open_ad.destroy()
			app_open_ad = null
