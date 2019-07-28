#encoding:utf-8
rgss_main do
  Font.default_name = (["黑体"])
  Font.default_outline = false
  Font.default_size = 22
  Graphics.resize_screen(640,480)
  Graphics.freeze 
  $scene = Scene_Title.new
  $scene.main while $scene
  Graphics.transition(20)
end
