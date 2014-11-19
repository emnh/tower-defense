class Misc
  @CURRENCY = "$"

  @snapToGrid: (x, y) ->
      sz = 40
      x = Math.floor(x / sz) * sz
      y = Math.floor(y / sz) * sz
      [x, y]

  @displayError: (msg) ->
    target = $("#alerts")
    target.find(".alert").remove()
    d = HTML.div(msg).addClass("alert").addClass("alert-danger")
    target.append(d)
    
  @displayMessage: (msg) ->
    target = $("#alerts")
    target.find(".alert").remove()
    d = HTML.div(msg).addClass("alert").addClass("alert-success")
    target.append(d)

  @copy: (ar) ->
    ar.slice()

class ImageSprite
   
  @cloneCanvas = (oldCanvas) ->
    
    #create a new canvas
    newCanvas = document.createElement("canvas")
    context = newCanvas.getContext("2d")
    
    #set dimensions
    newCanvas.width = oldCanvas.width
    newCanvas.height = oldCanvas.height
    
    #apply the old canvas to the new one
    context.drawImage oldCanvas, 0, 0
    
    #return the new canvas
    newCanvas

  #"#008A76"
  @transparent =
    r: 0x00
    g: 0x8a
    b: 0x76
  @transparent2 =
    r: 0x40
    g: 0x60
    b: 0x80

  @getPixel: (pixels, x, y) ->
    colorsize = pixels.data.length / (pixels.height * pixels.width)
    i = (y * pixels.width + x) * colorsize
    rgba =
      r: pixels.data[i]
      g: pixels.data[i+1]
      b: pixels.data[i+2]
      a: pixels.data[i+3]

  @setPixel: (pixels, x, y, rgba) ->
    colorsize = pixels.data.length / (pixels.height * pixels.width)
    i = (y * pixels.width + x) * colorsize
    pixels.data[i] = rgba.r
    pixels.data[i+1] = rgba.g
    pixels.data[i+2] = rgba.b
    pixels.data[i+3] = rgba.a

  @isTransparent: (rgb) ->
    rgb.r == @transparent.r && rgb.g == @transparent.g && rgb.b == @transparent.b ||
    rgb.r == @transparent2.r && rgb.g == @transparent2.g && rgb.b == @transparent2.b

  @bfs: ([px, py], id, pixels, components) ->
    colorsize = pixels.data.length / (pixels.height * pixels.width)
    neighbours = []
    for x in [-1,0,1]
      for y in [-1,0,1]
        if x != 0 || y != 0
          neighbours.push([x, y])
    queue = []
    queue.push([px, py])
    component =
      id: id
      positions: []
    while queue.length > 0
      [x, y] = queue.pop()
      rgb = @getPixel(pixels, x, y)
      #console.log(x, y, rgb, @isTransparent(rgb))
      if not @isTransparent(rgb)
        component.positions.push([x, y])
        components[x][y] = component
        for n in neighbours
          newX = x + n[0]
          newY = y + n[1]
          if newX >= 0 && newY >= 0 && newX < pixels.width && newY < pixels.height
            if not components[newX][newY]?
              queue.push([newX, newY])
    component


  @getParts: (texture) ->
    # load image in first canvas
    myCanvas = document.createElement("canvas")
    myCanvas.width = texture.width
    myCanvas.height = texture.height
    [width, height] = [texture.width, texture.height]
    myCanvasContext = myCanvas.getContext("2d") # Get canvas 2d context
    myCanvasContext.drawImage texture, 0, 0 # Draw the texture
    pixels = myCanvasContext.getImageData(0, 0, width, height) # Read the texels/pixels back      
    colorsize = pixels.data.length / (pixels.height * pixels.width)

    # create 2nd canvas for target image
    createCanvas = (width, height) ->
      newCanvas = document.createElement("canvas")
      newCanvas.width = width
      newCanvas.height = height
      newCanvasContext = newCanvas.getContext("2d")
      newPixels = newCanvasContext.getImageData(0, 0, width, height)
      ret =
        canvas: newCanvas
        canvasContext: newCanvasContext
        newPixels: newPixels

    components = []
    for x in [0..width-1]
      c = new Array(height)
      components[x] = c

    id = 0
    componentByID = {}
    for y in [0..height-1]
      for x in [0..width-1]
        pixel = ImageSprite.getPixel(pixels, x, y)
        if not ImageSprite.isTransparent(pixel) and not components[x][y]?
          component = ImageSprite.bfs([x, y], id, pixels, components)
          #console.log([x, y], component)
          componentByID[id] = component
          id += 1

    canvases = []
    for id of componentByID
      component = componentByID[id]
      minX = Number.MAX_VALUE
      minY = Number.MAX_VALUE
      maxX = 0
      maxY = 0
      if component.positions.length > 1
        for pos in component.positions
          minX = Math.min(minX, pos[0])
          minY = Math.min(minY, pos[1])
          maxX = Math.max(maxX, pos[0])
          maxY = Math.max(maxY, pos[1])
        component.minX = minX
        component.minY = minY
        component.maxX = maxX
        component.maxY = maxY
        component.width = 1 + maxX - minX
        component.height = 1 + maxY - minY
        #console.log(minX, minY, maxX, maxY, component.width, component.height)
        canvasRet = createCanvas(component.width, component.height)
        for pos in component.positions
          rgba = ImageSprite.getPixel(pixels, pos[0], pos[1])
          ImageSprite.setPixel(canvasRet.newPixels, pos[0] - minX, pos[1] - minY, rgba)
        canvasRet.canvasContext.putImageData(canvasRet.newPixels, 0, 0)
        canvases.push(canvasRet.canvas)

    canvases

