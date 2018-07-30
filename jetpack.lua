p1={}
lvl={}
ent={}
init={lives=4,lvls=30}
intro={done=false,f=0,tdx=1,tx=0}

function _init()
  music(0)
end

function reset()
  loadlvl(1)
  p1.score=0
  p1.lives=init.lives
end
lvlreset=false
function _update()
  if not intro.done then
    intro.f+=1
    if intro.tdx>0 and intro.tx>56 then intro.tdx*=-1 end
    if intro.tdx<0 and intro.tx<0 then intro.tdx*=-1 end
    intro.tx+=0.5*intro.tdx
    if btnp()>0 then 
      intro.done=true
      intro.f=0
      reset()
    end
    return
  end
  
  if lvlreset then
    if btnp(5) then
      lvlreset=false
      loadlvl(lvl.nr)
    elseif btnp()>0 then
      lvlreset=false
    end
    return
  end
  
  if btnp(5) then
    lvlreset=true
    return
  end

  updp1()
  foreach(ent.bots,updbot)
  foreach(ent.rkts,updrkt)
  foreach(ent.sph,updsph)
  foreach(ent.str,updstr)
  foreach(ent.spr,updspring)
end

function _draw()
  cls()
  camera()

  if lvlreset then
    print("restart level?",10,40,7)
    print("press x again to restart",10,54,6)
    print("any key to cancel",10,64,6)
    return
  end
  
  if not intro.done then
    map(112,48,0,0,16,16)
    fat("jetpack",33,36,6,8)
    print("by movax13h",43,49,6)
    print("press key",47,105,1)
   
    spr(23+flr(0.5*intro.f)%2,32+intro.tx,80,1,1,intro.tdx<0)
    return
  end
  
  if p1.yippie then
    outline("you beat the game!",31,46,7,1)
    print("score: "..pad(p1.score,5),41,60,6)
    print("press any key",39,110,5)
    print("to restart",46,118,5)
    return
  end
  
  map(lvl.x,lvl.y,0,0,lvl.w,lvl.h)
  local txt="level "..pad(lvl.nr,2).."/"..init.lvls
  outline(txt,43,1,7,1)
  
  camera(lvl.x*8,lvl.y*8)
  foreach(ent.bots,drwbot)
  foreach(ent.rkts,drwrkt)
  foreach(ent.sph,drwsph)
  foreach(ent.str,drwstr)
  foreach(ent.spr,drwspring)
  drwp1()
  
  camera()
  
  --ui
  rectfill(0,121,127,127,5)
  print("fuel",1,122,11)
  rectfill(18,122,51,126,0)
  rect(18,122,52,126,6)
  if (flr(p1.fuel)>0) rectfill(19,123,19+32*p1.fuel/100,125,11)

  print("lives",59,122,11)
  print(p1.lives,81,122,7)
  print("scr",91,122,11)
  print(pad(p1.score,5),105,122,7)
  
  if p1.dead and p1.f>20 then
    if p1.f==80 then
      p1.lives-=1
      sfx(2,3)
    end
    local y=min((p1.f-20)*5-100,30)
    rect(29,y-1,99,y+49,12)
    rectfill(30,y,98,y+48,1)
    if p1.lives<=0 then
      print("- game over -",39,y+13,7)
      print("press any key",39,y+28,5)
      print("to restart",46,y+37,5)
    else
      print("life lost",47,y+10,7)
      print("press key",47,y+35,5)
    end
    
    for i=1,p1.lives do
      if (i<p1.lives or p1.f>80 or p1.f%8<4) spr(1,36+10*i,y+20)
    end
  end

end

--level
function loadlvl(nr)
  reload(0x1000,0x1000,0x1000)
  reload(0x2000,0x2000,0x1000)

  initp1()
  ent={}
  ent.bots={}
  ent.rkts={}
  ent.sph={}
  ent.spr={}
  ent.str={}

  lvl.nr=nr  
  lvl.x=16*((nr-1)%8)
  lvl.y=16*flr((nr-1)/8)
  lvl.w=16
  lvl.h=15
  lvl.gems=0
  lvl.door={x=-10,y=-10}
  
  camera(lvl.x*8,lvl.y*8)
  
  for y=lvl.y,lvl.y+lvl.h do
  for x=lvl.x,lvl.x+lvl.w do
    local s=mget(x,y)
    if s==16 then lvl.gems+=1
    elseif s>0 and s<6 then 
      p1.x=8*x p1.y=8*y
      mset(x,y,0)
    elseif s==23 or s==24 then
      add(ent.bots,newbot(x,y))
      mset(x,y,0)
    elseif s>=64 and s<=66 then
      add(ent.rkts,newrkt(x,y,67-s))
      mset(x,y,0)
    elseif s==25 then
      add(ent.sph,newsph(x,y))
      mset(x,y,0)
    elseif s==68 or s==69 then
      add(ent.str,newstr(x,y))
      mset(x,y,0)
    elseif s==30 then
      add(ent.spr,newspring(x,y))
      mset(x,y,0)
    elseif s==11 then lvl.door={x=x,y=y} end
  end end
  
  sfx(7)
