model = require("./model.coffee")

webBridge = require("./netBridgeWeb.coffee")(model)
hardwareBridge = require("./netBridgeHardware.coffee")(model)

