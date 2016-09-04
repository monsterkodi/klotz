#  0000000    0000000  000000000  000   0000000   000   000
# 000   000  000          000     000  000   000  0000  000
# 000000000  000          000     000  000   000  000 0 000
# 000   000  000          000     000  000   000  000  0000
# 000   000   0000000     000     000   0000000   000   000

_ = require 'lodash'

class Action
    
    @NOOP       = 0
    @ROLL       = 1
    
    @SHOW       = 1
    @HIDE       = 2
    @DELETE     = 3
    
    @ONCE       = 0
    @REPEAT     = 1
    @TIMED      = 2

    constructor: (o, i, n, d, m) ->    
        
        if _.isPlainObject o 
            i = o.id ? -1
            n = o.name
            d = o.duration ? 0
            m = o.mode ? (d and Action.TIMED or Action.ONCE)
            o = o.func
        else
            i ?= -1
            d ?= 0
            m ?= (d and Action.TIMED or Action.ONCE)
            
        @object     = o
        @name       = n
        @id         = i
        @mode       = m
        @duration   = d
        @deleted    = false
        @reset()

    del: ->
        if @object? then @object.removeAction @
        @deleted = true

    perform: -> 
        log "Action.perform #{@name} action? #{@object.performAction?} #{@object.name}" if not @name in  ['noop', 'rotation']
        if @object.performAction? 
            @object.performAction @
        else if _.isFunction @object
            @object @
    
    # init: ->    @object.initAction? @
    finish: ->  @object.finishAction? @
    finished: -> 
        world.removeAction @
        @reset()
        @object?.actionFinished? @

    reset: -> 
        @delta   = 0 # ms between this and previous frame
        @current = 0 # relative (ms since @start)

    relTime:     -> @current / @getDuration() 
    relDelta:    -> @delta / @getDuration()
    getDuration: -> world.mapMsTime @duration 

    step: (step) ->
        @delta = step.delta
        msDur = @getDuration()
        @current += @delta
        if @current >= msDur
            rest     = @current - msDur
            @delta   = Math.max @delta - rest
            @current = msDur
            @perform()
            @finish()
            if @mode == Action.REPEAT
                @current = rest
            else
                @finished()
        else
            @perform()
        
module.exports = Action
