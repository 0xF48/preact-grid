{h,Component} = require 'preact'
require './Grid.less'
{TileGrid,Tile,Rect} = require './tile.coffee'



c = 0
# all the props used by this component and their default values.
DEFAULT_PROPS = 
	vert: yes #is the grid vertical?
	className: null #outer wrapper classNamea
	fixed: no  #is the grid fixed? if so the grid will fill up and any added children afterwards will replace the ones that were added at the beginning.
	renderRowsPad: 0
	viewRowsOffset:  0
	appendRowsCount: 5
	viewRowsPad: 0 #when to start animating children in (if they are x height units below the screen) adjust this based on scroll speed relative to how many units there.
	postChildren: null #add extra children after all the display children have been added.
	ease: '0.4s cubic-bezier(.29,.3,.08,1)' #easing for fade in effect on each child.
	size: 4 #grid size across≥
	endPadding: 0 # padding to add to the bottom of the grid (when appending and you want to display a loader)
	startPadding: 0 # padding to add to the top of the grid (when prepending and you want to display a loader)
	length: 5 # the length of the grid when it is fixed.
	animate: yes #do animations?
	variation: 1 #animation variation amount for each child.



# clamp helper
Math.clamp = (n,min,max)->
	return Math.min(Math.max(n, min), max)

# pass events to outer wrapper, because why not?
EVENT_REGEX = new RegExp('^on[A-Z]')


