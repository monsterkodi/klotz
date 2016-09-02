
#   000  000000000  00000000  00     00
#   000     000     000       000   000
#   000     000     0000000   000000000
#   000     000     000       000 0 000
#   000     000     00000000  000   000

Pos        = require './lib/pos'
Vector     = require './lib/vector'
Quaternion = require './lib/quaternion'

class Item

    constructor: ->
        @name = @constructor.name if not @name?
        @createMesh?()
        world.scene.add @mesh if @mesh?
        @position         = new Vector
        @direction        = new Vector
        @current_position = new Vector
        @current_orientation = new Quaternion

    del: ->
        return if @name == 'del'
        super 
        @name = 'del'
        world.scene.remove @mesh if @mesh?
        world.removeObject @
        @emit 'deleted'
        
    setPosition: (x,y,z) -> 
        @position = new Vector x,y,z
        @setCurrentPosition @position

    getPos: -> new Pos @current_position
    setPos: (x,y,z) -> @setPosition new Pos x,y,z
    
    setOrientation: (q) -> 
        @current_orientation = @orientation = new Quaternion q
        
    setCurrentPosition: (p) -> 
        # log "item.setCurrentPosition #{@name}", p
        @current_position = new Vector p
        @mesh?.position.copy @current_position
        
    setCurrentOrientation: (q) -> @current_orientation = q
    
module.exports = Item