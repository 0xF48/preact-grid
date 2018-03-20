{h,Component} = require 'preact'


DEFAULT_PROPS = 
	w: 1
	h: 1
	show: no
	style: {}
	ease: null
	scale_start: 0.9
	startMatrixString: null


class GridItem extends Component
	constructor: (props)->
		super(props)
		@state = 
			final: false
			show: false
			post_final: false

		# console.log 'consruct',@props.r
			

		# @state.mat_str = 'matrix3d('+@state.mat.join(',')+')'

		if props.w == 0 || props.h == 0
			throw new Error 'Invalid grid item w/h ('+w+','+h+')'
		
	shouldComponentUpdate: (props,state)->
		# console.log @__key
		if props.visible != @props.visible || @props.r != props.r || @props.c != props.c || @props.w != props.w || @props.h != props.h 
			if props.r != @props.r
				# console.log 'POST FINAL'
				@state.post_final = true
			return true
		return false
	

	getDim: ()->
		d =  @context.dim
		ld = @context.length_dim

		if @context.vert
			left = @props.c*d 
			width  = d*@props.w
			top = @props.r * ld + @context.startPadding
			height = @props.h * ld 
		
		else
			top = @props.c*d
			height  = d*@props.w
			left = @props.r * ld + @context.startPadding
			width = @props.h * ld 

		return 
			x:left
			y:top
			w:width
			h:height
			vert: height > width

	link_ref: (e)=>
		@_item = e

	rand: =>
		(-@context.variation + Math.random() * @context.variation*2 )

	rand_bool: ->
		Math.random() > .5
	
	componentDidUpdate: ->
		@postRender()

	componentDidMount: ->
		@postRender()

	postRender: ->
		if !@state.final && @props.visible
			@_timer = setTimeout @updateStyle,60+25*@rand()
		@state.final = true	


	updateStyle: =>
		@_item.style.transition = @getTransition()
		@_item.style.transform = @getMatrix()
		@_timer = null


	componentWillUnmount: ->
		clearTimeout @_timer


	componentWillMount: ->
		@state.animate = @context.animate


	startMatrixString: ()->
		a = @context.scroll_up && (Math.PI/2 + 0.3) || (-Math.PI/2 - 0.3)
		scale= 0.65 + @rand()*.1
		scale_xx = Math.floor(Math.cos(a)*100)/100
		scale_xz =  Math.floor(Math.sin(a)*100)/100
		scale_zx = - Math.floor(Math.sin(a)*100)/100
		scale_zz =  Math.floor(Math.cos(a)*100)/1000
		# matrix3d(0.921061, 0.4, 0.389418, 0.002, 0, 1, 0, 0, -0.389418, 0, 0.921061, 0, 86, 186, 0, 1)
		if !@state.dim.vert
			mat = [
				1.0*scale,0.0,0.0,0.000
				0,scale_xx*scale,scale_xz*scale,0
				0,scale_zx*scale,scale_zz*scale,0
				@state.dim.x,@state.dim.y,0,1				
			]
		else
			mat = [
				scale_xx*scale,0.0,scale_xz*scale,0.000
				0,1*scale,0,0
				scale_zx*scale,0,scale_zz*scale,0
				@state.dim.x,@state.dim.y,0,1				
			]

		return 'matrix3d('+mat.join(',')+')'



	getMatrix: ()->
		if !@state.final
			return @props.startMatrixString && @props.startMatrixString() || @startMatrixString()
		return 'translate('+@state.dim.x+'px,'+@state.dim.y+'px)'
			


	getTransition: ()->
		if @state.final && @state.post_final == false
			return 'transform ' + (if @props.ease != null then @props.ease else @context.ease)
		return null 



	getStyle: ->
		visibility : @props.visible && 'initial' || 'hidden'
		transition : @getTransition()
		'transform-origin': @state.dim.vert && (@context.scroll_up && 'left' || 'right') || ( !@context.scroll_up && 'top' || 'bottom' )#!@context.scroll_up && 'top' || 'bottom'
		transform : @getMatrix()
		height : @state.dim.h
		width : @state.dim.w 



	render: ()->
		# console.log 'RENDER'
		@state.dim = @getDim()

		h 'div',
			className: '-i-grid-item '+(@props.className||'')
			ref: @link_ref
			style: @getStyle() #Object.assign({},@props.style,@getStyle())
			@props.children


GridItem.defaultProps = DEFAULT_PROPS
module.exports = GridItem