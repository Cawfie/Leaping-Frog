extends Node

# AdManager: Central controller for Google AdMob mobile ads & Remove Ads Paywall
# STRICT POLICY:
# - ZERO ads during gameplay or hops. The game is never interrupted mid-action.
# - ONLY triggered on the Game Over screen after the run is finished.
# - Frequency capped (e.g. only every 3-4 game overs, never spamming).
# - Bypassed 100% permanently if player buys 'Stop Ads ($1.99)'.

var admob_app_id: String = "ca-app-pub-3382349314599719~5296716751"
var interstitial_ad_id: String = "ca-app-pub-3382349314599719/4608119910"
var app_open_ad_id: String = "ca-app-pub-3382349314599719/5468303262"

var deaths_since_last_ad: int = 0
const DEATHS_BETWEEN_ADS: int = 3 # Only show an ad every 3 game overs
var has_shown_app_open_ad: bool = false

func _ready() -> void:
	GameState.ads_status_changed.connect(_on_ads_status_changed)
	
	# Show App Open Ad on launch after a tiny delay ONLY IF player has not purchased 'Stop Ads'
	await get_tree().create_timer(0.4).timeout
	show_app_open_ad()

func _on_ads_status_changed(has_removed: bool) -> void:
	if has_removed:
		print("[AdManager] 'Stop Ads ($1.99)' purchased! All ads (App Open & Interstitial) permanently disabled.")

func show_app_open_ad() -> void:
	# Total blockade: if player owns 'Stop Ads', never show app open ad
	if GameState.ads_removed or has_shown_app_open_ad:
		return
	has_shown_app_open_ad = true
	print("[AdManager] Showing App Open Ad: ", app_open_ad_id)

func on_game_over() -> void:
	# If player purchased 'Stop Ads Permanently ($1.99)', NEVER show ads!
	if GameState.ads_removed:
		return
		
	deaths_since_last_ad += 1
	if deaths_since_last_ad >= DEATHS_BETWEEN_ADS:
		show_interstitial()
		deaths_since_last_ad = 0

func show_interstitial() -> void:
	if GameState.ads_removed:
		return
	print("[AdManager] Showing Interstitial Ad strictly on Game Over screen: ", interstitial_ad_id)
