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

  @getTime: () ->
    new Date().getTime()

  @addRotateAnimateToJQuery: () ->
    # http://stackoverflow.com/questions/15191058/css-rotation-cross-browser-with-jquery-animate
    $.fn.animateRotate = (startrad, rad, duration, easing, complete) ->
      args = $.speed(duration, easing, complete)
      step = args.step
      @each (i, e) ->
        args.complete = $.proxy(args.complete, e)
        args.step = (now) ->
          Misc.rotate(e, startrad + now)
          #$.style e, "transform", "rotate(" + now + "deg)"
          step.apply e, arguments  if step

        $(deg: 0).animate
          deg: rad - startrad
        , args

  @rotate: (container, rad) ->
    container = $(container)
    oleft = container.width() / 2
    otop = container.height() / 2
    rotate = "rotate(#{rad}rad)"
    origin = "#{oleft}px #{otop}px"
    props =
      "transform": rotate
      "-webkit-transform": rotate
      "-moz-transform": rotate
      "-ms-transform": rotate
      "transform-origin": origin
      "-webkit-transform-origin": origin
      "-moz-transform-origin": origin
      "-ms-transform-origin": origin
    container.css(props)

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
    if callback
      texture = new Image()
      texture.onload = () ->
        canvases = ImageSprite.getParts(texture)
        c2 = []
        for i in animationIndices
          c2.push(canvases[i])
        sprite.canvases = c2
        sprite.anim = new AnimatedSprite(sprite.canvases)
        sprite.anim.animate(interval)
        sprite.container = sprite.anim.container
        callback(sprite)
      texture.src = imgsrc
    @imgsrc = imgsrc
    @interval = interval
    @animationIndices = animationIndices

  clone: () ->
    n = new HVAnimSprite(@imgsrc, @animationIndices, @interval)
    n.canvases = []
    for c in @canvases
      n.canvases.push(ImageSprite.cloneCanvas(c))
    n.anim = new AnimatedSprite(n.canvases)
    n.anim.animate(@interval)
    n.container = n.anim.container
    n

  scale: (width, height) ->
    for c in @canvases
      $(c).css
        width: width
        height: height
    
class Explosion extends HVAnimSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Misc/expSmall.bmp'
    @animationIndices = [0..6]
    @interval = 150
    super(@imgsrc, @animationIndices, @interval, callback)

class BigExplosion extends HVAnimSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Misc/exploBig.bmp'
    @animationIndices = [0..13]
    @interval = 150
    super(@imgsrc, @animationIndices, @interval, callback)

class  extends HVAnimSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Buildings/base.bmp'
    @animationIndices = [0,0,0,0,0,1,2,3,2,1,0,0,0,0,0]
    @interval = 150
    super(@imgsrc, @animationIndices, @interval, callback)

class Creation2AAnim extends HVAnimSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Buildings/Creatn2a.bmp'
    @animationIndices = [0,1,2,3,4,9,8,7,6,5,10,11,12,13,14]
    @interval = 150
    super(@imgsrc, @animationIndices, @interval, callback)

class Factory2Anim extends HVAnimSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Buildings/Factory2.bmp'
    @animationIndices = [0,1,2,3,4,5,7,8,9,10,9,8,7,5,4,3,2,1]
    @interval = 50
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
    @container = HTML.div()
    if callback?
      texture = new Image()
      terrainSprite = @
      texture.onload = () ->
        canvases = ImageSprite.getParts(texture)
        if not canvases[index]?
          throw "incorrect sprite index #{index} for #{imgsrc}"
        terrainSprite.canvases = canvases
        terrainSprite.canvas = canvases[index]
        terrainSprite.container.append(terrainSprite.canvas)
        callback(terrainSprite)
      texture.src = imgsrc

  setIndex: (index) ->
    @container.empty()
    @container.append(@canvases[index])

  clone: () ->
    fs = new FixedSprite(@imgsrc, @index)
    fs.canvases = (ImageSprite.cloneCanvas(x) for x in @canvases)
    fs.canvas = ImageSprite.cloneCanvas(@canvas)
    fs.container.append(fs.canvas)
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

  createInstance: () ->
    @mapSprite.clone()

