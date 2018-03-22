var webpack = require("webpack");
var path = require('path');
var fs = require('fs');
var cfg = {
	devtool: 'source-map',
	module: {
		rules: [
			{ test: /\.coffee$/, use: "coffee-loader"},
			{ test: /\.(xml|html|txt|md)$/, loader: "raw-loader" },
			{ test: /\.(less)$/, use: ['style-loader','css-loader','less-loader'] },
			{ test: /\.(css)$/, use: ['style-loader','css-loader'] },
			{ test: /\.(woff|woff2|eot|ttf|svg)$/,loader: 'url-loader?limit=65000' }
		]
	},
	entry: {
		lib: "./source/lib.coffee",
	},
	output: {
		path: path.join(__dirname,"..","/dist/"),
		filename: "lib.js",
		library: 'PreactGrid',
		libraryTarget: 'umd'
	}
}
module.exports = cfg;