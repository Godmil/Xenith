pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- xenith
--by godmil
--v1.5 - based on beta15

-----------------------
-- GENERAL FUNCTIONS --
-----------------------

function bgndspeed()
	if(opentransition.complete and speedramp > 0) speedramp /=1.15
	if(speedramp < 0.5 or hitsperlevel[level] > 0 or level == 1) speedramp = 0
	if(mode == "ending") return 0
	if levelcomplete then
		return 5
	elseif speedramp > 3 then --speedcap for initial level start
		return 3
	else 
		return speedramp
	end
end

function resetcartdata()
	for i = 1, 13 do 
		dset(i, 0)
	end
end

function player2joins()
	if player2 and player2joinstimer > 0 then
		centretext("player 2 has joined", 10, rnd(15)+1)	
		player2joinstimer -=1
	end
end

function existsintable(table1,value)
	for entry in all(table1) do
		if (entry == value) return true
	end
	return false
end

function exit()
	if btn(3) then
		exitclipy -= 0.1
	else
		exitclipy = 6
	end
	print("⬇️exit⬇️", 50, 121, 6)
	clip(30,120,80,exitclipy)
	print("⬇️exit⬇️", 50, 121, 5)
	clip()

	if exitclipy <= -0.2 then
		mode="menu"
		musicplaying = false
	end
end

function invinsiblemode()
	print("⬇️ CHANGE GAME MODE ⬇️", levelselxcoord+21, 121.5+sin(t()/2), 13)

	if vunerablemode then
		shadowprint("standard mode", levelselxcoord+40, 48, 13)
		print("RESTART AS FEW TIMES AS POSSIBLE", levelselxcoord+1, 56, 5)
	else
		shadowprint("invincible mode", levelselxcoord+36, 48, 13)
		print("BE HIT AS FEW TIMES AS POSSIBLE", levelselxcoord+3, 56, 5)
	end

	if (btnp(3) and levelselect) vunerablemode = not vunerablemode
end