class BuyFactory2 extends BuyItem

  constructor: (buyMenuSprite, mapSprite) ->
    @sprite = buyMenuSprite
    @cost = 200
    @damage = 25
    @fireRate = 100
    @range = 100
    @startRotation = 0
    @mapSprite = mapSprite
    super()

class BuyArtillery2 extends BuyItem

  constructor: (buyMenuSprite, mapSprite) ->
    @sprite = buyMenuSprite
    @cost = 500
    @damage = 50
    @fireRate = 500
    @range = 250
    @startRotation = Math.PI / 4 #3 * Math.PI / 8
    @mapSprite = mapSprite
    super()

class Direction
  constructor: (spriteIndex, radians) ->
    @spriteIndex = spriteIndex
    @radians = radians

class DirectionIndices
  @m = Math.PI / 8
  @directions =
    TopLeft: new Direction(0, 3*@m)
    TopMid: new Direction(1, 2*@m)
    TopRight: new Direction(2, 1*@m)
    MidLeft: new Direction(3, 4*@m)
    MidRight: new Direction(4, 0*@m)
    BottomLeft: new Direction(5, 5*@m)
    BottomMid: new Direction(6, 6*@m)
    BottomRight: new Direction(7, 7*@m)

  @rad2index: (rad) ->
    while rad < 0
      rad += 2 * Math.PI
    while rad > 2 * Math.PI
      rad -= 2 * Math.PI
    mindist = Number.MAX_VALUE
    mindir = undefined
    for name, dir of @directions
      dist = Math.abs(rad - dir.radians)
      if dist < mindist
        mindist = dist
        mindir = dir.spriteIndex
    mindir

class BulletSprite extends FixedSprite

  constructor: (callback) ->
    @imgsrc = 'data/images/Misc/Bullets.bmp'
    @rotation = 3 * Math.pi / 8
    super(@imgsrc, 1, callback)

class Artillery2Sprite extends FixedSprite
 
  constructor: (callback) ->
    @imgsrc = 'data/images/Buildings/Artilery2.bmp'
    super(@imgsrc, 0, callback)

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

class Bullet
  constructor: (sprite) ->
    @container = HTML.div()
    @container.append(sprite.container)

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

  midX: () ->
    @pos.x + @container.width() / 2

  midY: () ->
    @pos.y + @container.height() / 2

  remove: () ->
    @container.empty()
    sprite =
      if @sprite.canvas.width > 20
        @gameState.sprites.bigExplosion
      else
        @gameState.sprites.smallExplosion
    newSprite = sprite.clone()
    newSprite.scale @sprite.canvas.width, @sprite.canvas.height
    @container.append(newSprite.container)
    container = @container
    setTimeout (() -> container.remove()), newSprite.anim.loopTime
    @active = false
    @dead = true

  updateHealth: (health) ->
    oldHealth = @health
    @health = health
    if health <= 0 and oldHealth > 0
      @gameState.winPrize(@prize)
      @remove()
    else if @health <= 0.2 * @maxHealth
      @healthBarSub.css "background", "red"
    else if @health <= 0.5 * @maxHealth
      @healthBarSub.css "background", "yellow"
    else
      @healthBarSub.css "background", "green"
    @healthBarSub.css "width", Math.round(@health * 100 / @maxHealth) + "%"

