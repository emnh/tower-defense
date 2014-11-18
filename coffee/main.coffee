class Misc
  @CURRENCY = "$"

  @snapToGrid: (x, y) ->
      sz = 40
      x = Math.floor(x / sz) * sz
      y = Math.floor(y / sz) * sz
      [x, y]

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
    rgb.r == @transparent.r && rgb.g == @transparent.g && rgb.b == @transparent.b

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

  constructor: (container, canvases) ->
    @container = container
    @canvases = canvases
    @i = 0

  animateHelper: () ->
    @container.empty()
    @container.append(@canvases[@i])
    @i += 1
    @i = @i % @canvases.length

  animate: (interval=150) ->
    ams = @
    setInterval (() -> ams.animateHelper()), interval


class DebugHVAnimSprite
  constructor: (container, imgsrc, animationIndices, interval) ->
    texture = new Image()
    texture.onload = () ->
      canvases = ImageSprite.getParts(texture)
      for c in canvases
        container.append(c)
    texture.src = imgsrc
 
class HVAnimSprite

  constructor: (container, imgsrc, animationIndices, interval) ->
    texture = new Image()
    texture.onload = () ->
      canvases = ImageSprite.getParts(texture)
      c2 = []
      for i in animationIndices
        c2.push(canvases[i])
      canvases = c2
      anim = new AnimatedSprite(container, canvases)
      anim.animate(interval)
    texture.src = imgsrc
    
class Base extends DebugHVAnimSprite

  constructor: (container) ->
    @container = container
    @imgsrc = 'data/images/Buildings/base.bmp'
    @animationIndices = [0,0,0,0,0,1,2,3,2,1,0,0,0,0,0]
    @interval = 150
    super(container, @imgsrc, @animationIndices, @interval)

class Creation2A extends HVAnimSprite

  constructor: (container) ->
    @container = container
    @imgsrc = 'data/images/Buildings/Creatn2a.bmp'
    @animationIndices = [0,1,2,3,4,9,8,7,6,5,10,11,12,13,14]
    @interval = 150
    super(container, @imgsrc, @animationIndices, @interval)

class Factory2 extends HVAnimSprite

  constructor: (container) ->
    @container = container
    @imgsrc = 'data/images/Buildings/Factory2.bmp'
    @animationIndices = [0,1,2,3,4,5,7,8,9,10]
    @interval = 150
    super(container, @imgsrc, @animationIndices, @interval)

class FixedSpriteDebug

  constructor: (imgsrc) ->
    texture = new Image()
    texture.onload = () ->
      canvases = ImageSprite.getParts(texture)
    texture.src = imgsrc

class FixedSprite

  constructor: (imgsrc, index, callback) ->
    texture = new Image()
    terrainSprite = @
    texture.onload = () ->
      canvases = ImageSprite.getParts(texture)
      terrainSprite.canvas = canvases[index]
      callback(terrainSprite)
    texture.src = imgsrc

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
    super()

class BuyArtillery2 extends BuyItem
  constructor: (sprite) ->
    @sprite = sprite
    @cost = 300
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

class BuyActive
  constructor: (buyItem, cursorImage) ->
    @buyItem = buyItem
    @cursorImage = cursorImage
    $(cursorImage).addClass("buyItem-cursorImage")

class BuyMenu
  constructor: (callback) ->
    buyMenu = @
    bar = $("#sidebar")
    bar.empty()
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
      console.log("click")
      if buyMenu.active?
        if gameState.money >= buyMenu.active.buyItem.cost
          gameState.money -= buyMenu.active.buyItem.cost
          buyMenu.updateMoney(gameState.money)
          newMapObjectCallback(buyMenu.active)
          newCanvas = ImageSprite.cloneCanvas(buyMenu.active.cursorImage)
          map.append(newCanvas)
          x = ev.pageX - $(this).offset().left
          y = ev.pageY - $(this).offset().top
          [x, y] = Misc.snapToGrid(x, y)
          $(newCanvas)
            .css('position', 'absolute')
            .css('left', x)
            .css('top', y)
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
    canvas.remove()

    canvas = grassMid.canvas
    for x in [0..(mapWidth / canvas.width)-1]
      for y in [1..(mapHeight / canvas.height)-1]
        clone = ImageSprite.cloneCanvas(canvas)
        terrain.push(clone)
        $(clone)
          .css('position', 'absolute')
          .css('left', x * canvas.width)
          .css('top', y * canvas.height)
    canvas.remove()

    callback(@)



class GameState
  constructor: () ->
    0

class CoffeeMain
  constructor: () ->
    @

  loadImage: () ->
    main = $("#maincontent")
    main.empty()
    main.css("height", "100%")
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
      new Map(mapWidth, mapHeight, defer map)
      new BuyMenu(defer buyMenu)

    Misc.displayError = (msg) ->
      target = buyMenu.container
      target.find(".alert").remove()
      d = HTML.div(msg).addClass("alert").addClass("alert-danger")
      target.append(d)
    
    for canvas in map.terrain
      mapdiv.append(canvas)
    
    # Logic to handle buying items
    buyMenu.updateMoney(gameState.money)
    buyMenu.setupMouseHandlers main, gameState, (buyActive) ->
      gameState.turrets.push(buyActive)

    main.css "cursor", "none"
    
    #console.log("terrain", terrain)

  main: () ->
    console.log("main")
          
    $('a[href*="#buy"]').click () ->
      @loadImage()
    @loadImage()

window.CoffeeMain = new CoffeeMain()
