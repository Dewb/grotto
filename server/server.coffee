http = require("http")
express = require("express")

app = express()
app.use express.static __dirname + "/../html"

server = http.createServer(app)
server.listen 8080

nowjs = require("now")
everyone = nowjs.initialize(server, { port: 8080 })

everyone.now.breakBeam = (tube1, tube2) ->
  everyone.now.receiveBreakBeam(tube1, tube2)
  
  
