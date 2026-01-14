const { generateWebpackConfig, merge } = require('shakapacker')
const webpackConfig = generateWebpackConfig()


const customConfig = {
  output: {
    publicPath: 'auto'
  },
  resolve: {
    fallback: { "util": false },
    extensions: ['.jsx', '.mjs', '.js', '.sass', '.scss', '.css', '.module.sass', '.module.scss', '.module.css', '.png', '.svg', '.gif', '.jpeg', '.jpg']
  }
}

module.exports = merge(webpackConfig, customConfig)
