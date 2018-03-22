var webpack = require("webpack");
// const MinifyPlugin = require("babel-minify-webpack-plugin");
var cfg = {
  devtool: 'source-map',
  module: {
    rules: [
      { test: /\.coffee$/, use: "coffee-loader"},
      { test: /\.glsl$/, use: "glsl-template-loader" },
      { test: /\.(xml|html|txt|md)$/, loader: "raw-loader" },
      { test: /\.(less)$/, use: ['style-loader','css-loader','less-loader'] },
      { test: /\.(woff|woff2|eot|ttf|svg)$/,loader: 'url-loader?limit=65000' }
    ]
  },
  entry: {
    main: "./source/site.coffee",
  },
  resolve: {
    // "modules": [__dirname+"/node_modules"],
  },
  output: {
    path: __dirname+'/site/',
    publicPath: '/site/',
    filename: "[name].js"
  },
  devServer: {
    port: 3004
  }
}
module.exports = cfg;