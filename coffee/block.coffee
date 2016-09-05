# 0000000    000       0000000    0000000  000   000
# 000   000  000      000   000  000       000  000 
# 0000000    000      000   000  000       0000000  
# 000   000  000      000   000  000       000  000 
# 0000000    0000000   0000000    0000000  000   000
{
def,
last,
deg2rad
}          = require './lib/tools'
Vector     = require './lib/vector'
Quaternion = require './lib/quaternion'
Item       = require './item'
Action     = require './action'
Material   = require './material'

class Block extends Item
    
    @id = 0
    @norm = 
        right: Vector.unitX
        top:   Vector.unitY
        front: Vector.unitZ
        left:  Vector.minusX
        bot:   Vector.minusY
        back:  Vector.minusZ
    @dirs =
        top:   ['left', 'right', 'front', 'back']
        bot:   ['left', 'right', 'front', 'back']
        front: ['left', 'right', 'top', 'bot']
        back:  ['left', 'right', 'top', 'bot']
        left:  ['top', 'bot', 'front', 'back']
        right: ['top', 'bot', 'front', 'back']
    @neg = 
        back:  'front'
        left:  'right'
        front: 'back'
        right: 'left'
        top:   'bot'
        bot:   'top'
    
    constructor: (colors) ->
        @color = def colors,
            front: 0
            back:  0
            left:  0
            right: 0
            top:   0
            bot:   0
            
        Block.id += 1
        @pivots = []
        @name = "block_#{Block.id}"
        super
        @addAction new Action @, Action.ROLL, "roll_#{@name}", 50 
    
    # 00000000   000  000   000   0000000   000000000   0000000
    # 000   000  000  000   000  000   000     000     000     
    # 00000000   000   000 000   000   000     000     0000000 
    # 000        000     000     000   000     000          000
    # 000        000      0       0000000      000     0000000 
    
    delPivots: ->
        while @mesh.children.length > 30
            @mesh.remove @mesh.children.pop()
      
    updatePivots: ->
        @pivots = []
        @delPivots()
        
        return if not world.mightMove @
         
        for dir,perps of Block.dirs
            if @neighborAtPos @position.plus @orientation.rotate Block.norm[dir]
                for side in perps
                    if @isFree side 
                        @pivots.push "#{side} #{dir}"
            # for side in perps
                # p = @position.clone()
                # p.add @orientation.rotate Block.norm[dir]
                # p.add @orientation.rotate Block.norm[side]
                # if @neighborAtPos p
                    # if @isFree side 
                        # @pivots.push "#{side} #{dir}"
                    
        for p in @pivots 
            geom = new THREE.SphereBufferGeometry 0.1, 16, 16
            color = @color[p.split(' ')[1]]
            mat = Material["block#{color+1}"]
            torus = new THREE.Mesh geom, mat
            torus.name = p
            torus.position.add Block.norm[p.split(' ')[0]].mul 0.4
            torus.position.add Block.norm[p.split(' ')[1]].mul 0.4
            @mesh.add torus
    
    neighborAtPos: (p) -> world.blockAtPos p
    distance: (o) -> @position.minus(o.position).length()
    isNeighbor: (o) -> Math.abs(@distance(o)-1) < 0.1
    
    isFree: (side) -> not @neighborAtPos @position.plus @orientation.rotate Block.norm[side]
        
    dirForPos: (p) ->
        for k,v of Block.norm
            n = @orientation.rotate v
            if n.dot(p.minus(@position)) > 0.9
                return k
    
    # 00000000   000   000   0000000  000   000
    # 000   000  000   000  000       000   000
    # 00000000   000   000  0000000   000000000
    # 000        000   000       000  000   000
    # 000         0000000   0000000   000   000
    
    push: (@pushSide) ->
        split = @pushSide.split ' '
        if split.length > 1
            pivot = "#{split[0]} #{split[1]}" 
            if pivot in @pivots
                @rotateAround pivot
                return pivot
            pivot = "#{Block.neg[split[0]]} #{Block.neg[split[1]]}"
            if pivot in @pivots
                @rotateAround pivot
                return pivot
            pivot = "#{split[1]} #{Block.neg[split[0]]}" 
            if pivot in @pivots
                @rotateAround pivot
                return pivot
        else 
            log "----- '#{split[0]}'", @pivots
        
    rotateAround: (pivot) ->
        [frst, scnd] = pivot.split ' '
        @rotPivot  = pivot
        @rotCenter = Block.norm[frst].div(2).plus Block.norm[scnd].div(2)
        @rotAxis   = Block.norm[frst].cross Block.norm[scnd]
        @rotAxis   = @orientation.rotate(Block.norm[frst]).cross @orientation.rotate(Block.norm[scnd])
        below = @position.plus @orientation.rotate(Block.norm[frst]).plus @orientation.rotate(Block.norm[scnd])
        @rotAngle  = world.blockAtPos(below) and 90 or 180
        world.delPivots()
        action = @actionWithId Action.ROLL
        world.addAction action
    
    performAction: (action) -> 
        switch action.id
            when Action.ROLL
                rot = Quaternion.rotationAroundVector(action.relTime()*@rotAngle, @rotAxis)
                ctr = @orientation.rotate @rotCenter
                newPos = @position.plus(ctr).minus(rot.rotate ctr)
                @setCurrentPosition newPos
                rot = Quaternion.rotationAroundVector(action.relTime()*@rotAngle, @rotAxis)
                @setCurrentOrientation rot.mul @orientation
                world.centerCamera()
       
    finishAction: (action) ->
        switch action.id
            when Action.ROLL
                oldPos = @position
                @setPosition    @currentPosition()
                @setOrientation @currentOrientation()
                world.updatePivots()
                world.delPivots()
    
    actionFinished: (action) ->
        switch action.id
            when Action.ROLL
                if not @isBonding()
                    side = @pushSide
                    p = @push side
                    if not p?
                        split = side.split ' '
                        p = @push "#{Block.neg[split[0]]} #{Block.neg[split[1]]}"
                        log 'block.actionFinished no push?' if not p?
                else
                    world.objectMoved @
    
    isBonding: ->
        hasNeighbor = false
        for dir,norm of Block.norm
            neighbor = @neighborAtPos @position.plus norm
            return false if not @isBondingWith neighbor
            hasNeighbor = true if neighbor?
        return hasNeighbor

    isBondingWith: (n) ->
        return true if not n?
        ndir = @dirForPos n.position
        mdir = n.dirForPos @position
        return @color[ndir] == n.color[mdir]
    
    createMesh: ->
        @mesh = new THREE.Object3D
        @mesh.name = @name
        
        @mesh.add @createSide @color.front,  0, 0,      "front"
        @mesh.add @createEdge @color.front,  0, 0, 0,   "top front"
        @mesh.add @createEdge @color.front,  0, 0, 180, "bot front"
        @mesh.add @createEdge @color.front,  0, 0, 90,  "left front"
        @mesh.add @createEdge @color.front,  0, 0, -90, "right front"
                              
        @mesh.add @createSide @color.back, 180, 0,      "back"
        @mesh.add @createEdge @color.back, 180, 0, 0,   "bot back"
        @mesh.add @createEdge @color.back, 180, 0, 180, "top back"
        @mesh.add @createEdge @color.back, 180, 0, 90,  "left back"
        @mesh.add @createEdge @color.back, 180, 0, -90, "right back"
                              
        @mesh.add @createSide @color.bot,   90, 0,      "bot"
        @mesh.add @createEdge @color.bot,   90, 0, 0,   "front bot"
        @mesh.add @createEdge @color.bot,   90, 0, 180, "back bot"
        @mesh.add @createEdge @color.bot,   90, 0, -90, "right bot"
        @mesh.add @createEdge @color.bot,   90, 0, 90,  "left bot"
                              
        @mesh.add @createSide @color.top,  -90, 0,      "top"
        @mesh.add @createEdge @color.top,  -90, 0, 0,   "back top"
        @mesh.add @createEdge @color.top,  -90, 0, 180, "front top"
        @mesh.add @createEdge @color.top,  -90, 0, 90,  "left top"
        @mesh.add @createEdge @color.top,  -90, 0, -90, "right top"
                              
        @mesh.add @createSide @color.right, 0, 90,      "right"
        @mesh.add @createEdge @color.right, 0, 90, 0,   "top right"
        @mesh.add @createEdge @color.right, 0, 90, 180, "bot right"
        @mesh.add @createEdge @color.right, 0, 90, 90,  "front right"
        @mesh.add @createEdge @color.right, 0, 90, -90, "back right"        
                              
        @mesh.add @createSide @color.left,  0,-90,      "left"
        @mesh.add @createEdge @color.left,  0,-90, 0,   "top left"
        @mesh.add @createEdge @color.left,  0,-90, 180, "bot left"
        @mesh.add @createEdge @color.left,  0,-90, 90,  "back left"
        @mesh.add @createEdge @color.left,  0,-90, -90, "front left"

    createSide: (color, xr, yr, name) ->

        k = 0.25
        l = 0.4
         
        geom = @quadGeom -k, -k, l, k, k, l, -k,  k, l, k, k, l, -k, -k, l, k, -k, l

        mat = Material["block#{color+1}"]
        mesh = new THREE.Mesh geom, mat
        mesh.receiveShadow = true
        mesh.castShadow = true
        mesh.rotation.copy new THREE.Euler deg2rad(xr), deg2rad(yr), 0
        mesh.name = name
        mesh

    createEdge: (color, xr, yr, zr, name) ->

        k = 0.25
        l = 0.4
        m = 0.5
         #              
        geom = @quadGeom -m,  m, m, m, m, m, k, l, k, -k, l, k, -m, m, m, k, l, k
