const fs = require('fs')
const path = require('path')
const HtmlPlugin = require('html-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const merge = require('webpack-merge')
const webpack = require('webpack')
const OptimizeCssAssetsPlugin = require('optimize-css-assets-webpack-plugin')
const UglifyJsPlugin = require('uglifyjs-webpack-plugin')
const CompressionPlugin = require('compression-webpack-plugin')

// Make sure any symlinks in the project folder are resolved:
// https://github.com/facebookincubator/create-react-app/issues/637
const appRoot = fs.realpathSync(process.cwd())
const resolveApp = (relativePath) => path.resolve(appRoot, relativePath)

const paths = {
    // Folders
    appPublic: resolveApp('./public'),
    appBuild: resolveApp('./build/Client'),
    appSrc: resolveApp('./src/Client'),

    // Files
    appHtml: resolveApp('./src/Client/index.html'),
    appIndexJs: resolveApp('./src/Client/index.js'),

    // Elm
    elmJson: resolveApp('./elm.json'),

    // publicUrl: getPublicUrl(resolveApp('elm-package.json')),
    // servedPath: getServedPath(resolveApp('elm-package.json')),
}

const common = {
    entry: paths.appIndexJs,
    output: {
        path: paths.appBuild,
        publicPath: '/',
    },
    resolve: {
        modules: ['node_modules'],
    },
    plugins: [
        new HtmlPlugin({
            inject: true,
            template: paths.appHtml,
        }),
        new MiniCssExtractPlugin({
            filename:
                process.env.NODE_ENV === 'development'
                    ? '[name].css'
                    : // Must use contenthash when using MiniCssExtract to
                      // ensure file invalidates when contents change.
                      '[name].[contenthash:8].css',
        }),
    ],
    module: {
        noParse: /\.elm$/,
        rules: [
            {
                test: /\.js$/,
                include: paths.appSrc,
                use: {
                    loader: require.resolve('ts-loader'),
                    options: {
                        transpileOnly: true,
                        configFile: path.resolve(__dirname, './tsconfig.json'),
                        compilerOptions: {
                            sourceMap: true,
                        },
                    },
                },
            },
            {
                test: /\.elm$/,
                include: paths.appSrc,
                loader: require.resolve('elm-webpack-loader'),
                options: {
                    // Shows the model history overlay
                    debug: process.env.NODE_ENV === 'development',
                    optimize: process.env.NODE_ENV === 'production',
                    cwd: paths.appRoot,
                    pathToElm: path.join(__dirname, './node_modules/.bin/elm'),
                },
            },
            {
                test: /\.(css|scss|sass)$/,
                use: [
                    process.env.NODE_ENV === 'production'
                        ? MiniCssExtractPlugin.loader
                        : require.resolve('style-loader'),
                    {
                        loader: require.resolve('css-loader'),
                        options: { sourceMap: true },
                    },
                    {
                        loader: require.resolve('sass-loader'),
                        options: { sourceMap: true },
                    },
                ],
            },
            {
                // TODO: oneOf the rules so that we can just have
                // the file-loader as a catch-all fallback.
                test: /\.(woff|woff2|eot|ttf|otf|svg)$/,
                loader: require.resolve('file-loader'),
            },
        ],
    },
}

const development = merge(common, {
    mode: 'development',
    watch: true,
    devtool: 'cheap-module-source-map',
    devServer: {
        watchOptions: {
            ignored: [__dirname + '/src/Server/**'],
        },
    },
    output: {
        filename: '[name].js',
    },
    plugins: [new webpack.HotModuleReplacementPlugin()],
})

const production = merge(common, {
    mode: 'production',
    // Don't attempt to continue if there are any errors.
    bail: true,
    devtool: 'source-map',
    output: {
        path: paths.appBuild,
        filename: '[name].[chunkhash:8].js',
    },
    plugins: [
        new OptimizeCssAssetsPlugin(),
        new CompressionPlugin({
            include: /\.(css|js)$/,
        }),
    ],
    optimization: {
        minimizer: [
            new UglifyJsPlugin({
                uglifyOptions: {
                    mangle: true,
                    compress: {
                        passes: 2,
                        unsafe: true,
                        unsafe_comps: true,
                        keep_fargs: false,
                        pure_getters: true,
                        pure_funcs: [
                            'F2',
                            'F3',
                            'F4',
                            'F5',
                            'F6',
                            'F7',
                            'F8',
                            'F9',
                            'A2',
                            'A3',
                            'A4',
                            'A5',
                            'A6',
                            'A7',
                            'A8',
                            'A9',
                        ],
                    },
                },
            }),
        ],
    },
})

module.exports =
    process.env.NODE_ENV === 'production' ? production : development