end

--player
function initp1()
  p1.x=40
  p1.y=80
  p1.dx=0
  p1.dy=0
  p1.f=0
  p1.wf=0 --walking cycle frame
  p1.walk=false
  p1.grnd=false -- grounded
  p1.flip=false
  p1.dead=false
  p1.win=false
  p1.yippie=false --game done
  p1.jp=0
  p1.jpmax=2
  p1.fuel=0
  p1.gems=0
  --p1.score=0
end

function updp1()
  if p1.yippie then
    if (btn()>0) reset()
    return--game ended
  end
  
  p1.f+=1
  if p1.dead then
    if p1.f>100 and btn()>0 then
      if p1.lives>0 then loadlvl(lvl.nr)
      else reset() end
    end
    return
  end
  
  if p1.win then
    p1.x+=p1.dx*0.5
    if p1.f>50 then
      if lvl.nr<init.lvls then loadlvl(lvl.nr+1)
      else 
        p1.yippie=true 
        music(1)
      end
    end
    return
  end

  p1.grnd=false
  local ox,oy=p1.x,p1.y
  
  p1.y+=1 --gravity
  --jetpack
  if btn(4) and p1.fuel>0 then 
    p1.fuel-=0.25
    if p1.jp<1 then 
      p1.jp=1
      sfx(8,3)
    end
    p1.jp+=(p1.jpmax-p1.jp)*0.2 
  else
    p1.jp*=0.8
    sfx(-1,3)
  end
  
  local s
  
  if p1.jp>1 then 
    p1.y-=p1.jp
  else
    --climb
    p1.climb=false
    if coll(p1.x+4,p1.y+6).s==10 and btn(2) then
      p1.y-=2
      p1.climb=true
      oy=p1.y
    end
  
    s=coll(p1.x+4,p1.y+7).s
    if (s==10 or s==0) and btn(3) then
      p1.climb=s==10
      oy=p1.y
    end
  end
  
  s=coll_char(p1).s
  if s>0 then 
    p1.y=oy p1.grnd=true 
  end
  
  --left/right
  p1.walk=false
  if btn(0) then p1.x-=1 p1.walk=true p1.flip=true end
  if btn(1) then p1.x+=1 p1.walk=true p1.flip=false end
  s=coll_char(p1).s
  if s>0 and s!=10 then
    p1.x=ox 
    p1.walk=false 
  end	
  
  if (p1.walk) p1.wf+=0.5
  
  p1.dx=p1.x-ox
  p1.dy=min(max(p1.y-oy,-1),1)
  
  --hit items
  local mx,my=(p1.x+3)/8,(p1.y+4)/8
  s=sat(p1.x+3,p1.y+4)
  if s==18 then hitfuel(mx,my,50) 
  elseif s==21 then hitfuel(mx,my,100)
  elseif s==16 then hitgem(mx,my,true,200) 
  elseif s==19 then hitgem(mx,my,false,50) 
  elseif s==20 then hitgem(mx,my,false,100) 
  elseif s==67 then hitlife(mx,my) 
  elseif s==59 or s==60 then --door
    p1.f=0
    p1.win=true
    sfx(3,3)
  elseif s==26 or s==70 then
    p1.f=0
    p1.dead=true
    sfx(1,3)
  end
  
  --hit entities
  if hitenemy(p1.x+4,p1.y+4) then
    p1.f=0
    p1.dead=true
    sfx(1,3)
  end
  
end

function drwp1()
  if p1.dead then
    exp(1,p1.x,p1.y,p1.f)
    return
  end
  
  if p1.win then
    win(1,p1.x,p1.y,p1.f,p1.flip)
    return
  end

  if p1.f<20 then
    exp(1,p1.x,p1.y,20-p1.f)
    return
  end

  if p1.jp>0.5 then --hero+fire
    spr(1,p1.x,p1.y,1,1,p1.flip)
    local x=p1.x
    if (p1.flip) x+=4
    sspr(56+4*(p1.f%3),0,4,8,x,p1.y+8,4,8,p1.flip)
  else
    if p1.climb then
      spr(6,p1.x,p1.y,1,1,p1.f%6>3)
    else
      if not p1.grnd then
        spr(5,p1.x,p1.y,1,1,p1.flip)
      elseif p1.dx==0 then
        spr(1,p1.x,p1.y,1,1,p1.flip)
      else
        spr(1+p1.wf%4,p1.x,p1.y,1,1,p1.flip)
      end
    end
  end
