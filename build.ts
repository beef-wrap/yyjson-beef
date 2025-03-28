import { type Build } from 'xbuild';

const build: Build = {
    common: {
        project: 'yyjson',
        archs: ['x64'],
        variables: [],
        copy: {},
        defines: [
            'yyjson_api_inline=yyjson_api'
        ],
        options: [],
        subdirectories: ['yyjson'],
        libraries: {
            yyjson: {}
        },
        buildDir: 'build',
        buildOutDir: '../libs',
        buildFlags: []
    },
    platforms: {
        win32: {
            windows: {},
            android: {
                archs: ['x86', 'x86_64', 'armeabi-v7a', 'arm64-v8a'],
            }
        },
        linux: {
            linux: {}
        },
        darwin: {
            macos: {}
        }
    }
}

export default build;