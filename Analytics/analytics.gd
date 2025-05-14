extends Node
## Manages game analytics through GameAnalytics: https://www.gameanalytics.com/


var game_analytics


func _ready():
	# ... other code from your project ...
	if(Engine.has_singleton("GameAnalytics")):
		game_analytics = Engine.get_singleton("GameAnalytics")
		game_analytics.setEnabledInfoLog(true)
		game_analytics.setEnabledVerboseLog(true)

		game_analytics.configureBuild("0.1.0")

		game_analytics.configureAvailableCustomDimensions01(["CustomA", "CustomB"])
		game_analytics.configureAvailableResourceCurrencies(["exp", "gold"])
		game_analytics.configureAvailableResourceItemTypes(["ItemA", "ItemB"])

		game_analytics.init(["6fb0a1013dc107c344db069cb7a0f27d"], ["88d77ae183bc7cbf99b0fb3d1eed16eed8698842"])