class AnimatedSprite

  constructor: (canvases) ->
    @container = HTML.div()
    @canvases = canvases
    @i = 0

  clone: () ->
    @newCanvases = (ImageSprite.cloneCanvas(i) for i in @canvases)
    @newAnim = new AnimatedSprite(@newCanvases)
    @newAnim.animate()
    @newAnim

  animateHelper: () ->
    @container.empty()
    @container.append(@canvases[@i])
    @i += 1
    @i = @i % @canvases.length

  animate: (interval=150) ->
    ams = @
    @loopTime = @canvases.length * interval
    setInterval (() -> ams.animateHelper()), interval


class DebugHVAnimSprite
  constructor: (imgsrc, animationIndices, interval, callback) ->
    sprite = @
    texture = new Image()
    texture.onload = () ->
      @canvases = ImageSprite.getParts(texture)
      callback(sprite)
    texture.src = imgsrc
 
class HVAnimSprite

  constructor: (imgsrc, animationIndices, interval, callback) ->
    sprite = @
    texture = new Image()
    texture.onload = () ->
      canvases = ImageSprite.getParts(texture)
      c2 = []
      for i in animationIndices
        c2.push(canvases[i])
      sprite.canvases = c2
      sprite.anim = new AnimatedSprite(sprite.canvases)
      sprite.anim.animate(interval)
      callback(sprite)
    texture.src = imgsrc
    
class Explosion extends HVAnimSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Misc/expSmall.bmp'
    @animationIndices = [0..6]
    @interval = 150
    super(@imgsrc, @animationIndices, @interval, callback)

class Base extends HVAnimSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Buildings/base.bmp'
    @animationIndices = [0,0,0,0,0,1,2,3,2,1,0,0,0,0,0]
    @interval = 150
    super(@imgsrc, @animationIndices, @interval, callback)

class Creation2A extends HVAnimSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Buildings/Creatn2a.bmp'
    @animationIndices = [0,1,2,3,4,9,8,7,6,5,10,11,12,13,14]
    @interval = 150
    super(@imgsrc, @animationIndices, @interval, callback)

class Factory2 extends HVAnimSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Buildings/Factory2.bmp'
    @animationIndices = [0,1,2,3,4,5,7,8,9,10]
    @interval = 150
    super(@imgsrc, @animationIndices, @interval, callback)

class FixedSpriteDebug

  constructor: (imgsrc) ->
    texture = new Image()
    texture.onload = () ->
      canvases = ImageSprite.getParts(texture)
    texture.src = imgsrc