class Tower

  constructor: ([x, y, width, height], startRotation, sprite, fireRate, damage, range) ->
    @container = HTML.div()
    @container.append(sprite.container)
    @container
        .css('position', 'absolute')
        .css('left', x)
        .css('top', y)
    @sprite = sprite
    @pos =
      x: x
      y: y
    @width = width
    @height = height
    @fireRate = fireRate
    @damage = damage
    @range = range
    @lastFire = Misc.getTime()
    @startRotation = startRotation
    @currentRotation = 0

  midX: () ->
    @pos.x + @width / 2.0

  midY: () ->
    @pos.y + @height / 2.0

class BuyActive
  constructor: (buyItem, cursorImage) ->
    @buyItem = buyItem
    @cursorImage = cursorImage
    $(cursorImage).addClass("buyItem-cursorImage")

class BuyMenu

  createActive: (buyItem, sprite) ->
      cursor = HTML.div().addClass("circle").addClass("buyItem-cursor")
      cursor
        .css
          width: buyItem.range
          height: buyItem.range
      canvas = ImageSprite.cloneCanvas(sprite.canvas)
      cursor.canvas = canvas
      cursor.append(canvas)
      $(canvas)
        .css
          position: "absolute"
          left: buyItem.range / 2 - sprite.canvas.width / 2
          top: buyItem.range / 2 - sprite.canvas.height / 2

      buyActive = new BuyActive(buyItem, cursor)

  constructor: (gameState, callback) ->
    buyMenu = @
    @container = HTML.div()
    bar = @container

    sprites = gameState.sprites
   
    buyItem = new BuyFactory2(sprites.factorySprite, sprites.mapFactorySprite)
    buyActive = @createActive(buyItem, sprites.factorySprite)
    bar.append(buyItem.container)
    buyItem.container.click do (buyActive) -> () -> buyMenu.setActive buyActive

    buyMenu.setActive(buyActive)

    buyItem = new BuyArtillery2(sprites.artillerySprite, sprites.mapArtillerySprite)
    buyActive = @createActive(buyItem, sprites.artillerySprite)
    bar.append(buyItem.container)
    buyItem.container.click do (buyActive) -> () -> buyMenu.setActive buyActive

    @moneyContainer = HTML.div().addClass("money")
    bar.append(@moneyContainer)
  
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

  setupMouseHandlers: (map, gameState) ->
    buyMenu = @
    getCoords = (map, event, cursor) ->
      x = event.pageX - map.offset().left - cursor.width() / 2
      y = event.pageY - map.offset().top - cursor.height() / 2
      [x, y] = Misc.snapToGrid(x, y)
    map.on "mousemove", (event) ->
      if buyMenu.active?
        map.css "cursor", "none"
        map.append(buyMenu.active.cursorImage)
        buyMenu.showCursor()
        cursor = buyMenu.active.cursorImage
        [x, y] = getCoords($(this), event, cursor)
        cursor
          .css
            position: 'absolute'
            left: x
            top: y
    map.on "mouseout", (event) ->
      buyMenu.hideCursor()
    map.click (event) ->
      if buyMenu.active?
        cursor = buyMenu.active.cursorImage
        [x, y] = getCoords($(this), event, cursor)
        x += cursor.width() / 2 - cursor.canvas.width / 2
        y += cursor.height() / 2 - cursor.canvas.height / 2
        gameState.buy(buyMenu, [x, y])

class Map
  
  constructor: (gameState, mapWidth, mapHeight) ->
    terrain = []
    @terrain = terrain

    sprites = gameState.sprites

    sprite = sprites.grassTopLeft.clone()
    $(sprite.container)
      .css('position', 'absolute')
      .css('left', 0)
      .css('top', 0)
    terrain.push(sprite.container)

    sprite = sprites.grassTopRight.clone()
    $(sprite.container)
      .css('position', 'absolute')
      .css('left', mapWidth - sprite.canvas.width)
      .css('top', 0)
    terrain.push(sprite.container)

    sprite = sprites.grassTop
    for x in [1..(mapWidth / sprite.canvas.width) - 2]
      clone = sprite.clone()
      terrain.push(clone.container)
      $(clone.container)
        .css('position', 'absolute')
        .css('left', x * sprite.canvas.width)
        .css('top', 0)

    sprite = sprites.grassMid.clone()
    for x in [0..(mapWidth / sprite.canvas.width)-1]
      for y in [1..(mapHeight / sprite.canvas.height)-1]
        clone = sprite.clone()
        terrain.push(clone.container)
        $(clone.container)
          .css('position', 'absolute')
          .css('left', x * sprite.canvas.width)
          .css('top', y * sprite.canvas.height)

