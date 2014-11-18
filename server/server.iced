# vim: st=2 sts=2 sw=2
http = require("http")
express = require("express")
path = require("path")
neo4j = require("neo4j")
#coffeeMiddleware = require('coffee-middleware')
coffeeMiddleware = require('iced-coffee-middleware')

app = express()
port = process.env.PORT or 5000

coffeeDir = path.join(__dirname, '../coffee')
coffeeLibDir = path.join(__dirname, '../coffee-lib')
publicDir = path.join(__dirname, '../static')

app.use coffeeMiddleware
  force: true
  src: coffeeDir
  compress: true
app.use coffeeMiddleware
  force: true
  src: coffeeLibDir
  compress: true

app.use "/", express.static(publicDir)
app.use "/", express.static(coffeeDir)
app.use "/static", express.static(publicDir) # for source map
#app.use express.bodyParser()
app.set('views', path.join(__dirname, '../views'))
app.set('view engine', 'jade')

#response.send(request.body)
neo4jurl = process.env.NEO4J_URL or "http://localhost:7474"
db = new neo4j.GraphDatabase(neo4jurl)
server = http.createServer(app)
server.listen port
console.log "http server listening on %d", port

app.get '/', (req, res) ->
  res.render 'index',
    title : 'Home'