class FixedSprite
  
  constructor: (imgsrc, index, callback) ->
    @imgsrc = imgsrc
    @index = index
    if callback?
      texture = new Image()
      terrainSprite = @
      texture.onload = () ->
        canvases = ImageSprite.getParts(texture)
        if not canvases[index]?
          throw "incorrect sprite index #{index} for #{imgsrc}"
        terrainSprite.canvas = canvases[index]
        callback(terrainSprite)
      texture.src = imgsrc

  clone: () ->
    fs = new FixedSprite(@imgsrc, @index)
    fs.canvas = ImageSprite.cloneCanvas(@canvas)
    fs

class BuyItem
  constructor: () ->
    @container = HTML.div()
    @container.addClass("buymenu-item")
    @costContainer = HTML.div()
    @costContainer.css "text-align", "center"
    @container.css "width", @sprite.canvas.width + 15
    @container.append(@sprite.canvas)
    @container.append(@costContainer)
    @updateCost(@cost)

  updateCost: (cost) ->
    @cost = cost
    @costContainer.html(@cost + Misc.CURRENCY)

class BuyFactory2 extends BuyItem

  constructor: (sprite) ->
    @sprite = sprite
    @cost = 200
    @damage = 5
    @speed = 1.0
    @range = 100
    super()

class BuyArtillery2 extends BuyItem
  constructor: (sprite) ->
    @sprite = sprite
    @cost = 500
    @damage = 50
    @speed = 5.0
    @range = 250
    super()

class Artillery2Sprite extends FixedSprite
 
  constructor: (callback) ->
    @imgsrc = 'data/images/Buildings/Artilery2.bmp'
    super(@imgsrc, 1, callback)

class Factory2Sprite extends FixedSprite
 
  constructor: (callback) ->
    @imgsrc = 'data/images/Buildings/Factory2.bmp'
    super(@imgsrc, 1, callback)

class GrassTop extends FixedSprite
 
  constructor: (callback) ->
    @imgsrc = 'data/images/Terrain/Grass.bmp'
    super(@imgsrc, 1, callback)

class GrassLeft extends FixedSprite
 
  constructor: (callback) ->
    @imgsrc = 'data/images/Terrain/Grass.bmp'
    super(@imgsrc, 3, callback)

class GrassMid extends FixedSprite
 
  constructor: (callback) ->
    @imgsrc = 'data/images/Terrain/Grass.bmp'
    super(@imgsrc, 4, callback)

class GrassTopLeft extends FixedSprite
 
  constructor: (callback) ->
    @imgsrc = 'data/images/Terrain/Grass.bmp'
    super(@imgsrc, 0, callback)

class GrassTopRight extends FixedSprite
 
  constructor: (callback) ->
    @imgsrc = 'data/images/Terrain/Grass.bmp'
    super(@imgsrc, 2, callback)

class DirectedSprite extends FixedSprite

class Tank1Sprite extends FixedSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Vehicles/Tank1.bmp'
    super(@imgsrc, 4, callback)

class Tank2Sprite extends FixedSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Vehicles/Tank2.bmp'
    super(@imgsrc, 4, callback)

class Tank5Sprite extends FixedSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Vehicles/Tank5.bmp'
    super(@imgsrc, 4, callback)

class Tank14Sprite extends FixedSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Vehicles/Tank14.bmp'
    super(@imgsrc, 4, callback)

class MotherSprite extends FixedSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Vehicles/Mother.bmp'
    super(@imgsrc, 0, callback)


class Creep

  constructor: (gameState, sprite, speed, health, path, prize) ->
    @gameState = gameState
    @sprite = sprite
    @speed = speed
    @path = path
    @health = health
    @maxHealth = health
    @prize = prize
    @active = false
    @container = HTML.div()
    healthBar = HTML.div()
    healthBarSub = HTML.div()
    healthBar.append(healthBarSub)
    healthBarSub.css "height", "100%"
    healthBar
      .css "background", "black"
      .css "width", sprite.canvas.width
      .css "height", "5px"
      .css "border", "1px solid black"
    @healthBar = healthBar
    @healthBarSub = healthBarSub
    @updateHealth(health)
    @container.append(healthBar)
    @container.append(sprite.canvas)

  updateHealth: (health) ->
    @health = health
    if @health <= 0
      @gameState.winPrize(@prize)
      @container.empty()
      @container.append(@gameState.smallExplosion.anim.clone().container)
      container = @container
      setTimeout (() -> container.empty()), @gameState.smallExplosion.anim.loopTime
      @active = false
    else if @health <= 0.2 * @maxHealth
      @healthBarSub.css "background", "red"
    else if @health <= 0.5 * @maxHealth
      @healthBarSub.css "background", "yellow"
    else
      @healthBarSub.css "background", "green"
    @healthBarSub.css "width", Math.round(@health * 100 / @maxHealth) + "%"