class Grid extends Component
	constructor: (props)->
		super(props)
		if @props.appendRowsCount == 0 || @size == 0
			throw new Error 'Grid invalid parameters. @props.appendRowsCount == 0 || @size == 0'
		
		@state =
			display_children: [] # the display children.
			rows_added: 0
			rows_added: 0 # how many rows we prepended, used to offset the scroll position.
			children_map: {} # map of children with their keys
			render_min: null # the min row we need to be at to rerender the grid with new children
			render_max: null # the max row we need to be at to rerender the grid with new children
			# view_min: null # the min row we need to be at to rerender the grid with updated children props.
			# view_max: null # the max row we need to be at to rerender the grid with updated children props.


		# build the matrix if its fixed since we wont be adding any more rows.
		@_grid = new TileGrid
			width: @props.size
			height: 1

	

	# pass events to outer wrapper cuz why not?
	passProps: (props)->
		@pass_props = {}
		for prop_name,prop of props
			if EVENT_REGEX.test(prop_name)
				@pass_props[prop_name] = prop 


	# child context object
	getChildContext: ()=>
		startPadding: @props.startPadding
		vert: @props.vert
		animate: @props.animate
		size: @props.size
		length: @props.length
		scroll_up: @state.scroll_up
		dim: @getDim()
		ease: @props.ease
		ease_dur: @props.ease_dur
		length_dim: @getLengthDim()
		fixed: @props.fixed
		variation: @props.variation
	
	componentWillMount: ->
		@passProps(@props)

	componentWillRecieveProps: (props)->
		@passProps(props)


	appendChild: (child)->
		tile = new Tile
			width: child.attributes.w
			height: child.attributes.h
			item: child

		while !@_grid.addTile(tile,@_grid.full.x2,@_grid.x2,@_grid.full.y2,@_grid.y2)
			@_grid.pad(0,0,0,@props.appendRowsCount)



	prependChild: (child)->
		
		tile = new Tile
			width: child.attributes.w
			height: child.attributes.h
			item: child
		
		while !@_grid.addTile(tile,0,@_grid.x2,@_grid.full.y1,0)
			@_grid.pad(0,0,10,0)
			@state.rows_added += @props.appendRowsCount



		
	setChildren: (children)->
		for child in children
			@appendChild(child)




	# append children, does not check already existing children, the grid is implied to have static items that are in order until key is changed and the grid is reinitialized.
	appendChildren: (children)->
		for i in [@props.children.length...children.length]
			@appendChild(children[i])
		@props.children = children #set the new children!
		
		


	# prepend from 0 to difference between children lengths
	prependChildren: (children)->
		for i in [children.length-@props.children.length-1...0]
			@prependChild(children[i])
		@props.children = children #set the new children!
		



	roundDim: (d)->
		rd = (Math.round(d) - d)
		if rd > -0.5 && rd < 0
			d = Math.round(d+0.5)
		else
			d = Math.round(d)

		return d
	

	# get single unit size dimention (width if vert) in pixels relative to outer container
	getDim: ()=>
		if !@_outer
			return 0
		if @props.vert
			d = @_inner.clientWidth / @props.size
		else
			d = @_outer.clientHeight / @props.size
		return @roundDim(d)

	# get single unit length dimention (height if vert) in pixels relative to outer container
	getLengthDim: ()=>
		if !@_outer
			return 0
		if @props.vert
			if @props.fixed
				d = @_inner.clientHeight / @props.length
			else
				d = @props.dim || @_outer.clientWidth / @props.size
		else
			if @props.fixed
				d = @_inner.clientWidth / @props.length
			else
				d = @props.dim || @_outer.clientHeight / @props.length
		return @roundDim(d)

	# recalculate grid when items have changed.
	updateGrid: (oldProps,newProps)->
		prepend_condition = !newProps.fixed && newProps.children[0] && oldProps.children[0] && newProps.children[0].key != oldProps.children[0].key
		
		# append/prepend new children
		if newProps.children.length > oldProps.children.length
			if prepend_condition
				@prependChildren(newProps.children)
			else
				@appendChildren(newProps.children)
			
			@setDisplayChildren()
			@forceUpdate()
			return true
		return false
			

	













	#calculate which children get rendered based on scroll position and container/child size. The offset in units is managed with bufferOffsetCells
	setDisplayChildren: ()=>
		scroll = @updateScrollPosition()



		if @props.vert
			outer_size = @_outer.clientHeight
			outer_scroll = scroll - @props.startPadding
		else
			outer_size = @_outer.clientWidth
			outer_scroll = scroll - @props.startPadding

		dim = @getLengthDim()
		l = if !@_grid.matrix.length then 0 else @_grid.matrix.length-1
		recalc_children = recalc_view = true

		# current min/max visible row
		r_min = Math.clamp(Math.floor( (outer_scroll) / dim) - @props.viewRowsOffset, 0, l) 
		r_max = Math.clamp(Math.floor( (outer_scroll + outer_size) / dim) + @props.viewRowsOffset, 0, l) 


	
		# calculate the min and max rows for children that need to be rendered to DOM
		if r_min >= @state.render_min && r_max <= @state.render_max && r_max != 0
			recalc_children = false
		else
			if @state.scroll_up
				@state.render_min = Math.clamp(r_min - @props.renderRowsPad,0,l)
				@state.render_max = r_max
			else
				@state.render_min = r_min
				@state.render_max = Math.clamp(r_max + @props.renderRowsPad,0,l)



		# calculate the min and max rows for children that need to be visible.
		if r_min >= @state.view_min && r_max < @state.view_max || @props.animate == false
			recalc_view = false
		else
			if @state.scroll_up
				@state.view_min = Math.clamp(r_min - @props.viewRowsPad,0,l)
				@state.view_max = r_max
			else
				@state.view_min = r_min 
				@state.view_max = Math.clamp(r_max + @props.viewRowsPad,0,l)



		# recalculate all children that need to be rendered.
		if recalc_children
			@state.display_children = []
			added = {}
			# get children between the start row and end row and set them as the display children to pass to render.
			for row in [@state.render_min..@state.render_max]
				for tile_arr,col in @_grid.matrix[row]
					if tile_arr == null
						continue
					
					tile = tile_arr[0]
					child = tile.item
					x = tile_arr[1]
					y = tile_arr[2]

					if added[child.key] == undefined
						added[child.key] = true
						child.attributes.r = row - y 
						child.attributes.c = col - x
						if @props.animate
							if row >= @state.view_min && row <= @state.view_max
								child.attributes.visible = true
							else
								child.attributes.visible = false
						else
							child.attributes.visible = true

						if @state.scroll_up
							@state.display_children.push child
						else 
							@state.display_children.unshift child			
			return true



		# recalculate rendered children to see if they need to be visible or not
		else if recalc_view
			for child in @state.display_children
				if child.attributes.r+child.attributes.h > @state.view_min && child.attributes.r <= @state.view_max
					child.attributes.visible = true
				else
					child.attributes.visible = false
			return true
		return false

	









	setScroll: (s)->
		s = s || 0
		if @props.vert && @_outer.scrollTop != s
			
			if @_outer.scrollHeight < s
				@_inner.style.height = s + @_outer.clientHeight
			@_outer.scrollTop = s
			@_outer.scrollTop = s
		else if @_outer.scrollLeft != s
			
			@_outer.scrollLeft = s
		return s

	# adjust the scroll position of the grid when it is resized.
	updateScrollPosition: ->
		if @props.vert
			scroll = @_outer.scrollTop
			size = @_outer.clientWidth
		else
			scroll = @_outer.scrollLeft
			size = @_outer.clientHeight
		
		if size != @state.size
			diff = size / @state.size
			@state.size = size
			scroll = @setScroll(scroll * diff)
		
		if @state.rows_added
			scroll = @setScroll(scroll + @state.rows_added * @getLengthDim())
			@state.rows_added = 0
		
		return scroll


	# initial mount
	componentDidMount: ()->
		if @props.fixed 
			@setChildren(@props.children)
			@state.display_children = @props.children
		
		# set the children.
		# offset display children
		else
			@setChildren(@props.children)
			@setDisplayChildren()
			
		@forceUpdate()
	

	#update the grid before rendering
	componentWillUpdate: (newProps)->
		if !@updateGrid(@props,newProps)
			if d = @getDim()
				if d != @_dim
					@setDisplayChildren()






	#after grid has been updataed.
	componentDidUpdate: (oldProps)->
		@_dim = @getDim()
		@_l_dim = @getLengthDim()
		@_rect = @_outer.getBoundingClientRect()
		@updateScrollPosition()

	# ref to outer div
	outer_ref: (e)=>	
		@_outer = e

	
	# ref to inner div
	inner_ref: (e)=>
		@_inner = e


	# calculate the properties of the outer scrollable grid wrapper.
	getOuterProps: ->
		outer_props = Object.assign
			key: @key
			ref: @outer_ref
			className: "-i-grid #{@props.vert && '-i-grid-vert' || ''} #{@props.fixed && '-i-grid-fixed' || ''} #{@props.className || @props.outerClassName}"
		,@pass_props

		outer_props.onScroll = @onScroll
		# outer_props.onMouseMove = @onMouseMove

		return outer_props


	# calculate the properties of the inner container.
	getInnerProps: ->
		inner_size = @getLengthDim() * @_grid.y2 + @props.endPadding + @props.startPadding

		if @props.vert
			if @props.fixed
				height = '100%'
				width = '100%'
			else
				height = inner_size+'px'
				width = '100%'
		else
			if @props.fixed
				width = '100%'
				height = '100%'
			else
				width = inner_size+'px'
				height = '100%'

		ref: @inner_ref
		className: "-i-grid-inner #{ @props.innerClassName || '' }"
		style:
			width: width
			height: height


	# update/recalculate grid when component is updated.
	onScroll: ()=>
		outer_scroll = if @props.vert then @_outer.scrollTop else @_outer.scrollLeft
		if @state.last_scroll > outer_scroll
			@state.scroll_up = true
		else
			@state.scroll_up = false
		if @state.last_scroll != outer_scroll
			@state.last_scroll = outer_scroll
			if @setDisplayChildren()
				@forceUpdate()



	# for moving items around in fixed grids.
	onMouseMove: (e)=>
		if !@props.onUnitMouseEnter
			return
		@_rect = @_outer.getBoundingClientRect()
		c = Math.floor((e.clientX - @_rect.x) / @_dim)
		r = Math.floor((e.clientY - @_rect.y) / @_l_dim)
		
		if @_mouse_c != c || @_mouse_r != r
			@props.onUnitMouseEnter(r,c,@state.matrix[r]?[c])

		@_mouse_c = c
		@_mouse_r = r
	

	# render everything
	render: ()=>
		# calculate inner and outer props.
		outer_props = @getOuterProps()
		inner_props = @getInnerProps()
	
		# render only the display children and a loader if there is one.
		h 'div',
			outer_props
			h 'div',
				inner_props
				@state.display_children
				@props.postChildren


Grid.defaultProps = DEFAULT_PROPS

module.exports = Grid

