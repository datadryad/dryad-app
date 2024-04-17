const { webpackConfig, merge } = require('@rails/webpacker')
const CopyPlugin = require('copy-webpack-plugin')

const customConfig = {
  plugins: [
    new CopyPlugin({
      patterns: [
        { from: "./node_modules/tinymce", to: "./tinymce" }
      ]
    })
  ],
  resolve: {
    fallback: { "util": false },
    extensions: ['.jsx', '.mjs', '.js', '.sass', '.scss', '.css', '.module.sass', '.module.scss', '.module.css', '.png', '.svg', '.gif', '.jpeg', '.jpg']
  }
}

module.exports = merge(webpackConfig, customConfig)