class Tower

  constructor: (pos, speed, damage, range) ->
    @pos =
      x: pos[0]
      y: pos[1]
    @width = pos[2]
    @height = pos[3]
    @speed = speed
    @damage = damage
    @range = range
    #@sprite = sprite
    #@container = @sprite

class BuyActive
  constructor: (buyItem, cursorImage) ->
    @buyItem = buyItem
    @cursorImage = cursorImage
    $(cursorImage).addClass("buyItem-cursorImage")

class BuyMenu
  constructor: (callback) ->
    buyMenu = @
    bar = $("#buyMenu")
    @container = bar
    await
      new Factory2Sprite(defer factorySprite)
      new Artillery2Sprite(defer artillerySprite)
    
    sprite = factorySprite
    buyItem = new BuyFactory2(sprite)
    buyActive = new BuyActive(buyItem, ImageSprite.cloneCanvas(sprite.canvas))
    bar.append(buyItem.container)
    buyItem.container.click do (buyActive) -> () -> buyMenu.setActive buyActive

    sprite = artillerySprite
    buyItem = new BuyArtillery2(artillerySprite)
    buyActive = new BuyActive(buyItem, ImageSprite.cloneCanvas(sprite.canvas))
    bar.append(buyItem.container)
    buyItem.container.click do (buyActive) -> () -> buyMenu.setActive buyActive

    buyMenu.setActive(buyActive)

    @moneyContainer = HTML.div().addClass("money")
    bar.append(@moneyContainer)

    callback(buyMenu)
  
  setActive: (buyActive) ->
    @active = buyActive
    $(".buymenu-item.active").removeClass("active")
    @hideCursor()
    @showCursor()
    $(buyActive.buyItem.container).addClass("active")

  showCursor: () ->
    if @active?
      $(@active.cursorImage).css("visibility", "visible")

  hideCursor: () ->
    $(".buyItem-cursorImage").css("visibility", "hidden")

  updateMoney: (money) ->
    @moneyContainer.html("Cash: " + money + Misc.CURRENCY)

  setupMouseHandlers: (map, gameState, newMapObjectCallback) ->
    buyMenu = @
    map.on "mousemove", (ev) ->
      if buyMenu.active?
        map.css "cursor", "none"
        map.append(buyMenu.active.cursorImage)
        buyMenu.showCursor()
        x = ev.pageX - $(this).offset().left
        y = ev.pageY - $(this).offset().top
        [x, y] = Misc.snapToGrid(x, y)
        $(buyMenu.active.cursorImage)
          .css('position', 'absolute')
          .css('left', x)
          .css('top', y)
    map.on "mouseout", (ev) ->
      buyMenu.hideCursor()
    map.click (ev) ->
      if buyMenu.active?
        if gameState.money >= buyMenu.active.buyItem.cost
          gameState.money -= buyMenu.active.buyItem.cost
          buyMenu.updateMoney(gameState.money)
          newCanvas = ImageSprite.cloneCanvas(buyMenu.active.cursorImage)
          map.append(newCanvas)
          x = ev.pageX - $(this).offset().left
          y = ev.pageY - $(this).offset().top
          [x, y] = Misc.snapToGrid(x, y)
          $(newCanvas)
            .css('position', 'absolute')
            .css('left', x)
            .css('top', y)
          newMapObjectCallback([x, y], buyMenu.active)
        else
          Misc.displayError("Not enough money!")


