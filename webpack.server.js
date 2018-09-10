const path = require('path')
const merge = require('webpack-merge')
const webpack = require('webpack')
const fs = require('fs')

const { NODE_ENV } = process.env

// Make sure any symlinks in the project folder are resolved:
// https://github.com/facebookincubator/create-react-app/issues/637
const appRoot = fs.realpathSync(process.cwd())
const resolveApp = (relativePath) => path.resolve(appRoot, relativePath)

const paths = {
    // Folders
    appBuild: resolveApp('./build/Server'),
    appSrc: resolveApp('./src/Server'),

    // Files
    appIndexJs: resolveApp('./src/Server/index.js'),
    appPackageJson: resolveApp('package.json'),

    // Elm
    elmJson: resolveApp('./elm.json'),

    // publicUrl: getPublicUrl(resolveApp('elm-package.json')),
    // servedPath: getServedPath(resolveApp('elm-package.json')),
}

console.log(paths)

const common = {
    target: 'node',
    entry: paths.appIndexJs,
    output: {
        filename: 'index.js',
        path: paths.appBuild,
    },
    resolve: {
        modules: ['node_modules'],
    },
    plugins: [],
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
                    debug: NODE_ENV === 'development',
                    optimize: NODE_ENV === 'production',
                    // cwd: "./src/server", //paths.appRoot,
                    pathToElm: path.join(__dirname, './node_modules/.bin/elm'),
                },
            },
        ],
    },
}

const development = merge(common, {
    mode: 'development',
    watch: true,
    devtool: 'cheap-module-source-map',
    plugins: [new webpack.IgnorePlugin(/^(bufferutil|utf-8-validate)$/)],
})

const production = merge(common, {
    mode: 'production',
    // Don't attempt to continue if there are any errors.
    bail: true,
    // output: {
    //     path: paths.appBuild,
    //     filename: '[name].[chunkhash:8].js',
    // },
    plugins: [],
})

module.exports =
    process.env.NODE_ENV === 'production' ? production : development
