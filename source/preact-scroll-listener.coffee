# A generic scroll end-start  listener. will listen and distpach events when its (one and only) child reaches the maximum (or minimum) desired scrolling position


{Component} = require 'preact'

DEFAULT_PROPS = 
	offsetMaxBeta: 100 #when scroll reaches % of scrollable element from end [---->|..(100)%..]
	offsetMinBeta: 100 #when scroll reaches % of scrollable element from start [..(100)%..|<----]
	offsetMax: 0 #when scroll reaches px of scrollable element from end [..(X)px..|<----]
	offsetMin: 0 #when scroll reaches px of scrollable element from start [---->|..(X)px..]
	vert: yes #vertical of horizontal scroll?
	onMaxReached: null #when scroll reaches bottom/right event
	onMinReached: null #when scroll reaches top/left event


class ScrollListener extends Component
	constructor: (opt)->
		super()
		@state=
			min: false
			max: false
	check: ()->
		if @props.vert
			max = @base.scrollHeight - @base.clientHeight - (@props.offsetMax || @base.clientHeight*@props.offsetMaxBeta/100)
			min = @base.clientHeight * (@props.offsetMin || @props.offsetMinBeta/100)

			if @base.scrollTop >= max && !@state.max
				@state.max = true
				@props.onMaxReached?(@base)
			else if @base.scrollTop <= min && !@state.min
				@state.min = true
				@props.onMinReached?(@base)
			else 
				if @base.scrollTop < max
					@state.max = false
				if @base.scrollTop > min
					@state.min = false
		else
			max = @base.scrollWidth - @base.clientWidth - (@props.offsetMax || @base.clientWidth*@props.offsetMaxBeta/100)
			min = @base.clientWidth * (@props.offsetMin || @props.offsetMinBeta/100)
			
			if @base.scrollLeft >= max && !@state.max
				@state.max = true
				@props.onMaxReached?(@base)
			else if @base.scrollLeft <= min && !@state.min
				@state.min = true
				@props.onMinReached?(@base)
			else
				if @base.scrollLeft < max
					@state.max = false
				if @base.scrollTop > min
					@state.min = false

	onScroll: =>
		@check()
		
	componentDidMount: ->
		@base.addEventListener 'scroll',@onScroll
		@check()

	componentWillUnmount: ->
		@base.removeEventListener 'scroll',@onScroll

	render: ->
		@props.children[0]

ScrollListener.defaultProps = DEFAULT_PROPS

module.exports = ScrollListener