{h,Component} = require 'preact'


DEFAULT_PROPS = 
	w: 1
	h: 1
	show: no
	style: {}
	ease: null
	scale_start: 0.9


class GridItem extends Component
	constructor: (props)->
		super(props)
		@state = 
			animate: true
			show: false
			mat: [
				1,0,0,0
				0,1,0,0
				0,0,1,0
				0,0,0,1
			]

		# @state.mat_str = 'matrix3d('+@state.mat.join(',')+')'

		if props.w == 0 || props.h == 0
			throw new Error 'Invalid grid item w/h ('+w+','+h+')'
		
	shouldComponentUpdate: (props,state)->
		# console.log @__key
		if props.show != @props.show || @props.r != props.r || @props.c != props.c || @props.w != props.w || @props.h != props.h
			if @props.r != props.r || @props.c != props.c
				# console.log 'animate = false'
				@state.animate = false
			else
				@state.animate = true
			# if @props.key != props.key
			# 	@state.fresh = true
			return true
		return false
		# if props.show == @props.show && @context.dim == @state.dim && @props.w == props.w && @props.h == props.h && @props.c = props.c && @props.r == props.r && state.vert == @context.vert
		# 	return false

		# return true

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
	
	componentDidUpdate: ->
		@state.animate = false
		@state.show = @props.show

	updateStyle: =>
		@_item.style.transition = @getTransition(@state.dim,false)
		@_item.style.transform = @getMatrix(@state.dim,false)
		@_timer = null

	componentWillUnmount: ->
		clearTimeout @_timer

	componentWillMount: ->
		@state.animate = true

	getMatrix: (dim,fresh)->
		# if fresh
		# 	scale_x = 0.7#!dim.vert && 0.0 || 0.6
		# 	scale_y = 1.0#dim.vert && 0.0 || 0.6
		# 	persp_y = 0.0001
		# 	persp_z = 2.0
		if fresh
			a = 1.0
			scale= 0.1
			scale_xx = Math.cos(a)
			scale_xz = Math.sin(a)
			scale_zx = -Math.sin(a)
			scale_zz = Math.cos(a)
			# matrix3d(0.921061, 0.4, 0.389418, 0.002, 0, 1, 0, 0, -0.389418, 0, 0.921061, 0, 86, 186, 0, 1)
			mat = [
				scale_xx*scale,0.0,scale_xz*scale,0.000
				0,1*scale,0,0
				scale_zx*scale,0,scale_zz,0
				dim.x,dim.y,0,1				
			]
		else
			mat = [
				1,0,0,0
				0,1,0,0
				0,0,1,0
				dim.x,dim.y,0,1
			]

		return 'matrix3d('+mat.join(',')+')'



	getTransition: (dim,fresh)->
		if fresh
			return ''
		else
			return 'transform '+@context.ease


	getStyle: ->

		fresh = @state.animate
		dim = @state.dim = @getDim()
		if fresh then @_timer = setTimeout @updateStyle,@rand()*200
		visibility : @props.show && 'initial' || 'hidden'
		transition : @state.animate && @getTransition(dim,fresh) || ''
		transform : @getMatrix(dim,fresh)
		height : dim.h
		width : dim.w 
		
	render: ()->
		# console.log @_timer
		h 'div',
			className: '-i-grid-item '+(@props.className||'')
			ref: @link_ref
			style: Object.assign({},@props.style,@getStyle())
			@props.children


GridItem.defaultProps = DEFAULT_PROPS
module.exports = GridItem