# 0000000    000       0000000    0000000  000   000
# 000   000  000      000   000  000       000  000 
# 0000000    000      000   000  000       0000000  
# 000   000  000      000   000  000       000  000 
# 0000000    0000000   0000000    0000000  000   000
{
last,
deg2rad
}        = require './lib/tools'
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

        faces     = 1
        triangles = faces * 2

        positions = new Float32Array triangles * 3 * 3
        normals   = new Float32Array triangles * 3 * 3
            
        i = -1
        x = -0.5
        y = -0.5
        z =  0.5
        o = 1
          
        positions[i+=1] = x  ; normals[i] = 0  
        positions[i+=1] = y  ; normals[i] = 0
        positions[i+=1] = z  ; normals[i] = 1

        positions[i+=1] = x+o; normals[i] = 0  
        positions[i+=1] = y+o; normals[i] = 0
        positions[i+=1] = z  ; normals[i] = 1
         
        positions[i+=1] = x  ; normals[i] = 0  
        positions[i+=1] = y+o; normals[i] = 0
        positions[i+=1] = z  ; normals[i] = 1
        
        positions[i+=1] = x+o; normals[i] = 0  
        positions[i+=1] = y+o; normals[i] = 0
        positions[i+=1] = z  ; normals[i] = 1

        positions[i+=1] = x  ; normals[i] = 0  
        positions[i+=1] = y  ; normals[i] = 0
        positions[i+=1] = z  ; normals[i] = 1

        positions[i+=1] = x+o; normals[i] = 0  
        positions[i+=1] = y  ; normals[i] = 0
        positions[i+=1] = z  ; normals[i] = 1

            
        geom = new THREE.BufferGeometry
        geom.addAttribute 'position', new THREE.BufferAttribute positions, 3 
        geom.addAttribute 'normal',   new THREE.BufferAttribute normals,   3 

        mesh = new THREE.Mesh geom, mat
        mesh.receiveShadow = true
        mesh.rotation.copy new THREE.Euler deg2rad(xr), deg2rad(yr), 0
        mesh

module.exports = Block
