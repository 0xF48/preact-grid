{h,Component} = require 'preact'
require './Grid.less'

# all the props used by this component and their default values.
DEFAULT_PROPS = 
	vert: yes #is the grid vertical?
	className: null #outer wrapper className
	fixed: no  #is the grid fixed? if so the grid will fill up and any added children afterwards will replace the ones that were added at the beginning.
	bufferOffsetCells: 4 #how many height units to buffer items for when updating the display children. depending on the size of your grid you may need more buffering to avoid extra renders. when there are many buffered children, the total div count increases but the calculations to diff the children decreases.
	animationOffsetCellBeta: 3 #when to start animating children in (if they are x height units below the screen) adjust this based on scroll speed relative to how many units there.
	postChildren: null #add extra children after all the display children have been added.
	ease: '0.4s cubic-bezier(.29,.3,.08,1)' #easing for fade in effect on each child.
	size: 4 #grid size across≥
	endPadding: 50 # padding to add to the bottom of the grid (when appending and you want to display a loader)
	startPadding: 50 # padding to add to the top of the grid (when prepending and you want to display a loader)
	length: 5 # the length of the grid when it is fixed.
	animate: yes #do animations?
	variation: 1 #animation variation amount for each child.
	# append: yes #append or prepend the children? use this when adding new items depending on 


# math clamp helper
_clamp = (n,min,max)->
	return Math.min(Math.max(n, min), max)

# pass events to outer wrapper, because why not?
EVENT_REGEX = new RegExp('^on[A-Z]')


