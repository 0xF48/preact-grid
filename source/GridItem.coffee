{h,Component} = require 'preact'


DEFAULT_PROPS = 
	w: 1
	h: 1
	visible: false
	style: {}
	ease: null
	scale_start: 0.9
	startMatrixString: null


class GridItem extends Component
	constructor: (props)->
		super(props)
		@state = 
			visible: false
			update: false
			pw: 0

		if props.w == 0 || props.h == 0
			throw new Error 'Invalid grid item w/h ('+w+','+h+')'


	shouldComponentUpdate: (props,state)->
		if !@_item || !@_item.parentNode then return false

		
		if @props.visible != props.visible
			if props.visible == false
				@hide()
			else if props.visible == true
				@show()			


		else if @_item.parentNode.clientWidth != @state.pw && @state.pw != 0
			@state.pw = @_item.parentNode.clientWidth
			setTimeout @resize,0


		return false


	hide: =>
		@_item.style.visibility = 'hidden'

	show: =>
		if !@_item
			return
		@state.visible = true
		@_item.style.visibility = ''
		@_item.style.transition = @getTransition()
		@_item.style.transform = @endTransform()

	resize: =>
		@state.dim = @getDim()
		@_item.style.transition = ''
		@_item.style.transform = @endTransform()
		@_item.style.width = @state.dim.w
		@_item.style.height = @state.dim.h




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


		if height > width || (height == width && @rand()>0)
			vert = true
		else
			vert = false

		return 
			x:left
			y:top
			w:width
			h:height
			vert: vert


	link_ref: (e)=>
		@_item = e


	rand: =>
		(-@context.variation + Math.random() * @context.variation*2 )


	componentDidMount: ->
		@state.pw = @_item.parentNode.clientWidth
		clearTimeout @show
		if @props.visible != @state.visible && @props.visible == true
			setTimeout @show,50+@rand()*50





	componentWillUnmount: ->
		@state.visible = false
		clearTimeout @show

	startTransform: ()->
		a = @context.scroll_up && (Math.PI/2 + 0.3) || (-Math.PI/2 - 0.3)
		scale= 0.5 + @rand()*.2
		scale_xx = Math.floor(Math.cos(a)*100)/100
		scale_xz =  Math.floor(Math.sin(a)*100)/100
		scale_zx = - Math.floor(Math.sin(a)*100)/100
		scale_zz =  Math.floor(Math.cos(a)*100)/1000

		if !@state.dim.vert
			mat = [
				1.0*scale,0.0,0.0,0.000
				0,scale_xx*scale,scale_xz*scale,0
				0,scale_zx*scale,scale_zz*scale,0
				@state.dim.x,@state.dim.y,0,1				
			]
		else
			mat = [
				scale_xx*scale,@rand()*0.1,scale_xz*scale,0.000
				@rand()*0.1,1*scale,0,0
				scale_zx*scale,@rand()*0.1,scale_zz*scale,0
				@state.dim.x,@state.dim.y,0,1				
			]

		return 'matrix3d('+mat.join(',')+')'

	endTransform: ()->
		'translate('+@state.dim.x+'px,'+@state.dim.y+'px)'

	getTransition: ()->
		'transform ' + (if @props.ease != null then @props.ease else @context.ease)

	render: ()->
		@state.dim = @getDim()
		style = 
			visibility : 'hidden'
			transform : @startTransform()
			height : @state.dim.h
			width : @state.dim.w 
		h 'div',
			className: '-i-grid-item '+(@props.className||'')
			ref: @link_ref
			style: style 
			@props.children


GridItem.defaultProps = DEFAULT_PROPS
module.exports = GridItem