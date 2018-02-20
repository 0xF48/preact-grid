{h,Component} = require 'preact'

DEFAULT_PROPS =
	vert: yes
	className: null
	fixed: no
	bufferOffsetUnits: 4
	animationOffsetUnitsBeta: 2
	ease: '0.4s cubic-bezier(.29,.3,.08,1)'
	size: 4
	length: 5
	animate: yes
	variation: 1



# math clamp helper
_clamp = (n,min, max)->
	return Math.min(Math.max(n, min), max)







###
@Grid class
scrollable / fixed information flow grid
###
class Grid extends Component
	constructor: (props)->
		super(props)
		@state =
			min_row_index: 0
			display_children: []
			index_array: []
			child_props: []
			inner_width: 0
			arr_len: 0


	###
	@getChildContext method
	###
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


	###
	@componentWillRecieveProps method
	###
	componentWillRecieveProps: (props)->
		if props.innerClass
			props.iclass = props.innerClass
		if props.outerClass
			props.oclass = props.outerClass
		if props.className
			props.oclass = props.className
		if props.outerClass
			props.oclass = props.outerClass


	###
	@checkSpot method
	check to see if spot is taken
	###	
	checkSpot: (r,c,w,h)->
		arr = @state.index_array

		if arr[r][c] > -1
			return false

		for row in [r...r+h]
			for col in [c...c+w]
				if arr[row]? && arr[row][col]?
					if arr[row][col] > -1
						return false
				else
					return false

		return true


	###
	@fillSpot method
	fill a particular spot with index reference
	###	
	fillSpot: (w,h,r,c,index)->
		arr = @state.index_array
		for row in [r...r+h]
			for col in [c...c+w]
				if arr[row]? && arr[row][col]?
					arr[row][col] = index

	

	###
	@buildFixedIndexArray method
	create fixed index array and fill it with empties.
	###	
	buildFixedIndexArray: ()->
		for row in [0...@props.length]
			@state.index_array[row] = @state.index_array[row] || []
			for col in [0...@props.size]
				@state.index_array[row][col] = -1



	removeIndex: (r,c,h,w)->
		arr = @state.index_array
		for row in [r...r+h]
			for col in [c...c+w]
				index = arr[row][col]
				
				if index == -1
					continue
				c_w = @children[index].attributes.w
				c_h = @children[index].attributes.h
				c_r = @state.child_props[index].r
				c_c = @state.child_props[index].c
				@state.child_props[index] = undefined

				# log c_w,c_h,c_r,c_c
				for row2 in [c_r...c_r+c_h]
					for col2 in [c_c...c_c+c_w]
						arr[row2][col2] = -1


	findHiddenChild: (w,h)->

		if !@props.fixed
			throw new Error 'findHiddenChild props.fixed == false'

		for i in [@children.length-1...0]
			c = @children[i]
			if c.attributes.w <= w && c.attributes.h <= h && !@state.child_props[c.attributes.i]
				return [c,i]
			
					

		return [null]




	fillEmptySpots: ()->
		
		arr = @state.index_array
		for row in [0...arr.length]
			for col in [0...arr[row].length]
				if arr[row][col] == -1
					cw = 1
					ch = 1
					while arr[row][col+cw] == -1
						cw++
						while arr[row+ch] && arr[row+ch][col] == -1
							cw_i = 0
							while cw_i++ && cw_i < cw
								if !arr[row+ch][col+cw_i]
									return
							ch++
					# log cw,ch
					@addChild(...@findHiddenChild(cw,ch))



	###
	@freeSpot method
	free up a particular spot,
	rank each spot based on lowest index and size
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
						if arr[c_row][c_col] == -1
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




	###
	@addSpots method
	add a certain amount of spots to the index array
	###	
	addSpots: (h,arr)->
		for i in [0...h]
			row = []
			for c in [0...@props.size]
				row[c] = -1
			arr.push row



	###
	@getSpot method
	get a spot, if there arent any existing spots, create a new ones until there is enough space.
	###
	getSpot: (w,h,test)->
		arr = @state.index_array
		# log 'getSpot',w,h
		min_r_i = 0 #min row index
		found = false #found spot
		row_filled = true #row filled 


		
		if !@props.fixed && (arr.length - @state.min_row_index) < h
			@addSpots(h,arr)

		

		for row in [@state.min_row_index...arr.length]
			for spot,col in arr[row]
				if spot > -1
					row_filled = false #row is filled
				else if @checkSpot(row,col,w,h,arr)
					return [row,col]
			if row_filled
				@state.min_row_index = row

		if test
			throw 'could not find free spot?'

		if !@props.fixed
			@addSpots(h,arr)
			return @getSpot(w,h,arr)
		else
			@freeSpot(w,h,arr)
			return @getSpot(w,h,arr,true)


	###
	@flushState method
	reset the state
	###
	flushState: ()->
		@state.display_children = []
		@state.index_array = []
		@state.min_row_index = 0
		@state.row_h = null
		@state.row_n = null
		@state.row_start = null
		@state.row_end = null
		@state.offset_update = null

		if @props.fixed
			@buildFixedIndexArray()



	###
	@addChild method
	add new child and calculate its size and positioning.
	###	
	addChild: (child,index)->
		
		if !child
			return false
		cw = child.attributes.w
		ch = child.attributes.h

		[row,col] = @getSpot(cw,ch)

	
		@state.child_props[index] = 
			r: row
			c: col
			w: cw
			h: ch
		
		@fillSpot(cw,ch,row,col,index)



	# clearChildFromArray: (child)->
	# 	arr = @state.index_array
	# 	for row in [0...arr.length]
	# 		for col in [0...arr[row].length]
	# 			if arr[row][col] == child.attributes.i
	# 				arr[row][col] = -1


	setChild: (child,index)->
		if !child
			return false
		
		ch = child.attributes.h
		cw = child.attributes.w
		row = child.attributes.r
		col = child.attributes.c
		o_p = @state.child_props[index]
		
		@removeIndex(o_p.r,o_p.c,o_p.h,o_p.w)
		@removeIndex(row,col,ch,cw)
		
		@state.child_props[index] = 
			r: row
			c: col
			w: cw
			h: ch
		
		@fillSpot(cw,ch,row,col,index)


	###
	@setChildren method
	reset state, and readd all children
	###
	setChildren: (children)->
		@children = children
		# log 'set'
		@state.arr_len = children.length
		@flushState()
		for child,i in children
			@addChild(child,i)
		return children


	###
	@appendChildren method
	append children, do not reset state but check to see if child has been already added and its parameters are set.
	###
	appendChildren: (children)->
		@children = children
		for i in [@state.arr_len...children.length]
			@addChild(children[i],i)

		@state.arr_len = children.length
		if @props.fixed
			@fillEmptySpots()
		return children


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
		@getDim() * @state.index_array.length


	###
	@offsetChildren method
	calculate wich children get rendered based on scroll position and container/child size. The offset in units is managed with bufferOffsetUnits
	###
	offsetChildren: (children)=>
		if @props.vert
			outer_size = @_outer.clientHeight
			outer_scroll = @_outer.scrollTop
		else
			outer_size = @_outer.clientWidth
			outer_scroll = @_outer.scrollLeft			

		dim = @getLengthDim()

		# console.log dim
		
	
		
		r_start = _clamp(Math.round( (outer_scroll) / dim ) - 1, 0, @state.index_array.length-1)
		r_end = _clamp(Math.round( (outer_scroll + outer_size) / dim ) + 1, 0, @state.index_array.length-1)

		# console.log r_end,@state.row_end

		# console.log r_start,@state.row_start,',',r_end,@state.row_start
		if r_start > @state.row_start && r_end < @state.row_end
			@state.offset_update = false
			# console.log 'dont update'
			return @state.display_children

		@state.row_start = _clamp(Math.round( (outer_scroll) / dim ) - @props.bufferOffsetUnits, 0, @state.index_array.length-1)
		@state.row_end = _clamp(Math.round( (outer_scroll + outer_size) / dim ) + @props.bufferOffsetUnits, 0, @state.index_array.length-1)
		

		@state.offset_update = true


		# @state.row_start = row_start
		# @state.row_end = row_end
		


		display_children = []
		added = []
		

		for row in [@state.row_start...@state.row_end]
			for spot in @state.index_array[row]
				if !children[spot]
					continue
				if spot == -1
					continue
				if !(added[spot]?)
					added[spot] = true
					if @state.scroll_up
						children[spot].attributes.top = true
						display_children[display_children.length] = children[spot]
					else
						children[spot].attributes.top = false
						display_children.unshift(children[spot])
		

		return display_children

	###
	@offsetFixedChildren method
	add all display children from unit matrix. 
	###
	setFixedDisplayChildren: ()=>
		@state.display_children = []
		added = {}
		arr = @state.index_array
		for row in [0...@props.length]
			for col in [0...@props.size]
				index = arr[row][col]
				if index == -1
					continue
				if added[index]
					continue
				added[index] = true
				
				@state.display_children.push @children[index]

		

	###
	@updateGrid method
	update/recalculate grid when component is updated.
	###
	updateGrid: (oldProps,newProps)->

		force_fill = false

		if newProps.children.length > @state.arr_len && oldProps.key == newProps.key
			if @props.fixed
				@appendChildren(newProps.children)
				@setFixedDisplayChildren()
			else
				@state.display_children = @offsetChildren(@appendChildren(newProps.children))
		else if oldProps.key != newProps.key
			if @props.fixed
				@setChildren(newProps.children)
				@setFixedDisplayChildren()
			else
				@state.display_children = @offsetChildren(@setChildren(newProps.children))			
		else
			for child in @state.display_children
				if !child
					continue
				
				
				
				c_attr = child.attributes
				if @state.child_props[c_attr.i] && c_attr.r? && c_attr.c? && (@state.child_props[c_attr.i].r != c_attr.r || @state.child_props[c_attr.i].c != c_attr.c)
					# log 'set child'
					@setChild(child,child.attributes.i)
					force_fill = true

			

		if force_fill
			if !@stop_fill
				@fillEmptySpots()
			@setFixedDisplayChildren()
			
		# if oldProps.children.length != newProps.children.length || oldProps.list_key != newProps.list_key
		# 	if @props.fixed
		# 		@state.display_children = @offsetFixedChildren(@setChildren(newProps.children))
		# 	else
		# 		@state.display_children = @offsetChildren(@setChildren(newProps.children))

		# else if oldProps.appendChildren.length != newProps.appendChildren.length
		# 	if @props.fixed
		# 		@state.display_children = @offsetFixedChildren(@appendChildren(newProps.children))
		# 	else
		# 		@state.display_children = @offsetChildren(@appendChildren(newProps.children))


	###
	@onScroll method
	update/recalculate grid when component is updated.
	###
	onScroll: ()=>
		outer_scroll = if @props.vert then @_outer.scrollTop else @_outer.scrollLeft
		if @state.last_scroll > outer_scroll
			@state.scroll_up = true
		else
			@state.scroll_up = false
		@state.last_scroll = outer_scroll
		@state.display_children = @offsetChildren(@props.children)
		if @state.offset_update
			@forceUpdate()


	onMouseMove: (e)=>
		if !@props.onUnitMouseEnter
			return
		@_rect = @_outer.getBoundingClientRect()
		c = Math.floor((e.clientX - @_rect.x) / @_dim)
		r = Math.floor((e.clientY - @_rect.y) / @_l_dim)
		
		if @_mouse_c != c || @_mouse_r != r
			@props.onUnitMouseEnter(r,c,@state.index_array[r]?[c])

		@_mouse_c = c
		@_mouse_r = r
	



	###
	@componentDidMount method
	update/recalculate grid when component is updated.
	###
	componentDidMount: ()->
		if @props.fixed 
			@state.display_children = @setChildren(@props.children)
		else
			@state.display_children = @offsetChildren(@setChildren(@props.children))
			# console.log @state.display_children
		
		@forceUpdate()
	

	###
	@componentWillUpdate method
	###
	componentWillUpdate: (newProps)->
		@updateGrid(@props,newProps)


	###
	@componentDidUpdate method
	###
	componentDidUpdate: (oldProps)->
		size = if @props.vert then @_outer.clientWidth else @_outer.clientHeight
		if size != @state.size
			diff = size / @state.size
			@state.size = size
			if @props.vert
				@_outer.scrollTop *= diff
			else
				@_outer.scrollLeft *= diff

		@_dim = @getDim()
		@_l_dim = @getLengthDim()
		@_rect = @_outer.getBoundingClientRect()


	###
	@childVisible decide if child is visible based on its size and position relative to the outer container
	###
	childVisible: (child)->
		outer_size = if @props.vert then @_outer.clientHeight else @_outer.clientWidth
		scroll_pos = if @props.vert then @_outer.scrollTop else @_outer.scrollLeft
		if !@_outer
			return false

		
		dim = @getLengthDim()
		offset = dim * @props.animationOffsetUnitsBeta
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


	###
	@render method
	###
	render: ()=>
		

		for child,i in @state.display_children
			if child
				child.attributes.r = @state.child_props[child.attributes.key].r
				child.attributes.c = @state.child_props[child.attributes.key].c
				child.attributes.show = if @props.fixed then true else @childVisible(child)



		if @props.show_loader
			stop_loader  = @props.max_reached && @max_scroll_pos >= @total_max_pos && '-i-loader-stop' || ''
			loader = h 'div',
				className: "-i-loader #{stop_loader||''}"


		@state.offset_update = false
		if @props.vert
			inner_style =
				height: if !@props.fixed then (@getInnerSize()+'px') else '100%'
		else
			inner_style =
				width: if !@props.fixed then (@getInnerSize()+'px') else '100%'
		h 'div',
			key: @key
			ref: @outer_ref
			onScroll: @onScroll
			onMouseMove: @onMouseMove
			className: "-i-grid #{@props.vert && '-i-grid-vert' || ''} #{@props.fixed && '-i-grid-fixed' || ''} #{@props.className || @props.outerClassName}"
			h 'div',
				style: inner_style
				ref: @inner_ref
				className: "-i-grid-inner #{ @props.innerClassName || '' }"
				@state.display_children
				loader


Grid.defaultProps = DEFAULT_PROPS

module.exports = Grid

