var exec = require('cordova/exec');

var PLUGIN_NAME = "PrivacyScreen"
var PLUGIN_FUNCTION_ENABLE_PRIVACY_SCREEN = "EnablePrivacyScreen"
var PLUGIN_FUNCTION_SET_PRIVACY_SCREEN = "SetPrivacyScreen"
var PLUGIN_FUNCTION_DISABLE_PRIVACY_SCREEN = "DisablePrivacyScreen"
var PLUGIN_FUNCTION_SUBSCRIBE_PRIVACY_SCREEN = "SubscribePrivacyScreen"

var PrivacyScreen = function () {}

PrivacyScreen.subscribePrivacyScreen = function (onResultOK, onResultError) {
	exec(onResultOK, onResultError, PLUGIN_NAME, PLUGIN_FUNCTION_SUBSCRIBE_PRIVACY_SCREEN);
}

PrivacyScreen.setPrivacyScreen = function (onResultOK, onResultError, privacyScreenImageURL) {
	if (Object.prototype.toString.call(privacyScreenImageURL) === "[object String]") {
		exec(onResultOK, onResultError, PLUGIN_NAME, PLUGIN_FUNCTION_SET_PRIVACY_SCREEN, [privacyScreenImageURL]);
	} else {
		console.log('[PrivacyScreen Plugin Error] setPrivacyScreen only allow String Type')
		return new Error('PrivacyScreen Plugin Error')
	}
}

PrivacyScreen.enablePrivacyScreen = function (onResultOK, onResultError) {
	exec(onResultOK, onResultError, PLUGIN_NAME, PLUGIN_FUNCTION_ENABLE_PRIVACY_SCREEN);
}

PrivacyScreen.disablePrivacyScreen = function (onResultOK, onResultError) {
	exec(onResultOK, onResultError, PLUGIN_NAME, PLUGIN_FUNCTION_DISABLE_PRIVACY_SCREEN);
}

module.exports = PrivacyScreen