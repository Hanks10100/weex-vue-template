const path = require('path')
const webpack = require('webpack')
const VueLoaderPlugin = require('vue-loader/lib/plugin')
const UglifyJSPlugin = require('uglifyjs-webpack-plugin')

function generateConfig (type) {
  const webpackConfig = {
    entry: {
      [type]: './src/index.js',
      // [`${type}.min`]: './src/index.js',
    },
    output: {
      path: path.resolve(__dirname, 'dist'),
      filename: 'bundle.[name].js'
    },
    mode: 'production',
    optimization: { minimize: false },
    externals: { vue: 'Vue' },
    resolve: {
      extensions: ['.js', '.json']
    },
    module: {
      rules: [
        {
          test: /\.vue$/,
          use: [type === 'weex' ? 'weex-loader' : {
            loader: 'vue-loader',
            options: {
              cssSourceMap: false,
              productionMode: true,
              optimizeSSR: false,
              hotReload: false,
              compilerOptions: {
                modules: [{
                  postTransformNode: el => {
                    // to convert vnode for weex components.
                    require('weex-vue-precompiler')()(el)
                  }
                }]
              }
            }
          }]
        }, {
          test: /\.js$/,
          use: ['babel-loader'],
          exclude: file => (
            /node_modules/.test(file)
          )
        }, {
          test: /\.css$/,
          use: ['style-loader', 'css-loader', {
            loader: 'postcss-loader',
            options: {
              indent: 'postcss',
              plugins: [
                // to convert weex exclusive styles.
                require('postcss-plugin-weex')(),
                require('autoprefixer')({
                  browsers: ['> 0.1%', 'ios >= 8', 'not ie < 12']
                }),
                require('postcss-plugin-px2rem')({
                  // base on 750px standard.
                  rootValue: 75,
                  // to leave 1px alone.
                  minPixelValue: 1.01
                })
              ]
            }
          }]
        }, {
          test: /\.scss$/,
          use: ['vue-style-loader', 'css-loader', 'sass-loader']
        }
      ]
    },
    plugins: [
      // new UglifyJSPlugin({
      //   parallel: true,
      //   // include: /\.min\.js$/,
      //   include: /web\.min\.js$/,
      //   // uglifyOptions: { }
      // }),
      new webpack.BannerPlugin({
        raw: true,
        entryOnly: true,
        banner: '// { "framework": "Vue" }\n"use weex:vue";\n'
      })
    ]
  }
  if (type === 'web') {
    webpackConfig.plugins.unshift(new VueLoaderPlugin())
  }
  return webpackConfig
}

module.exports = [
  generateConfig('weex'),
  generateConfig('web')
]
