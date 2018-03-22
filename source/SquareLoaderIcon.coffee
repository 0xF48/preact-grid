{h} = require 'preact'
require './SquareLoaderIcon.less'
class SquareLoaderIcon
	render: (props)->
		h 'div',
			className: '-ii-loader '+(props.stop && '-ii-loader-stop' || '') + (' '+(@props.className||''))

module.exports = SquareLoaderIcon