end

function hitenemy(x,y)
  for bot in all(ent.bots) do
    if abs(bot.x+4-x)<5 and abs(bot.y+4-y)<5 then
      return true
    end
  end
  for rkt in all(ent.rkts) do
    if abs(rkt.x+4-x)<5 and abs(rkt.y+4-y)<5 then
      return true
    end
  end
  for sph in all(ent.sph) do
    if abs(sph.x+4-x)<4 and abs(sph.y+4-y)<4 then
      return true
    end
  end
  for str in all(ent.str) do
    if abs(str.x+1-x)<4 and abs(str.y+1-y)<4 then
      return true
    end
  end
  for spring in all(ent.spr) do
    if abs(spring.x+4-x)<4 and abs(spring.y+6-y)<4 then
      return true
    end
  end
  return false
end

--bots
function newbot(x,y)
  return {x=8*x,y=8*y,dx=1,l=0}
end

function updbot(bot)
  if bot.l>0 then
    bot.l-=1
    if (bot.l==0) bot.dx*=-1
    return
  end

  bot.x+=bot.dx*0.5
  local cx=bot.x+6*bot.dx
  if (bot.dx<0) cx=bot.x+1
  local s=coll(cx,bot.y+4).s
  if coll(cx,bot.y+8).s==0 or
     (s>0 and s!=10)
  then
    bot.l=20
  end
end

function drwbot(bot)
  spr(23+bot.x%2,bot.x,bot.y,1,1,bot.dx<0)
end

--rockets
function newrkt(x,y,d)
  return {x=8*x,y=8*y,d=d,fire={}}
end

function updrkt(rkt)

  if rkt.d==1 then -- up
    add(rkt.fire,{x=rkt.x+3,y=rkt.y+9})
    if collrkt(rkt.x+4,rkt.y-1) then
      if collrkt(rkt.x+8,rkt.y+4) then rkt.d=4
      else rkt.d=2 end
    else rkt.y-=1 end
    
  elseif rkt.d==2 then -- right
    add(rkt.fire,{x=rkt.x-1,y=rkt.y+3})
    if collrkt(rkt.x+8,rkt.y+4) then
      if collrkt(rkt.x+4,rkt.y+8) then rkt.d=1
      else rkt.d=3 end
    else rkt.x+=1 end
    
  elseif rkt.d==3 then -- down
    add(rkt.fire,{x=rkt.x+3,y=rkt.y-1})
    if collrkt(rkt.x+4,rkt.y+8) then
      if collrkt(rkt.x+8,rkt.y+4) then rkt.d=4
      else rkt.d=2 end
    else rkt.y+=1 end
    
  elseif rkt.d==4 then -- left
    add(rkt.fire,{x=rkt.x+9,y=rkt.y+4})
    if collrkt(rkt.x-1,rkt.y+4) then
      if collrkt(rkt.x+4,rkt.y+8) then rkt.d=1
      else rkt.d=3 end
    else rkt.x-=1 end
  end

  srand(p1.f)
  for i=1,count(rkt.fire) do
    local fire=rkt.fire[i]
    fire.x+=(rnd(2)-1)
    fire.y+=(rnd(2)-1)
  end

  if count(rkt.fire)>10 then
    del(rkt.fire,rkt.fire[1])
  end
end

function collrkt(x,y)
  local s=coll(x,y).s
  return (s>0 and s!=10)
end

function drwrkt(rkt)
  if rkt.d==1 then
    spr(66,rkt.x,rkt.y,1,1)
  elseif rkt.d==2 then
    spr(65,rkt.x,rkt.y,1,1)
  elseif rkt.d==3 then
    spr(64,rkt.x,rkt.y,1,1)
  else 
    spr(65,rkt.x,rkt.y,1,1,true)
  end
  
  local colors={10,9,8,2}
  local c=count(rkt.fire)
  for i=1,c do
    local fire=rkt.fire[i]
    local col=colors[flr(4*(1-i/c))+1]
    pset(fire.x,fire.y,col)
  end
end


--spheres
function newsph(x,y)
  return {x=8*x,y=8*y,dx=1}
end

