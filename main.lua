debug.setmetatable(_G,{__index=function(self,k) error("NOPEI: "..tostring(k),2) end,__newindex=function(self,k) print("NOPEN: "..tostring(k),2) error("NOPEN: "..tostring(k),2) end})
local lgi=require"lgi"
local Gtk=lgi.require("Gtk","3.0")
local Gdk=lgi.require("Gdk")
local cairo=lgi.require"cairo"
local window = Gtk.Window{title="InfiniDRAW",on_destroy=Gtk.main_quit,default_width=500,default_height=500}
local area=Gtk.DrawingArea{}
local image_h=1000
local images={}
local scroll=0
local function get_image(y)
  y=math.floor(y/image_h)
  if not images[y] then
    images[y]={image=cairo.ImageSurface.create(0,1920,image_h)}
    local paint_cr=cairo.Context.create(images[y].image)
    paint_cr:set_source_rgb(255,255,255)
    paint_cr:paint()
    images[y].cr=paint_cr
  end
  return images[y]
end
local last_mouse_pos
local tool
function area:on_draw(cr)
  --print(area.width)
  local si=math.ceil(scroll/image_h)
  for i=si-1,si+10 do
    cr:identity_matrix()
    cr:scale(area.width/1920,area.width/1920)
    local y=((i-1)*image_h)-scroll
    cr:translate(0,y)
    cr:set_source_surface(get_image(y+(si*image_h)).image)
    cr:paint()
  end
  local function a()
    cr:identity_matrix()
    cr:scale(area.width/1920,area.width/1920)
    cr:translate(0,-scroll)
    cr:arc(last_mouse_pos.x,last_mouse_pos.y,10,0,math.pi*2)
  end
  if last_mouse_pos then
    if tool=="draw" then
      cr:set_source_rgb(0,0,0)
    else
      cr:set_source_rgb(255,255,255)
    end
    a()
    cr:fill()
    cr:set_source_rgb(0,0,0)
    a()
    cr:stroke()
  end
end
local function save()
  local img=cairo.ImageSurface.create(0,1920,#images*image_h)
  local cr=cairo.Context.create(img)
  for i=0,#images do
    cr:identity_matrix()
    cr:set_source_surface(get_image(i*image_h).image)
    cr:translate(0,i*image_h)
    cr:paint()
  end
  img:write_to_png(os.time()..".png")
end
area:add_events(Gdk.EventMask.POINTER_MOTION_MASK)
area:add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
window:add_events(Gdk.EventMask.KEY_PRESS_MASK)
area:add_events(Gdk.EventMask.BUTTON_RELEASE_MASK)
local f
do
  local function mv(this,last,state)
    --for k,v in pairs(state) do print(k,v) end
    local cr=get_image(this.y).cr
    local function dd()
      local y=math.fmod(this.y,image_h)
      local ly=(y-this.y)+last.y
      cr:move_to(last.x,ly)
      cr:line_to(this.x,y)
      cr:stroke()
    end
    if state.BUTTON1_MASK and state.BUTTON3_MASK then
      scroll=math.max(scroll-(this.ry-last.ry),0)
    elseif state.BUTTON1_MASK and state.BUTTON2_MASK then
      tool="erase"
      tool="draw"
      cr:set_source_rgb(255,255,255)
      cr:set_line_width(20)
      dd()
    elseif state.BUTTON1_MASK then
      tool="draw"
      cr:set_source_rgb(0,0,0)
      cr:set_line_width(2)
      dd()
    end
  end
  f=function(area,event)
    area:grab_focus()
    local x=event.x/(area.width/1920)
    local y=(event.y/(area.width/1920))
    local t={x=x,y=y+scroll,ry=y}
    tool=nil
    if last_mouse_pos then
      mv(t,last_mouse_pos,event.state)
    end
    area:queue_draw()
    last_mouse_pos=t
  end
end
area.on_motion_notify_event=f
area.on_button_press_event=f
area.on_button_release_event=f
function window:on_key_press_event(evt)
  if evt.keyval==115 then
    save()
  end
end
window:add(area)
--window:fullscreen()
window:set_keep_above(true)
window:show_all()
Gtk.main()
