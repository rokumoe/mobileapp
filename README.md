# mobileapp 
基于gomobile编译android app，并生成未签名的apk。

因为直接用`gomobile build`生成的apk，自带签名，且无法设置icon，所以把编译go部分提取出来，接入android打包流程，实现打包。

## 环境
* go
* android-sdk

## 准备
```
$ go get golang.org/x/mobile/cmd/gomobile
$ gomobile init -v
```

## 编译
```
$ ./build_apk
```

编译成功后会在build/下生成一个未签名的${APPNAME}_unsigned.apk

## 其他
### 签名
```
$ jarsigner -keystore <keystore file> -storepass <storepass> -keypass <keypass> -signedjar <signed apk>  <unsigned apk> <aliasname>
```

### 对齐
```
$ $ANDROID_HOME/build-tools/$BUILD_TOOL_VERSION/zipalign 4 <unalign apk> <aligned apk>
```

### 安装
```
$ $ANDROID_HOME/platform-tools/adb install <apk>
```

### 查看打印
```
$ $ANDROID_HOME/platform-tools/adb logcat -s GoLog:I
```
