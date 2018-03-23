{Component,h,render} = require 'preact'
require './test.less'
Slide = require 'preact-slide'
{MinMaxScrollEvent} = require 'preact-scroll-events'
{Grid,GridItem} = require '../index'
LoadIcon = require '../source/SquareLoaderIcon.coffee'
DIM = 80
window.log = console.log.bind(console)


nums = require './random.json'
rn = 0
rand = ()->
	if rn >= nums.length
		rn = 0
	return nums[rn++]/100

shuffle = (arr)->
	ind = [0...arr.length].map rand
	map = {}
	map[j] = i for i,j in ind
	arr.sort (a,b)->
		if map[a] > map[b] then return -1
		else if map[a] < map[b] then return 1
		return 0

rc = ->
	rand().toString(36).substring(7,8)

# rbg = ->
# 	v = 200
# 	d = 100
# 	v1 = rand() * (v)
# 	v2 = rand() * (v)
# 	v3 = (v - v1 - v2)
# 	c = shuffle([v1,v2,v3])
# 	if rand() < 0.5
# 		c[0] = v2
# 		c[1] = v3
# 		c[2] = v1
# 	else
# 		c[0] = v1
# 	c = [Math.floor(255-d-c[0]),Math.floor(255-d-c[1]),Math.floor(255-d-c[2])]
# 	background: "rgb(#{c[0]},#{c[1]},#{c[2]})"


class Toggle extends Component
	constructor: (props)->
		super(props)
		@state =
			toggle: props.initial

	render: ->
		h 'span',
			className: 'toggle '+(@state.toggle && 'on' || null)
			onClick: =>
				@state.toggle != null && @setState
					toggle: !@state.toggle
				@props.onToggle?(@state.toggle)
			@props.name + (@state.toggle != null && (@state.toggle && ' - on' || ' - off') || '')

class Counter extends Component
	constructor: ->
		super()
		@state =
			total: 0
	update: =>
		total = document.body.querySelectorAll('.-i-grid-item').length
		if @state.total != total
			@setState
				total: total

	componentDidMount: ->
		setInterval @update,1000

	render: ->
		h Toggle,
			initial: null
			name: 'visible count - '+@state.total
	



class LargeGridTest extends Component
	constructor: ->
		super()
		@state =
			total_divs: 0
			use_timeout: yes
			max_reached: no
			use_animate: yes
			prepend: false
			vertical: yes
			key: rc()+rc()
		@list = []
		@appendItems()

	appendItems: ()=>
		log 'append'
		for i in [0...100]
			c = Math.floor(255 - rand()*40)
			@list.push h GridItem,
				w: Math.floor(1+rand()*2)
				h: Math.floor(1+rand()*2)
				key: @list.length
				h Slide,
					center: yes
					style: 
						color: 'black'
						background: "rgb(#{c-100},#{c},#{c}"
					@list.length
				

	# prependItems: ()=>
	# 	l = @list.length
	# 	for i in [0...200]
	# 		c = Math.floor(255 - rand()*40)
	# 		@list.unshift h GridItem,
	# 			w: Math.floor(1+rand()*2)
	# 			h: Math.floor(1+rand()*2)
	# 			key: l + 200 - i
	# 			h Slide,
	# 				style:
	# 					background: "rgb(#{c-100},#{c},#{c}"
	# 				className: 'grid-item'
	# 				center: yes
	# 				l + 200 - i

	onMaxReached: =>
		log 'max reached'
		setTimeout =>
			if @list.length > 1000
				return @setState
					max_reached: yes
			@appendItems()
			@forceUpdate()
		,(@state.use_timeout && 1000 || 0)

	onMinReached: =>
		log 'min reached'
		# return false
		# setTimeout =>
		# 	if @list.length > 5000
		# 		return @setState
		# 			max_reached: yes
		# 	@prependItems()
		# 	@forceUpdate()
		# ,@state.use_timeout && 1000 || 0

	render: ->
		# console.log @list
		grid = h MinMaxScrollEvent,
			vert: @state.vertical
			onMinReached: @onMinReached
			onMaxReached: @onMaxReached
			h Grid,
				className: 'grid'
				key: @state.key
				size: 8
				vert: @state.vertical
				prepend: @state.prepend
				animate: @state.use_animate
				viewRowsOffset: 2
				renderRowsPad: 4
				viewRowsPad: 0
				variation: 1
				endPadding: 40
				postChildren: h Slide,
					style:
						position: 'absolute'
						bottom: 0
						left: 0
					height: 40
					h LoadIcon,
						stop: @state.max_reached
				@list

							
		options = h Slide,
			center: yes
			className: 'opts'
			h Toggle,
				name: 'timeout'
				initial: @state.use_timeout
				onToggle: (v)=>
					@setState
						use_timeout: v
			h Toggle,
				name: @list.length+'/5000'
				initial: null
			h Toggle,
				name: 'grid key (reset): '+@state.key
				initial: null
				onToggle: (v)=>
					@setState
						key: rc()+rc()
			h Toggle,
				name: 'animate'
				initial: @state.use_animate
				onToggle: (v)=>
					@setState
						use_animate: v
			h Toggle,
				name: 'prepend'
				initial: @state.prepend
				onToggle: (v)=>
					@setState
						prepend: v
			h Toggle,
				name: 'vertical'
				initial: @state.vertical
				onToggle: (v)=>
					@setState
						vertical: v
						key: rc()+rc()


		h Slide,
			vert: yes
			h Slide,
				center: yes
				vert: yes
				dim: DIM
				# 'Scrollable grid with stickies and timeout loader (1s). When grid key is changed, the grid is fully recalculated.'
				options
			h Slide,
				className: 'grid-wrap'
				grid