#              
        mat = Material["block#{color+1}"]
        mesh = new THREE.Mesh geom, mat
        mesh.receiveShadow = true
        mesh.castShadow = true
        mesh.rotation.copy new THREE.Euler deg2rad(xr), deg2rad(yr), deg2rad(zr)
        mesh.name = name
        mesh
     
    quadGeom: (x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, x5, y5, z5, x6, y6, z6) ->
        faces     = 2
        triangles = faces * 2

        p = new Float32Array triangles * 3 * 3
        n = new Float32Array triangles * 3 * 3
            
        i = -1
        
        tri = (x1, y1, z1, x2, y2, z2, x3, y3, z3) ->
            v1 = new Vector x1, y1, z1
            v2 = new Vector x2, y2, z2
            v3 = new Vector x3, y3, z3
            m = v2.minus(v1).cross(v3.minus(v1)).normal()
            p[i+=1] = x1 ; n[i] = m.x ; p[i+=1] = y1; n[i] = m.y ; p[i+=1] = z1 ; n[i] = m.z
            p[i+=1] = x2 ; n[i] = m.x ; p[i+=1] = y2; n[i] = m.y ; p[i+=1] = z2 ; n[i] = m.z
            p[i+=1] = x3 ; n[i] = m.x ; p[i+=1] = y3; n[i] = m.y ; p[i+=1] = z3 ; n[i] = m.z
     
        tri  x1, y1, z1, x2, y2, z2, x3, y3, z3
        tri  x4, y4, z4, x5, y5, z5, x6, y6, z6
                      
        geom = new THREE.BufferGeometry
        geom.addAttribute 'position', new THREE.BufferAttribute p, 3 
        geom.addAttribute 'normal',   new THREE.BufferAttribute n, 3 
        geom
        
module.exports = Block
