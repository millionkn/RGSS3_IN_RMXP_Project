def p(*args)
  msgbox_p(*args)
end
Graphics.frame_rate = 40
Window = Class.new(XSE716_Window = Window)
class Window < XSE716_Window
  def initialize(viewport = nil)
    super()
    (@text_window = XSE716_Window.new()).back_opacity = 0
    self.windowskin = RPG::Cache.windowskin($game_system.windowskin_name)
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.viewport = viewport if viewport
    self.z = 100
    self.contents_opacity = self.contents_opacity
    self.opacity = self.opacity
    self.padding = 16#必须预先设置上面的某些参数，rgss的bug
    self.padding_bottom = 16
  end
  XSE716_Window.instance_methods(false).each do |name|
    define_method(name,lambda do |*args|
      super(*args)
      @text_window.method(name).call(*args)
    end)
  end
  remove_method("cursor_rect")
  remove_method("cursor_rect=")
  remove_method("back_opacity=")
  def update
    super
    rect = self.cursor_rect
    @text_window.cursor_rect.set(rect.x+self.ox,rect.y+self.oy,rect.width,rect.height)
    @text_window.update
  end
  def z=(val)
    @text_window.z = z+2
    super
  end
  def opacity=(val)
    @text_window.opacity = 0
    super
  end
  def contents_opacity=(val)
    super(0)
    @text_window.contents_opacity = val
  end
  def contents_opacity
    return @text_window.contents_opacity
  end
end
