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
Material = require './material'

class Block extends Item
    
    constructor: () ->
        super
       
    createMesh: ->
        @mesh = new THREE.Object3D
        @mesh.add @createSide Material.block1,   0, 0
        @mesh.add @createSide Material.block1, 180, 0
        @mesh.add @createSide Material.block2,  90, 0
        @mesh.add @createSide Material.block2, -90, 0
        @mesh.add @createSide Material.block3,  0, 90
        @mesh.add @createSide Material.block3,  0,-90
       
    createSide: (mat, xr, yr) ->

        faces     = 5
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

        k = 0.25
        l = 0.4
        m = 0.5
         
        tri  -k, -k, l,     k,  k, l,    -k,  k, l
        tri   k,  k, l,    -k, -k, l,     k, -k, l
             
        tri   m, -m, m,     l,  k, k,     m,  m, m
        tri   l, -k, k,     l,  k, k,     m, -m, m
             
        tri  -m, -m, m,    -m,  m, m,    -l,  k, k 
        tri  -l, -k, k,    -m, -m, m,    -l,  k, k 
             
        tri  -m,  m, m,     m,  m, m,     k,  l, k
        tri  -k,  l, k,    -m,  m, m,     k,  l, k
             
        tri  -m, -m, m,     k, -l, k,     m, -m, m
        tri  -k, -l, k,     k, -l, k,    -m, -m, m
         
        geom = new THREE.BufferGeometry
        geom.addAttribute 'position', new THREE.BufferAttribute p, 3 
        geom.addAttribute 'normal',   new THREE.BufferAttribute n, 3 

        mesh = new THREE.Mesh geom, mat
        mesh.receiveShadow = true
        mesh.rotation.copy new THREE.Euler deg2rad(xr), deg2rad(yr), 0
        mesh

module.exports = Block
