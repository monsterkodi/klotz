# 0000000    000       0000000    0000000  000   000
# 000   000  000      000   000  000       000  000 
# 0000000    000      000   000  000       0000000  
# 000   000  000      000   000  000       000  000 
# 0000000    0000000   0000000    0000000  000   000
{
last,
deg2rad
}        = require './lib/tools'
Vector   = require './lib/vector'
Item     = require './item'
Action   = require './action'
Material = require './material'

class Block extends Item
    
    @id = 0
    @norm = 
        top:   Vector.unitZ
        bot:   Vector.minusZ
        left:  Vector.unitX
        right: Vector.minusX
        front: Vector.unitY
        back:  Vector.minusY
    
    constructor: () ->
        Block.id += 1
        @name = "block_#{Block.id}"
        super
        @addAction new Action @, Action.ROLL, "roll", 200 
    
    push: (name) ->
        side = name.split(' ')[0]
        log "Block.push '#{name}' side: '#{side}'", Block.norm[side]
        world.addAction @actionWithId Action.ROLL
        
    # initAction: (action) -> log "initAction #{action.name}"
    finishAction: (action) -> #log "finishAction #{action.name}" 
    actionFinished: (action) -> #log "actionFinished #{action.name}" 
    performAction: (action) -> 
        # log "performAction #{action.name} #{action.delta} #{action.current}"
        # log "performAction #{action.name} #{action.relTime()}"
       
    createMesh: ->
        @mesh = new THREE.Object3D
        @mesh.name = @name
        
        @mesh.add @createSide Material.block1,   0, 0,      "front"
        @mesh.add @createEdge Material.block1,   0, 0, 0,   "top front"
        @mesh.add @createEdge Material.block1,   0, 0, 180, "bot front"
        @mesh.add @createEdge Material.block1,   0, 0, 90,  "left front"
        @mesh.add @createEdge Material.block1,   0, 0, -90, "right front"
        
        @mesh.add @createSide Material.block2, 180, 0,      "back"
        @mesh.add @createEdge Material.block2, 180, 0, 0,   "bot back"
        @mesh.add @createEdge Material.block2, 180, 0, 180, "top back"
        @mesh.add @createEdge Material.block2, 180, 0, 90,  "left back"
        @mesh.add @createEdge Material.block2, 180, 0, -90, "right back"
        
        @mesh.add @createSide Material.block3,  90, 0,      "bot"
        @mesh.add @createEdge Material.block3,  90, 0, 0,   "front bot"
        @mesh.add @createEdge Material.block3,  90, 0, 180, "back bot"
        @mesh.add @createEdge Material.block3,  90, 0, -90, "right bot"
        @mesh.add @createEdge Material.block3,  90, 0, 90,  "left bot"
        
        @mesh.add @createSide Material.block4, -90, 0,      "top"
        @mesh.add @createEdge Material.block4, -90, 0, 0,   "back top"
        @mesh.add @createEdge Material.block4, -90, 0, 180, "front top"
        @mesh.add @createEdge Material.block4, -90, 0, 90,  "left top"
        @mesh.add @createEdge Material.block4, -90, 0, -90, "right top"

        @mesh.add @createSide Material.block5,  0, 90,      "right"
        @mesh.add @createEdge Material.block5,  0, 90, 0,   "top right"
        @mesh.add @createEdge Material.block5,  0, 90, 180, "bot right"
        @mesh.add @createEdge Material.block5,  0, 90, 90,  "front right"
        @mesh.add @createEdge Material.block5,  0, 90, -90, "back right"        
        
        @mesh.add @createSide Material.block6,  0,-90,      "left"
        @mesh.add @createEdge Material.block6,  0,-90, 0,   "top left"
        @mesh.add @createEdge Material.block6,  0,-90, 180, "bot left"
        @mesh.add @createEdge Material.block6,  0,-90, 90,  "back left"
        @mesh.add @createEdge Material.block6,  0,-90, -90, "front left"

    createSide: (mat, xr, yr, name) ->

        k = 0.25
        l = 0.4
         
        geom = @quadGeom -k, -k, l, k, k, l, -k,  k, l, k, k, l, -k, -k, l, k, -k, l

        mesh = new THREE.Mesh geom, mat
        mesh.receiveShadow = true
        mesh.rotation.copy new THREE.Euler deg2rad(xr), deg2rad(yr), 0
        mesh.name = name
        mesh

    createEdge: (mat, xr, yr, zr, name) ->

        k = 0.25
        l = 0.4
        m = 0.5
         #              
        geom = @quadGeom -m,  m, m, m, m, m, k, l, k, -k, l, k, -m, m, m, k, l, k
#              
        mesh = new THREE.Mesh geom, mat
        mesh.receiveShadow = true
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