class Wave

class Wave1 extends Wave
  constructor: () ->
    @count = 5
    @speed = 10.0 / 100
    @interval = 1500
    @health = 200
    @prize = 20
    @spriteClass = Tank1Sprite
    #@spriteClass = MotherSprite

class Wave2 extends Wave
  constructor: () ->
    @count = 15
    # pixels per millisecond
    @speed = 5.0 / 100
    @interval = 2000
    @health = 500
    @prize = 50
    @spriteClass = Tank5Sprite

class Wave3 extends Wave
  constructor: () ->
    @count = 100
    @speed = 7.0 / 100
    @interval = 250
    @health = 100
    @prize = 20
    @spriteClass = Tank14Sprite

class Wave4 extends Wave
  constructor: () ->
    @count = 1
    @speed = 1.0 / 100
    @interval = 5000
    @health = 5000
    @prize = 500
    @spriteClass = MotherSprite

class Sprites

  constructor: (callback) ->
    await
      new BulletSprite(defer @bullet)
      new Explosion(defer @smallExplosion)
      new BigExplosion(defer @bigExplosion)
      new Factory2Sprite(defer @factorySprite)
      new Factory2Anim(defer @mapFactorySprite)
      new Artillery2Sprite(defer @artillerySprite)
      new Artillery2Sprite(defer @mapArtillerySprite)
      new GrassTopLeft(defer @grassTopLeft)
      new GrassTop(defer @grassTop)
      new GrassTopRight(defer @grassTopRight)
      new GrassMid(defer @grassMid)
    callback(@)