function updsph(sph)
  sph.x+=sph.dx
  local cx=sph.x+7*sph.dx
  if (sph.dx<0) cx=sph.x-1
  local s=coll(cx,sph.y+4).s
  if coll(cx,sph.y+8).s==0 or
     (s>0 and s!=10)
  then
    sph.dx*=-1
  end
end

function drwsph(sph)
  spr(25,sph.x,sph.y,1,1)
end

--stars
function newstr(x,y)
  return {x=8*x+rnd(7),
    y=8*y+rnd(7),
    dx=0.5*sgn(rnd(2)-1),
    dy=0.5*sgn(rnd(2)-1)}
end

function updstr(str)
  local s=0
  
  s=coll(str.x+str.dx+1,str.y+1).s
  if s>0 and s!=10 then str.dx*=-1
  else str.x+=str.dx end
  
  s=coll(str.x+1,str.y+str.dy+1).s
  if s>0 and s!=10 then str.dy*=-1
  else str.y+=str.dy end
end

function drwstr(str)
  sspr(32+4*(flr(0.25*p1.f)%4),32,3,3,str.x,str.y)
end

--springs
function newspring(x,y)
  return {x=8*x,y=8*y,dy=1}
end

function updspring(spring)
  spring.y+=spring.dy
  local cy=spring.y+7*spring.dy
  if (spring.dy<0) cy=spring.y+4
  
  local s=coll(spring.x+4,cy).s
  if s>0 then
    spring.dy*=-1
  end
end

function drwspring(spring)
  spr(30,spring.x,spring.y,1,1,p1.f%4>1)
end


--collisions
function hitfuel(mx,my,val)
  p1.fuel=min(100,p1.fuel+val)
  mset(mx,my,0)
  sfx(0,2)
end

function hitgem(mx,my,isgem,pts)
  if isgem then
    p1.gems+=1
    mset(mx,my,17)
    if p1.gems>=lvl.gems then
      sfx(4,2)
      mset(lvl.door.x,lvl.door.y,43)
      mset(lvl.door.x+1,lvl.door.y,44)
      mset(lvl.door.x,lvl.door.y+1,59)
      mset(lvl.door.x+1,lvl.door.y+1,60)
    else
      sfx(5,2)
    end
  else
    mset(mx,my,0)
    sfx(0,2)
  end
  p1.score+=pts
end

function hitlife(mx,my)
  mset(mx,my,0)
  sfx(6,2)
  p1.lives=min(4,p1.lives+1)
end

--collision helpers
function coll_char(p)
  local hit={}
  hit=coll(p.x+2,p.y+7) if (hit.s>0) return hit
  hit=coll(p.x+5,p.y+7) if (hit.s>0) return hit
  hit=coll(p.x+2,p.y+4) if (hit.s>0) return hit
  hit=coll(p.x+5,p.y+4) if (hit.s>0) return hit
  return {s=0}
end

function coll(x,y)
  local s=mget(x/8,y/8)
  if fget(s,0) then 
    local c=sget(8*(s%16)+x%8,8*flr(s/16)+y%8)
    if (c>0) return {s=s,x=x,y=y}
  end
  return {s=0}
end

function collcell(x,y)
  local s=mget(x,y)
  return fget(s,0)
end

function sat(x,y)
  return mget(x/8,y/8)
end

--draw helpers
function exp(id,x,y,t)
  t*=1.8
  local mx,my=8*(id%16),8*(flr(id/16))
  srand(id*0.9123)
  for j=0,8 do for i=0,8 do
    local c=sget(mx+i,my+j)
    if c>0 then
      pset(x+i+t*(rnd(2)-1),y+j+t*(rnd(2)-1),c)
    end
  end end
end

function win(id,x,y,t,fl)
  local mx,my=8*(id%16),8*(flr(id/16))
  local i=min(8,p1.f*0.5)
  local s=8-i
  sspr(mx,my,8,8,x+i*0.5,y+i,s,s,fl)
end

function pad(n,digits)
  local len=digits-#(n.."")
  if len<1 then return n end
  local s=""
  for i=1,len do s=s.."0" end
  return s..n
end

function fat(txt,x,y,col1,col2)
  for i=1,#txt do
    outline(sub(txt,i,i),x+10*(i-1),y,col1,col2)
  end
end

function outline(txt,x,y,col1,col2)
  print(txt,x-1,y-1,col2)
  print(txt,x-1,y,col2)
  print(txt,x-1,y+1,col2)
  print(txt,x,y+1,col2)
  print(txt,x,y-1,col2)
  print(txt,x+1,y-1,col2)
  print(txt,x+1,y,col2)
  print(txt,x+1,y+1,col2)
  print(txt,x,y,col1)
end