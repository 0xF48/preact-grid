{h} = require 'preact'

require './SquareLoaderIcon.less'
class LoadIcon
	render: (props)->
		cn = '-i-loader'
		if props.vert
			cn += ' -i-loader-vert'
		if props.stop
			cn += ' -i-loader-stop '

		h 'div',
			className: cn
			null





module.exports = LoadIcon