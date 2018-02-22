{h,Component} = require 'preact'

DEFAULT_PROPS = 
	w: 1
	h: 1
	show: yes
	ease: null


###
@GridItem class
infinite scroll optimized tetris grid.
###
class GridItem extends Component
	constructor: (props)->
		super(props)
		@state = 
			hidden: false
			show: false
			left: null
			top: null
		
		if props.w == 0 || props.h == 0
			throw new Error 'invalid grid item w/h '+w+','+h

		@style = {}

	shouldComponentUpdate: (props)->
		if @props.r != props.r || @props.c != props.c || @props.show != props.show
			return true
		else
			return false


	getDim: ()->
		d =  @context.dim
		ld = @context.length_dim

		if @context.vert
			left = @props.c*d 
			width  = d*@props.w
			top = @props.r * ld 
			height = @props.h * ld 
		
		else
			top = @props.c*d
			height  = d*@props.w
			left = @props.r * ld
			width = @props.h * ld 

		return 
			x:left
			y:top
			w:width
			h:height


	move: (x,y)->
		# log 'MOVE'
		clearTimeout @move_t
		@move_t = setTimeout ()=>
			@setState
				transform: 'matrix3d(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1) translate('+x+'px,'+y+'px)'
		,0

	show: (set,delay,xy)->
		if @hide_t
			clearTimeout(@hide_t)
			@hide_t = null

		@hide_t = setTimeout ()=>
			if !@_item
				return

			@state.transition = 'transform '+(@props.ease || @context.ease)
			@state.transform = 'matrix3d(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1) translate('+xy.x+'px,'+xy.y+'px)'
			@_item?.style.transition = @state.transition
			@_item?.style.transform = @state.transform

		,delay
		@props.onShow?()

	link_ref: (e)=>
		@_item = e

	# shouldComponentUpdate: (props,state)->
	# 	if props.show == @props.show && @context.dim == @state.dim && @props.w == props.w && @props.h == props.h && @props.c = props.c && @props.r == props.r
	# 		return false

	# 	return true

	# componentWillMount: ()->
	# 	log 'WILL MOUNT'

	rand: =>
		(-@context.variation + Math.random() * @context.variation*2 )
		

	
	render: ()->
		xy = @getDim()
		
		# @state.transform = 'matrix3d(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1) translate('+xy.x+'px,'+xy.y+'px)'
		
		# log xy.x,xy.y
		


		@state.dim = @context.dim

		if @state.show != @props.show
			@state.show = @props.show

			if @state.show == true && @context.animate == false
				@state.transform = 'translate('+xy.x+'px,'+xy.y+'px)'
			else if @state.show == true
				if (@context.vert && @context.dim*@props.w > @context.length_dim*@props.h) || (!@context.vert && @context.dim*@props.w < @context.length_dim*@props.h)
					@state.transform = 'matrix3d('+(@context.variation && 0.6 || 0.9)+',0,0,'+(@rand()*0.002)+',0.00,0,1,'+(@props.top && '-' || '')+'0.003,0,-1,0,0,0,0,0,1) translate('+xy.x+'px,'+xy.y+'px)'
				else
					@state.transform = 'matrix3d(0,0,1,'+(@rand()*0.002)+',0.00,0.6,0,0.001,-1,0,0,0,0,0,0,1) translate('+xy.x+'px,'+xy.y+'px)'

				@state.transition = ''

				@show(false,@rand()*50,xy)
		else
			# log @state.left == left,@state.top == top
			if (xy.x != @state.x || @state.y != xy.y) && @state.y != null && @state.x != null
				@move(xy.x,xy.y)
			

			
		@state.i = @props.i


		@state.x = xy.x
		@state.y = xy.y

		if xy.w != @state.w || xy.h != @state.h
			transition = ''
			
		else
			transition = @state.transition

		@state.w = xy.w
		@state.h = xy.h
		# log @state.transform



		h 'div',
			className: '-i-grid-item-outer '+(@props.class||@props.className||@props.outerClassName||'')
			ref: @link_ref
			key: @props.i
			style:
				visibility : !@props.show && 'hidden' || 'initial'
				transition : @state.transition
				transformOrigin: "#{xy.x + xy.w/2}px #{xy.y + xy.h/2}px"
				transform : @state.transform
				height : xy.h
				width : xy.w
				zIndex: @props.w*@props.h
			@props.children




GridItem.defaultProps = DEFAULT_PROPS

module.exports = GridItem
