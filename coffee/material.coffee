
#   00     00   0000000   000000000  00000000  00000000   000   0000000   000    
#   000   000  000   000     000     000       000   000  000  000   000  000    
#   000000000  000000000     000     0000000   0000000    000  000000000  000    
#   000 0 000  000   000     000     000       000   000  000  000   000  000    
#   000   000  000   000     000     00000000  000   000  000  000   000  0000000

module.exports =

    text: new THREE.MeshPhongMaterial 
        side:           THREE.FrontSide
        shading:        THREE.SmoothShading
        transparent:    true

    menu: new THREE.MeshPhongMaterial 
        side:           THREE.FrontSide
        shading:        THREE.SmoothShading
        transparent:    true

    raster: new THREE.MeshPhongMaterial 
        side:           THREE.FrontSide
        shading:        THREE.SmoothShading

    wall: new THREE.MeshPhongMaterial 
        side:           THREE.FrontSide
        shading:        THREE.SmoothShading
          
    plate: new THREE.MeshPhongMaterial 
        side:           THREE.FrontSide
        shading:        THREE.SmoothShading
        emissiveIntensity: 0.05

    block1: new THREE.MeshPhongMaterial 
        side:           THREE.FrontSide
        shading:        THREE.SmoothShading

    block2: new THREE.MeshPhongMaterial 
        side:           THREE.FrontSide
        shading:        THREE.SmoothShading

    block3: new THREE.MeshPhongMaterial 
        side:           THREE.FrontSide
        shading:        THREE.SmoothShading
    