if jit then
  debug.setmetatable(_G,{__index=function(self,k) error("NOPEI: "..tostring(k),2) end,__newindex=function(self,k) print("NOPEN: "..tostring(k),2) error("NOPEN: "..tostring(k),2) end})
end
local lgi=require"lgi"
local Gtk=lgi.require("Gtk","3.0")
local Gdk=lgi.require("Gdk")
local G=lgi.require("GLib")
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
  for i=si-1,si+1 do
    cr:identity_matrix()
    cr:scale(area.width/1920,area.width/1920)
    local y=((i-1)*image_h)-scroll
    cr:translate(0,y)
    cr:set_source_surface(get_image(y+(si*image_h)).image,0,0)
    cr:paint()
  end
  cr:identity_matrix()
  cr:set_source_rgba(0,0,0,0.5)
  cr:scale(area.width/1920,area.width/1920)
  cr:translate(0,math.fmod(-scroll,image_h)-image_h)
  local grid_space=30
  for y=0,image_h*3,grid_space do
    cr:move_to(0,y)
    cr:line_to(1920,y)
    cr:stroke()
  end
  cr:identity_matrix()
  for x=0,1920,grid_space do
    cr:move_to(x,0)
    cr:line_to(x,image_h)
    cr:stroke()
  end
  local function a()
    cr:identity_matrix()
    cr:scale(area.width/1920,area.width/1920)
    cr:translate(0,-scroll)
    local r=10
    if tool=="draw" then r=3 end
    if not tool then r=5 end
    cr:arc(last_mouse_pos.x,last_mouse_pos.y,r,0,math.pi*2)
  end
  if last_mouse_pos then
    if tool=="draw" then
      cr:set_source_rgba(0,0,0,1)
    elseif tool then
      cr:set_source_rgba(0,0,0,0.3)
    else
      cr:set_source_rgba(0,0,0,0.5)
    end
    a()
    cr:stroke()
  end
end
local function save()
  local img=cairo.ImageSurface.create(0,1920,(1+#images)*image_h)
  local cr=cairo.Context.create(img)
  for i,img in pairs(images) do
    cr:identity_matrix()
    cr:translate(0,i*image_h)
    cr:set_source_surface(img.image,0,0)
    cr:paint()
  end
  img:write_to_png(os.time()..".png")
end
area:add_events(Gdk.EventMask.POINTER_MOTION_MASK)
area:add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
window:add_events(Gdk.EventMask.KEY_PRESS_MASK)
area:add_events(Gdk.EventMask.BUTTON_RELEASE_MASK)
local last_draw=0
local f
do
  local function mv(this,last,state)
    --for k,v in pairs(state) do print(k,v) end
    local cr=get_image(this.y).cr
    local function dd(su)
      su(cr)
      local y=math.fmod(this.y,image_h)
      local ly=(y-this.y)+last.y
      cr:move_to(last.x,ly)
      cr:line_to(this.x,y)
      cr:stroke()
      if ly<0 or ly>=image_h then
        local cr=get_image(last.y).cr
        su(cr)
        local y=math.fmod(last.y,image_h)
        local ly=(y-last.y)+this.y
        cr:move_to(this.x,ly)
        cr:line_to(last.x,y)
        cr:stroke()
      end
    end
    if state.BUTTON1_MASK and state.BUTTON3_MASK then
      scroll=math.max(scroll-(this.ry-last.ry),0)
    elseif state.BUTTON1_MASK and state.BUTTON2_MASK then
      tool="erase"
      dd(function(cr)
        cr:set_source_rgb(255,255,255)
        cr:set_line_width(20)
      end)
    elseif state.BUTTON1_MASK then
      tool="draw"
      dd(function(cr)
        cr:set_source_rgb(0,0,0)
        cr:set_line_width(2)
      end)
    else
    end
  end
  f=function(area,event)
    area:grab_focus()
    local x=event.x/(area.width/1920)
    local y=event.y/(area.width/1920)
    local t={x=x,y=y+scroll,ry=y}
    tool=nil
    if last_mouse_pos then
      mv(t,last_mouse_pos,event.state)
    end
    last_mouse_pos=t
    local cur=G.get_monotonic_time()
    if (cur-last_draw)>30*1000 then
      area:queue_draw()
      last_draw=cur
    end
  end
end
area.on_motion_notify_event=f
area.on_button_press_event=f
area.on_button_release_event=f
function window:on_key_press_event(evt)
  if evt.keyval==115 then
    save()
  elseif evt.keyval==110 then
    save()
    images={}
  else
  end
end
window:add(area)
window:fullscreen()
window:set_keep_above(true)
window:show_all()
Gtk.main()