class GameState
  constructor: (sprites, mapWidth, mapHeight) ->
    @sprites = sprites
    @mapWidth = mapWidth
    @mapHeight = mapHeight
    @wave = 0
    @nextWave = 1
    @waveReady = true
    @map = null
    @creeps = []
    @towers = []
    @bullets = []
    @lives = 30
    @money = 1000

  start: () ->
    @waveStart = Misc.getTime() + 1*1000
    gameState = @
    setInterval (() -> gameState.updateGameTimer()), 1000

  waveFinished: () ->
    @wave == @nextWave and @waveReady and @creeps.length == 0

  startWave: () ->
    if @wave < @nextWave
      @waveReady = false
      @wave = @nextWave
      @waveStarted = @waveStart
      delete @waveStart
      Misc.displayMessage("Wave starting!")
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

  startWaveP: (wave) ->
    path = [[0, @mapHeight / 2], [@mapWidth, @mapHeight / 2]]
    await
      new wave.spriteClass(defer tank)
    currentTime = Misc.getTime()
    for i in [0..wave.count]
      creep = new Creep(@, tank.clone(), wave.speed, wave.health, path, wave.prize)
      creep.id = i
      creep.startTime = currentTime + i * wave.interval
      creep.newCreep = true
      @creeps.push(creep)
    @oldFrameTime = currentTime
    @waveReady = true

  frameCreeps: () ->
    currentTime = Misc.getTime()
    oldFrameTime = @oldFrameTime
    elapsed = currentTime - oldFrameTime
    mapContainer = @mapContainer
    aliveCreeps = []
    for creep in @creeps
      if not creep.active
        if creep.startTime <= currentTime
          if creep.newCreep
            creep.newCreep = false
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
        creep.pos.x += creep.speed * ndx * elapsed
        creep.pos.y += creep.speed * ndy * elapsed
        if creep.pos.x > @mapWidth or creep.pos.y > @mapHeight
          @loseLife(1)
          creep.remove()
      if not creep.dead
        aliveCreeps.push(creep)
    @creeps = aliveCreeps
    @oldFrameTime = currentTime

  shoot: (tower, creep) ->
    hit = () ->
      creep.updateHealth(creep.health - tower.damage)
    tower.lastFire = Misc.getTime()
    bullet = new Bullet(@sprites.bullet.clone())
    bullet.targetPos = creep.pos
    bullet.duration = 100
    setTimeout hit, bullet.duration
    bullet.startTime = Misc.getTime()
    bullet.startPos =
      x: tower.pos.x
      y: tower.pos.y
    bullet.pos =
      x: bullet.startPos.x
      y: bullet.startPos.y
    @bullets.push(bullet)

  rotateTower: (tower, creep) ->
    dx = tower.midX() - creep.midX()
    dy = tower.midY() - creep.midY()
    rad = Math.atan2(dy, dx) - tower.startRotation
    tower.moving = true
    tower.container.animateRotate tower.currentRotation, rad, 100, "swing", () ->
      tower.currentRotation = rad
      #if tower.sprite.setIndex?
      #  index = DirectionIndices.rad2index(rad)
      #  tower.sprite.setIndex(index)
      tower.moving = false

  animate: () ->
    @mapContainer.find(".dead").remove()
    for tower in @towers
      if not tower.moving and tower.target? and not tower.target.dead?
        @rotateTower(tower, tower.target)
    for creep in @creeps
      if creep.active and not creep.dead?
        if not creep.addedToMap?
          @mapContainer.append(creep.container)
          creep.addedToMap = true
        creep.container
          .css
            position: "absolute"
            left: creep.pos.x
            top: creep.pos.y
    for bullet in @bullets
      if not bullet.addedToMap?
        @mapContainer.append(bullet.container)
        bullet.addedToMap = true
      bullet.container
        .css
          position: "absolute"
          left: bullet.pos.x
          top: bullet.pos.y
    gameState = @
    requestAnimationFrame(() -> gameState.animate())

  frameBullets: () ->
    currentTime = Misc.getTime()
    activeBullets = []
    for bullet in @bullets
      elapsed = (currentTime - bullet.startTime) / bullet.duration
      if elapsed <= 1.0
        ndx = bullet.targetPos.x - bullet.startPos.x
        ndy = bullet.targetPos.y - bullet.startPos.y
        bullet.pos.x = bullet.startPos.x + ndx * elapsed
        bullet.pos.y = bullet.startPos.y + ndy * elapsed
        activeBullets.push(bullet)
      else
        bullet.container.addClass("dead")
    @bullets = activeBullets

  frameTowers: () ->
    currentTime = Misc.getTime()
    for tower in @towers
      aliveCreeps = []
      for creep in @creeps
        if creep.active
          dx = tower.midX() - creep.midX()
          dy = tower.midY() - creep.midY()
          dist = Math.sqrt(dx * dx + dy * dy)
          if dist < tower.range
            if not tower.target? or tower.target.dead?
              tower.target = creep
            if currentTime - tower.lastFire > tower.fireRate
              @shoot(tower, tower.target)
          if creep.health > 0
            aliveCreeps.push(creep)
        else
          aliveCreeps.push(creep)
      @creeps = aliveCreeps


  frame: () ->
    if @waveFinished()
      @nextWave += 1
      @waveStart = Misc.getTime() + 3 * 1000
      delete @waveStarted
    #if @wave == @nextWave and @waveReady and @creeps.length > 0
    @frameBullets()
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
      if gameState.waveStarted?
        d = new Date(cur - gameState.waveStarted)
        $("#gametimer").html("Wave timer: #{d.getMinutes()}:#{d.getSeconds()}")
      else
        gameState.startWave()

  updateLives: () ->
    $("#lives").html("Lives left: #{@lives}")

  buy: (buyMenu, [x, y]) ->
    gameState = @
    buyActive = buyMenu.active
    buyItem = buyMenu.active.buyItem
    if gameState.money >= buyItem.cost
      gameState.money -= buyItem.cost
      buyMenu.updateMoney(gameState.money)
      sprite = buyItem.createInstance()
      [width, height] = [buyActive.cursorImage.width(), buyActive.cursorImage.height()]
      buyItem = buyActive.buyItem
      tower = new Tower([x, y, width, height], buyItem.startRotation, sprite, buyItem.fireRate, buyItem.damage, buyItem.range)
      @mapContainer.append(tower.container)
      gameState.towers.push(tower)
    else
      Misc.displayError("Not enough money!")


