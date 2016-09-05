
#   000   000   0000000   00000000   000      0000000  
#   000 0 000  000   000  000   000  000      000   000
#   000000000  000   000  0000000    000      000   000
#   000   000  000   000  000   000  000      000   000
#   00     00   0000000   000   000  0000000  0000000  
{
absMin,
randInt,
deg2rad,
clamp,
first,
last}       = require './lib/tools'
log         = require "/Users/kodi/s/ko/js/tools/log"
Camera      = require './camera'
Light       = require './light'
Sound       = require './sound'
Actor       = require './actor'
Item        = require './item'
Block       = require './block'
Action      = require './action'
ScreenText  = require './screentext'
Menu        = require './menu'
Material    = require './material'
Scheme      = require './scheme'
Quaternion  = require './lib/quaternion'
Vector      = require './lib/vector'
Size        = require './lib/size'
Pos         = require './lib/pos'
_           = require 'lodash'
now         = require 'performance-now'
world       = null

class World extends Actor
    
    constructor: (@view) ->
              
        @speed      = 5
        @rasterSize = 0.05
        super
        
        global.world = @
        
        @startTimer()
        
        @screenSize = new Size @view.clientWidth, @view.clientHeight
        @renderer = new THREE.WebGLRenderer 
            antialias:              true
            logarithmicDepthBuffer: false
            autoClear:              false
            sortObjects:            true

        @renderer.setSize @view.offsetWidth, @view.offsetHeight
        @renderer.shadowMap.type = THREE.PCFSoftShadowMap
                        
        #    0000000   0000000  00000000  000   000  00000000
        #   000       000       000       0000  000  000     
        #   0000000   000       0000000   000 0 000  0000000 
        #        000  000       000       000  0000  000     
        #   0000000    0000000  00000000  000   000  00000000
        
        @scene = new THREE.Scene()

        @camera = new Camera 
            view:   @view
            aspect: @view.offsetWidth / @view.offsetHeight

        
        #   000      000   0000000   000   000  000000000
        #   000      000  000        000   000     000   
        #   000      000  000  0000  000000000     000   
        #   000      000  000   000  000   000     000   
        #   0000000  000   0000000   000   000     000   

        # @ambient = new THREE.AmbientLight 0x222222
        # @scene.add @ambient
        
        @sun = new THREE.PointLight 0xffffff
        @scene.add @sun

        @sun2 = new THREE.PointLight 0xffffff
        @sun2.castShadow = true
        @sun2.shadow.darkness = 0.25
        @sun2.shadow.mapSize = new THREE.Vector2 2048, 2048
        @sun2.shadow.bias = 0.01
        @scene.add @sun2
        
        @renderer.shadowMap.enabled = true
        
        geom = new THREE.SphereGeometry @camera.far/2, 32, 32
        geom.translate 0,@camera.far/4,@camera.far/4
        @plane = new THREE.Mesh geom, Material.plane
        @plane.receiveShadow = true
        # @scene.add @plane
        
        @objects = []
        @lights  = []
     
        @view.addEventListener 'mousedown',  @onMouseDown
    
    # 00     00   0000000   000   000   0000000  00000000
    # 000   000  000   000  000   000  000       000     
    # 000000000  000   000  000   000  0000000   0000000 
    # 000 0 000  000   000  000   000       000  000     
    # 000   000   0000000    0000000   0000000   00000000
    
    onMouseDown: (event) =>
        br = @view.getBoundingClientRect()
        x = event.clientX - br.left
        y = event.clientY - br.top
        mouse = new THREE.Vector2 2*(x/@view.clientWidth)-1, -(2*(y/@view.clientHeight)-1)
        raycaster = new THREE.Raycaster
        raycaster.setFromCamera mouse, @camera
        hit = raycaster.intersectObjects @scene.children, true
        if hit.length
            o = first(hit).object
            block = @objectWithName o.parent.name
            block?.push o.name
        
    # 000  000   000  000  000000000
    # 000  0000  000  000     000   
    # 000  000 0 000  000     000   
    # 000  000  0000  000     000   
    # 000  000   000  000     000   
        
    @init: (view) ->
        return if world?
        @initGlobal()
        world = new World view
        world.create()
        world
        
    @initGlobal: () ->
        return if global.log?        
        global.log = log
        ScreenText.init()
        Sound.init()
        
    #  0000000  00000000   00000000   0000000   000000000  00000000
    # 000       000   000  000       000   000     000     000     
    # 000       0000000    0000000   000000000     000     0000000 
    # 000       000   000  000       000   000     000     000     
    #  0000000  000   000  00000000  000   000     000     00000000
        
    create: (@dict={}) -> 
        @deleteAllObjects()
        Block.id = 0
        @camera.reset()
  
        for i in [0...2]
            for j in [0...2]
                for k in [0...2]
                    colors = {}
                    colors.right  = 1 if i == 1
                    colors.left   = 1 if i == 0
                    colors.top    = 2 if j == 1
                    colors.bot    = 2 if j == 0
                    colors.front  = 3 if k == 1
                    colors.back   = 3 if k == 0
                    block = new Block colors
                    @addObjectAtPos block, i,j,k
             
        # for i in [0...8]
            # block = new Block 
                # front: 1
                # left:  2
                # top:   0
                # back:  0
                # right: 1
                # bot:   2
            # block.setOrientation Quaternion.ZdownY if i % 2
            # @addObjectAtPos block, i,0,0
                         
        @applyScheme @dict.scheme ? 'default'
        @centerCamera()

        @updateGraph()
        @updatePivots()

        @randCount = 32 # @objects.length * 5
        @randomize()
        
    randomize: ->
        pivs = []
        for o in @objects
            for p in o.pivots
                pivs.push [o, p]
        piv = pivs[randInt pivs.length]            
        piv[0].push piv[1]
        @randCount -= 1
        if @randCount == 0
            for o in @objects
                o.actionWithId(Action.ROLL).duration = 200
        
    centerCamera: ->
        center = new Vector
        for block in @objects
            center.add block.currentPosition()
        @camera.lookAt center.div @objects.length
    
    restart: => @create @dict

    #  0000000   0000000  000   000  00000000  00     00  00000000
    # 000       000       000   000  000       000   000  000     
    # 0000000   000       000000000  0000000   000000000  0000000 
    #      000  000       000   000  000       000 0 000  000     
    # 0000000    0000000  000   000  00000000  000   000  00000000
    
    applyScheme: (scheme) ->
        return if not Scheme[scheme]
        
        colors = _.clone Scheme[scheme]
        
        shininess = 
            text:    30
            menu:    30
            plate:   10
            block1:  20
            block2:  20
            block3:  20
            block4:  20
            block5:  20
            block6:  20
            
        for k,v of colors
            mat = Material[k]
            mat.color    = v.color
            # mat.specular = v.specular if v.specular?
            mat.specular = v.specular ? new THREE.Color(v.color).multiplyScalar 0.2
            if shininess[k]?
                mat.shininess = v.shininess ? shininess[k]
    
    #    0000000    0000000  000000000  000   0000000   000   000
    #   000   000  000          000     000  000   000  0000  000
    #   000000000  000          000     000  000   000  000 0 000
    #   000   000  000          000     000  000   000  000  0000
    #   000   000   0000000     000     000   0000000   000   000
          
    exitLevel: (action) =>
        @finish()
        nextLevel = (world.level_index+(_.isNumber(action) and action or 1)) % World.levels.list.length
        world.create World.levels.list[nextLevel]

    #  0000000   0000000          000  00000000   0000000  000000000   0000000
    # 000   000  000   000        000  000       000          000     000     
    # 000   000  0000000          000  0000000   000          000     0000000 
    # 000   000  000   000  000   000  000       000          000          000
    #  0000000   0000000     0000000   00000000   0000000     000     0000000 

    addObjectAtPos: (object, x, y, z) ->
        pos = new Pos x, y, z
        object = @newObject object
        @addObject object
        @setObjectAtPos object, pos
        
    setObjectAtPos: (object, pos) -> 
        object.setPosition new Pos pos
        @updateGraph()
        @updatePivots()
        
    updatePivots: ->
        for o in @objects
            o.updatePivots()

    delPivots: ->
        for o in @objects
            o.delPivots()

    updateGraph: ->
        @graph = {}
        for o in @objects
            @graph[o.name] = []
            for b in @objects
                if o.isNeighbor b
                    @graph[o.name].push b.name

    mightMove: (o) ->
        g = _.cloneDeep @graph
        for n in g[o.name]
            _.pull g[n], o.name
        delete g[o.name]
        connected = @isConnected g
        log "mightMove #{o.name} #{connected}", g
        connected
        
    isConnected: (g) ->
        return false if _.size(g) == 0
        for k,v of g
            return false if v.length == 0
        visited = []
        check = [first _.keys(g)]
        while check.length
            k = check.shift()
            visited.push k if visited.indexOf(k) < 0
            for n in g[k]
                if visited.indexOf(n) < 0 and check.indexOf(n) < 0
                    check.push n
        log 'visited', visited
        return visited.length == _.size g

    objectMoved: (object) ->
        @updateGraph()
        @updatePivots()
        if @randCount
            @randomize()

    neighboring: (p1, p2) ->
        l = p1.minus(p2).length()
        l <= 1.1
    
    newObject: (object) ->
        if _.isString object
            if object.startsWith 'new'
                return eval object 
            return new (require "./#{object.toLowerCase()}")()
        if object instanceof Item
            return object
        else
            return object()
        
    addObject: (object) ->
        object = @newObject object
        @objects.push object

    removeObject: (object) ->
        _.pull @lights, object
        _.pull @objects, object
        
    blockAtPos: (pos) ->
        for o in @objects
            return o if o.position.minus(pos).length() < 0.1
    
    #   0000000    00000000  000      00000000  000000000  00000000
    #   000   000  000       000      000          000     000     
    #   000   000  0000000   000      0000000      000     0000000 
    #   000   000  000       000      000          000     000     
    #   0000000    00000000  0000000  00000000     000     00000000
        
    deleteAllObjects: () ->
    
        while @lights.length
            oldSize = @lights.length
            last(@lights).del() # destructor will call remove object
            if oldSize == @lights.length
                log "WARNING World.deleteAllObjects light no auto remove"
                @lights.pop()
    
        while @objects.length
            oldSize = @objects.length
            last(@objects).del() # destructor will call remove object
            if oldSize == @objects.length
                log "WARNING World.deleteAllObjects object no auto remove #{last(@objects).name}"
                @objects.pop()
                
        @actions = {}
    
    objectWithName: (name) ->
        for o in @objects
            if name == o.name
                return o
        null
        
    #  0000000  000000000  00000000  00000000       
    # 000          000     000       000   000      
    # 0000000      000     0000000   00000000       
    #      000     000     000       000            
    # 0000000      000     00000000  000          
    
    step: (step) ->
        
        o.step?(step) for o in @objects
        a.step step for k,a of @actions
        @lastStep = step

        Sound.setPosDirUp @camera.getPosition(), @camera.getDirection(), @camera.getUp()
            
        @sun.position.copy @camera.position
        @sun2.position.copy new Vector(@camera.position).plus @camera.getUp().mul(8).plus(@camera.getDirection().mul(2))
        
        @plane.quaternion.copy @camera.quaternion
        
        @renderer.autoClearColor = false
        @renderer.render @scene, @camera
        @renderer.render @text.scene, @text.camera if @text
        @renderer.render @menu.scene, @menu.camera if @menu
        
    # 000000000  000  00     00  00000000
    #    000     000  000   000  000     
    #    000     000  000000000  0000000 
    #    000     000  000 0 000  000     
    #    000     000  000   000  00000000
    
    getTime: -> now().toFixed 0
    setSpeed: (s) -> @speed = s
    getSpeed: -> @speed
    mapMsTime:  (unmapped) -> parseInt 10.0 * unmapped/@speed
    unmapMsTime: (mapped) -> parseInt mapped * @speed/10.0
        
    continuous: (cb) ->
        new Action 
            func: cb
            name: "continuous"
            mode: Action.REPEAT

    once: (cb) ->
        new Action 
            func: cb
            name: "once"
            mode: Action.ONCE

    # 00000000   00000000   0000000  000  0000000  00000000  0000000  
    # 000   000  000       000       000     000   000       000   000
    # 0000000    0000000   0000000   000    000    0000000   000   000
    # 000   000  000            000  000   000     000       000   000
    # 000   000  00000000  0000000   000  0000000  00000000  0000000  
    
    resized: (w,h) ->
        @aspect = w/h
        @camera?.aspect = @aspect
        @camera?.updateProjectionMatrix()
        @renderer?.setSize w,h
        @screenSize = new Size w,h
        @text?.resized w,h
        @menu?.resized w,h
                
    # 00     00  00000000  000   000  000   000
    # 000   000  000       0000  000  000   000
    # 000000000  0000000   000 0 000  000   000
    # 000 0 000  000       000  0000  000   000
    # 000   000  00000000  000   000   0000000 
    
    showMenu: (self) -> # handles an ESC key event
        @menu = new Menu()
        @menu.addItem "restart",    @restart 
        @menu.addItem "load level", @showLevels
        @menu.addItem "about",      @showAbout
        @menu.addItem "quit",       @quit
        @menu.show()
    
    playSound: (sound, pos, time) -> Sound.play sound, pos, time if not @creating
    
    #   000   000  00000000  000   000
    #   000  000   000        000 000 
    #   0000000    0000000     00000  
    #   000  000   000          000   
    #   000   000  00000000     000   
    
    modKeyComboEventDown: (mod, key, combo, event) ->
        if @menu?            
            @menu.modKeyComboEvent mod, key, combo, event 
            return 
        @text?.fadeOut()
        switch combo
            when 'esc' then @showMenu()
            when '=' then @speed = Math.min 10, @speed+1
            when '-' then @speed = Math.max 1,  @speed-1
            when 'r' then @restart()
            when 'n' then @exitLevel()
            when 'm' then @exitLevel 5

    modKeyComboEventUp: (mod, key, combo, event) ->

module.exports = World