class Map
  
  constructor: (mapWidth, mapHeight, callback) ->
    terrain = []
    @terrain = terrain

    await
      new GrassTopLeft(defer grassTopLeft)
      new GrassTop(defer grassTop)
      new GrassTopRight(defer grassTopRight)
      new GrassMid(defer grassMid)
  
    canvas = grassTopLeft.canvas
    $(canvas)
      .css('position', 'absolute')
      .css('left', 0)
      .css('top', 0)
    terrain.push(canvas)

    canvas = grassTopRight.canvas
    $(canvas)
      .css('position', 'absolute')
      .css('left', mapWidth - canvas.width)
      .css('top', 0)
    terrain.push(canvas)

    canvas = grassTop.canvas
    for x in [1..(mapWidth / canvas.width) - 2]
      clone = ImageSprite.cloneCanvas(canvas)
      terrain.push(clone)
      $(clone)
        .css('position', 'absolute')
        .css('left', x * canvas.width)
        .css('top', 0)
    $(canvas).remove()

    canvas = grassMid.canvas
    for x in [0..(mapWidth / canvas.width)-1]
      for y in [1..(mapHeight / canvas.height)-1]
        clone = ImageSprite.cloneCanvas(canvas)
        terrain.push(clone)
        $(clone)
          .css('position', 'absolute')
          .css('left', x * canvas.width)
          .css('top', y * canvas.height)
    $(canvas).remove()

    callback(@)

class Wave

class Wave1 extends Wave
  constructor: () ->
    @count = 20
    @speed = 5.0
    @interval = 1500
    @health = 200
    @prize = 20
    @spriteClass = Tank1Sprite

class Wave2 extends Wave
  constructor: () ->
    @count = 15
    @speed = 3.5
    @interval = 2000
    @health = 500
    @prize = 50
    @spriteClass = Tank5Sprite

class Wave3 extends Wave
  constructor: () ->
    @count = 100
    @speed = 7.0
    @interval = 250
    @health = 100
    @prize = 20
    @spriteClass = Tank14Sprite

class Wave4 extends Wave
  constructor: () ->
    @count = 1
    @speed = 1.0
    @interval = 1000
    @health = 5000
    @prize = 500
    @spriteClass = MotherSprite


class GameState
  constructor: () ->
    @wave = 0
    @waveCompleted = 1
    @inWave = false
    @map = null
    @creeps = []
    @towers = []
    @lives = 30

  startWave: () ->
    if not @inWave
      @wave += 1
      if @wave == 1
        wave = new Wave1()
        @startWaveP(wave)
      else if @wave == 2
        wave = new Wave2()
        @startWaveP(wave)
      else if @wave == 3
        wave = new Wave3()
        @startWaveP(wave)
      else if @wave == 4
        wave = new Wave4()
        @startWaveP(wave)

      @inWave = true

  startWaveP: (wave) ->
    path = [[0, @mapHeight / 2], [@mapWidth, @mapHeight / 2]]
    await
      new wave.spriteClass(defer tank)
    d = new Date()
    cur = d.getTime()
    for i in [0..wave.count]
      creep = new Creep(@, tank.clone(), wave.speed, wave.health, path, wave.prize)
      creep.id = i
      creep.startTime = cur + i * wave.interval
      @creeps.push(creep)

  frameCreeps: () ->
    d = new Date()
    cur = d.getTime()
    mapdiv = @mapdiv
    if @creeps.length == 0 and @inWave == true
      @inWave = false
      @waveCompleted += 1
    aliveCreeps = []
    for creep in @creeps
      done = false
      if not creep.active and creep.startTime <= cur and creep.health > 0
        creep.pos =
          x: creep.path[0][0]
          y: creep.path[0][1]
        creep.prevWayPoint = creep.path[0]
        creep.nextWayPoint = creep.path[1]
        creep.active = true
      if creep.active
        nextTarget = creep.nextWayPoint
        dx = nextTarget[0] - creep.prevWayPoint[0]
        dy = nextTarget[1] - creep.prevWayPoint[1]
        dist = Math.sqrt(dx * dx + dy * dy)
        ndx = dx / dist
        ndy = dy / dist
        creep.pos.x += creep.speed * ndx
        creep.pos.y += creep.speed * ndy
        if creep.pos.x > @mapWidth or creep.pos.y > @mapHeight
          @loseLife(1)
          creep.health = 0
          done = true
          
        mapdiv.append(creep.container)
        $(creep.container)
          .css "position", "absolute"
          .css "left", creep.pos.x
          .css "top", creep.pos.y
      if not done
        aliveCreeps.push(creep)
    @creeps = aliveCreeps

  frameTowers: () ->
    d = new Date()
    cur = d.getTime()
    for tower in @towers
      aliveCreeps = []
      for creep in @creeps
        if creep.active
          dx = (tower.pos.x - creep.pos.x + tower.width / 2)
          dy = (tower.pos.y - creep.pos.y + tower.height / 2)
          dist = Math.sqrt(dx * dx + dy * dy)
          if dist < tower.range
            if not tower.lastFire? or (tower.lastFire? and cur - tower.lastFire > tower.speed * 100)
              creep.updateHealth(creep.health - tower.damage)
              tower.lastFire = cur
          if creep.health > 0
            aliveCreeps.push(creep)
        else
          aliveCreeps.push(creep)
      @creeps = aliveCreeps


  frame: () ->
    if @inWave
      @frameCreeps()
      @frameTowers()

  updateGameTimer: () ->
    gameState = @
    d = new Date()
    cur = d.getTime()
    seconds = Math.round((gameState.waveStart - cur) / 1000)
    if seconds >= 0
      $("#gametimer").html("Next wave in " + seconds + " seconds")
    else
      gameState.startWave()
      d = new Date(cur - gameState.waveStart)
      $("#gametimer").html("Wave timer: #{d.getMinutes()}:#{d.getSeconds()}")

  updateLives: () ->
    $("#lives").html("Lives left: #{@lives}")

