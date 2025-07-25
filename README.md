# fnOS_wallpaper_diy
最简单的方式DIY飞牛fnOS登录页面背景壁纸   
Automatically change the background wallpaper of the fnOS login page.  

# 用法
```
chmod 777 ./wallpaperChange.sh  
./wallpaperChange.sh /vol1/1000/bg/girl.png  # 用指定图片更换登录页背景  
./wallpaperChange.sh -r  # 恢复系统默认
```

# 功能
* 支持设置PNG/JPG/BMP/GIF/WEBP等格式图片作为飞牛登录页面背景
* 同时支持缩略图，可在飞牛页面打开我的账号——个人设置——主题壁纸查看
* 重启生效 支持自动恢复默认
* ROOT权限执行成功后刷新登录页面缓存即可立竿见影看到效果   

# 效果
[演示效果](https://github.com/playGitboy/fnOS_wallpaper_diy/blob/0aa619e70a864b907c570df0cc43ee7fe479e2ee/login_wallpaper.png)  

# 注意
* 设置后会用指定图片替换掉系统首张默认壁纸
* 如果系统升级等有任何疑问，可以用“-r”参数恢复默认 

飞牛fnOS默认不支持自定义登录页面图片背景，千篇一律难免审美疲劳
