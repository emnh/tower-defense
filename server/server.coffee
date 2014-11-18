# vim: st=2 sts=2 sw=2
http = require("http")
express = require("express")
path = require("path")
neo4j = require("neo4j")
app = express()
port = process.env.PORT or 5000

app.use "/", express.static(path.join(__dirname, "../static"))
app.use "/static", express.static(path.join(__dirname, "../static")) # for source map
#app.use express.bodyParser()
app.set('views', __dirname + '/views')
app.set('view engine', 'jade')

#response.send(request.body)
neo4jurl = process.env.NEO4J_URL or "http://localhost:7474"
db = new neo4j.GraphDatabase(neo4jurl)
server = http.createServer(app)
server.listen port
console.log "http server listening on %d", port
