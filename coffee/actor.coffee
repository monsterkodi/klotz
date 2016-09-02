
#    0000000    0000000  000000000   0000000   00000000 
#   000   000  000          000     000   000  000   000
#   000000000  000          000     000   000  0000000  
#   000   000  000          000     000   000  000   000
#   000   000   0000000     000      0000000   000   000
{
last
}       = require '/Users/kodi/s/ko/js/tools/tools'
Action  = require './action'
Emitter = require 'events'
_       = require 'lodash'

class Actor extends Emitter
    
    constructor: -> 
        @actions = Object.create null
        @events  = []
        super
        
    #    0000000    0000000  000000000  000   0000000   000   000
    #   000   000  000          000     000  000   000  0000  000
    #   000000000  000          000     000  000   000  000 0 000
    #   000   000  000          000     000  000   000  000  0000
    #   000   000   0000000     000     000   0000000   000   000
    
    addAction: (action) -> @actions[action.name] = action
        
    del: -> @deleteActions()

    deleteActions: -> 
        a?.del() for a in @actions
        @actions = []
            
    removeAction: (action) -> delete @actions[action.name]
    removeActionsOfObject: (o) -> 
        for k,a of @actions
            @removeAction a if a.object == o
         
    getActionWithId: (actionId) -> _.find @actions, (a) -> a?.id == actionId
    getActionWithName: (name) -> _.find @actions, (a) -> a?.name == name

    initAction: ->
    performAction: ->
    finishAction: -> 
    actionFinished: -> 
       
    #   000000000  000  00     00  00000000  00000000 
    #      000     000  000   000  000       000   000
    #      000     000  000000000  0000000   0000000  
    #      000     000  000 0 000  000       000   000
    #      000     000  000   000  00000000  000   000
 
    stopAction: (action) -> world.removeAction action 
       
    startTimer: (duration, mode) -> @addAction new Action @, 0, "timer", duration, mode
        
    startTimedAction: (action, duration) ->
        action.duration = duration if duration >= 0
        world.addAction action        
  
module.exports = Actor
