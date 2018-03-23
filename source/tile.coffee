#a javascript utility library to manage tile grids with arbitrary data.


DEFAULT_OPT = 
	x2: 3
	y2: 3

_clamp = (n,min,max)->
	return Math.min(Math.max(n, min), max)


# base rect class ith "bounds".
class Rect
	constructor: (x1,x2,y1,y2)->
		@set(x1,x2,y1,y2)
	
	set: (x1,x2,y1,y2)->
		@x1 = x1 || 0
		@x2 = x2 || 0
		@y1 = y1 || 0
		@y2 = y2 || 0
		return @

	copy: (rect)->
		@x1 = rect.x1
		@x2 = rect.x2
		@y1 = rect.y1
		@y2 = rect.y2		
		return @

	normalize: ->
		if @x1 < 0
			@x2 -= @x1
			@x1 = 0
		if @y1 < 0
			@y2 -= @y1
			@y1 = 0
		return @

	loopMatrix: (matrix,cb,argA,argB,argC)->
		# log @y1,@y2
		for y in [@y1...@y2]
			if y < 0 then continue
			if y > matrix.length then return false
			for x in [@x1...@x2]
				if matrix[y][x] == undefined then continue
				if cb(matrix[y][x],x,y,argA,argB,argC) == false
					log 'ret'
					return false
		return true

	loopRect: (cb,argA,argB,argC)->
		for y in [@y1...@y2]
			for x in [@x1...@x2]
				if cb(x,y,argA,argB,argC)
					return false
		return true


# tile class, added as items in grid
class Tile extends Rect
	constructor: (opt)->
		opt.x2 = opt.width
		opt.y2 = opt.height
		super(0,opt.width,0,opt.height)
		@item = opt.item
		@rect = opt.rect || null
		# if @x2 == 0 + @y2  0 || @x1 < 0 || @y1 < 0
		# 	throw new Error 'bad tile.'

	setXY: (x,y)->
		@rect.set(x,x+@x2,y,y+@y2)


