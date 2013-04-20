module.exports = (model) ->
  http = require("http")
  express = require("express")

  app = express()
  app.use express.static __dirname + "/../html"

  server = http.createServer(app)
  server.listen 8080

  nowjs = require("now")
  everyone = nowjs.initialize(server, { port: 8080 })

  everyone.now.tubeCoords = model.tubeCoords
  everyone.now.beamCoords = model.beamCoords

  everyone.now.onBeamBroken = (tube1, tube2) ->
    model.onBeamBroken(tube1, tube2)
    
  model.addBeamCallback (tube1, tube2) ->
    everyone.now.receiveBreakEvent(tube1, tube2)
    
  nowjs.on 'connect', () ->
    console.log("Client connected");  
  