class Test extends Component
	constructor: ->
		super()
		@state =
			total_divs: 0
			use_timeout: yes
			max_reached: no
			use_animate: yes
			append: true
			vertical: yes
			scrollable_grid_key: rc()+rc()
		@buildItems()



	buildItems: ->
		@scrollable_list_items = [0...200].map (i)->
			c = Math.floor(255 - rand()*40)
			h GridItem,
				w: 1
				h: 3
				key: i
				h Slide,
					style:
						background: "rgb(#{c},#{c},#{c-100}"
					className: 'grid-item'
					center: yes
					i

		@scrollable_grid_items = []

		@scrollable_slist_items = [0...200].map (i)->
			c = Math.floor(255 - rand()*40)
			h GridItem,
				w: 1
				h: 1
				key: i
				h Slide,
					style:
						background: "rgb(#{c-100},#{c},#{c-100}"
					className: 'grid-item'
					center: yes
					i
		
		@scrollable_sgrid_items = [0...200].map (i)->
			c = Math.floor(255 - rand()*40)
			h GridItem,
				w: Math.floor(1+rand()*2)
				h: Math.floor(1+rand()*2)
				key: i
				h Slide,
					style:
						background: "rgb(#{c},#{c-100},#{c}"
					className: 'grid-item'
					center: yes
					i







	render: ->
		# console.log 'test'


		scrollable_list = h Grid,
			className: 'grid'
			size: 1
			dim: 40
			variation: 0
			viewRowsOffset: 4
			renderRowsPad: 1
			viewRowsPad: 0
			animate: false
			@scrollable_list_items
		


		scrollable_sticky_list = h Grid,
			className: 'grid'
			size: 1
			dim: 100
			variation: 0
			@scrollable_slist_items
		
		scrollable_sticky_grid = h Grid,
			className: 'grid'
			size: 4
			variation: 1

			dim: 100
			@scrollable_sgrid_items


		
		h Slide,
			className: 'main'
			vert: yes
			
			h Slide,
				center: yes
				dim: DIM
				h Counter

			h Slide,
				vert: no
				h Slide,
					vert: yes
					h Slide,
						center: yes
						dim: DIM
						'scrollable list with stickies'
					h Slide,
						className: 'grid-wrap'
						scrollable_list
				h LargeGridTest
			

					

			h Slide,
				vert: no
				h Slide,
					vert: yes
					h Slide,
						center: yes
						dim: DIM
						'scrollable list without stickies'
					h Slide,
						className: 'grid-wrap'
						scrollable_sticky_list
				h Slide,
					vert: yes
					h Slide,
						center: yes
						dim: DIM
						'scrollable grid without stickies'
					h Slide,
						className: 'grid-wrap'
						scrollable_sticky_grid


@test_el = render(h(Test),document.body,@test_el)