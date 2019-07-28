# RGSS3_IN_RMXP_Project
在尽量不改变rmxp工程的情况下，使用rgss3引擎

注意,使用之前需要:右键点击`RPG Maker XP`,选择`属性`,`兼容性`,勾选`管理员身份运行`

1.将“覆盖”文件夹下的文件拷入工程下

2.在脚本的最前面添加`require("./Scripts/profile/index.rb")`

3.把`Main`中的脚本替换为`require("./Scripts/Main.rb")`

4.测试,如果有必要的话修改`devGame.ini`的内容