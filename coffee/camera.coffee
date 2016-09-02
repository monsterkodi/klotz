
#    0000000   0000000   00     00  00000000  00000000    0000000 
#   000       000   000  000   000  000       000   000  000   000
#   000       000000000  000000000  0000000   0000000    000000000
#   000       000   000  000 0 000  000       000   000  000   000
#    0000000  000   000  000   000  00000000  000   000  000   000
{
clamp
}           = require './lib/tools'
Matrix      = require './lib/matrix'
Vector      = require './lib/vector'
Quaternion  = require './lib/quaternion'

class Camera extends Matrix

    constructor: (opt) ->
        @fov    = opt?.fov    ? 60
        @near   = opt?.near   ? 0.01
        @far    = opt?.far    ? 30
        @aspect = opt?.aspect ? 1
        @dist   = opt?.dist or 3
        @maxDist = opt?.maxDist or @far/2
        @minDist = opt?.minDist or 2
        
        super

        window.addEventListener 'mousewheel', @onMouseWheel
        window.addEventListener 'mousedown',  @onMouseDown
        window.addEventListener 'mousemove',  @onMouseDrag
        window.addEventListener 'mouseup',    @onMouseUp
        window.addEventListener 'keypress',   @onKeyPress
        window.addEventListener 'keyrelease', @onKeyRelease
        
        @cam = new THREE.PerspectiveCamera @fov, @aspect, @near, @far
        @cam.position.set 0, 0, @dist

    del: =>
        window.removeEventListener 'mousewheel', @onMouseWheel
        window.removeEventListener 'mousedown',  @onMouseDown
        window.removeEventListener 'mousemove',  @onMouseDrag 
        window.removeEventListener 'mousemove',  @onMouseMove        
        window.removeEventListener 'mouseup',    @onMouseUp
        window.removeEventListener 'keypress',   @onKeyPress
        window.removeEventListener 'keyrelease', @onKeyRelease
        @cam = null

    onMouseDown: (event) => 
        @mouseX = event.clientX
        @mouseY = event.clientY
        window.addEventListener    'mousemove',  @onMouseDrag
        window.removeEventListener 'mousemove',  @onMouseMove
        @isPivoting = true
        
    onMouseUp: (event) => 
        window.removeEventListener 'mousemove',  @onMouseDrag
        window.addEventListener    'mousemove',  @onMouseMove
        @isPivoting = false  
        
    onMouseDrag:  (event) =>  
        return if not @isPivoting
        deltaX = @mouseX-event.clientX
        deltaY = @mouseY-event.clientY
        @mouseX = event.clientX
        @mouseY = event.clientY
        q = @cam.quaternion.clone()
        q.multiply new THREE.Quaternion().setFromAxisAngle new THREE.Vector3(1, 0, 0) ,deltaY*0.005
        q.multiply new THREE.Quaternion().setFromAxisAngle new THREE.Vector3(0, 1, 0), deltaX*0.005
        @cam.position.set(0,0,@dist).applyQuaternion q
        @cam.quaternion.copy q

    onMouseWheel: (event) => @zoom 1-event.wheelDelta/10000
    
    zoom: (factor) =>
        @dist = clamp @minDist, @maxDist, @dist*factor
        @cam.position.setLength @dist
        
    setFov: (fov) -> @fov = Math.max(2.0, Math.min fov, 175.0)
        
module.exports = Camera