function partemit(x,y,number, angle, range, force, resistance, duration, lifetime, quiet)
	local partemitter={
		parttable={},
		d = duration,
		ctab = split"7,7,10,10,10,9,9,9,9,8,2",

		emit = function(self)
			for i = 1, number do
				local particle={}

				particle.l = (lifetime+rnd(lifetime/2))
				particle.f = force + rnd(force/2)
				particle.x = x
				particle.y = y
				particle.a = angle -range/2 + rnd()*range
				particle.c = self.ctab[1]

				add(self.parttable, particle)
			end
			if not bosssecondstage then 
				if quiet then
					sfx(63,-1,8,2)
				else
					sfx(63,-1,0,3)
				end
			end
		end,

		move = function(self)
			if(self.d > 0) then
				self:emit()
				self.d -= 1
			end

			for par in all(self.parttable) do
				par.l /= 1.5
				par.x += cos(par.a)*par.f
				par.y += sin(par.a)*par.f

				par.y += 0.2
				--if(levelcomplete and level != lastlevel) par.y+=5
				par.f /= resistance

				par.c = self.ctab[#self.ctab - ceil(par.l/#self.ctab)]

				if(par.f <= (rnd()/10)) del(self.parttable, par)
			end
		end,
		draw = function(self)
			for par in all(self.parttable) do
				pset(par.x, par.y, par.c)
			end
		end,
	}
	return partemitter
end

function presstostart()
	if btnp(4,1) or btnp(5,1) then
		player2 = true
		startnextlevel()
	end
	if(btnp(4) or btnp(5)) startnextlevel() 
end

function mutebutton(xoffset)
	print("⬅️ MUTE", xoffset + 12, 120,5)
	spr(64, xoffset+1, 118)
	if not playmusic then
		circ(xoffset+5,122,5,8)
		line(xoffset+2,119,xoffset+8, 125,8)
	end	

	if(mode == "menu" or mutedelaytimer <= 0) then 
		if (btnp(0) and not lockcontrols and not levelselect) playmusic = not playmusic
	end
	mutedelaytimer -=1
end

function centretext(text, y, col, shadow, shadowcol, wide)
	local w = 4
	if (wide) w = 5
	local padding = (127-#text*w)/2
	local shadowcolour = shadowcol or 2
	if (shadow) print(text, padding+1, y+1, shadowcolour) 
	print(text, padding, y, col)
end

function shadowprint(text, x, y, col, shadowcol)
	local shadowcolour = shadowcol or 1
	print(text, x+1, y+1, shadowcolour)
	print(text, x, y, col)
end

function quadeaseout(t,b,c,d)
	t /= d
	return -c * t*(t-2) + b
end

function hyp(x,y)
	local x1=abs(64-x)
	local y1=abs(64-y)
	return sqrt(x1*x1+y1*y1)
end

function anglefromcentre(x,y)
	return atan2(x-64, y-64)
end

function collision(player, enemy)
	if player.y + player.coly> enemy.y + enemy.coly + enemy.colh+1 then 
		return false 
	elseif player.x + player.colx > enemy.x + enemy.colx + enemy.colw then
		return false
	elseif player.x + player.colx + player.colw+1 < enemy.x + enemy.colx then 
		return false 
	elseif player.y + player.coly + player.colh+1 < enemy.y + enemy.coly then 
		return false 
	elseif player.dead then 
		return false
	end

	return true
end

function pointangle(player, enemy)
	return atan2(player.x-enemy.x, player.y-enemy.y)
end


-------------------
--GRAPHIC EFFECTS--
-------------------

function titlereveal()
	local titlerev ={
		rows ={},

		gen = function(self)
			for i = 0, 96 do
				row = {}
				row.x = 0
				row.y = i

				add(self.rows, row)
			end
		end,

		move = function(self)
			lastrowx = 0
			for r in all(self.rows) do
				if r.y == 0 then
					r.x += 8
					lastrowx = r.x
				else
					if lastrowx >= 15 then
						r.x += 8
						lastrowx = r.x
					end 
				end
			end
		end,

		draw = function(self)
			for r in all(self.rows) do
				if (r.x <= 127) line(r.x, r.y, 127, r.y, 0)
			end
		end
	}
	return titlerev
end

function circlestar(radius, ticks, colour, setspeed, loop)
	local star = {
		x = 0,
		y = 0,
		rad = radius,
		tick = ticks,
		speed = setspeed,
		alive = true,
	
	 	move = function(_ENV)
	 		x = 64 + cos(tick)*rad
	 		y = 64 + sin(tick)*rad

	 		tick += 1/(5*rad)*speed
	 	 	rad -= speed/10
	 	end,
		
		draw = function(_ENV)
  			pset(x,y,colour)


  			if rad <= 8 then
  				local angle = atan2(x-64,y-64)
  				line(64, 64, 64+cos(angle)*100, 64+sin(angle)*100, 13)
  				
  				if loop then 
  					rad = 70+rnd(10)
  				else
  					alive = false
  				end

  			end
  		end
	}
	return setmetatable(star, {__index = _ENV})
end

function transition(transitioncolour)
	local tran = {
		timer = 0,
		complete = false,
		draw = function(self)
			if(transitioncolour ==-2) then 
				rectfill(0,self.timer*5,129,129, 0)
				if(self.timer > 25) self.complete = true
			elseif(transitioncolour != -1)	then 
				rectfill(0,0,129,self.timer*5, transitioncolour)
			end
			self.timer += 1
		end
	}
	return tran
end

function createbgnd(size, speed)
	local bgndobj ={
		bgndtable = {},
		clouds = {},
		asteroids ={},
		startable ={},
		gen = function(_ENV)
			if existsintable(split"space,spacereverse,asteroids",leveltype) then 
				for i = 1, size do
					add(bgndtable, {x = rnd(127), y = rnd(127), s = rnd(speed)+0.5})
				end
			elseif existsintable(split"upatmos,midatmos,lowatmos",leveltype) then
				for i = 1, size do
					add(bgndtable, {x = rnd(127), y = rnd(127), l = rnd(10)+5})
				end
			elseif leveltype == "water" or leveltype == "waterclouds" then
				for i = 1, size do
					add(bgndtable, {x = rnd(127), y = rnd(127)-8})
				end
			elseif leveltype == "grass" or leveltype == "grassclouds" then
				for i = 1, size do
					add(bgndtable, {x = rnd(127), y = rnd(127)-8, sp = (rnd(2)+6)})
				end			
			elseif leveltype == "sand" then
				for i = 1, size/2+size/8 do add(bgndtable, {x = rnd(127), y = rnd(127)-8, sp = rnd(2)+24}) end
				for i = 1, size/4 do add(bgndtable, {x = rnd(127), y = rnd(127)-8, sp = rnd(2)+22}) end
				for i = 1, size/8 do add(bgndtable, {x = rnd(127), y = rnd(127)-8, sp = rnd(2)+26}) end
			elseif leveltype == "cave" or leveltype == "deepcave" then
				cavetiley = split"-32,0,32,64,96"
			elseif leveltype == "lava" then
				for i = 1, size do
					add(bgndtable, {x = rnd(127), y = rnd(127)-8, s = rnd(5)+5, sizecurrent = rnd(20)-20})
				end
			elseif existsintable(split"moon1,moon2,moon3,mars",leveltype) then
				for i = 1, size do add(bgndtable, {x = rnd(127), y = rnd(127)-8, sp = rnd(2)+26}) end
				for i = 1, size/3 do add(asteroids, {x = rnd(127), y = rnd(127)-16}) end
			elseif leveltype == "city" then 
				for i = 1, size do
					add(bgndtable, {x = rnd(128), y = i*(128/size)})
				end
			elseif leveltype == "boss" then 
				for i = 1, size do
					add(bgndtable, circlestar(rnd(64), rnd(), 6,1,true))
				end
				for i = 1, size do
					add(bgndtable, circlestar(rnd(64), rnd(), 13,0.25,true))
				end
				for i = 1, size do
					add(bgndtable, circlestar(rnd(64), rnd(), 1,0.05,true))
				end
			end
			--clouds
			if existsintable(split"city,grassclouds,waterclouds",leveltype) then 
				for i = 1, size/5 do
					add(clouds, {x = rnd(128), y = i*(128/(size/5))})
				end
			end
			--asteroids
			if leveltype == "asteroids" then 
				for i = 1, rnd(3)+2 do
					add(asteroids, {x = flr(rnd(128))+128, y = flr(rnd(128))-128, size = 2, spr = 14, sp = speed/2})
				end
				add(asteroids, {x = flr(rnd(128))+128, y = flr(rnd(128))-128, size = 4, spr = 76, sp = speed/8}) --large asteroid
			end
		end,

		move = function(_ENV)
			local speedoffset = bgndspeed()
			if existsintable(split"upatmos,midatmos,lowatmos,moon1,moon2,moon3,mars",leveltype) then 
				for i in all(bgndtable) do
					i.y += speed+speedoffset
					if(i.y >= 150) i.y -= 170
				end
				for i in all(asteroids) do
					i.y+=speed+speedoffset
					if(i.y >= 128) i.y -= 170
				end
			elseif leveltype == "boss" then 
				for st in all(bgndtable) do
					st:move()
				end
			elseif leveltype == "cave" or leveltype == "deepcave" then 
				for i = 1, #cavetiley do
					cavetiley[i] += 1 +speedoffset
					if(cavetiley[i] >= 128) cavetiley[i] -= 160	
				end
			elseif leveltype == "spacereverse" then 
				for i in all(bgndtable) do
					if i.s >= 1.5 then
						if level == 49 then
							i.y += i.s/4
							if(i.y >= 127) i.y -= 135
						else
							i.y -= i.s
							if(i.y <= 0) i.y = 150
						end
					else
						if level == 49 then
							i.y += i.s/2
						else
							i.y += i.s/4
						end
						if(i.y >= 127) i.y -= 135
					end
					
				end
			elseif leveltype == "space" or leveltype == "asteroids" then 
				for i in all(bgndtable) do
					i.y += i.s+speedoffset
					if(i.y >= 127) i.y -= 135
				end
				if leveltype =="asteroids" then 
					for i in all(asteroids) do
						i.y += i.sp +speedoffset
						i.x -= i.sp
						if i.y >= 128 then 
							i.y = rnd(128)-128
							i.x = rnd(128)+128
						end
					end
				end
			else
				for i in all(bgndtable) do
					i.y += speed+speedoffset
					if(i.y >= 127) i.y -= 135
				end
				for i in all(clouds) do
					i.y += speed*2+speedoffset
					if(i.y >= 127) i.y -= 135
				end
			end
			if leveltype == "lava" then 
				for i in all(bgndtable) do
					if i.sizecurrent < i.s then 
						i.sizecurrent += 0.25
					else --reset bubble
						i.x = rnd(127)
						i.y = rnd(127)-8
						i.s = rnd(5)+5
						i.sizecurrent = rnd(20)-20
					end
				end
			end
		end,

		draw = function(_ENV)
			if existsintable(split"space,spacereverse,asteroids",leveltype) then
				for i in all(bgndtable) do
					scol = 6 -- default star col
					if(i.s < 1.5) scol = 13
					if(i.s < 1) scol = 1
					pset(i.x, i.y, scol)
				end
			elseif existsintable(split"upatmos,midatmos,lowatmos",leveltype) then
				for i in all(bgndtable) do
					line(i.x, i.y, i.x, i.y-i.l, 6)
				end
			elseif leveltype == "water" or leveltype =="waterclouds" then
				for i in all(bgndtable) do
					spr(5, i.x, i.y)
				end
			elseif existsintable(split"grass,grassclouds,sand",leveltype) then
				for i in all(bgndtable) do
					spr(i.sp, i.x, i.y)
				end	
			elseif leveltype == "cave" or leveltype == "deepcave" then
				if(leveltype == "deepcave") pal(5,0)
				
				for i = 1, #cavetiley do
					map(32,4+(i-2)*4,0,cavetiley[i],16,4)	
				end

				local darkcolour = 0
				local shadowlines = split"0,1,2,3,4,5,6,7,8,10,11,12,14,16,18,22,105,109,111,113,115,116,117,119,120,121,122,123,124,125,126,127"
				if(leveltype == "cave") darkcolour = 1
				for i = 1,#shadowlines do
					line(shadowlines[i],0,shadowlines[i],127,darkcolour)
				end
			elseif leveltype == "city" then 
				for i in all(bgndtable) do
					spr(abs(i.y)/32+51, i.x, i.y)
				end
			elseif existsintable(split"moon1,moon2,moon3,mars",leveltype) then 
				if leveltype == "mars" then
					pal(13,4) --mars colours
					pal(6,9)
				end
				if(leveltype == "moon1") pal(6,7)
				if(leveltype == "moon2") pal(6,13)
				if(leveltype == "moon3") pal(1,0) pal(6,5) pal(13,5) pal(5,1)

				for i in all(bgndtable) do spr(i.sp, i.x, i.y) end
			    for i in all(asteroids) do spr(46, i.x, i.y, 2, 2) end
			    pal()
			elseif leveltype == "lava" then 
				for i in all(bgndtable) do
					offset = i.sizecurrent/4
					if i.sizecurrent < (i.s-2) then
						circfill(i.x-offset, i.y-offset, i.sizecurrent, 8)
					else
						circ(i.x-offset, i.y-offset, i.sizecurrent, 4)
					end
				end
			elseif leveltype == "boss" then 
				for st in all(bgndtable) do
					st:draw()
				end
				circfill(64,64,8,0) --blackhole
			end
			--draw clouds
			if existsintable(split"city,grassclouds,waterclouds",leveltype) then 
				for i in all(clouds) do
					spr(56, i.x, i.y,2,1)
				end
			end
			--draw asteroids
			if leveltype == "asteroids" then 
				for i in all(asteroids) do
					spr(i.spr, flr(i.x), flr(i.y), i.size, i.size)
				end
			end
		end,
	}
	return setmetatable(bgndobj, {__index = _ENV})
end


----------------
--MAIN OBJECTS--
----------------

function enemyclass(enemytable)
	--spawntime, x0,y0,x1,y1, speed, sprite, movtype, startingtimer, shoottype, shootdelay, noofmines, noofbullets, kami, bulletproperty, repeats, twist, gaptable
	local enemy={
		x = enemytable[2],
		y = enemytable[3],
		x1 = enemytable[4],
		y1 = enemytable[5],
		speed = enemytable[6],
		sprite = enemytable[7],
		movtype = enemytable[8],
		shoottype = enemytable[10],
		shdel = enemytable[11],
		mines = enemytable[12],
		noofbullets = enemytable[13],
		kami = enemytable[14],
		bulletproperty = enemytable[15],
		nrepeats = enemytable[16],
		twist = enemytable[17],
		gaptable = enemytable[18] or 0,

		--collision box offset
		colx = 2, 
		coly = 1,
		colw = 3,
		colh = 5,
		--

		inplace = false,
		firstshot = true,
		dead = false,
		t0 = enemytable[9],
		entime = enemytable[9],
		repeatcounter = 7,
		pause = false,
		targetted = false,
		shtangle = 0,

		ang = atan2(enemytable[4] - enemytable[2], enemytable[5] - enemytable[3]),
		a = 0,
		startexit = false,

		move = function(_ENV)
			if not inplace then
				x += cos(ang)*speed
				y += sin(ang)*speed

				if y >= y1 then
					if(level != lastlevel or bossfightstarted) inplace = true
				end
			
			elseif startexit then
				x += cos(a)*speed
				y += sin(a)*speed
			else 
				--movement types
				if not pause then 
					if movtype == "straight" then
						y += speed
					elseif movtype == "straightslow" then
						y += speed/5
					elseif movtype == "straightvslow" then
						y += speed/9
					elseif movtype == "wiggledown" then
						y += 0.2*speed
						x += sin(0.5*entime)*speed
					elseif movtype == "wiggledownslow" then
						y += 0.1*speed
						x += sin(0.5*entime)*speed
					elseif movtype == "wiggle" then
						x += sin(0.5*entime)*speed
					elseif movtype == "circleft" then
						y += (sin(0.5*entime+0.5)*speed)/2
						x += (cos(0.5*entime+0.5)*speed)/2
						y += speed/20 --move down screen
					elseif movtype == "circright" then
						y += (-sin(0.5*entime+0.5)*speed)/2
						x += (cos(0.5*entime+0.5)*speed)/2
						y += speed/20 --move down screen
					elseif movtype == "fig8" then
						x += (sin(0.25*entime)*speed)/2
						y += (cos(0.5*entime)*speed)/2
					else
						--staystill
					end
				end

				if inplace then 
					local playertarget
					if #players == 1 then
						playertarget = players[1]
					else
						if players[1].dead then 
							playertarget = players[2]
						elseif players[2].dead  then
							playertarget = players[1]
						else
							playertarget = players[flr(rnd(#players)+1)]
						end
					end

					if mines > 0 then
						if firstshot or ((entime - t0) >= shdel) then
							if shoottype == "sin" or shoottype == "aimedsin" then
								--drop sin mine
								--x1,y1, ang, rate, range, count
								t0 = entime 
								if shoottype == "sin" then
									add(allbullets, emitsin(x+4,y+8,0.75,bulletproperty,10,noofbullets))
								else
									add(allbullets, emitsin(x+4,y+8,pointangle(playertarget, {x=x, y=y}),bulletproperty,10,noofbullets))
								end
								mines	-= 1
								firstshot = false
							end
							if shoottype == "spread" then
								--shoot spread shot
								--x1,y1,ang, range, count, size, gaptable)
								add(allbullets, emitspread(x+4,y+4, pointangle(playertarget,{x=x, y=y}), bulletproperty ,noofbullets, gaptable))
								t0 = entime 
								mines	-= 1
								firstshot = false
							end
							if shoottype == "spreadtwist" then
								--(x1,y1,ang, range, count, size)
								if nrepeats > 0 then
									pause = true
									if repeatcounter < 1 then
										local shotangle = 0
										if twist == "cw" then
											shotangle = (nrepeats/360)*2
										else
											shotangle = (-nrepeats/360)*2
										end
										add(allbullets, emitspread(x,y+2, shotangle, bulletproperty ,noofbullets, gaptable))
										nrepeats -= 1
										repeatcounter = 7
									else
										repeatcounter -=1
									end
								else
									t0 = entime 
									mines -= 1
									nrepeats = repeats
									pause = false
									firstshot = false
								end
							end
							if shoottype == "spiral" or shoottype == "revspiral" then
								--drop sin mine  (x1,y1,ang, direction, rate,count, size)
								t0 = entime 
								if shoottype == "spiral" then
									add(allbullets, emitspiral(x+4,y+8,0, 0 ,2,noofbullets))
								end
								if shoottype == "revspiral" then
									add(allbullets, emitspiral(x+4,y+8,0, 1 ,2,noofbullets))
								end
								mines -= 1
								firstshot = false
							end
							if shoottype == "aimed" then
								--aimed shots (x1,y1,ang, speed, count)
								t0 = entime 
								add(allbullets, emitaimedshot(x+4,y+8, pointangle(playertarget, {x=x, y=y}), 2, 1))
								mines -= 1
								firstshot = false
							end
						end
					else
						if (entime - t0) >= shdel then
							if kami == 1 then
								a = pointangle(playertarget, {x=x, y=y})
								sfx(60)
							else 
								a = pointangle({x = 128-x1, y = 150}, {x=x, y=y})
							end
							startexit = true
						end
					end
				end
			end

			if inplace then
				if(y > 140) or (y < -10) or (x > 140) or (x < -10) then dead = true end
			end
			
			if(not pause) entime += 1/60

			return dead
		end,

		draw = function(_ENV)
			if existsintable(levelswithshadows,leveltype) then
				for i = 2, 15 do
					pal(i, 1)
				end
				spr(sprite, x+3, y+3)
			end
			pal()
			spr(sprite, x,y)
		end,
	}
	return setmetatable(enemy, {__index = _ENV})
end

function createplayer(x0, y0, y1, nplayer)
	local player = {
		x= x0, 
		y = y0,
		sp = 1,
		iframes = 0,

		st = 2,
		inplace = false,
		dead = false,
		flames = false,
		exploded = false,

		--collision box offset
		colx = 3, 
		coly = 4,
		colw = 1,
		colh = 1,
		

		et = 0,
		yc = y1-y0,
		ed = 60,

		--code for smooth diagonal movement
		--source: https://www.youtube.com/watch?v=stoDWgR-kF8
		butarr=split"1,2,1,3,5,6,3,4,8,7,4,0,1,2,0",
		dirx=split"-1,1,0,0,-0.75,0.75,0.75,-0.75",
		diry=split"0,0,-1,1,-0.75,-0.75,0.75,0.75",
		lastdir = 0,
		dir = 0,

		move = function(_ENV)

			if(iframes > 0) iframes-=1

			local s = 1.5
			if (btn(4,nplayer-1) or btn(5, nplayer-1)) s = 0.5

			butarr[0] = 0
			if level == lastlevel and not bossfightstarted then 
				--wait
			elseif not inplace then
				et += 1
				y = quadeaseout(et, y0, yc, ed)
				if(et >= ed) inplace = true
			else
				if nplayer == 1 then
					dir = butarr[btn()&0b1111]
				else --player 2s controls need to be bitshifted to the right by 8
					dir = butarr[(btn()>>8)&0b1111]
				end

				if (lastdir != dir) and (dir >= 5) then 
					--anti cobblestone
					x = flr(x) + 0.5
					y = flr(y) + 0.5
				end

				if dir>0 then

					changeinx = dirx[dir]* s

					x += changeinx
					y += diry[dir]* s

					--set animation sprite
					if (changeinx > 0) and (sp == 1 or sp == 3) then
						sp = 3
					elseif changeinx < 0 and (sp == 1 or sp == 2) then
						sp = 2
					else 
						sp = 1
					end 


				else
					sp = 1
				end


				--keep in frame
				if(x <= -1) x = -1
				if(x >= 119) x = 119
				if(y <= 0) y = 0
				if(y >= 116) y = 116

				lastdir = dir

			end
		end,


		draw = function(_ENV)
			if not dead then 
				--draw shadow on non space levels
				if existsintable(levelswithshadows,leveltype) then
					for i = 2, 15 do pal(i, 1) end --change all colours to dark blue

					spr(sp, x+3, y+3)
				end
				pal()

				--jet flames at the back
				if levelcomplete then
					spr(rnd(2)+16, x, y+8)
				else
					if btn(4) or btn(5) then --if not going slow then do little flames
						spr(rnd(2)+20, x, y+7)
					else
						spr(rnd(2)+20, x, y+8)
					end
				end

				--endgame streaks
				if (endgamesequence) line(x+4, y+7, x+4, 128, 7)

				--change colours for player2
				if(nplayer == 2) pal(11,8) pal(3,2)

				if (iframes > 0) for i = 2, 15 do pal(i, 9) end

				spr(sp, x, y) --draw character
				pal()

				--friction flames
				if(flames) spr(flr(rnd(2))+18, x, y-4) --sfx(61)

			end
		end
	}
	return setmetatable(player, {__index = _ENV})
end

function makebullet(x1,y1,ang, speed, purple)
	local bullet ={
		x = x1,
		y = y1,
		a = ang, -- used for explosion angle
		dead = false,
		--collision box offset
		colx = -1,
		coly = -1,
		colw = 1,
		colh = 1,
		--
		move = function(_ENV)
			x += cos(ang)*speed/2
		 	y += sin(ang)*speed/2

		 	return x >129 or y >129 or x < -4 or y < -4
		end,
		
		draw = function(_ENV)
			if leveltype == "sand" or leveltype =="lava" or purple then 
				pal(10,14)
				pal(9,2)
				spr(4, x-2, y-2, 0.5,0.5)
				pal()
			else
		 		spr(4, x-2, y-2, 0.5,0.5)
		 	end
		end,
	}
	return setmetatable(bullet, {__index = _ENV})
end

function createlargesprite(x0,y0,type)
	local largesprite={
		x = x0,
		y = y0,
		inplace = false,

		move=function(self)
			if type == "mothership" then 
				self.y+=0.5
			elseif type =="boss"  then 
				if self.y <= -8 then 
					self.y+=0.25
					leveltimer = 0
				else
					bossfightstarted = true
				end
			elseif type =="xen" then 
				if(self.x < menuxcoord+24 and not self.inplace) then 
					self.x += 1
				else
					self.x = menuxcoord+24
					self.inplace = true
				end
			elseif type =="ith" then 
				if(self.x > menuxcoord+65 and not self.inplace) then 
					self.x -= 1
				else
					self.x = menuxcoord+65
					self.inplace = true
				end
			end
		end,

		draw = function(self)
			if type == "mothership" then
				if player2 then 
					map(0,11,self.x, self.y, 16, 3)
				else
					map(0,8,self.x, self.y, 16, 3)
				end
			end

			if type == "boss" then 
				pal(6,5)
				pal(5,1)
				map(0,0,self.x, self.y+5, 16,7) --lower section
				pal()
				map(0,0,self.x, self.y, 16,7) --upper section
			end

			if(type == "xen") spr(203, self.x, self.y, 5,2)
			if(type == "ith") spr(235, self.x, self.y, 5,2)
		end
	}
	return largesprite
end

--------------------
--ENEMY SHOT TYPES--
--------------------

function emitsin(x,y,ang, rate, range,shotcount)
	local sinobj ={
		bulltable ={},
		y = y, --used to shoot it down the screen at end of level
		c = shotcount,
		hasmines = true,
		exploded = false,

		emit = function(_ENV)
			if c >0 then 
				add(bulltable, makebullet(x,y,(sin(rate*leveltimer)/range+ang), 1 ))
				c -= 1
				if(not bosssecondstage) sfx(62)
			end
		end,

		move = function(_ENV)
			for b in all(bulltable) do
				if(b:move()) then del(bulltable,b) end --while moving checks if the bullet is still alive and removes if not
			end
			--if(levelcomplete) y+=5
		end,

		draw = function(_ENV)
			for b in all(bulltable) do
				b:draw()
			end
			
			--if there are still shots coming out then draw the mine, otherwise explode it
			if level != lastlevel then --hide mines in last level
				if(c > 0) then
					
					if existsintable(levelswithshadows,leveltype) then
						for i = 2, 15 do
							pal(i, 1) --zero sets it for following colours, 1 retroactively changes everything on screen
						end
						spr(9, x-3, y-3)
					end
					pal()
					spr(9, x-4, y-4) --draw mine
				else
					if not exploded then 
						add(allexplosions, partemit(x,y,30, 0, 1,2,1.5,10,200,true))
						exploded = true
					end
				end
			end
		end,
	}
	return setmetatable(sinobj, {__index = _ENV})
end

function emitspread(x1,y1,ang, range, count, isgaps)
	local spreadobj ={
		bulltable ={},
		x = x1+4,
		y = y1+4,
		alive = true,
		startang = ang - range/2,
		anglesteps = range / count,
		gaps = {1},

		emit = function(_ENV)
			if alive then 
				for i = 1, count do
					--takes in a binary table where zeros are gaps in the firing pattern
					if (isgaps == 1) gaps={1,0,1}

					if(gaps[i%#gaps+1] == 1) add(bulltable, makebullet(x,y,startang,1))
					
					startang += anglesteps
				end
				alive = false
				if(not bosssecondstage) sfx(58)
			end
		end,

		move = function(_ENV)
			for b in all(bulltable) do
				if(b:move()) del(bulltable,b) --while moving checks if the bullet is still alive and removes if not
			end
		end,

		draw = function(_ENV)
			for b in all(bulltable) do
				b:draw()
			end
		end,
	}
	return setmetatable(spreadobj, {__index = _ENV})
end

function emitaimedshot(x,y1,ang, speed, count)
	local aimedobj ={
		bulltable ={},
		y = y1, --needed for end of level zoom
		fired = false,

		emit = function(self)
			if not self.fired then
				add(self.bulltable, makebullet(x,y1,ang,speed, true))
				self.fired = true
				if(not bosssecondstage) sfx(59)
			end
		end,

		move = function(self)
			for b in all(self.bulltable) do
				if(b:move()) del(self.bulltable,b) --while moving checks if the bullet is still alive and removes if not
			end
		end,

		draw = function(self)
			for b in all(self.bulltable) do
				b:draw()
			end
		end,
	}
	return aimedobj
end

function emitspiral(x1,y1,ang, direction, rate,count)
	local spiralobj ={
		bulltable ={},
		x = x1+4,
		y = y1+4,
		a = ang,
		c = count,
		exploded = false,

		emit = function(_ENV)
			if c >0 then 
				add(bulltable, makebullet(x,y,a,1))
				if(not bosssecondstage) sfx(57)
				c -= 1
				if(direction == 0) a += 0.151
				if(direction == 1) a -= 0.151
			end
		end,

		move = function(_ENV)
			for b in all(bulltable) do
				if(b:move()) del(bulltable,b) --while moving checks if the bullet is still alive and removes if not
			end
		end,

		draw = function(_ENV)
			for b in all(bulltable) do
				b:draw()
			end

			if level != lastlevel then --dont draw in final level
				if c > 0 then
					if existsintable(levelswithshadows,leveltype) then
						for i = 2, 15 do
							pal(i, 1) --zero sets it for following colours, 1 retroactively changes everything on screen
						end
						spr(9, x-3, y-3)
					end
					pal()
					spr(12, x-4, y-4) --draw mine
				else
					if not exploded then 
						add(allexplosions, partemit(x,y,30, 0, 1,2,1.5, 10, 200, true))
						exploded = true
					end
				end
			end
		end,
	}
	return setmetatable(spiralobj, {__index = _ENV})
end

------------------
--LEVEL CONTROLS--
------------------

function startnextlevel()
	if(mode == "menu" and level != 1) startedfromthebeginning = false
	mode = "game"
	levelstarted = false
	levelselect = false
	lockcontrols = false
	menuxcoord = 0
end

function start_level()
	allbullets={}
	allenemies={}
	allexplosions={}
	othersprites ={}
	players={}
	tran = nil
	

	if player2 then 
		add(players, createplayer(76,130,112,1))
		add(players, createplayer(44,130,112,2))
	else
		add(players, createplayer(60,130,112,1))
	end
	
	gamelevel(level) --called to set leveltype before creating the bgdn
	
	if(existsintable(split"grass,grassclouds,boss",leveltype)) bgnd = createbgnd(30, 1.5)
	if(existsintable(split"water,waterclouds,city",leveltype)) bgnd = createbgnd(15, 1)
	if(existsintable(split"space,spacereverse,asteroids",leveltype)) bgnd = createbgnd(100, 1.6)
	if(existsintable(split"mars,moon1,moon2,moon3",leveltype)) bgnd = createbgnd(7, 1)
	if(leveltype == "upatmos") bgnd = createbgnd(20, 5)
	if(leveltype == "midatmos") bgnd = createbgnd(40, 3)
	if(leveltype == "lowatmos") bgnd = createbgnd(20, 1.5)
	if(leveltype == "sand") bgnd = createbgnd(32, 1) --must be divisible by 8
	if(existsintable(split"cave,deepcave",leveltype)) bgnd = createbgnd(20, 0.5)
	if(leveltype == "lava") bgnd = createbgnd(7, 0.5)

	if(bgnd) bgnd:gen()

	opentransition = transition(-2)

	levelstarted = true
	levelcomplete = false
	deathsequence = false
	progressbar = 0
	progressbar2 = 0
	timeofdeath = 0
	leveltimer = 0
	clicks = 0
	speedramp = 20
	mutedelaytimer = 25
end

function gamelevel()
	leveltype = levelscenetable[level]
	if not levelstarted and level != 51 then 
		trans = transition(levelbgndtrantable[level])

	else --load in the enemies table and spawn them
		for en in all(levelenemytable[level]) do 
			local entable = split(en)
			if (entable and clicks == entable[1]) add(allenemies,enemyclass(entable))
		end
	end

	--set player flames for the correct levels
	for p in all(players) do
		if existsintable(split"3,4,5,22,23,24",level) then
			p.flames = true
		else
			p.flames = false
		end
	end 

	--special events
	if (level == 1 and not levelstarted) add(othersprites, createlargesprite(0, 90, "mothership"))
	if level == 2 and levelcomplete then 
		for p in all(players) do
			p.flames = true
		end	
	end 
	if level == lastlevel and not levelstarted then
		local bossy = -100
		if (bossfightstarted) bossy = -8

		add(othersprites, createlargesprite(0, bossy, "boss"))
	end

	if endgamesequence then
		--explode where the characters hit the ship
		if endgametimer > 200 and endgametimer < 320 then 
			--do explosions where the players hit it
			for p in all(players) do
				if endgametimer%5 == 0 then 
					add(allexplosions, partemit(p.x+4,rnd(30),20, 0, 1,2,1.5, 10, 80))
				end
			end
		end
		--general explosions
		if endgametimer > 400 and endgametimer < 550 then 
			if endgametimer%8 == 0 then 
				add(allexplosions, partemit(rnd(80)+22,rnd(30),20, 0, 1,2,1.5, 10, 110))
			end
		end

		--scan each pixel and turn it into a circlestar
		if endgametimer == 650 then --just do this at the start of the sequence
			local pixcolour
			othersprites = {}
			for y = 50, 0, -1 do
				for x = 0, 127, 1.25 do
					pixcolour = pget(x,y)
					if pixcolour != 0 then 
						--circlestar(radius, angle, colour, setspeed, loop)
						add(endgamefragments, circlestar(hyp(x,y), anglefromcentre(x,y), pixcolour, 1, false))
					end
				end
			end
		end
		endgametimer += 1

		for i in all(endgamefragments) do
			i:move()
			if(not i.alive) del(endgamefragments, i)
		end
	end

	
	


	if levelstarted then --check level complete to not repeat the sfx
		leveltimer += 1/60 --leveltimer in seconds, check to see if it exists first
		clicks += 1-- was like leveltimer, but need to be super precise for adding enemies
		
		if(not players[1].inplace) leveltimer = 0 clicks = 0

		if(level == lastlevel and not bossfightstarted) clicks = 0 --wait for boss before starting clicks
		if leveltimer >= 10 and not deathsequence and level != lastlevel then
			if(not levelcomplete) sfx(56)
			levelcomplete = true
		end
		if level == lastlevel and not deathsequence then
			if clicks == 600 then 
				music(-1)
				musicplaying = false
				bosssecondstage = true
				sfx(53,3)
			end

			if leveltimer >= 20 then
				if(not endgamesequence) then 
					sfx(-1)
					music(-1)
					sfx(52) 
					endgamesequence = true
					bosssecondstage = false -- so explosions sound again
				end
				for en in all(allenemies) do 
					en.dead = true
				end --kill all the turrets
				levelcomplete = true
			end
		end
		if level == lastlevel and leveltimer >= 10 then 
			for p in all(players) do
				p.flames = true
			end
		end
	end
end

---------
--MUSIC--
---------

function controlmusic()
	if musicplaying and not playmusic then 
		music(-1, 1000)
		musicplaying = false
	elseif not musicplaying and playmusic then 
		if (mode == "loadingscreen") return
		if mode=="menu" then
			if menumusicstart then
				music(2)
			else
				music(0)
			end
		end
		if (mode =="ending") music(55)
		if mode=="deathscreen" then 
			if existsintable(split"1,43,44,45,49,50",level) then
				music(-1,1000)
			else
				music(63)
			end
		end
		if mode == "endlevel" then
			if existsintable(split"2,43,44,45,49,50",level) then 
				music(-1)
			else
				music(63)
			end
		end
		if mode=="game" then
			if level != lastlevel then
				if(not levelcomplete) music(levelmusic[level], nil, 3)
			else
				if not endgamesequence then
					if not bossfightstarted then
						music(48,nil,1)
					else
						if bosssecondstage then							
							music(51,nil,7)
						else
							music(49,nil,3)
						end
					end
				end
			end
		end
		musicplaying = true
	end

	if mode == "deathscreen" and musicplaying  and bosssecondstage then
		music(-1,100)
		musicplaying = false
		bosssecondstage = false 
	end

	--this line is for when you've muted the music in the death screen and unmute
	--otherwise it keeps playing the deathscreen music (pattern 63)
	if (musicplaying and mode=="game" and stat(54) == 63) music(levelmusic[level], nil, 3)

	if musicplaying and mode == "game" and levelcomplete then 
		music(-1, 200)
		musicplaying = false
	end

	if (lastmode != mode and lastmode == "menu") musicplaying = false
	lastmode = mode
end

----------------------------------
-----------STATE ENGINE-----------
--UPDATE and DRAW for each state--
----------------------------------

--function update_loadingscreen()
--	loadingtimer += 1
	--if(btnp(4) or btnp(5) or btnp(4,1) or btnp(5,1)) mode = "menu"
--end

function draw_loadingscreen()
	if(loadingtimer == 0) sfx(54,1,0,18)
	if(loadingtimer == 50) sfx(-1)
	if(loadingtimer%2 == 0) then
		cls(13)
		if loadingtimer <= 48 or loadingtimer == 80 then
			
			if(loadingtimer == 80) sfx(54,1,32)
			local y = 0
			while y <= 128 do
				--draw random lines on screen
				local height = rnd(4)
				rectfill(0,y,128, y+height,rnd(15))
				y += height
			end
		end
			
		rectfill(16,16,112,112,12)
		if(loadingtimer >= 16) print('godmil presents', 20, 20, 10)
		if(loadingtimer >= 130) mode = "menu"
	end
	loadingtimer += 1
end

function update_menu()
	if not menuinitialised then 
		menuxcoord = 0
		revealtitle = titlereveal()
		revealtitle:gen()
		logo_xen = createlargesprite(-77, 80, "xen")
		logo_ith = createlargesprite(166, 80, "ith")
		menuinitialised = true
		menutimer = 0
		levelselect = false
		menueasingtime = 0
		menueasingduration = 60
	end

	--graphics animation
	revealtitle:move()
	logo_xen:move()
	logo_ith:move()

	if(logo_xen.inplace) lockcontrols = false menumusicstart = true

	if not levelselect and not lockcontrols and btnp(1) then 
		leveltransition = true
		lockcontrols = true
	end

	if levelselect and not lockcontrols and level == 1 and btnp(0) then 
		leveltransition = true
		lockcontrols = true
	end

	--screentransition
	if leveltransition then 
		menueasingtime += 1
		local tempmenux = quadeaseout(menueasingtime, 0, -128, menueasingduration)
		if levelselect then 
			menuxcoord = -128 -tempmenux
		else
			menuxcoord = tempmenux
		end
		if menueasingtime >= menueasingduration then 
			lockcontrols = false
			leveltransition = false
			menueasingtime = 0

			levelselect = not levelselect
		end
	end

	if not lockcontrols and levelselect then 
		if(btnp(0) and level > 1) level -=1
		if(btnp(1) and level < 51) level +=1
	end

	--start a timer after the menu animation
	if (logo_xen.inplace) menutimer +=1
	
	--players start
	presstostart()
end

function draw_menu()
	cls()
	map(18,0,menuxcoord + 20,0,12,12 )
	revealtitle:draw()
	logo_xen:draw()
	logo_ith:draw()

	--draw levelselect off to right
	levelselxcoord = menuxcoord+128

	--map
	shadowprint("choose a starting level",levelselxcoord+22,5,9)
	spr(32, levelselxcoord+7, 16, 14,1)
	rect(levelselxcoord+7, 15, levelselxcoord+121, 24, 8)
	rect(levelselxcoord+level*2+12, 18, levelselxcoord+level*2+15, 21, rnd(15)+1)

	--if levelselect then
		if level < 51 then levelnumber = level else levelnumber = "final" end
		shadowprint("level: ".. levelnumber, levelselxcoord+49, 33, 8)
	--end
	local flashingcolour = sin(t()/1.5)+10

	if (levelselect and level < 51)	shadowprint("\^w\^t>", levelselxcoord+87, 31, flashingcolour)
	if (levelselect and level > 1) shadowprint("\^w\^t<", levelselxcoord+39, 31, flashingcolour)

	if not(old1pstandardrecorded or old2pstandardrecorded or old1pinvunrecorded or old2pinvunrecorded) then
		print("complete all levels in\none go to set highscore ",levelselxcoord+24,86,5)
	end

	if(old1pstandardrecorded) print(old1pstandardhighscore, levelselxcoord+35, 86, 2)
	if(old1pinvunrecorded)	print(old1pinvunhighscore, levelselxcoord+83, 86, 2)
	if(old2pstandardrecorded)	print(old2pstandardhighscore, levelselxcoord+35, 94, 2)
	if(old2pinvunrecorded) print(old2pinvunhighscore, levelselxcoord+83, 94, 2)

	shadowprint("highscores",levelselxcoord+46, 68, 9)
	print("STANDARD   INVINCIBLE",levelselxcoord+25, 75, 2)
	line(levelselxcoord+25,82,levelselxcoord+108,82,5)
	print("p1", levelselxcoord+7, 86, 2)
	print("p1+p2", levelselxcoord+1, 94, 2)



	invinsiblemode()

	if(menutimer >= 30)	shadowprint("press ❎/🅾️ to start", 25,105,9,2)

	if menutimer >= 60 then 
		print("MENU ➡️", menuxcoord	+ 90, 120,5)
		mutebutton(menuxcoord)
	end
	--line(levelselxcoord+64, 0,levelselxcoord+64,128,7 )
end

function update_game()

	if (not levelstarted) start_level()

	--player 2 joins next level if button is pushed
	if(btn(4,1) or btn(5,1)) player2 = true

	gamelevel(level)

	if(bgnd) bgnd:move()
	for e in all(allenemies) do
		if(e:move()) del(allenemies,e)
	end
	for b in all(allbullets) do
		b:emit()
		if(b:move()) del(allbullets,b)

		if(#b.bulltable == 0) del(allbullets, b)
	end

	--update explosion particles
	for exp in all(allexplosions) do
		if(exp:move()) del(allexplosions,exp)
	end

	--collisions and player movement
	if not levelcomplete and not deathsequence then --only calculate collisions if the level isn't finished
		for p in all(players) do
			p:move() -- player only has control during gameplay
		end

		for p in all(players) do
			for e in all(allenemies) do
				if collision(p, e) then
					if vunerablemode then
						p.dead = true
						del(allenemies, e)
						--explosion code
						--(x0,y0,number, angle, range, force, resistance, forcemode, duration, lifetime, colourmode, colourtab)
						add(allexplosions, partemit(e.x+4,e.y+4,25/#players, 0, 1,2,1.5, 10, 200))
						add(allexplosions, partemit(p.x+4,p.y+4,40/#players, 0, 1,1.5,1.1, 15, 200))
					else
						if(p.iframes == 0) then 
							hitsperlevel[level] +=1
							p.iframes=10
							totalrestartcounter+=1
							add(allexplosions, partemit(p.x+4,p.y+4,10, 0, 0.25,2,1.1, 5, 100))
						end
					end
				end
			end
		end
		
		for p in all(players) do
			for b in all(allbullets) do
				for b2 in all(b.bulltable) do
					if collision(p, b2) then
						if vunerablemode then
							p.dead = true
							del(allbullets, p)
							if not p.exploded then --check if exploded yet, to stop multiple hits
								add(allexplosions, partemit(p.x+4,p.y+4,25/#players, b2.a, 0.25,2,1.1, 10, 200))
								add(allexplosions, partemit(p.x+4,p.y+4,35/#players, 0, 1,0.75,1.1, 10, 100))
								p.exploded = true
							end
						else
							if(p.iframes == 0) then 
								hitsperlevel[level] +=1
								p.iframes=10
								totalrestartcounter+=1
								add(allexplosions, partemit(p.x+4,p.y+4,10, b2.a, 0.25,2,1.1, 5, 100))
							end
						end
					end
				end
			end
		end


		if #players>1 then
			if(players[1].dead and players[2].dead) deathsequence = true 
		else
			if(players[1].dead) deathsequence = true 
		end
		

	elseif levelcomplete and not deathsequence then
		--player level complete animation
		--shoot player up the screen and everything else down
		for p in all(players) do
			p.y-=5
			if(endgamesequence) p.y -= 5
		end

		for b in all(allbullets) do
			if not endgamesequence then 
				b.y += 5
				for b2 in all(b.bulltable) do
					b2.y +=5
				end
			end
		end
		for e in all(allenemies) do e.y += 5 end

		if endgamesequence then 
			if(leveltimer >= 46) mode = "ending"
		elseif leveltimer >= 11  and not deathsequence then
			mode = "endlevel"
			level += 1
		end
	end

	for sprs in all(othersprites) do
		sprs:move()
	end


	if(deathsequence) timeofdeath += 1
	if timeofdeath >= 60 then
		mode = "deathscreen"
		totalrestartcounter +=1
		hitsperlevel[level] += 1
	end

	--update progress bar if player still alive
	if level == lastlevel and bossfightstarted then
		if not deathsequence then
			progressbar = 126*leveltimer/10
			progressbar2 = progressbar -124
		end
	elseif not deathsequence then 
		progressbar = 126*leveltimer/10
	end
end

function draw_game()
	--clear the screen the colour of the stage
	cls(levelbgndtable[level])

	if(bgnd) bgnd:draw()

	--check if a transition exists before drawing it
	if (levelcomplete and leveltimer > 10.5 and level != lastlevel) trans:draw()

	--end game sequence
	if endgamesequence then 
		foreach(endgamefragments, function(obj) obj:draw() end)

		circfill(64,64,8,0) --blackhole
	end

	for p in all(players) do
		if(endgametimer < 50) p:draw()
	end

	--draw all the enemies
	for e in all(allenemies) do
		e:draw()
	end

	--draw any other sprites
	for sprs in all(othersprites) do
		sprs:draw()
	end

	--for last level flying over ship
	if level == lastlevel and not endgamesequence then 
		foreach(players, function(obj) obj:draw() end)
	end

	for b in all(allbullets) do
		b:draw()
	end

	--draw any explosions
	for exp in all(allexplosions) do
		exp:draw()
		if(exp.parttable == 0) del(allexplosions, exp)
	end

	--display level number
	if(leveltimer <= 1.5 and level != lastlevel) centretext("level "..level, 60, 7, true)
	
	if leveltimer <= 2.5 then 
		if level == 1 then
				centretext("survive until your", 70, 10, true)
				centretext("boost is charged", 78, 10, true)
		end 
		if(level == 2) centretext("hold button to slow down", 70, 10, true)
		if(level == 3) centretext("goodluck!", 70, 10, true)
		if not existsintable(split"1,2,3,51", level) then 
			if(hitsperlevel[level] == 10) centretext("you can do it!", 70, 10, true)
			if(hitsperlevel[level] == 20) centretext("you've got this!", 70, 10, true)
			if(hitsperlevel[level] == 50) centretext("it's ok to take a break", 70, 10, true)
		end
	end

	--progress bar
	if not levelcomplete then
		rectfill(1,125,126,126,0)
		rectfill(0, 125, progressbar, 126, 10)
		if(level == lastlevel) rectfill(0, 125, progressbar2, 126, rnd(3)+8)
		rect(0,124,127,127,2)
	end

	--endgame wipe
	if(leveltimer >44) circfill(64,64,(leveltimer-44)*150, 7)

	if(leveltimer <1) opentransition:draw()
end

function update_deathscreen()
	sfx(-1)
	if(bosssecondstage) musicplaying = false
	presstostart()
end

function draw_deathscreen()
	cls()
	centretext("\^w\^tyou lost", 32, 8, true,2,true)
	centretext("press ❎/🅾️ to restart", 65, 9, true)
	print("restarts:", 5, 96, 5)
	print(totalrestartcounter, 5, 106, 9)
	print("this level:", 85, 96, 5)
	print(hitsperlevel[level], 128-print(hitsperlevel[level],0,256), 106, 9)
	mutebutton(0)
	exit()
end

function update_endlevel()
	presstostart()
end

function draw_endlevel()
	cls()
	spr(32, 7, 16, 14,1)
	rect(7, 15, 121, 24, 8)
	rect(level*2+12, 18, level*2+15, 21, rnd(15)+1)

	centretext("congratulations", 42, 10, true)
	shadowprint("press ❎/🅾️ to", 35, 70, 10, 2)
	centretext("start next level", 80, 10, true)
	if(not vunerablemode) centretext("hits in the last level: "..hitsperlevel[level-1], 100,9, true)

	mutebutton(0)
	exit()
end

function update_ending()
	if endscreentimer == 0 then 
		players = {} --reset to get rid of players
		endgamesequence = false
		leveltype = "space"
		bgnd = createbgnd(100, 1.6)
		bgnd:gen()
		congrattexty = -20
		endmapy = 140
		restartcounterx = -80
		histogram = split"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
		newhighscore = false

		--highscores
		if startedfromthebeginning and not newhighscore then --just doing not new highscore to stop it spamming dset, but not needed 
			if vunerablemode then
				if player2 then 
					if old2pstandardrecorded then
						if(totalrestartcounter < old2pstandardhighscore) dset(1, totalrestartcounter) newhighscore = true
					else
						dset(1, totalrestartcounter) dset(11,1) newhighscore = true
					end
				else
					if old1pstandardrecorded then 
						if(totalrestartcounter < old1pstandardhighscore) dset(0, totalrestartcounter) newhighscore = true
					else
						dset(0, totalrestartcounter) dset(10,1) newhighscore = true
					end
				end
			else
				if player2 then 
					if old2pinvunrecorded then
						if(totalrestartcounter < old2pinvunhighscore) dset(3, totalrestartcounter) newhighscore = true
					else
						dset(3, totalrestartcounter) dset(13,1) newhighscore = true
					end
				else
					if old1pinvunrecorded then
						if(totalrestartcounter < old1pinvunhighscore) dset(2, totalrestartcounter) newhighscore = true
					else
						dset(2, totalrestartcounter) dset(12,1) newhighscore = true
					end
				end
			end
		end
	end
	
	if(endscreentimer > 120 and congrattexty < 16) congrattexty += 0.5
	
	if endscreentimer == 260 then 
		levelcomplete = true --turn on jet flames
		if player2 then 
			add(players, createplayer(44,130,40,1))
			add(players, createplayer(76,130,40,2))
		else
			add(players, createplayer(59,130,40,1))
		end
	end

	if(endscreentimer > 350 and restartcounterx < 30) restartcounterx += 1 

	if(endscreentimer > 500 and endmapy > 110) endmapy -= 0.5

	for p in all(players) do 
		p:move()
	end

	bgnd:move()
	endscreentimer += 1
end

function draw_ending()
	if(endscreentimer <100) then 
		cls(7)
	else
		cls()
		bgnd:draw()
	end

	for p in all(players) do 
		p:draw()
	end

	print("\^w\^tcongratulations", 4, congrattexty+1, 9)
	print("\^w\^tcongratulations", 3, congrattexty, 10)

	local totalmessage = " total hits: "
	if (vunerablemode) totalmessage = "total restarts: "

	print(totalmessage..totalrestartcounter, restartcounterx, 64, 9)

	if(endscreentimer > 500 and newhighscore) centretext("new high score!", 72, rnd(3)+8)

	--map
	spr(32, 7, endmapy+1, 14,1)
	rect(6, endmapy, 122, endmapy+9, 13)

	--draw histogram
	if endscreentimer > 600 then 
		for i = 1, 51 do
			if hitsperlevel[i] > 0 then
				rect(13+i*2, 109, 13+i*2, 109-histogram[i], 8)
				if histogram[i]<hitsperlevel[i] then
					histogram[i]+=1
					break
				end
			end
		end
	end
end


--[[function draw_screenshot()
	cls(1)
	map(18,0,20,23,12,12 )
	spr(203, 24, 10, 10,2)
	spr(235, 65, 10, 10,2)
end]]

------------------
--MAIN FUNCTIONS--
------------------

function _init()
	cartdata("xenith")
	menuitem(2, "reset highscores", resetcartdata)
	loadingtimer = -1
	lastmode = "loadingscreen" --used for music changes
	mode = "loadingscreen"
	levelstarted = false
	bossfightstarted = false
	bosssecondstage = false
	endgamefragments = {}
	endgamesequence = false
	menuinitialised = false
	playmusic = true
	musicplaying = false
	level = 1
	lastlevel = 51
	leveltype = ""
	player2 = false
	vunerablemode = true
	totalrestartcounter = 0
	endgametimer = 0
	endscreentimer = 0
	lockcontrols = true --in main menu for transitions
	menumusicstart = false --used to set the start place for the menu music when its turned on again.
	exitclipy = 6
	player2joinstimer = 100
	mutedelaytimer = 25

	startedfromthebeginning = true
	--populate the table for each level Yeah I know its a mess but it uses fewer tokens.
	hitsperlevel=split"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
	levelmusic=split"8,9,10,11,10,12,11,10,13,12,14,12,15,12,20,21,22,21,20,6,7,23,7,6,16,17,16,26,27,26,16,24,25,24,17,28,29,28,18,19,18,19,30,31,30,18,19,28,32,-1,50"
	levelscenetable = split"space,space,upatmos,midatmos,lowatmos,grass,grass,water,water,grass,sand,sand,sand,water,waterclouds,grassclouds,city,city,grassclouds,lowatmos,lowatmos,midatmos,midatmos,upatmos,space,space,space,moon1,moon2,moon3,space,asteroids,asteroids,asteroids,space,mars,mars,mars,cave,cave,deepcave,deepcave,lava,lava,lava,deepcave,cave,mars,spacereverse,spacereverse,boss"
	levelswithshadows = split"grass,water,city,sand,moon1,moon2,moon3,mars,cave,deepcave"

	old1pstandardrecorded = false
	old2pstandardrecorded = false
	old1pinvunrecorded = false
	old2pinvunrecorded = false

	--highscores: standard mode
	if(dget(10) == 1) old1pstandardrecorded = true old1pstandardhighscore = dget(0)
	if(dget(11) == 1) old2pstandardrecorded = true old2pstandardhighscore = dget(1)
	--invincible mode
	if(dget(12) == 1) old1pinvunrecorded = true old1pinvunhighscore = dget(2)
	if(dget(13) == 1) old2pinvunrecorded = true old2pinvunhighscore = dget(3) 

	levelbgndtable=split"0,0,1,13,12,3,3,12,12,3,9,9,9,12,12,3,3,3,3,12,12,13,13,1,0,0,0,6,13,5,0,0,0,0,0,4,4,4,13,13,1,1,9,9,9,1,13,4,0,0,0,"
	levelbgndtrantable=split"-1,1,13,12,3,-1,12,-1,3,9,-1,-1,12,-1,3,-1,-1,-1,12,-1,13,-1,1,0,-1,-1,6,13,5,0,-1,-1,-1,-1,4,-1,-1,1,-1,0,-1,9,-1,-1,1,-1,4,0,-1,-1,"

	levelenemytable = {
		{--1
			"50,135,-10,64,10,2,10,wiggledown,0.35,sin,0.5,2,50,0,2",
			"250,-10,-10,64,10,2,10,wiggledown,-0.2,sin,0.5,2,50,0,2"
		},
		{--2
			"120,135,-10,64,10,2,8,wiggle,0,spreadtwist,1.5,1,30,0,1,7,cw",
			"300,-10,-10,64,10,2,8,wiggle,0,spreadtwist,1.5,1,30,0,1,7,ccw"	
		},
		{--3
			"50,-10,-10,30,10,2,8,wiggledown,0.45,spread,1.25,12,12,0,1,5,cw",
			"150,135,-10,30,10,2,8,wiggledown,0,spread,1.25,12,12,0,1,5,cw",
			"250,-10,-10,30,10,2,8,wiggledown,0.4,spread,1.25,12,12,0,1,5,cw"
		},
		{--4
			"50,-10,-10,30,10,2,13,wiggledown,0.5,aimed,1.25,5,1,1",
			"120,135,-10,64,10,2,13,wiggle,0,aimed,1.25,3,1,1",
			"200,-10,-10,30,20,2,13,wiggle,0.5,aimed,1.25,4,1,1"
		},
		{--5
			"50,-10,-10,30,10,2,11,circright,0,spiral,1,1,100,0",
			"200,135,-10,64,10,2,11,circright,0,revspiral,1,1,100,0",
			"300,135,-10,30,10,2,11,circright,0,spiral,1,1,100,0"	
		},
		{--6
			"50,-10,-10,30,10,2,8,wiggle,0,spreadtwist,1.5,1,30,0,1,10,cw",
			"185,-10,-10,30,10,2,13,wiggle,0.5,aimed,1.25,3,1,1",
			"270,135,-10,64,10,2,13,wiggledown,0,aimed,1.25,3,1,1"	
		},
		{--7
			"50,-10,-10,30,10,2,8,wiggle,0.5,spread,0.9,7,60,0,1,11,cw,1"
		},
		{--8
			"50,-10,-10,30,10,2,8,wiggledown,0.5,spread,1.25,12,12,0,1,5,cw",
			"150,135,-10,30,10,2,8,wiggledown,0,spread,1.25,12,12,0,1,5,cw",
			"250,-10,-10,90,10,2,8,wiggledown,0.5,spread,1.5,1,40,0,1,5,cw"	
		},
		{--9
			"100,-10,-10,64,10,2,8,wiggle,0,spreadtwist,1.1,1,25,0,1,10,cw",
			"100,135,-10,30,10,2,8,wiggle,0,spreadtwist,1.1,1,25,0,1,10,cw"	
		},
		{--10
			"50,135,-10,64,10,2,11,circright,0,revspiral,1,1,100,0",
			"150,-10,-10,64,10,2,8,wiggle,0,spread,0.75,8,10,0,0.25,10,cw"
		},
		{--11
			"50,-10,-10,30,10,2,13,wiggledownslow,0.5,aimed,0.25,40,1,1"
		},
		{--12
			"50,135,-10,64,10,2,11,circright,0,revspiral,1.25,2,50,0",
			"150,-10,-10,35,35,2,11,circleft,0,spiral,1.25,4,50,0"
		},
		{--13
			"50,-10,-10,30,10,2,13,wiggledownslow,0.5,aimed,0.25,40,1,1",
			"150,135,-10,64,10,2,13,wiggledownslow,-0.1,aimed,0.25,40,1,1"	
		},
		{--14
			"50,135,-10,30,10,2,10,wiggledownslow,0.1,aimedsin,0.9,5,20,0,2",
			"300,135,-10,64,10,2,10,wiggledownslow,-0.1,aimedsin,0.7,6,20,0,2"	
		},
		{--15
			"50,-10,-10,10,10,2,8,straightslow,0,spread,0.75,8,5,0,0.25,10,cw",
			"50,135,-10,110,10,2,8,straightslow,0,spread,0.75,8,5,0,0.25,10,cw"	
		},
		{--16
			"75,-10,-10,30,10,2,8,wiggle,0,spreadtwist,1.5,1,30,0,1,30,cw"
		},
		{--17
			"50,135,-10,64,10,2,11,circright,0,revspiral,1,1,350,0",
			"150,-10,-10,110,10,2,11,circright,0,revspiral,1,1,300,0"	
		},
		{--18
			"100,-10,-10,30,10,2,8,wiggledown,0.5,spread,0.9,7,60,0,1,11,cw,1"
		},
		{--19
			"50,-10,-10,10,10,2,8,straightvslow,0,spread,0.7,10,5,0,0.15,10,cw",
			"150,135,-10,100,10,2,8,straightvslow,0,spread,1,10,8,0,0.25,10,cw"
		},
		{--20
			"50,-10,-10,30,10,2,11,circright,0.5,spiral,1,4,50,0",
			"200,135,-10,64,10,2,11,circright,0,revspiral,1,4,50,0"
		},
		{--21
			"50,-10,-10,30,10,2,8,wiggle,0.5,spread,0.7,12,45,0,0.5,11,cw,1"
		},
		{--22
			"50,135,-10,30,10,2,10,wiggledownslow,0,aimedsin,0.7,8,50,0,2",
			"175,64,-10,64,10,2,13,straightslow,0,aimed,0.5,20,1,1"	
		},
		{--23
			"50,-10,-10,30,10,2,13,circright,0.1,aimed,1,8,50,1",
			"100,135,-10,90,30,2,13,circleft,0.5,aimed,1,8,50,1",
			"150,64,-10,64,10,2,8,straightslow,0,spread,1.25,12,12,0,1,5,cw"
		},
		{--24
			"50,-10,-10,10,10,2,8,straightslow,0,spread,1.25,12,12,0,1,5,cw",
			"90,135,-10,110,10,2,8,straightslow,0,spread,1.25,12,12,0,1,5,cw",
			"130,-10,-10,30,10,2,8,straightslow,0,spread,1.25,12,12,0,1,5,cw",
			"170,135,-10,90,10,2,8,straightslow,0,spread,1.25,12,12,0,1,5,cw"
		},
		{--25
			"50,135,-10,64,10,2,10,circright,0,aimedsin,0.5,16,25,0,2",
			"150,64,-10,90,2,2,13,wiggle,0,aimed,1,8,50,1"
		},
		{--26
			"70,-10,-10,10,10,2,8,straightvslow,0,spread,0.9,7,20,0,1,11,cw,1",
			"70,135,-10,110,10,2,8,straightvslow,0,spread,0.9,7,20,0,1,11,cw,1"
		},
		{--27
			"50,-10,-10,5,5,2,13,straightvslow,0,aimed,0.5,20,1,1",
			"90,135,-10,120,10,2,13,straightvslow,0,aimed,0.5,20,1,1",
			"130,-10,-10,30,10,2,13,straightvslow,0,aimed,0.5,20,1,1",
			"170,135,-10,90,10,2,13,straightvslow,0,aimed,0.5,20,1,1"
		},
		{--28
			"50,-10,-10,10,10,2,10,straightvslow,0,aimedsin,1.5,12,40,0,2",
			"150,135,-10,110,10,2,10,straightvslow,0,aimedsin,1.5,12,40,0,2"
		},
		{--29
			"50,135,-10,30,10,2,10,wiggle,0,aimedsin,0.9,2,200,0,2",
			"150,64,-10,90,5,2,13,wiggle,0,aimed,0.5,12,50,1"
		},
		{--30
			"50,-10,-10,30,10,2,8,wiggle,0.5,spread,0.5,15,60,0,1,12,cw,1"
		},
		{--31
			"50,135,-10,30,20,2,10,wiggle,0,sin,1,1,420,0,4",
			"100,-10,-10,64,3,2,10,wiggle,0,aimedsin,1.5,5,40,0,2"
		},
		{--32
			"50,-10,-10,30,5,2,11,wiggle,0.5,spiral,1.2,6,50,0",
			"100,135,-10,64,15,2,11,wiggle,0,revspiral,1.3,6,50,0",
		},
		{--33
			"50,-10,-10,0,2,2,13,straightvslow,0,aimed,0.15,60,1,1",
			"100,135,-10,120,10,2,13,straightvslow,0,aimed,0.25,60,1,1"	
		},
		{--34
			"50,-10,-10,10,10,2,8,straightslow,0,spread,1.25,12,12,0,1,5,cw",
			"80,135,-10,110,10,2,8,straightslow,0,spread,1.25,12,12,0,1,5,cw",
			"120,-10,-10,60,10,2,8,straightslow,0,spread,1.25,12,12,0,1,5,cw",
			"150,135,-10,90,10,2,8,straightslow,0,spread,1.25,12,12,0,1,5,cw",
			"180,-10,-10,30,10,2,8,straightslow,0,spread,1.25,12,12,0,1,5,cw"	
		},
		{--35
			"50,-10,-10,10,10,2,10,straightvslow,0,aimedsin,1,12,40,0,2",
			"100,135,-10,110,10,2,10,straightvslow,0,aimedsin,1,12,40,0,2"	
		},
		{--36
			"50,-10,-10,64,10,2,8,wiggle,-0.5,spreadtwist,1.5,1,30,0,1,45,ccw"	
		},
		{--37
			"50,135,-10,30,10,2,10,wiggledownslow,0,aimedsin,0.9,6,25,0,2",
			"175,-10,-10,30,10,2,10,wiggledownslow,0.5,aimedsin,0.8,6,25,0,2",
			"250,135,-10,64,10,2,10,wiggledownslow,0,aimedsin,0.7,7,35,0,2"		
		},
		{--38
			"50,-10,-10,35,35,2,13,circright,0,aimed,0.45,15,1,1",
			"80,100,-10,95,35,2,13,circleft,0,aimed,0.5,15,1,1",
		 	"110,-10,-10,35,35,2,13,circright,0,aimed,0.47,15,1,1",
			"140,135,-10,90,10,2,13,circleft,0,aimed,0.52,15,1,1",
			"170,64,-10,64,2,2,13,wiggle,0.5,aimed,0.54,15,1,1"
		},	
		{--39
			"50,130,20,85,40,2,8,fig8,0.1,spread,0.4,20,30,0,1,12,cw"	
		},
		{--40
			"50,-10,-10,64,10,2,8,wiggle,0,spreadtwist,1.5,1,30,0,1,12,ccw",
			"155,135,-10,30,10,2,8,wiggle,0,spreadtwist,1.5,1,30,0,1,10,cw",
			"260,-10,-10,64,10,2,8,wiggle,0,spreadtwist,1.5,1,30,0,1,15,ccw"	
		},
		{--41
			"50,-10,-10,64,10, 2, 13,fig8,0.5,aimed,1.2,15,1,true",
			"150,-10,-10,10,10,2,8,straightvslow,0,spread,1.2,15,50,0,1,12,cw,1",
			"280,135,-10,110,10,2,8,straightvslow,0,spread,1.2,15,50,0,1,12,cw,1"
		},
		{--42
			"30,-10,-10,10,10,2,28,straightvslow,0,spread,1.2,15,45,0,1,12,cw,1",
			"150,135,-10,110,10,2,28,straightvslow,0,spread,1.2,15,45,0,1,12,cw,1",
			"270,-10,-10,10,10,2,28,straightvslow,0,spread,1.2,15,45,0,1,12,cw,1",
			"390,135,-10,110,10,2,28,straightvslow,0,spread,1.2,15,45,0,1,12,cw,1"
		},
		{--43
			"50,-10,20,64,35,2,28,straightslow,0,spreadtwist,1,1,6,0,1,100,cw",
			"50,135,-10,110,10,2,13,straightvslow,0,aimedsin,1,12,25,0,2",
			"400,135,20,35,35,2,28,straightslow,0,spread,1,6,6,0,0.25,10,cw"
		},
		{--44
			"50,135,-10,30,2,2,10,wiggle,0,aimedsin,0.75,11,40,0,2",
			"150,60,-10,60,16,2,28,still,0,spread,1.5,15,30,0,1,12,cw"
		},
		{--45
			"50,-10,-10,10,10,2,73,straightvslow,0,spiral,1.5,5,60,0",
			"100,135,-10,110,10,2,73,straightvslow,0,revspiral,1.5,5,60,0"
		},
		{--46
			"50,-10,20,64,35,2,8,fig8,0,spread,1,20,30,0,1,12,cw",
			"100,-10,-10,10,10,2,10,still,0,aimedsin,1.5,6,25,0,2",
			"100,135,-10,110,10,2,10,still,0,aimedsin,1.5,6,25,0,2"
		},
		{--47
			"50,-10,-10,35,35,2,11,circleft,0.5,spiral,1.3,10,60,0",
			"100,135,-10,80,25,2,11,circright,0,revspiral,1.3,10,60,0"
		},
		{--48
			"70,135,-10,110,10,2,8,straightvslow,0,spread,0.8,15,30,false,1,30,cw,1",
			"50,-10,-10,30,10,2,8,wiggle,0.5,spread,0.75,15,30,false,1,30,cw,1",
			"100,135,-10,10,10,2,8,straightvslow,0,spread,0.8,15,30,false,1,30,cw,1"
		},
		{--49
			"50,64,-10,64,10,2,8,straightvslow,0,spread,1,20,25,0,0.75,12,cw",
			"50,-10,-10,10,10,2,8,still,0,spread,1.1,20,10,0,0.25,12,cw",
			"50,135,-10,110,10,2,8,still,0,spread,1.2,20,10,0,0.25,12,cw"
		},
		{--50
			"50,-10,-10,30,10, 2, 13,wiggle,0.5,aimed,0.6,20,1,1",
			"50,-10,20,64,35,2,8,fig8,0,spread,0.35,30,10,0,0.5,12,cw",
			"100,135,-10,110,10,2,8,still,0,spread,0.8,15,30,0,1,30,cw,1"
		},
		{--51
			"260,0,-20,16,-4,2,10,still,0,aimedsin,7,20,100,0,2",
			"120,0,0,27,12,2,8,still,0,spread,1.2,15,50,0,1,12,cw,1",
			"10,0,0,48,21,2,13,still,0,aimed,2,30,1,1",
			"60,0,0,68,21,2,8,still,0,spread,3,15,30,0,1,12,cw",
			"180,0,0,89,14,2,8,still,0,spreadtwist,20,1,30,1,1,5,ccw",
			"320,0,-20,99,-6,2,11,still,0,revspiral,4,8,80,0",
			"600,0,0,89,14,2,8,still,0,spreadtwist,20,1,30,1,1,5,cw"
		},
	}
end

function _update60()
	if(mode == "menu") update_menu()
	if(mode == "game") update_game()
	if(mode == "deathscreen") update_deathscreen()
	if(mode == "endlevel") update_endlevel()
	if(mode == "ending") update_ending()

	controlmusic()
end

function _draw()
	if(mode == "menu") draw_menu()
	if(mode == "game") draw_game()
	if(mode == "deathscreen") draw_deathscreen()
	if(mode == "endlevel") draw_endlevel()
	if(mode == "ending") draw_ending()
	if(mode == "loadingscreen") draw_loadingscreen(loadingtimer)
	--if(mode == "screenshot") draw_screenshot()
	player2joins()
end





__gfx__
00000000000b30000003b000000b500009900000000000000000b000000000000008200000000000666006660099940000000000060660600000000000000000
00000000000b30000003b000000350009aa90000000000000000b000b000000000898200006060006d5156d509aaa94000a0a000060650500000055dd5500000
00700700000b30000003b000000350009aa90000000000000000b000b00000b000898200006655506c5dd6c59aacca9400aa99400657c55000005dddddd00000
0007700000b335000003b00000035000099000000666060000000000000000b0a088820a066555006c5dc6c5aa67c5a90aa99900060cc05000056dddddd51000
0007700000bc630000c63b0000b56c000000000000000000000000000000b0b09ac6cc99006551106c5cc6c5a967659a0099944006065050005d66ddddd11000
007007000b36635000663b000035660000000000000000000b0000000000b00009acc990065511006c5156c50a6765a00a9944000006500005d66dddd5511100
000000000b33335000b33b000035530000000000000000000b00000b00000000009a9900000101006c5006c50067650000040400000650000d6dddddd5115110
0000000000055000000550000005100000000000000000000000000b000000000009900000000000655006550006500000000000000650000ddddd5d51115150
009aa900009aa9000000000000000000000aa000000aa000000000a5000000aa00a0000000000000000000000000000000082000556666550555555551111110
090aa090000aa000000aa000000000000009a000000a900000000a500000aa5500000000000a0000000000000006600000898200567777150155151111115511
000aa000000aa00000a99a00000aa00000009000000900000000a500000a550000000000000000a00065000000665500008982006771177100d515d555155111
000aa000000aa000009889000a9999a0000000000000000000aa500000a50000000000000a0000000055100000655550a088820a671761710055555dd5155100
000aa000000aa0000a8008a00990099000000000000000000a5500000a5000000000000a000000000015100000655510aac6ccaa67166171001155dd51111000
000a90000009a00009800080a980009a00000000000000000a5000000a500000000000000000000000010000000111000a9cc9a0677117710000155111111000
000990000000900098000089a80000890000000000000000a5000000a50000000000000000000000000000000000000000a99a00567777150000155515510000
000900000000000080000008900000080000000000000000a5000000a500000000a0000000a0000a0000000000000000000aa000551111550000015115100000
000000600000011ddcc3333ccccccc333cccccccc3333ccccdddd110060000000000500500000609944444444444444444444450000000000000000000000000
06000000060011ddccc333ccc33c333333cccccc335563ccccdddd11000000006600000005000009444544444444444444444450000000000000001111100000
00000006000011ddcc3333cccc333993333cccc3555533ccccdddd11000000065d50000000000094444444444444499994444445000011000000111151510000
00000965000011ddcc3333cccc33999999ccc636565636ccccdddd110000006dddd5005050500094444466665555999999556645000100100000111551551000
00000955000011ddcc3333cccc33999993cccc33553333ccccdddd1100000065ddd500000000009444444444444499999944444500010010000111155555d100
00000005000011ddcc3333cccc33399993cccc33556333ccccdddd1100000006dd50000006000094454444444444999994444445000011000011515555ddd510
00000000600011ddccc33cccccc3339933ccccc3333336ccccdddd11000600006500000550050094444444444444499444444450000000000015155d55dddd10
006000000000011ddcc333cccccc3399333cccc363553ccccdddd110000000000000000000000009444454444444444444444450000000000011555ddddddd50
6555556566600000000006663666666333333333333333333333333333333333000077760000000055676615556666156666666655555565001155dddddd6dd5
5155655111600000000006113655556336666663333333333333333333333333000777776000000055676615666676661611111156665551001555dddddd66d5
56156165566000000000066136555563365555633666666335555553355555530077777777776000556766155667666156156165561115550015555dddd66d50
5615615156600000000006613666666136555561365555613666666135555551007777767777776055676615556766155615615156155655000155ddd6d6dd50
5665615556600000000006613555555136666661365555613655556136666661077777677676776055676615556766155665615555155515000155d5dd6dd500
5511661555600000000006153555555135555551366666613655556136555561777677776777666055676615556766155511661555666655000155ddd6ddd500
55615115556666666666661535555551355555513555555136666661365555617777666677776000556766155567661555615115560000610000155d55d55000
56615561566155616155666133111111331111113311111133111111366666610666000067760000556766155567661556615561660000660000011151500000
00000000660000000000000000000000000000000222222200000000000000000000000000444400000000000000000000000000000015510000000000000000
000050005566000000000000000000000000288888888888888420000000000000000000049aa9400000000000000000000000000005ddd55551000000000000
00005500555560000000000000000000288888888888888888888884200000000000000049acca94000000000000000000000000005ddddd55dd500000000000
000050505665560000000000000004888888888420000000248888888884000000000000aa67c5a900000000000000000000000005dd5dddd5ddd55000000000
000050005511556000000000000488888822000000000000000002488888882000000000a967659a0000000000000000000000005dddddddddddddd510000000
0000500055661560000000000488888200000000000000000000000002888888000000000a6765a0000000000000000000000005ddddd5ddddd5ddd555000000
0055500055561556000000028888400000000000000000000000000000044888840000000067650000000004000000000000000ddddddddddd555dd555500000
00555000555515560000028888200000000000000000060000000000054aa94888820000000650000000059aa00000000000005dddddddddd5555d5555510000
000000660000000000008888200000000000000000000000000000054aa9455548888000000000000054aaaaa40000000000005dddddddddd555555555110000
0000661100000000002888800000000000000000000000000000004aa9455000008888200000000059aaaaaaaa000000000001ddddddddddd555555551111000
000611550000000004888200000000000000000000000000000059a9455000000002888400000549aaaaaaaaa4000000000005dddddd5dd5d555555555111000
0061555500000000888800000000000000000000000000000059a945500000000000088840059aaaaaaaaa9440000000000005ddddd55555dd5555d555511100
06155665000000088840000000000000000000000000000059aa45500000000000000044449aaaaaaaa994400000000000005dddddd5dddddd55555515511100
061555110000008882000600000000000006000000000059aa4550000006000000000054aaaaaaaaa9445000000000000000ddddddd55ddddd55555555111000
6155665500000888200000000000000000000000000004aa4550000000000000000549aaaaaaaa9445500000000000000005ddddddd5ddddddd5555551111000
61556115000088820000000000000000000000000004aa4550000000000000000599aaaaaaa944455000000000000000000ddddddddddddddd55511111111100
0000000000088820000000000000000000000000059a955000000000000000559aaaaaaa994454500000000000000000001dddddddd5ddddd515511111111100
00000000008882000000000000000000000000059a95500000000000000054aaaaaaa994455524200000000000000000005ddddddd55dddd5511111111111100
000000000488200000000000000000000000059a95500000000000000059aaaaaaa9445550002882000000000000000000dddddddd5dddd55551111111111000
0000000008880000000000000000000000059a95000000000000000549aaaaaa9445550000000888000000000000000000dddddddddddd515551111111110000
00000000888000000000000000000000059a9500000000000000559aaaaaa9945550000000000088800000000000000001dddddddddddd515511111111110000
000000088800000000000000000000054a9500000000000000559aaaaa9944550000000000000028840000000000000005ddd5dd55ddd5515111115111100000
0000000882000000600000000000004a950000000000000054aaaaa99445550000000000000000048800000000000000055555d5555555515111115115100000
00000088800000000000000000004a950000000000000549aaaaa944555000000000000000000000888000000000000001555551555555551111155111000000
000002882000000000000000004995000000000000054aaaaa94455500000000000000000000000028820000000000000005555555d555511111555110000000
0000088800000000000000005994500000000000559aaaa994555000000000000000000000600000088800000000000000055555555555111111551100000000
0000288000000000000000599400000000000054aaaa9945550000000000000000000000000000000288200000000000000055555d5555111111511100000000
00008880000000000000599400000000000059aaaa94455000000000000000000000000000000000008880000000000000001555dd5555111151111000000000
000288000000000000599400000000000549aaa94455000000000000000000000000000000000000002880000000000000000555555551111551100000000000
000888000000000054945000000000059aaa99455500000000000000000000000000000000000000000888000000000000000055551111111111100000000000
0008820000000004940000000000559aaa9455500000000000000000000000000000000000000000000288000000000000000015000000001111000000000000
0028800000000494000000000054aaa9455000000011111110000000060000000000000000000000000088400000000000000000000000000000000000000000
00884000000494500000000059aa945500000001111dddddd11000000000000000000000000000000000888061561555551151000015110555555551105d5115
00882000059450000000054aaa9455000000005ddd33dddddddd10000000000000006000000000000000288061561565111555550511155551155151005d5555
028800059450000000059aa94550000000001dddd3dddddddddddd10000000000000000000000000000008806156156100555155115515555510115101151155
0488054450000000549a9455000000000001ddddddddddddddddddd10000000000000000000000001155d8886156655105155015155115555551100111011155
0884445000000059aa95500000000000001ddddddddddddddddddddd100000000000000000155ddd666664886155115501155015151015555511100011001555
08845000000059a9450000000000000000dddddddddddddddd666dddd100333bbb31115ddd66666666666e886155665515550055010050155511111151151500
4880000000005950000000000000000001dd3ddddd66666ddd6666dd33bbbb66666ddddd66666666dddd558861556115505000555050005115555555515d5115
488000000000000000000000000000001d33ddddd6666666666666d3bbd66666ddddddd66666dd53333330886155515505011010550155515111155501555155
484000006555655600000000060000001333ddddd66777666ddd3b5d66666d53335dddd6d333333333310048000000000015551001555d555510011001d51555
882000006155615600000000000000005ddddddd6677776dd3bbbbddbbddd3333333333333333335ddddddd880000000501555500155d5515115555105511551
88200000515561560000000000000001ddddddd667776dbbbbddddbbbbbb333333333333ddd666666666666880000000501515515515510055555dd155551550
88200000555661560000000000000001dddddddddd3bbbb666ddddbbbbddddddddddd66666ff66666dddd4488000000000150555555001115555551555555500
880000005555115600000000000003333333333bbbbbd66ddddd66dd666666666fffaaaaaaaaaaaaaaaa99999940000001101510155511555555511115155105
8800000055665556000000000333bbb3333bbbbbbd6ddd6dd66676666fffaaaaaaaaaaaaa999aaaaaa99999a9aaaa00001105d51115115555155555115555005
880000005556155600000033bbbbbbbbbbbbbb33b76d3dddddd67bb7a9aaaaaaaaaaaaaaaaaaaaaaaaaa99999999940001105500111155555151155511110110
880000005551155600003bbbbbb33bb33333333b6763333333367b67aaaaaaaaa994444aaaaaaaaaaaaaaaaaa994499015015000115555555551115551001500
88000000000000000000bbb333333333333333bb77d3333333366366aaaa999a944499449aaaaaa99999999999999a9901155115551555555555515555151155
88000000000600000003b33333333bbbbbbbbbb6765333333356d3d6aaaaaaaaaa999999999999999aa999aaaa9999400155555d5115d5511555555555151111
8820000000000000000333333333bbbbbbbbbb676d333333333db33daaaaaaaaaaaaaaaa4aaa6fff666666666ddd00005551555555ddd551555d551155551155
882000000000000000033333333bbb3bbbbddd666dddddddddddddd6f666666666666666666666666666666666d00000555555155dd555001555551155551555
88200000000000000000333333b33bbbbd66666666666666666ddddddf666dddd66faaa44455555555555522210000005555d555555101555551551555150555
888000000000000000003333b33bbbddddddd553555333333333333334aaaa9944455550000000000000004820000000515555555001155d55155555511555d5
4880000000000000000033333bbbdddd533333333333333333333333335445550000000000000000000000880000000011111055101155555555555510155d51
088000000000000000003b33bbdddd53333333333333333333333333000000000000000000000000000000880000000055550155015555110155555505555550
08800000000000000003bbbbdddd53333333333333333333333dd55555ddddddd555555555555551111100880000000055551550555dd1155555555555d55511
0882000000000000003bbbbdddddddddddddd5555555533333355555555555555555dddddddd66666666666666660000055115515dd551155555555555551555
08880000000000003bbbbdddd533555555555555dd6666666666dddd555111111111000001111001111115555550000055110011115155555515110155155111
0288000000000003bbbd6dd33333333333300000011333555555ddddddddd666666666666dddd5555555588100000000d5000011015555555d51155550015105
008820000000003bb66dd33333333333100000000000000000000000000000015555dddddd666666666666666660000050000005551555115d5115555111105d
0088400000000bb6dd33333333333000000000000000000000000000000000000000000000000011555555dddd00000000055155ddd11001d551155111100055
002880000000d766d53300000000000000000000000000000000000000000000000000000000000000008800000000000155115dd55111105551555551015551
000882000000d65ddddd5510000000000000000000000600000000000000000000000000000000000002880000000000111051551001151101555155511dd511
0004880000000000015ddd6ddd510000000000000000000000000000000000000000000000006000000884007770000077700007777777770000077770007777
000088000000000000000015ddddddd510000000000000000094455000000000000000000000000000288000766d000766d000076666666d000007666d00766d
000088800000000000000000000155dd66dd5110000000000055544999945550000000000000000000888000076d00076d0000076666666d000007666d00766d
00002880000000000000000000000000115dddddd555100000000000005549999945555000000000028800000766d0766d000007666ddddd000007666d00766d
0000088800000000000000000000000000000015dd6666dd55000000000000005544999994445500088800000766d0766d000007666d00000000076666d0766d
00000288200000000000000000000000000000000015dd667766d510000000000000000554646699488000000076d076d0000007666d00000000076666d0766d
00000088800000000000000000000000000000000000000155d66666dd51100000000000000000558880000000766766d0000007666777700000076666d0766d
0000000882000000600000000000000000000000000000000000155d66666dd551100000000000048800000000766666d0000007666666d000000766666d666d
000000028800000000000000000000000000000000000000000000000055ddd666dd5551000000088200000000766666d0000007666666d0000007666d66666d
00000000888000000000000000000000000000000000000000000000000000155dd66666dd5510288000000000766d66d0000007666dddd000000766d076666d
0000000008880000000000000000000600000000000000000000000000000000000155dd666666d4511000000766d0766d0000076666000000000766d076666d
000000000288200000000000000000000000000000000000000000000000000000000000115dd666666dd5500766d0766d0000076666000000000766d007666d
00000000008882000000000000000000000000000000000000000000000000000000000000025d55dd666666076d00076d0000076667777700000766d007666d
0000000000088820000000000000000000000000000000000000000000000000000000000028840000155dd0766d000766d000076666666d00000766d007666d
0000000000008882000000000000000000000000006000000000000000000000000000000288400000000000766d000766d000076666666d00000766d000766d
00000000000008882000000000000000000000000000000000000000000000000000000028880000000000006dd000006dd00006dddddddd000006ddd0006ddd
61556555000000888200000000000000000000000000000000000000000600000000000288800000000000000000077770000777777777770000777700077770
615566550000000888400000000000000000000000000000000000000000000000000048880000000000000000000766d00007666666666d0000766d000766d0
061551150000000088880000000000000000000000000000000000000000000000000888400000000000000000000766d00007666666666d0000766d000766d0
061556650000000008888200000000000000000000000000000000000000000000028882000000000000000000000766d00006dddd666ddd0000766d000766d0
006155110000000000288880000000000000000000000000600000000000000000888800000000000000000000000766d00000000766d0000000766d000766d0
000611550000000000008888200000000000000000000000000000000000000028884000000000000000000000000766d00000000766d0000000766d000766d0
000066110000000000000088882000000000000000000000000000000000002888820000000000000000000000000766d00000000766d00000007666777666d0
000000660000000000000008888840000000000000000000000000000000488888000000000000000000000000000766d00000000766d00000007666666666d0
555655560000000000000000288888820000000000000000000000000288888820000000000000000000000000000766d00000000766d00000007666666666d0
556615560000000000000000002888888822000000000000000002488888882000000000000000000000000000000766d00000000766d00000007666ddd666d0
551115600000000000000000000002888888888420000000248888888882000000000000000000000000000000000766d00000000766d0000000766d000766d0
566555600000000000000000000000000888888888888888888888882000000000000000000000000000000000000766d00000000766d0000000766d000766d0
551156000000000000000000000000000000228888888888888220000000000000000000000000000000000000000766d00000000766d0000000766d000766d0
555560000000000000000000000000000000000022222222200000000000000000000000000000000000000000000766d00000000766d0000000766d000766d0
556600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000766d00000000766d0000000766d000766d0
6600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006ddd000000006ddd00000006ddd0006ddd0
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077700000777000077777777700000777700077770000007777000077777777777000077770007777000000000000000000000000
000000000000000000000000766d000766d000076666666d000007666d00766d000000766d00007666666666d0000766d000766d000000000000000000000000
000000000000000000000000076d00076d0000076666666d000007666d00766d000000766d00007666666666d0000766d000766d000000000000000000000000
0000000000000000000000000766d0766d000007666ddddd000007666d00766d000000766d00006dddd666ddd0000766d000766d000000000000000000000000
0000000000000000000000000766d0766d000007666d00000000076666d0766d000000766d00000000766d0000000766d000766d000000000000000000000000
0000000000000000000000000076d076d0000007666d00000000076666d0766d000000766d00000000766d0000000766d000766d000000000000000000000000
00000000000000000000000000766766d0000007666777700000076666d0766d000000766d00000000766d00000007666777666d000000000000000000000000
00000000000000000000000000766666d0000007666666d000000766666d666d000000766d00000000766d00000007666666666d000000000000000000000000
00000000000000000000000000766666d0000007666666d0000007666d66666d000000766d00000000766d00000007666666666d000000000000000000000000
00000000000000000000000000766d66d0000007666dddd000000766d076666d000000766d00000000766d00000007666ddd666d000000000000000000000000
0000000000000000000000000766d0766d0000076666000000000766d076666d222200766d00000000766d0000000766d000766d000000000000000000000000
0000000000000000000000000766d0766d0000076666000000000766d887666d888888766d00000000766d0000000766d000766d000000000000000000000000
000000000000000000000000076d00076d0000076667777700002766d887666d888888766d84200000766d0000000766d000766d000000000000000000000000
000000000000000000000000766d000766d000076666666d04888766d887666d000024766d88888400766d0000000766d000766d000000000000000000000000
000000000000000000000000766d000766d000076666666d88888766d000766d000000766d48888888766d0000000766d000766d000000000000000000000000
0000000000000000000000006dd000006dd00006dddddddd888206ddd0006ddd0000006ddd000288886ddd00000006ddd0007ddd000000000000000000000000
00000000000000000000000000000000000000000002888840000000000000000000000000000004488884000000000000000000000400000000000000000000
0000000000000000000000000000000000000000028888200000000000000000060000000000054aa94888820000000000000000059aa0000000000000000000
00000000000000000000000000000000000000008888200000000000000000000000000000054aa9455548888000000000000054aaaaa4000000000000000000
000000000000000000000000000000000000002888800000000000000000000000000000004aa9455000008888200000000059aaaaaaaa000000000000000000
00000000000000000000000000000000000004888200000000000000000000000000000059a9455000000002888400000549aaaaaaaaa4000000000000000000
000000000000000000000000000000000000888800000000000000000000000000000059a945500000000000088840059aaaaaaaaa9440000000000000000000
0000000000000000000000000000000000088840000000000000000000000000000059aa45500000000000000044449aaaaaaaa9944000000000000000000000
00000000000000000000000000000000008882000600000000000006000000000059aa4550000006000000000054aaaaaaaaa944500000000000000000000000
000000000000000000000000000000000888200000000000000000000000000004aa4550000000000000000549aaaaaaaa944550000000000000000000000000
0000000000000000000000000000000088820000000000000000000000000004aa4550000000000000000599aaaaaaa944455000000000000000000000000000
000000000000000000000000000000088820000000000000000000000000059a955000000000000000559aaaaaaa994454500000000000000000000000000000
0000000000000000000000000000008882000000000000000000000000059a95500000000000000054aaaaaaa994455524200000000000000000000000000000
00000000000000000000000000000488200000000000000000000000059a95500000000000000059aaaaaaa94455500028820000000000000000000000000000
000000000000000000000000000008880000000000000000000000059a95000000000000000549aaaaaa94455500000008880000000000000000000000000000
0000000000000000000000000000888000000000000000000000059a9500000000000000559aaaaaa99455500000000000888000000000000000000000000000
00000000000000000000000000088800000000000000000000054a9500000000000000559aaaaa99445500000000000000288400000000000000000000000000
000000000000000000000000000882000000600000000000004a950000000000000054aaaaa99445550000000000000000048800000000000000000000000000
0000000000000000000000000088800000000000000000004a950000000000000549aaaaa9445550000000000000000000008880000000000000000000000000
00000000000000000000000002882000000000000000004995000000000000054aaaaa9445550000000000000000000000002882000000000000000000000000
000000000000000000000000088800000000000000005994500000000000559aaaa9945550000000000000000000006000000888000000000000000000000000
000000000000000000000000288000000000000000599400000000000054aaaa9945550000000000000000000000000000000288200000000000000000000000
0000000000000000000000008880000000000000599400000000000059aaaa944550000000000000000000000000000000000088800000000000000000000000
00000000000000000000000288000000000000599400000000000549aaa944550000000000000000000000000000000000000028800000000000000000000000
00000000000000000000000888000000000054945000000000059aaa994555000000000000000000000000000000000000000008880000000000000000000000
000000000000000000000008820000000004940000000000559aaa94555000000000000000000000000000000000000000000002880000000000000000000000
000000000000000000000028800000000494000000000054aaa94550000000111111100000000600000000000000000000000000884000000000000000000000
0000000000000000000000884000000494500000000059aa945500000001111dddddd11000000000000000000000000000000000888000000000000000000000
0000000000000000000000882000059450000000054aaa9455000000005ddd33dddddddd10000000000000006000000000000000288000000000000000000000
00000000000000000000028800059450000000059aa94550000000001dddd3dddddddddddd100000000000000000000000000000088000000000000000000000
000000000000000000000488054450000000549a9455000000000001ddddddddddddddddddd10000000000000000000000001155d88800000000000000000000
000000000000000000000884445000000059aa95500000000000001ddddddddddddddddddddd100000000000000000155ddd6666648800000000000000000000
0000000000000000000008845000000059a9450000000000000000dddddddddddddddd666dddd100333bbb31115ddd66666666666e8800000000000000000000
000000000000000000004880000000005950000000000000000001dd3ddddd66666ddd6666dd33bbbb66666ddddd66666666dddd558800000000000000000000
00000000000000000000488000000000000000000000000000001d33ddddd6666666666666d3bbd66666ddddddd66666dd533333308800000000000000000000
00000000000000000000484000000000000000000000060000001333ddddd66777666ddd3b5d66666d53335dddd6d33333333331004800000000000000000000
00000000000000000000882000000000000000000000000000005ddddddd6677776dd3bbbbddbbddd3333333333333333335ddddddd880000000000000000000
0000000000000000000088200000000000060000000000000001ddddddd667776dbbbbddddbbbbbb333333333333ddd666666666666880000000000000000000
0000000000000000000288200000000000000000000000000001dddddddddd3bbbb666ddddbbbbddddddddddd66666ff66666dddd44880000000000000000000
00000000000000000002880000000000000000000000000003333333333bbbbbd66ddddd66dd666666666fffaaaaaaaaaaaaaaaa999999400000000000000000
000000000000000000028800000000000000000000000333bbb3333bbbbbbd6ddd6dd66676666fffaaaaaaaaaaaaa999aaaaaa99999a9aaaa000000000000000
00000000000000000002880000000000000000000033bbbbbbbbbbbbbb33b76d3dddddd67bb7a9aaaaaaaaaaaaaaaaaaaaaaaaaa999999999400000000000000
00000000000000000002880000000000000000003bbbbbb33bb33333333b6763333333367b67aaaaaaaaa994444aaaaaaaaaaaaaaaaaa9944990000000000000
0000000000000000000288000000000000000000bbb333333333333333bb77d3333333366366aaaa999a944499449aaaaaa99999999999999a99000000000000
0000000000000000000288000000000600000003b33333333bbbbbbbbbb6765333333356d3d6aaaaaaaaaa999999999999999aa999aaaa999940000000000000
000000000000000000028820000000000000000333333333bbbbbbbbbb676d333333333db33daaaaaaaaaaaaaaaa4aaa6fff666666666ddd0000000000000000
00000000000000000002882000000000000000033333333bbb3bbbbddd666dddddddddddddd6f666666666666666666666666666666666d00000000000000000
0000000000000000000088200000000000000000333333b33bbbbd66666666666666666ddddddf666dddd66faaa4445555555555552221000000000000000000
00000000000000000000888000000000000000003333b33bbbddddddd553555333333333333334aaaa9944455550000000000000004820000000000000000000
000000000000000000004880000000000000000033333bbbdddd5333333333333333333333333354455500000000000000000000008800000000000000000000
00000000000000000000088000000000000000003b33bbdddd533333333333333333333333330000000000000000000000000000008800000000000000000000
0000000000000000000008800000000000000003bbbbdddd53333333333333333333333dd55555ddddddd5555555555555511111008800000000000000000000
000000000000000000000882000000000000003bbbbdddddddddddddd5555555533333355555555555555555dddddddd66666666666666660000000000000000
0000000000000000000008880000000000003bbbbdddd533555555555555dd6666666666dddd5551111111110000011110011111155555500000000000000000
000000000000000000000288000000000003bbbd6dd33333333333300000011333555555ddddddddd666666666666dddd5555555588100000000000000000000
00000000000000000000008820000000003bb66dd33333333333100000000000000000000000000000015555dddddd6666666666666666600000000000000000
000000000000000000000088400000000bb6dd33333333333000000000000000000000000000000000000000000000000011555555dddd000000000000000000
00000000000000000000002880000000d766d5330000000000000000000000000000000000000000000000000000000000000000880000000000000000000000
00000000000000000000000882000000d65ddddd5510000000000000000000000600000000000000000000000000000000000002880000000000000000000000
000000000000000000000004880000000000015ddd6ddd5100000000000000000000000000000000000000000000000060000008840000000000000000000000
00000000000000000000000088000000000000000015ddddddd51000000000000000009445500000000000000000000000000028800000000000000000000000
00000000000000000000000088800000000000000000000155dd66dd511000000000005554499994555000000000000000000088800000000000000000000000
0000000000000000000000002880000000000000000000000000115dddddd5551000000000000055499999455550000000000288000000000000000000000000
000000000000000000000000088800000000000000000000000000000015dd6666dd550000000000000055449999944455000888000000000000000000000000
0000000000000000000000000288200000000000000000000000000000000015dd667766d5100000000000000005546466994880000000000000000000000000
0000000000000000000000000088800000000000000000000000000000000000000155d66666dd51100000000000000000558880000000000000000000000000
000000000000000000000000000882000000600000000000000000000000000000000000155d66666dd551100000000000048800000000000000000000000000
00000000000000000000000000008800000000000000000000000000000000000000000000000055ddd666dd5551000000088200000000000000000000000000
0000000000000000000000000000888000000000000000000000000000000000000000000000000000155dd66666dd5510288000000000000000000000000000
000000000000000000000000000008880000000000000000000600000000000000000000000000000000000155dd666666d45110000000000000000000000000
00000000000000000000000000000288200000000000000000000000000000000000000000000000000000000000115dd666666dd55000000000000000000000
0000000000000000000000000000008882000000000000000000000000000000000000000000000000000000000000025d55dd66666600000000000000000000
000000000000000000000000000000088820000000000000000000000000000000000000000000000000000000000028840000155dd000000000000000000000
00000000000000000000000000000000888200000000000000000000000000600000000000000000000000000000028840000000000000000000000000000000
00000000000000000000000000000000088820000000000000000000000000000000000000000000000000000000288800000000000000000000000000000000
00000000000000000000000000000000008882000000000000000000000000000000000000000006000000000002888000000000000000000000000000000000
00000000000000000000000000000000000888400000000000000000000000000000000000000000000000000048880000000000000000000000000000000000
00000000000000000000000000000000000088880000000000000000000000000000000000000000000000000888400000000000000000000000000000000000
00000000000000000000000000000000000008888200000000000000000000000000000000000000000000028882000000000000000000000000000000000000
00000000000000000000000000000000000000288880000000000000000000000000600000000000000000888800000000000000000000000000000000000000
00000000000000000000000000000000000000008888200000000000000000000000000000000000000028884000000000000000000000000000000000000000
00000000000000000000000000000000000000000088882000000000000000000000000000000000002888820000000000000000000000000000000000000000
00000000000000000000000000000000000000000008888840000000000000000000000000000000488888000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000288888820000000000000000000000000288888800000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000002888888822000000000000000002488888882000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000002888888888420000000248888888882000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000888888888888888888888882000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000228888888888888220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000022222222200000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
8b00000000000000000000000000009100000000424344454647486b4a4b00008c8d8e8f8c8d8e8eaf8eafaf8f9f8eaf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0301d303b3030303030303b301d30f00000005152535455565758595a5b00009c9d9e9f9c9d9e9f9eaf9e9f8f9f9f9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008b30303a303b30303b303a303091000000606162636465666768696a000000acadaeafacadaeaf8e8f8e8f8e8f8e8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e030301d303a30303a301d3030f0000000707172737475767778797a000000bcbdbebfbdbdbebfaf9f9e9f9e9f8e9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000e03d30301d30301d30303df000000000808182838485868788898a0000008c8d8e8f8c8d8e8f8e8f8e8fbd8f8e8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000e03d3d30303d3df000000000000090d392939495969798999a9b00009c9d9e9faebe9e9f9eaf8e8faf9f9e9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000e0f0000000000000000000a0a1a2a3a4a5a6a7a8a9aaab0000acad9cbeacadaeafbdbd9e9f8e8faf8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000b0b1b2b3b4b5b6b7b8b9babb0000bcbdbebfbcbdbebf9e9f9e9faf8e9e9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
503c3c3c3c3c3c31323c3c3c3c3c3c410000c0c1c2c3c4c5c6c7c8c9ca0000008c8dbd8fbf8dbd8faf9f8ebe9eaf8e8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030000000d1d2d300d5d6d7d8d9da0000009c8e9ebd9c9d9e8e9e9f9e9faf9f9e9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030000000e1e2e3e4e5e6e7e8e900000000acadbcafac8eaeaf8eaf9e8f9ebd8eaf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
503c3c3c3c31323c3c31323c3c3c3c410000000000f3f4f5f6f7000000000000bcbdbdbfbdbdbcbf9e9f8eafbdaf8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030000000000000000000000000000000008c8dbebe8ebe8e8faf8e8f9f8eaf9f9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030004000000000000000000000000000009c9d8ebeae9d9e9d9eaf9f8f9e9faf9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000acadaeafacadaeaf8e8f9ebe8e8fbe8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000bcbdbe8ebcbdbe8e9ebd8fafaf9f9e9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000be9c9dacafaeadbfafaf8f8e9ebeaf9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000009cbebdbeaebebe9fafaf9e9f9e9f9f9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000acadaeaf9dadaeaf9e9f8ebdaf8fbebd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000bcbdbebfbebd8ebf9e9f9e9f9e9f9ebf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
292705002801410011100121001210012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000200c743007000070000700186350000000700007000c743007000c7430070018635007000c743007000c743007000c7430070018635007000c743007000c743007000c7430070018635007000c74300700
0110002010120041201012004120121200412010120041201712004120101200412013120041201012004120121200412010120041201312004120101200412011120021200e120021200e120021200e12002120
252000001c2141c2211c2311c2301c2301c2321c2321c232232312323023232232321f2311f2301f2321f2321b2111b2211b2311b2301b2301b2301b2301b230232312320523232232051a2301a2051a2321f232
25200000212302123021230212322123215202212302123223231232302323223232242312423026232262321f2111f2211f2311f2321f2321b2001f2341f23026230232002623023200212301a2002423000000
511004000441500405044150441504415004050441504415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252000001f2141f2211f2211f2201f2201f2221f2221f2221f2211f2201f2221f2221c2211c2201c2221c22227211272212722127220272202722027220272201b222232051b222232051a2241a2052122223222
2520000028220282202822028222282221520218220182221a2211a2201a2221a2221c2211c2201f2221f22226211262212622126222262221b20026224262202b220232002b22023200242201a2002822000000
092000200c743007000070000700186350000000700007000c743007000c7430070018635007000c743007000c743007000c7430070018635007000c743007000c743007000c7430070018635007000c74300700
0d20000010235102350020510235002050e2350e2350e2351123511235002001023510235002000c2350c2350e235002051123510235002051123510235112350c2350c235002050e2350e235002051023511235
0110002010120041201012004120121200412010120041201712004120101200412013120041201012004120121200412010120041201312004120101200412011120021200e120021200e120021200e12002120
091000200c743007000070000700186350000000700007000c743007000c7430070018635007000c743007000c743007000c7430070018635007000c743007000c743007000c7430070018635007000c74300700
252000001c2141c2211c2311c2301c2301c2321c2321c232232312323023232232321f2311f2301f2321f2321b2111b2211b2311b2301b2301b2301b2301b230232312320523232232051a2301a2051a2321f232
511008000441500405044150441504415004050441504415004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
011000200442500405044250442505425044250442507425044250442505425044250642507425064250442504425004050442504425054250442504425074250442504425054250442506425074250642505425
011000000441500405044150441504415004050441504415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
414000001011410121101311013513114131211313113135121141212112131121351511415121151311513510114101211013110135121141212112131121351311413121131311313511114111211113111135
414000001511415121151311513512114121211213112135131141312113131131351111411121111311113510114101211013110135000000000000000000000000000000000000000000000000000000000000
011000000642500405064250642507425064250642509425064250642507425064250742509425074250642506425004050642506425074250642506425094250642506425074250642507425094250742506425
01100000074250040507425074250942507425074250b425074250742509425074250b425074250942507425074250040507425074250942507425074250b425074250742509425074250b425074250942507425
011000200c743004050442504425186350442504425074250c743044250542504425186350742506425044250c743004050442504425186350442504425074250c74304425054250442518635074250642505425
6d200020103341033110331103320b3340b3310b3310b33207334073310733107332093340933109331093320b3340b3310b3310b332113341133111331113321333413331133311333209334093310933109332
6d200020133341333113331133321533415331153311533218334183311833118332173341733117331173321a3341a3311a3311a332183341833118331183321733417331173311733117332173321733217332
414000001311413121131211312517114171211712117125151141512115121151251811418121181211812517114171211712117125171141712117121171251711417121171211712515114151211512115125
252019000073106731007310673100731067310073106731007310673100731007310073100731007320073200731007310073200732007320073200732007320073200000000000000000000000000000000000
0d0d07000c7530c7530c7531864518645186451864500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0d00200c74304320093200832018645043200b320003200c743103200f3200e320186451732013320123200c7431a3201832017320186451632015320143200c74313320163200f320186450e3201232011320
0f1a00180425500200042550425500200002000425500200052550020005255052550020000200052550020007255002000725507255002000020007255002000225000200022500225000200002000225000000
15100b001032000300103251032000300103200030010320003001032000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
15100b001632000300163251632000300163200030017320003001732000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010900200c74300700007000070018635000000c7430c7430c743007000c7430070018635007000c743007000c743007000c7430070018635007000c743007000c743007000c74300700186350c7430c7430c743
150c1800102200f2200d22011220102200f2201322011220102201422013220112201622014220132201722016220142201922017220142201b22019220182200000000000000000000000000000000000000000
210c18001c2141c2211c2311c2311c2321c2322021420221202312023120232202321f2141f2211f2311f2311f2321f2322221422221222312223122232222320000000000000000000000000000000000000000
211818001c2141c2211c2311c2301c2321c23223231232321f2311f2321f2321b2111b2211b2311b2301b2301b2301b2302323123231232312323223232000000000000000000000000000000000000000000000
150c0018102200f2200d22011220102200f2201322011220102201422013220112201622014220132201722016220142201922017220142201b22019220182200000000000000000000000000000000000000000
140c00180e2200c2201222011220102201322012220112201522013220122201722015220132201822017220152201a22018220172201b2201922018220000000000000000000000000000000000000000000000
211009001b2141b2211b2311b2311b2311b2321b2321b2321b2322421424221242312321423221232312321123222232322220022200222002220022200222000000000000000000000000000000000000000000
41400000181141812118121181251a1141a1211a1211a125171141712117121171251511415121151211512513114131211312113125121141212112121121211212212122131111312113122131221311113101
710c0018102100e2100c21011210102100e210102100e2100c21011210102100e21013210112101021011210102100e21013210112101021011210102100e2100020000200002000020000200002000020000200
0d2000000c753072350020507235186450723507235072350c753092350020007235186450020007235072350c753002050923507235186450923507235092350723307235002050723507235002050723509235
11100020104051040510425104051042510425104251342513405134051342515405154251542515425154251040510405104250c405134251342513425134251340513405134251540515425154251542515425
2d100020103100e3100d3100e31011310103100e310103101331011310103101131015310133101131013310103100e3100d3100e3101331011310103101131015310133101131013310113100d3100c3100d310
2d1000201331011310103101131017310153101331015310183101731015310173101331015310173101831013310113101031011310153101530013310153001531013300113101331017310153101331015310
412000001011410121042200422513114131210722007225121141212106220062251511415121092200922510114101210423004235121141212106220062251311413121072200722511114111210522105225
412000001511415121092200922512114121210622006225131141312107230072351111411121052200522510114101210422004225000000000004220042250000000000042200422500000000000422004225
0d100a0010320153201232017320133200c320153200e320173201c32000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
0d10000010435104351030010320153201232017320133200c320153200e3201732010435104350030010320153201232017320133200c320153200e320173201043510435003001032013435134350030010320
0d10000017425174251030010300153001230017300133000c300153000e3001730017425174250030010300153001230017300133000c300153000e300173001742517425003001030017425174250030010300
251000201023000200112201022013230112201022013230112201022013230112201022011220132301122010230002001122010220132301122010220172201823017220152201823017220152201823016220
394000001c2101c2211c2221c2221d2101d2211d2221d2221c2101c2211c2221c2221f2101f2211f2221f2221c2101c2211c2221c2221d2101d2211d2221d2221c2101c2211c2221c2221a2101a2211a2221a222
4540000010114101211012010120101201012010111101150f1140f1210f1200f1200f1200f1200f1110f11516114161211612016120161201612016111161151511415121151201512015120151201511115115
454000001311413121131201312013120131201311113115121141212112120121201212012120121111211518114181211812018120181201812018111181151711417121171201712017120171201711117115
010800003475410751107150070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
03281e00106141161112621136211462115621166211762118631196311a6311b6311c6311d6311e6311f631206412164122641236412464125641266412764128641296512a6512b6512c6512d6530000034600
03040000280202802028020280202802028020280202802028020280202802028020280202802028020280202802028020280202802028020280200000000000000000000000000000000000028600346203a620
4b0a00001062104621046250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b101000106141c6211c6311c6411c6311c6311c6311c6211c6211c6211c6111c6111c6111c6111c6150060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0d0800001341300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
550600000b34109345003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
151000000642104415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d1400000441416411164101641016410164101641016415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a31000000b61000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0a00000453100002005020050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
030a00001064104641046450060000600006000060000600176110b61100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00424344
00 01024344
01 01020344
00 01020344
00 01020444
02 01020444
03 0b294e44
03 14294e44
03 104e4e44
03 110e4e44
03 0b0e4e44
03 0b124e44
03 0b134e44
03 15144e44
03 16144e44
03 28144e44
03 10170b44
03 11250b44
03 0b264e44
03 14264e44
03 094b4e44
03 090b4e44
03 09274e44
03 142a4e44
03 2b0b4b44
03 2c0b4b44
03 2d0b4e44
03 2e0b2f44
03 300b6044
03 31300b44
03 320b4b44
03 32330844
03 10174b44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
03 4b4e4e44
00 184e4e44
00 194e4e44
03 1a1b4e44
00 1c1d1e44
01 1e1f2044
01 241f1e44
04 211e2344
01 01020346
00 01020306
00 01020407
02 01020407
00 49424344
00 4a4b4344
03 4c4a4b44
03 4c4a4b44
03 05424344

