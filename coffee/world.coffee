
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
              
        @speed       = 10
        @rasterSize = 0.05
        
        super
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
        
        #   000      000   0000000   000   000  000000000
        #   000      000  000        000   000     000   
        #   000      000  000  0000  000000000     000   
        #   000      000  000   000  000   000     000   
        #   0000000  000   0000000   000   000     000   

        @camera = new Camera aspect:@view.offsetWidth / @view.offsetHeight
        
        @sun = new THREE.PointLight 0xffffff
        @scene.add @sun
        
        @ambient = new THREE.AmbientLight 0x222222
        @scene.add @ambient
        
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
        raycaster.setFromCamera mouse, @camera.cam
        hit = raycaster.intersectObjects @scene.children, true
        if hit.length
            o = first(hit).object
            log o
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
        global.world = world
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
        block = new Block
        block.setOrientation Quaternion.ZupY
        @addObjectAtPos block, 0,0,0
        block = new Block
        @addObjectAtPos block, 1,0,0
        block = new Block
        @addObjectAtPos block, -1,0,0
        
        @applyScheme @dict.scheme ? 'default'
    
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
            raster:  20
            wall:    20
            block1:  10
            block2:  10
            block3:  10
            block4:  10
            block5:  10
            block6:  10
            
        for k,v of colors
            mat = Material[k]
            mat.color    = v.color
            mat.specular = v.specular if v.specular?
            if shininess[k]?
                mat.shininess = v.shininess ? shininess[k]

    #  000      000   0000000   000   000  000000000
    #  000      000  000        000   000     000   
    #  000      000  000  0000  000000000     000   
    #  000      000  000   000  000   000     000   
    #  0000000  000   0000000   000   000     000   
    
    addLight: (light) ->
        @lights.push light
        @enableShadows true if light.shadow
        
    removeLight: (light) ->
        _.pull @lights, light
        for l in @lights
            shadow = true if l.shadow
        @enableShadows shadow

    enableShadows: (enable) ->
        @renderer.shadowMap.enabled = enable
    
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
        @setObjectAtPos object, pos
        @addObject object
        
    setObjectAtPos: (object, pos) -> object.setPosition new Pos pos

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
        if object instanceof Light
            @lights.push object
        else
            @objects.push object

    removeObject: (object) ->
        _.pull @lights, object
        _.pull @objects, object
    
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
    
    objectWithName: (name) ->
        for o in @objects
            if name == o.name
                return o
        log "World.objectWithName [WARNING] no object with name #{name}"
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

        Sound.setMatrix @camera
            
        @sun.position.copy @camera.cam.position
        @renderer.autoClearColor = false
        @renderer.render @scene, @camera.cam
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
        camera = @camera.cam
        camera?.aspect = @aspect
        camera?.updateProjectionMatrix()
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

