
#   000  000000000  00000000  00     00
#   000     000     000       000   000
#   000     000     0000000   000000000
#   000     000     000       000 0 000
#   000     000     00000000  000   000

Pos        = require './lib/pos'
Vector     = require './lib/vector'
Quaternion = require './lib/quaternion'
Actor      = require './actor'

class Item extends Actor

    constructor: ->
        super
        @name = @constructor.name if not @name?
        @createMesh?()
        world.scene.add @mesh if @mesh?
        @position         = new Vector
        @orientation      = Quaternion.ZupY.clone()

    del: ->
        world.scene.remove @mesh if @mesh?
        world.removeObject @
        @mesh = null

    getPos: -> new Pos @current_position
    setPos: (x,y,z) -> @setPosition new Pos x,y,z
        
    setPosition: (x,y,z) -> 
        @position = new Vector x,y,z
        @setCurrentPosition @position

    setOrientation: (q) -> 
        @orientation = new Quaternion q
        @setCurrentOrientation @orientation        
        
    setCurrentPosition:    (p) -> @mesh?.position.copy p
    setCurrentOrientation: (q) -> @mesh?.quaternion.copy q
    currentPosition:           -> new Vector @mesh.position
    currentOrientation:        -> new Quaternion @mesh.quaternion
    
module.exports = Item