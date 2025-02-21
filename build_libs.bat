:: many of the symbols are not exported by default. -Dyyjson_api_inline=yyjson_api makes all symbols exported
:: https://github.com/ibireme/yyjson/issues/165
clang -c -g -gcodeview -o yyjson-windows.lib -target x86_64-pc-windows -fuse-ld=llvm-lib -Wall -Dyyjson_api_inline=yyjson_api yyjson\src\yyjson.c

mkdir libs
move yyjson-windows.lib libs
