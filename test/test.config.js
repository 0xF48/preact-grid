var webpack = require("webpack");
// const MinifyPlugin = require("babel-minify-webpack-plugin");
console.log(__dirname)
var cfg = {
  devtool: 'source-map',
  module: {
    loaders: [
      { test: /\.coffee$/, use: "coffee-loader"},
      { test: /\.glsl$/, use: "glsl-template-loader" },
      { test: /\.(xml|html|txt|md)$/, loader: "raw-loader" },
      { test: /\.(less)$/, use: ['style-loader','css-loader','less-loader'] },
      { test: /\.(woff|woff2|eot|ttf|svg)$/,loader: 'url-loader?limit=65000' }
    ]
  },
  entry: {
    test: "./test/test.coffee",
  },
  resolve: {
    // "modules": [__dirname+"/node_modules"],
  },
  output: {
    path: __dirname,
    publicPath: '/',
    filename: "[name].js"
  },
  devServer: {
    port: 3005,
    publicPath: '/',
    contentBase: __dirname
  }
}
module.exports = cfg;