class CoffeeMain
  constructor: () ->
    @

  loadGame: () ->
    main = $("#maincontent")
    main.empty()
    #main.css("height", "100%")
    main.css
      height: "800px"
    sidebar = $("#sidebar")
    #basediv = HTML.div()
    #main.append(basediv)
    #crtdiv = HTML.div()
    #main.append(crtdiv)
    Misc.addRotateAnimateToJQuery()
    
    # should be divisible by 20 because of map tiles
    mapWidth = Math.floor(main.width() / 20) * 20
    mapHeight = 800 # Math.floor(main.height() / 20) * 20
    await
      new Sprites(defer sprites)
    gameState = new GameState(sprites, mapWidth, mapHeight)
    window.gameState = gameState # for debugging with js console
    gameState.start()

    mapContainer = HTML.div()
      .css('width', mapWidth)
      .css('height', mapHeight)
    main.append(mapContainer)

    mapCanvas = HTML.canvas('')
    #mapContainer.append(mapCanvas)
    mapCanvas
      .css('width', mapWidth)
      .css('height', mapHeight)

    #base = new Base(basediv)
    #crt = new Factory2(crtdiv)
    
    map = new Map(gameState, mapWidth, mapHeight)
    buyMenu = new BuyMenu(gameState)

    gameState.mapContainer = mapContainer
    gameState.winPrize = (prize) ->
      # TODO: animate money rising up from corpse
      gameState.money += prize
      buyMenu.updateMoney(gameState.money)
    gameState.loseLife = (lives) ->
      gameState.lives -= lives
      gameState.updateLives()
    gameState.updateLives()
   
    for canvas in map.terrain
      mapContainer.append(canvas)
    
    buyMenuDOM = $("#buyMenu")
    buyMenuDOM.empty()
    buyMenuDOM.append(buyMenu.container)
    
    # Logic to handle buying items
    buyMenu.updateMoney(gameState.money)
    buyMenu.setupMouseHandlers mapContainer, gameState

    $("#startNext").click () ->
      gameState.waveStart = Misc.getTime()
      gameState.startWave()

    setInterval (() -> gameState.frame()), 10
    requestAnimationFrame(() -> gameState.animate())

  todo: () ->
    main = $("#maincontent")
    main.empty()
    todo = HTML.ul()
    main.append(todo)
    todoItems = [
      'let tower / creep distance computation be from the closest corner',
      'fix click responsiveness in placing tower',
      'rotate bullets',
      'improve tower rotation. use sprites, relative rotation',
      'rotate tower randomly when no creeps around',
      'animate money rising up from dead creep',
      'toggle range display overlay for towers',
      'create map editor',
      'click tower to see properties and statistics',
      'DPS overlay',
      'disallow multiple towers in same location'
    ]
    for item in todoItems
      todo.append(HTML.li(item))

    

  main: () ->
    console.log("main")
    main = @
          
    $('a[href*="#buy"]').click () ->
      main.loadGame()
    $('a[href*="#todo"]').click () ->
      main.todo()
    @loadGame()

window.CoffeeMain = new CoffeeMain()