class CoffeeMain
  constructor: () ->
    @

  loadImage: () ->
    main = $("#maincontent")
    main.empty()
    main.css("height", "100%")
    sidebar = $("#sidebar")
    #basediv = HTML.div()
    #main.append(basediv)
    #crtdiv = HTML.div()
    #main.append(crtdiv)
    #buy = new BuyMenu()
    
    # should be divisible by 20 because of map tiles
    mapWidth = Math.floor(main.width() / 20) * 20
    mapHeight = Math.floor(main.height() / 20) * 20
    gameState = new GameState()
    gameState.mapWidth = mapWidth
    gameState.mapHeight = mapHeight
    gameState.money = 1000
    gameState.turrets = []
    gameState.waveStart = new Date().getTime() + 30*1000
    setInterval (() -> gameState.updateGameTimer()), 1000

    mapdiv = HTML.div()
      .css('width', mapWidth)
      .css('height', mapHeight)
    main.append(mapdiv)
    mapCanvas = HTML.canvas('')
    #mapdiv.append(mapCanvas)
    mapCanvas
      .css('width', mapWidth)
      .css('height', mapHeight)
    #base = new Base(basediv)
    #crt = new Factory2(crtdiv)
    
    await
      new Explosion(defer explosion)
      new Map(mapWidth, mapHeight, defer map)
      new BuyMenu(defer buyMenu)

    gameState.mapdiv = mapdiv
    gameState.smallExplosion = explosion
    gameState.winPrize = (prize) ->
      # TODO: animate money rising up from corpse
      gameState.money += prize
      buyMenu.updateMoney(gameState.money)
    gameState.loseLife = (lives) ->
      gameState.lives -= lives
      gameState.updateLives()
    gameState.updateLives()
   
    for canvas in map.terrain
      mapdiv.append(canvas)
    
    # Logic to handle buying items
    buyMenu.updateMoney(gameState.money)
    buyMenu.setupMouseHandlers main, gameState, ([x, y], buyActive) ->
      [width, height] = [buyActive.cursorImage.width, buyActive.cursorImage.height]
      tower = new Tower([x, y, width, height], buyActive.buyItem.speed, buyActive.buyItem.damage, buyActive.buyItem.range)
      gameState.towers.push(tower)

    $("#startNext").click () ->
      Misc.displayMessage("Wave starting!")
      gameState.waveStart = new Date().getTime() + 1000

    setInterval (() -> gameState.frame()), 100
    

  main: () ->
    console.log("main")
          
    $('a[href*="#buy"]').click () ->
      @loadImage()
    @loadImage()

window.CoffeeMain = new CoffeeMain()