# main grid class
class TileGrid extends Rect
	constructor: (opt)->

		super()
		
		@check_holes = if opt.check_holes? then opt.check_holes else true
		@_temp = [new Rect,new Rect,new Rect]
		@offset_x = 0
		@offset_y = 0
		
		
		@matrix = [] #2d matrix array that contains references to items in the list.
		# @item_list = [] # a list of items.
		@removed = []


		@full = new Rect(opt.width-1,0,opt.height-1,0) # keep track of what portion of the matrix is full.
		@full.count_x = []
		@full.count_y = []

		@set(0,opt.width,0,opt.height)

	
		

		

	# clear one coordinate from matrix
	clearCoord: (item,x,y)=>
		if @matrix[y][x]
			@decrY(y)
			@decrX(x)
		@matrix[y][x] = null
		return true


	isItemNull: (item)=>
		item == null

	isCoordEmpty: (x,y)=>
		@matrix[y][x] == null

	# set the coordinate item
	setCoordItem: (item,x,y,new_item)=>
		if item then throw new Error 'setCoord, coord taken ['+x+','+y+'] by '+item
		@matrix[y][x] = [new_item,x-new_item.rect.x1,y-new_item.rect.y1] 
		@incrY(y)
		@incrX(x)

	# (perf) decrease full row y value
	decrY: (y)->
		@full.count_y[y]--
		if @full.y1 > y
			@full.y1 = y

		if @full.y2 > y
			@full.y2 = y

	# (perf) decrease
	decrX: (x)->
		@full.count_x[x]--
		if @full.x1 > x
			@full.x1 = x

		if @full.x2 > x
			@full.x2 = x


	# increment row full value and count (all x items on y)
	incrY: (y)->
		@full.count_y[y]++

		# decide the full X/Y coord
		if @full.count_y[y] == @width
			if y < @full.y1
				# check for holes
				if @check_holes
					for yi in [y...@full.y1]
						if @full.count_y[yi] != @width
							return
				@full.y1 = y
				# log 'y1',y
			else
				# check for holes
				if @check_holes
					for yi in [@full.y1...y]
						if @full.count_y[yi] != @width
							return
				@full.y2 = y
				# log 'y2',y
					
	
	# increment column full value and count (all y items on x)
	incrX: (x)->
		@full.count_x[x]++

		# decide the full X/Y coord
		if @full.count_x[x] == @width
			if x < @full.x1
				# check for holes
				if @check_holes
					for xi in [x...@full.x1]
						if @full.count_x[xi] != @width
							return
				@full.x1 = x
			else
				# check for holes
				if @check_holes
					for xi in [@full.x1...x]
						if @full.count_y[xi] != @width
							return
				@full.x2 = x
					





	# clear all items in a rect from the matrix
	clearRect: (rect)->
		rect.loopMatrix(@matrix,@clearItem)


	# clear one item from the matrix
	clearItem: (spot,x,y)=>
		if !spot then return falsel
		item = spot[0]
		sx = x - spot[1]
		sy = y - spot[2]
		if !item.rect
			throw new Error 'cant clear item, item has no rect. '+sx+','+sy

		for iy in [sy...sy+item.y2]
			for ix in [sx...sx+item.x2]
				@clearCoord(item,ix,iy)

		item.rect = null
		# @removed.push item
		

	# clear a row from matrix
	clearY: (y)->
		for item,x in @matrix[y]
			@clearItem @matrix[y][x],x,y


	# clear any items in a column that are also in column x2
	clearLinkedX: (x,x2)->
		for row,y in @matrix
			if row[x] && row[x2] && row[x2][0] == row[x][0]
				@clearItem row[x],x,y


	# clear any items in a column that are also in column x2
	clearLinkedY: (y,y2)->
		for spot,x in @matrix[y]
			if spot && @matrix[y2] && @matrix[y2][x][0] == spot[0]
				@clearItem spot,x,y
				

	# clear a column from matrix
	clearX: (x)->
		for row,y in @matrix
			@clearItem row[x],x,y


	# insert column(s) into matrix
	insertX: (pos,count)->
		@clearLinkedX(pos,_clamp(pos-1,0,@x2-1))
		
		if @full.x1 > pos
			@full.x1 += count
		else
			@full.x1 = @x2-1
		if @full.x2 > pos
			@full.x2 = 0

		@full.y1 = @y2
		@full.y2 = 0

		for i in [0...count]
			@full.count_x.splice(pos,0,0)
			for y in @matrix
				y.splice(pos,0,null)


	# insert row(s) into matrix
	insertY: (pos,count)->
		@clearLinkedY(pos,_clamp(pos-1,0,@y2-1))
		if @full.y1 < pos
			@full.y1 = pos+count
		for i in [0...count]
			@full.count_y.splice(pos,0,0)
			@matrix.splice(pos,0,new Array(@x2).fill(null))


	# set new bounds for matrix.
	set: (x1,x2,y1,y2)->
		if !@height
			@height = 0
		if !@width
			@width = 0
		if @x1 == undefined
			return super(x1,x2,y1,y2)

		diff = new Rect x1 - @x1,x2 - @x2,y1 - @y1,y2 - @y2

		if (diff.y1 - diff.y2) > @height
			throw new Error 'set: Y out of bounds'

		if (diff.x1 - diff.x2) > @width
			throw new Error 'set: X out of bounds'
		
		# log 'diff',diff

		

		
		#diff X2
		if diff.x2 > 0
			for i in [0...diff.x2]
				@full.count_x.push 0
				for y in @matrix
					y.push null
		else if diff.x2 < 0
			for i in [0...diff.x2]
				@clearX(@x2-1+i)
				@full.count_x.pop()
				for y in @matrix
					y.pop()
		@x2 = x2

		#diff X1
		if diff.x1 < 0
			for i in [0...diff.x1]
				@full.count_x.unshift 0
				@full.x2++
				@full.x1++
				@offset_x--
				for row in @matrix
					row.unshift null
						

		else if diff.x1 > 0
			for i in [0...diff.x1]
				@clearX(0)
				@full.x2--
				@full.x1--
				@offset_x++
				@full.count_x.shift()
				for row in @matrix
					row.shift()
		@x1 = x1




		#diff Y2
		if diff.y2 > 0
			for i in [0...diff.y2]
				@full.count_y.push 0
				@matrix.push new Array(@x2-@x1).fill(null)
		else if diff.y2 < 0
			for i in [0...diff.y2]
				@clearY(@y2-1+i)
				@full.count_y.pop()
				@matrix.pop()
			# for i in [0...diff.y2]
		@y2 = y2


		#diff Y1
		if diff.y1 > 0
			for i in [0...diff.y1]
				@clearY(0)
				@full.y2--
				@full.y1--
				@offset_y++
				@full.count_y.shift()
				@matrix.shift()
		else if diff.y1 < 0
			for i in [0...diff.y1]
				@offset_y--
				@full.y2++
				@full.y1++
				@full.count_y.unshift 0
				@full.x1 = 0
				@full.x2 = 0
				@matrix.unshift new Array(@x2-@x1).fill(null)
		@y1 = y1

		@normalize()


		if diff.x2 - diff.x1 > 0
			@full.y1 = @y2-1
			@full.y2 = @y1
		
		if diff.y2 - diff.y1 > 0
			@full.x1 = @x2-1
			@full.x2 = @x1

		@width = @x2
		@height = @y2



	pad: (x1,x2,y1,y2)->
		@set(@x1-x1,@x2+x2,@y1-y1,@y2+y2)





	# find a free rect within bounds, if no rect is found, return null
	# rect x1 and y1 must be normalized.
	findEmptyRect: (rect,bounds,result)->
		rect.normalize()
		for y in [bounds.y1...bounds.y2]
			for x in [bounds.x1...bounds.x2]
				break_rect = false
				for iy in [y+rect.y2-1..y]
					if break_rect
						break
					for ix in [x+rect.x2-1..x]
						if !@matrix[iy]
							break_rect = true
							break
						if @matrix[iy][ix] != null
							break_rect = true
							break
				if break_rect == false
					return result.set(x,x+rect.x2,y,y+rect.y2)

				


	# add an item with a specific bound to look for free space, if the grid is full within the search bounds, callback function will be fired and its return value will decide to either search again with the same callback or to do a final search without the callback.
	addTile: (item,x1,x2,y1,y2)->
		bounds = @_temp[0].set(x1,x2,y1,y2)
		
		# limit search  by the rect that we are trying to find (no overflow searches)
		if bounds.x2 > bounds.x1
			bounds.x2 -= item.x2 - 1
		else
			bounds.x1 -= item.x2 - 1
		
		
		if bounds.y2 > bounds.y1
			bounds.y2 -= item.y2 - 1
		else
			bounds.y1 -= item.y2 - 1

		if bounds.y2 < 0 || bounds.x2 < 0 || bounds.y1 > @y2 || bounds.x1 > @x2
			return false





		result = @_temp[1].set()

		if !@findEmptyRect(item,bounds,result)
			return false
		else
			item.rect = new Rect().copy(result)
			item.rect.loopMatrix(@matrix,@setCoordItem,item)
			# @item_list.push item
			return true

	setTileCb: (bounds)->
		@clearRect(bounds)
		return false
	
	# setTile: (item,x1,y1)->
	# 	@addTile(item,x1,x1+item.x2,y1,y1+item.y2)


	log: ->
		console.log '-----------------\n\n'
		for y in @matrix
			str = y.map (x)->
				return x && String(x[0].item.key) || '- '
			console.log(str.join('     ')+'\n\n')
		console.log '-----------------'





module.exports = {Rect,Tile,TileGrid}