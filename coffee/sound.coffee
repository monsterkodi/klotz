#  0000000   0000000   000   000  000   000  0000000  
# 000       000   000  000   000  0000  000  000   000
# 0000000   000   000  000   000  000 0 000  000   000
#      000  000   000  000   000  000  0000  000   000
# 0000000    0000000    0000000   000   000  0000000  

Howler = require 'howler'
Howl   = Howler.Howl

class Sound
    
    @sounds = Object.create null
    @files = 
        STONE_MOVE: file: "stone_move.wav", volume: 1.0
    
    @init: -> 
        return if _.size @sounds
        for k,v of @files
            @sounds[k] = new Howl 
                src: ["#{__dirname}/../sound/#{v.file}"]
                volume: v.volume
            @sounds[k].pannerAttr 
                coneInnerAngle:     360
                coneOuterAngle:     360
                coneOuterGain:      0
                maxDistance:        10
                refDistance:        1
                rolloffFactor:      4
                distanceModel:      'exponential'
                panningModel:       'HRTF'
    
    @setPosDirUp: (p, f, u) -> 
        Howler.Howler.pos p.x, p.y, p.z
        Howler.Howler.orientation f.x, f.y, f.z, u.x, u.y, u.z
    
    @play: (sound, pos, time) ->
        id = @sounds[sound]?.play()
        @sounds[sound]?.pos pos.x, pos.y, pos.z, id if pos?
        
module.exports = Sound
