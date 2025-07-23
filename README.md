# fnOS_wallpaper_diy
最简单的方式DIY飞牛fnOS登录页面背景壁纸   
Automatically change the background wallpaper of the fnOS login page.  

截止202508飞牛fnOS仍不支持自定义登录页面背景
旧版本fnOS可以直接修改“/usr/trim/www/static/bg/wallpaper-1.webp”自定义登录界面背景
但fnOS版本更新后系统会锁定www目录，如cp/mv/chmod等操作过几秒就会自动恢复默认导致DIY失败

# 用法
```
chmod 777 ./wallpaperChange.sh  
./wallpaperChange.sh /vol1/1000/bg/girl.png  # 用指定图片更换登录页背景  
./wallpaperChange.sh -r  # 恢复系统默认
```
# 功能
常见PNG/JPG/BMP/GIF/WEBP等格式都支持
同时处理缩略图，可在我的账号——个人设置——主题壁纸查看  
ROOT权限执行成功后刷新登录页面缓存即可立竿见影看到效果  

# 注意
* 设置后会用指定图片替换掉系统首张壁纸
* 如果系统升级等有任何疑问，可以用“-r”参数恢复默认 
