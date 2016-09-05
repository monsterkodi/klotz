
#    0000000   0000000   00     00  00000000  00000000    0000000 
#   000       000   000  000   000  000       000   000  000   000
#   000       000000000  000000000  0000000   0000000    000000000
#   000       000   000  000 0 000  000       000   000  000   000
#    0000000  000   000  000   000  00000000  000   000  000   000
{
clamp
}           = require './lib/tools'
Vector      = require './lib/vector'
Quaternion  = require './lib/quaternion'

class Camera extends THREE.PerspectiveCamera

    constructor: (opt) ->
        @elem    = opt.view
        @fov     = opt.fov    ? 60
        @near    = opt.near   ? 0.01
        @far     = opt.far    ? 30
        @aspect  = opt.aspect ? 1
        @dist    = opt.dist or 3
        @maxDist = opt.maxDist or @far/2
        @minDist = opt.minDist or 2
        @center  = new Vector 0.5, 0.5, 0.5
        
        super @fov, @aspect, @near, @far

        @elem.addEventListener 'mousewheel', @onMouseWheel
        @elem.addEventListener 'mousedown',  @onMouseDown
        @elem.addEventListener 'mouseup',    @onMouseUp
        @elem.addEventListener 'keypress',   @onKeyPress
        @elem.addEventListener 'keyrelease', @onKeyRelease
        
        @position.set 0, 0, @dist

    reset: ->
        @lookAt 0,0,0
        @quaternion.copy Quaternion.ZupY

    getPosition:  -> new Vector @position
    getDirection: -> new Quaternion(@quaternion).rotate Vector.minusZ
    getUp:        -> new Quaternion(@quaternion).rotate Vector.unitY

    del: =>
        @elem.removeEventListener 'keypress',   @onKeyPress
        @elem.removeEventListener 'keyrelease', @onKeyRelease
        @elem.removeEventListener 'mousewheel', @onMouseWheel
        @elem.removeEventListener 'mousedown',  @onMouseDown
        @elem.removeEventListener 'mouseup',    @onMouseUp
        window.removeEventListener 'mousemove',  @onMouseDrag 

    onMouseDown: (event) => 
        @mouseX = event.clientX
        @mouseY = event.clientY
        window.addEventListener    'mousemove',  @onMouseDrag
        @isPivoting = true
        
    onMouseUp: (event) => 
        window.removeEventListener 'mousemove',  @onMouseDrag
        @isPivoting = false  
        
    onMouseDrag:  (event) =>  
        return if not @isPivoting
        deltaX = @mouseX-event.clientX
        deltaY = @mouseY-event.clientY
        @mouseX = event.clientX
        @mouseY = event.clientY
        q = @quaternion.clone()
        q.multiply new THREE.Quaternion().setFromAxisAngle new THREE.Vector3(1, 0, 0) ,deltaY*0.005
        q.multiply new THREE.Quaternion().setFromAxisAngle new THREE.Vector3(0, 1, 0), deltaX*0.005
        @position.copy @center.plus new THREE.Vector3(0,0,@dist).applyQuaternion q
        @quaternion.copy q

    onMouseWheel: (event) => @setDist 1-event.wheelDelta/10000
    
    setDist: (factor) =>
        @dist = clamp @minDist, @maxDist, @dist*factor
        @position.copy @center.plus new THREE.Vector3(0,0,@dist).applyQuaternion @quaternion
        
    lookAt: (x,y,z) ->
        @center = new Vector x,y,z 
        @position.copy @center.plus new THREE.Vector3(0,0,@dist).applyQuaternion @quaternion
        
    setFov: (fov) -> @fov = Math.max(2.0, Math.min fov, 175.0)
        
module.exports = Camera