class Grid extends Component
	constructor: (props)->
		super(props)
		@state =
			#the display children.
			display_children: []
			
			#the matrix that holds the info for the positions and width/height (in integer units) of the children for easy search.
			matrix: []

			# minimum row index for matrix
			min_row_index: 0
			
			#leftovers from react.
			# child_props: []
			children_map: {}

			# used in setDisplayChildren to diff the current min/max rendered row and the needed min/max row
			row_min: null
			row_max: null

		if @props.fixed
			@buildFixedMatrix()
	
	# flush the state (reset grid key)
	# flushState: ()->
	# 	console.log 'FLUSH?'
	# 	@state.display_children = []
	# 	@state.matrix = []
	# 	@state.row_h = null
	# 	@state.row_n = null
	# 	@state.offset_update = null

	# 	if @props.fixed
	# 		@buildFixedMatrix()

	
	# build the matrix for a fixed grid.
	buildFixedMatrix: ()->
		for row in [0...@props.length]
			@state.matrix[row] = @state.matrix[row] || []
			for col in [0...@props.size]
				@state.matrix[row][col] = null



	# pass events to outer wrapper cuz why not?
	passProps: (props)->
		@pass_props = {}
		for prop_name,prop of props
			if EVENT_REGEX.test(prop_name)
				@pass_props[prop_name] = prop 


	# child context object
	getChildContext: ()=>
		vert: @props.vert
		animate: @props.animate
		size: @props.size
		length: @props.length
		dim: @getDim()
		ease: @props.ease
		ease_dur: @props.ease_dur
		length_dim: @getLengthDim()
		fixed: @props.fixed
		variation: @props.variation



	componentWillRecieveProps: (props)->
		@passProps(props)





	# fill matrix spot with child key
	fillSpot: (child)->
		for row in [child.attributes.r...child.attributes.r+child.attributes.h]
			for col in [child.attributes.c...child.attributes.c+child.attributes.w]
				if !@state.matrix[row] || @state.matrix[row][col] != null || @state.matrix[row][col] == undefined
					throw new Error "Internal Error: cannot fill spot that is not empty! Please report this bug : #{row},#{col},#{@state.matrix[row]}"
				@state.matrix[row][col] = child.attributes.key

	




	# removeIndex: (r,c,h,w)->
	# 	arr = @state.matrix
	# 	for row in [r...r+h]
	# 		for col in [c...c+w]
	# 			child = @state.children_map[arr[row][col]]
				
	# 			if index == -1
	# 				continue

	# 			c_w = child.attributes.w
	# 			c_h = child.attributes.h
	# 			c_r = child.attributes.r
	# 			c_c = child.attributes.c
	# 			delete @state.children_map[arr[row][col]]

	# 			# log c_w,c_h,c_r,c_c
	# 			for row2 in [c_r...c_r+c_h]
	# 				for col2 in [c_c...c_c+c_w]
	# 					arr[row2][col2] = -1


	# findHiddenChild: (w,h)->

	# 	if !@props.fixed
	# 		throw new Error 'findHiddenChild props.fixed == false'

	# 	for i in [@props.children.length-1...0]
	# 		c = @props.children[i]
	# 		if c.attributes.w <= w && c.attributes.h <= h && !@state.child_props[c.attributes.i]
	# 			return c
			
					

	# 	return [null]




	fillEmptySpots: ()->
		arr = @state.matrix
		for row in [0...arr.length]
			for col in [0...arr[row].length]
				if arr[row][col] == null
					cw = 1
					ch = 1
					while arr[row][col+cw] == null
						cw++
						while arr[row+ch] && arr[row+ch][col] == null
							cw_i = 0
							while cw_i++ && cw_i < cw
								if !arr[row+ch][col+cw_i]
									return
							ch++
					# log cw,ch
					@addChild(@findHiddenChild(cw,ch))

	
	componentWillMount: ->
		@passProps(@props)



	
	###
	@freeSpot method
	free up a parti
	###	
	freeSpot: (w,h,arr)->
		
		if @props.freeSpot
			return @props.freeSpot(w,h,arr)
		ranks = []

		for row in [0...arr.length]
			for col in [0...arr[row].length]
				rank = 0
				bad_spot = false
				r_obj = {}
				r_obj.n_count = 0
				r_obj.rank = 0
				for c_row in [row...row+h]
					if !arr[c_row]?
						bad_spot = true
						break
					for c_col in [col...col+w]
						if !arr[c_row][c_col]?
							bad_spot = true
							break
						if arr[c_row][c_col] == null
							r_obj.n_count++
							continue
						index = arr[c_row][c_col]
						if r_obj[index]
							continue
						r_obj.n_count++
						r_obj[index] = true	
						r_obj.rank += index
				
				if bad_spot
					continue

				
				r_obj.r  = row
				r_obj.c  = col
				# log r_obj.rank,r_obj.n_count
				r_obj.rank = r_obj.rank / r_obj.n_count
				ranks.push r_obj



		ranks = ranks.sort (a,b)->
			return a.rank - b.rank
	

		
		# log ranks[0].r,h
		# log ranks[0].c,w

		@removeIndex(ranks[0].r,ranks[0].c,h,w,arr)
	
	

		return




	#add more empties to the matrix.
	increaseMatrixSize: (amount)->
		# fixed grids cant increase the matrix size.
		if @props.fixed then return

		for i in [0...amount]
			row = []
			for c in [0...@props.size]
				row[c] = null
			@state.matrix.push row




	#check to see if spot is taken
	checkSpot: (r,c,w,h)->
		
		
		if !@state.matrix[r] or @state.matrix[r][c] != null then return false
		
		# check for single to avoid the loop
		if w == 1 && h == 1 && @state.matrix[r][c] == null then return true

		# loop to right and down to check if space is free.
		for row in [r...r+h]
			for col in [c...c+w]
				if !@state.matrix[row] || @state.matrix[row][col] != null
					return false
		return true


	#try and get a free spot with w/width and h/height.
	getSpot: (w,h,_test)->
		min_r_i = 0 #min row index
		found = false #found spot
		row_filled = true #row filled 

		# console.log @state.min_row_index
		
		if (@state.matrix.length - @state.min_row_index) <= h then @increaseMatrixSize(h)

		for row in [@state.min_row_index...@state.matrix.length]
			for spot,col in @state.matrix[row]
				if spot == null
					row_filled = false #row is filled
				if @checkSpot(row,col,w,h)
					return [row,col]
			if row_filled
				@state.min_row_index = row

		if _test
			throw new Error 'Internal Error: could not find free spot! Please report this bug.'

		if !@props.fixed
			@increaseMatrixSize(h)
			return @getSpot(w,h)
		else
			@freeSpot(w,h)
			return @getSpot(w,h,true)





	###
	@addChild method
	add new child and calculate its size and positioning.
	###	
	addChild: (child,index)->
		if !child
			throw new Error 'props.children can only be GridItems.'
		[child.attributes.r,child.attributes.c] = @getSpot(child.attributes.w,child.attributes.h)
		@state.children_map[child.attributes.key] = child
	
		@fillSpot(child)




	# setChild: (child,index)->
	# 	if !child
	# 		throw new Error 'props.children can only be GridItems.'
		
	# 	ch = child.attributes.h
	# 	cw = child.attributes.w
	# 	row = child.attributes.r
	# 	col = child.attributes.c
	# 	o_p = @state.child_props[index]
		
	# 	@removeIndex(o_p.r,o_p.c,o_p.h,o_p.w)
	# 	@removeIndex(row,col,ch,cw)
		
	# 	@state.child_props[index] = 
	# 		r: row
	# 		c: col
	# 		w: cw
	# 		h: ch
		
	# 	@fillSpot(cw,ch,row,col,index)


	###
	@setChildren method
	reset state, and readd all children
	###
	setChildren: (children)->
		# @flushState()
		for child,i in children
			@addChild(child,i)
		@props.children = children
		return true



	# append children, ***does not check already existing children!** the grid is implied to have static children, otherwise we would need to recalculate everything each render.
	appendChildrenUpdate: (children)->
		# append from last array length.
		for i in [@props.children.length...children.length]
			@addChild(children[i],i)
		
		# when overwriting spots in a fixed grid, make sure empty spots are filled
		if @props.fixed
			@fillEmptySpots()
		
		@props.children = children #set the new children!
		return true
	
	# same as append but added to the beginning of the grid instead of the end.
	prependChildrenUpdate: (children)->
		@children = children
		for i in [0...children.length-@props.children.length]
			@addChild(children[i],-1)
		
		# when overwriting spots in a fixed grid, make sure empty spots are filled
		if @props.fixed
			@fillEmptySpots()
		
		@props.children = children #set the new children!
		return true

	###
	@roundDim method
	pixel rounding.
	###
	roundDim: (d)->
		rd = (Math.round(d) - d)
		if rd > -0.5 && rd < 0
			d = Math.round(d+0.5)
		else
			d = Math.round(d)

		return d
	

	###
	@getDim method
	get a single unit size in pixels relative to the outer container size. 
	###
	getDim: ()=>

		if !@_outer
			return 0
		if @props.vert
			d = @_outer.clientWidth / @props.size
		else
			d = @_outer.clientHeight / @props.size
		
		@roundDim(d)

	###
	@getDim method
	get a single unit size in pixels relative to the outer container length. 
	###	
	getLengthDim: ()=>
		if !@_outer
			return 0
		if @props.vert
			if @props.fixed
				d = @_outer.clientHeight / @props.length
			else
				d = @props.dim || @_outer.clientWidth / @props.size
		else
			if @props.fixed
				d = @_outer.clientWidth / @props.length
			else
				d = @props.dim || @_outer.clientHeight / @props.length


		@roundDim(d)



	###
	@getDim method
	the inner container size depends on how many rows of items the grid has. as soon as inner container height is set, the outer wrapper becomes scrollable.
	###
	getInnerSize: ()->
		@getLengthDim() * @state.matrix.length + @props.endPadding + @props.startPadding



	updateChildAttributes: (child)->
		# child.attributes.r = @state.child_props[child.attributes.key].r
		# child.attributes.c = @state.child_props[child.attributes.key].c
		child.attributes.show = if (@props.fixed || !@props.animate) then true else @isChildAnimationVisible(child)
		return child




		



		

	# recalculate grid when items have changed.
	updateGrid: (oldProps,newProps)->
		
		# different grid key means that we need to set the children again.
		# if newProps.children.length < oldProps.children.length #a precaution.
		# 	if @props.fixed
		# 		@setChildren(newProps.children)
		# 		@state.display_children = @props.children
		# 		@setFixedDisplayChildren()
		# 	else
		# 		@setChildren(newProps.children)
		# 		@setDisplayChildren()
		

		# append/prepend new children
		if newProps.children.length > oldProps.children.length
			if @props.fixed

				# preact-grid lazy check to see if we are prepending or appending new children
				if newProps.children[0] && oldProps.children[0] && newProps.children[0].key != oldProps.children[0].key
					@prependChildrenUpdate(newProps.children)
				else 
					@appendChildrenUpdate(newProps.children)
				@setFixedDisplayChildren()
			else
				if newProps.children[0] && oldProps.children[0] && newProps.children[0].key != oldProps.children[0].key
					@prependChildrenUpdate(newProps.children)
				else 
					@appendChildrenUpdate(newProps.children)
				
				# update the display children
				@setDisplayChildren()
		

		else if @props.fixed
			for child in @state.display_children
				if !child
					continue
				c_attr = child.attributes
				r = @state.children_map[c_attr.key].r
				c = @state.children_map[c_attr.key].c
				




				# if @state.child_props[c_attr.i] && c_attr.r? && c_attr.c? && (@state.child_props[c_attr.i].r != c_attr.r || @state.child_props[c_attr.i].c != c_attr.c)
				# 	@setChild(child,child.attributes.i)
				# 	if !@stop_fill
				# 		@fillEmptySpots()
				# 	@setFixedDisplayChildren()


	#same as set display children but for fixed grids.
	setFixedDisplayChildren: ()=>
		@state.display_children = []
		added = {}
		arr = @state.matrix
		for row in [0...@props.length]
			for col in [0...@props.size]
				index = arr[row][col]
				if index == -1
					continue
				if added[index]
					continue
				added[index] = true
				
				@state.display_children.push @children[index]


	#calculate which children get rendered based on scroll position and container/child size. The offset in units is managed with bufferOffsetCells
	setDisplayChildren: ()=>
		if @props.vert
			outer_size = @_outer.clientHeight
			outer_scroll = @_outer.scrollTop
		else
			outer_size = @_outer.clientWidth
			outer_scroll = @_outer.scrollLeft			

		dim = @getLengthDim()



		# current min row
		r_start = _clamp(Math.round( (outer_scroll) / dim ) - 1, 0, @state.matrix.length-1)
		
		#current max row
		r_end = _clamp(Math.round( (outer_scroll + outer_size) / dim ) + 1, 0, @state.matrix.length-1)


		

		if r_start > @state.row_min && r_end < @state.row_max
			return false

		# the new min row
		@state.row_min = _clamp(Math.round( (outer_scroll) / dim ) - @props.bufferOffsetCells, 0, @state.matrix.length-1)
		
		# the new  row
		@state.row_max = _clamp(Math.round( (outer_scroll + outer_size) / dim ) + @props.bufferOffsetCells, 0, @state.matrix.length-1)
		
		
		@state.display_children = []
		added = []

		
		# get children between the start row and end row and set them as the display children to pass to render.
		for row in [@state.row_min...@state.row_max]
			for spot in @state.matrix[row]
				if !@props.children[spot]
					continue
				if spot == -1
					continue
				if !(added[spot]?)
					added[spot] = true
					# if !@state.scroll_up
					# 	@props.children[spot].attributes.top = true
					@state.display_children.push @updateChildAttributes(@props.children[spot])
					# else
					# 	@props.children[spot].attributes.top = false
					# 	@state.display_children.unshift(@updateChildAttributes(@props.children[spot]))
		
		return true



	# adjust the scroll position of the grid when it is resized.
	adjustResizedScrollPosition: ->
		size = if @props.vert then @_outer.clientWidth else @_outer.clientHeight
		if size != @state.size
			diff = size / @state.size
			@state.size = size
			if @props.vert
				@_outer.scrollTop *= diff
			else
				@_outer.scrollLeft *= diff


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
		@updateGrid(@props,newProps)



	#after grid has been updataed.
	componentDidUpdate: (oldProps)->
		# console.log 'GRID UPDATED'
		@adjustResizedScrollPosition()
		@_dim = @getDim()
		@_l_dim = @getLengthDim()
		@_rect = @_outer.getBoundingClientRect()



	#check if child is visible for the animation based on its size and position relative to the outer container and the propery animationOffsetCellBeta
	isChildAnimationVisible: (child)->

		# since we only check the visibility of children which are already in the buffer, we can just set their visibility to true if we are not animating.
		if @props.animate == false
			return true


		outer_size = if @props.vert then @_outer.clientHeight else @_outer.clientWidth
		scroll_pos = if @props.vert then @_outer.scrollTop else @_outer.scrollLeft
		if !@_outer
			return false

		
		dim = @getLengthDim()
		offset = dim * @props.animationOffsetCellBeta
		if child.attributes.r * dim + dim * child.attributes.h < scroll_pos - offset
			return false

		if child.attributes.r * dim > scroll_pos + outer_size + dim + offset
			return false

		return true
	

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
		outer_props.onMouseMove = @onMouseMove

		return outer_props


	# calculate the properties of the inner container.
	getInnerProps: ->
		if @props.vert
			if @props.fixed
				height = '100%'
				width = '100%'
			else
				height = @getInnerSize()+'px'
				width = '100%'
		else
			if @props.fixed
				width = '100%'
				height = '100%'
			else
				width = @getInnerSize()+'px'
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

