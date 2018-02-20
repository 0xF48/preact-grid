{Component,h,render} = require 'preact'
require './test.less'
Slide = require 'preact-slide'
{Grid,GridItem} = require '../source/preact-grid.coffee'
DIM = 40



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






class Test extends Component
	render: ->
		scrollable_list_items = [0...1000].map (i)->
			c = Math.floor(255 - rand()*40)
			h GridItem,
				w: 1
				h: 1
				key: i
				h Slide,
					style:
						background: "rgb(#{c},#{c},#{c-100}"
					className: 'grid-item'
					center: yes
					i
		
		scrollable_grid_items = [0...1000].map (i)->
			c = Math.floor(255 - rand()*40)
			h GridItem,
				w: Math.floor(1+rand()*2)
				h: Math.floor(1+rand()*2)
				key: i
				h Slide,
					style:
						background: "rgb(#{c-100},#{c},#{c}"
					className: 'grid-item'
					center: yes
					i

		scrollable_slist_items = [0...1000].map (i)->
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
		
		scrollable_sgrid_items = [0...1000].map (i)->
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

		scrollable_list = h Grid,
			className: 'grid'
			size: 1
			dim: 100
			variation: 0
			scrollable_list_items
		
		scrollable_grid = h Grid,
			className: 'grid'
			size: 4
			variation: 0
			scrollable_grid_items

		scrollable_sticky_list = h Grid,
			className: 'grid'
			size: 1
			dim: 100
			variation: 0
			scrollable_slist_items
		
		scrollable_sticky_grid = h Grid,
			className: 'grid'
			size: 4
			variation: 0
			scrollable_sgrid_items


		
		h Slide,
			className: 'main'
			vert: yes
			h Slide,
				center: yes
				dim: DIM
				'stats:'

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
				h Slide,
					vert: yes
					h Slide,
						center: yes
						dim: DIM
						'scrollable grid with stickies'
					h Slide,
						className: 'grid-wrap'
						scrollable_grid
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