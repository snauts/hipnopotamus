dofile("script/pattern.lua")
dofile("script/player.lua")
dofile("script/rings.lua")
dofile("script/ball.lua")
dofile("script/mob.lua")
dofile("script/hud.lua")

mob.Create()
rings.Create()

player.Create({ x =  300, y = -100 }, 1)
player.Create({ x = -300, y = -100 }, 2)

input.Bind("P1_Select", false, actor.Pause)
input.Bind("P2_Select", false, actor.Pause)

actor.Quit(function() util.Goto("startup") end)

local function Sprinkler()
	local dir = { x = ball.speed, y = 0 }

	return function()
		for i = 0, 30, 15 do
			ball.Emit(vector.Rotate(dir, i + 90), 1)
			ball.Emit(vector.Rotate(dir, i - 90), 2)
		end
		dir = vector.Rotate(dir, 10)
		pattern.Schedule(0.1)
	end
end

local function ZigZag()
	local step = 6
	local counter = 1
	local dir = { x = ball.speed, y = 0 }

	return function()
		local index = 1
		for i = 0, 359, 30 do
			ball.Emit(vector.Rotate(dir, i), index)
			index = 3 - index
		end
		if counter > 12 then
			step = -step
			counter = 1
		end
		dir = vector.Rotate(dir, step)
		counter = counter + 1
		pattern.Schedule(0.1)
	end
end

local function AimAtMe()
	local step = 3
	local angle = 0

	return function()
		for i = 1, 2, 1 do
			local playerPos = actor.GetPos(player.objs[i])
			local aim = vector.Sub(playerPos, mob.GetPos())
			aim = vector.Normalize(aim, ball.speed)
			ball.Emit(vector.Rotate(aim, angle), 3 - i)
		end
		if math.abs(angle) > 6 then step = -step end
		angle = angle + step
		pattern.Schedule(0.1)
	end
end

local function ThousandSuns()
	local index = 1
	local counter = 0
	local spacing = 10	
	local dir = { x = ball.speed, y = 0 }

	return function()
		for angle = 0, 359, 2 * spacing do
			ball.Emit(vector.Rotate(dir, angle + counter), index)
			ball.Emit(vector.Rotate(dir, angle - counter), index)
		end
		if counter >= spacing then
			pattern.Schedule(0.5)
			index = 3 - index
			counter = 0
		else
			pattern.Schedule(0.1)
			counter = counter + 2
		end
	end
end

local function FloatingIslands()
	local delta = 0
	local maxVal = 0.6
	local progress = 0
	local threshold = 0.45
	local lowerThreshold = 0.3
	local arm = { x = 48, y = 0 }
	local function GetNoise(x, y, z)
		return eapi.Fractal(0.01 * x, 0.01 * y, 0.01 * z, 4, 2)
	end
	local function NoiseBullet(pos, size) 
		local index = 1
		if size < lowerThreshold then
			size = threshold + lowerThreshold - size
			index = 2
		end
		if size > threshold then
			local range = (size - threshold) / (maxVal - threshold)
			local scale = 0.5 + 0.5 * range
			ball.z_epsilon = 0.001 * scale
			local vel = vector.Normalize(pos, ball.speed)
			ball.Emit(vector.Rnd(vel, 4), index)
		end
	end
	return function()
		for angle = 0, 359, 10 do
			local pos = vector.Rotate(arm, angle + delta)
			local size = GetNoise(pos.x, pos.y, progress)
			NoiseBullet(pos, size)
		end
		delta = (delta + util.fibonacci) % 360
		progress = progress + 1
		pattern.Schedule(0.04)		
	end
end

local function ArcsOfChange()
	local step = 3
	local offset = 0
	local select = 1
	local dir = { { x = ball.speed - 1, y = 0 },
		      { x = ball.speed + 1, y = 0 }, }
	local function GetDir()
		select = 3 - select
		return dir[select]
	end
	return function()
		for i = 0, 179, step do
			ball.Emit(vector.Rotate(GetDir(), i + offset), 1)
		end
		for i = 180, 359, step do
			ball.Emit(vector.Rotate(GetDir(), i + offset), 2)
		end
		offset = (offset + util.fibonacci) % 360
		pattern.Schedule(1.0)		
	end
end

local function RaysOfViolence()
	local progress = 0
	local compensate = 0
	local dir = { x = ball.speed, y = 0 }
	local stencil = { 1, 1, 1, 1, 1, false, false, false, 
			  2, 2, 2, 2, 2, false, false, false }
	local function Emit(angle, color)
		if color then 
			angle = angle + compensate
			ball.Emit(vector.Rotate(dir, angle), color)
		end
	end
	return function()
		for j = 0, 3, 1 do		       
			for i = j * 10, 359, 40 do
				local index = (progress + 4 * j) % #stencil
				Emit(i, stencil[index + 1])
			end
		end
		progress = (progress + 1) % #stencil 
		compensate = compensate + 0.5
		pattern.Schedule(0.1)		
	end
end

local function TailOfRetribution()	
	return function()
		local dir = vector.Normalize(mob.GetVel(), ball.speed)
		ball.Emit(vector.Rotate(dir, -135), 1)
		ball.Emit(vector.Rotate(dir,  -90), 2)
		ball.Emit(vector.Rotate(dir,   90), 1)
		ball.Emit(vector.Rotate(dir,  135), 2)
		pattern.Schedule(0.05)		
	end
end

local function ForkOfDespair()
	local step = 2
	local angle = 0
	local maxAngle = 90
	return function()
		local dir = vector.Normalize(mob.GetPos(), -ball.speed)
		local angle2 = maxAngle - math.abs(angle)
		ball.Emit(vector.Rotate(dir, angle), 1)
		ball.Emit(vector.Rotate(dir, -angle), 1)
		ball.Emit(vector.Rotate(dir, angle2), 2)
		ball.Emit(vector.Rotate(dir, -angle2), 2)
		if math.abs(angle) > maxAngle then step = -step end
		angle = angle + step
		pattern.Schedule(0.1)
	end
end

local function SideEffectsOfDoom()
	local dir = { x = ball.speed, y = 0 }
	return function()
		local index = 1
		for i = 0, 359, 60 do			
			ball.Emit(vector.Rotate(dir, i), index)
			index = 3 - index
		end
		pattern.Schedule(0.1)
	end
end

local function Bolt(dir, index)
	for i = 150, 250, 10 do
		ball.Emit(vector.Normalize(dir, i), index)
	end
end

local function MenaceFromAbove()
	return function()
		local index = (mob.GetVel().x > 0) and 1 or 2
		local playerPos = actor.GetPos(player.objs[index])
		local dir = vector.Sub(playerPos, mob.GetPos())
		for i = -20, 20, 10 do
			index = 3 - index
			Bolt(vector.Rotate(dir, i), index)
		end
		pattern.Schedule(0.6)
	end
end

local function FabricOfAnnihilation()
	local downward = { x = 0, y = -ball.speed }
	return function()
		local x = mob.GetVel().x
		local index = (x > 0) and 1 or 2
		local angle = (mob.GetPos().x - 300 * util.Sign(x)) * 0.2
		ball.Emit(vector.Rotate(downward, angle - 180), 3 - index)
		ball.Emit(vector.Rotate(downward, angle), index)
		pattern.Schedule(0.01)
	end
end

local function RadiationOfSenselessness()
	local index = 1
	return function()
		local playerPos = actor.GetPos(player.objs[index])
		local dir = vector.Sub(playerPos, mob.GetPos())		
		for i = 0, 359, 30 do
			Bolt(vector.Rotate(dir, i), 3 - index)
		end
		index = 3 - index
		pattern.Schedule(util.golden)
	end
end

local function RingsOfSadness()
	local dir = { x = ball.speed, y = 0 }
	local index = 1
	return function()
		for i = 0, 359, 2 do
			ball.Emit(vector.Rotate(dir, i), index)
		end
		index = 3 - index
		pattern.Schedule(2 * util.golden)
	end
end

local function CrapOfBitterness()
	local step = 10
	local maxOffset = 30
	local offset = -maxOffset
	return function()
		local index = (step < 0) and 1 or 2
		local playerPos = actor.GetPos(player.objs[index])
		local dir = vector.Sub(playerPos, mob.GetPos())
		Bolt(vector.Rotate(dir, offset), 3 - index)
		offset = offset + step
		if math.abs(offset) >= maxOffset then
			pattern.Schedule(0.6)
			step = -step
		else
			pattern.Schedule(0.2)
		end
	end
end

local function FadingText(yOffs, str, font)
	local function FadeIn(tile)
		local color = eapi.GetColor(tile)
		local srcColor = util.CopyTable(color)
		eapi.SetColor(tile, util.SetColorAlpha(srcColor, 0))
		eapi.AnimateColor(tile, eapi.ANIM_CLAMP, color, 2, 0)
	end
	local pos = vector.Offset(util.TextCenter(str, font), 0, yOffs)
	local tiles = util.PrintOrange(pos, str, 550, staticBody, 0.2, font)
	util.Map(FadeIn, tiles)
end

local function LightsOut()
	local black = { r = 0, g = 0, b = 0, a = 0 }
	local screen = actor.FillScreen(util.white, 600, black)
	eapi.AnimateColor(screen, eapi.ANIM_CLAMP, util.Gray(0), 2.0, 0)
end

local function TheEnd()
	local z = 500
	local srcSize = { x = 2, y = 2 }
	local srcPos = { x = -1, y = -1 }
	local dstSize = { x = 1024, y = 1024 }
	local dstPos = { x = -512, y = -512 }
	local tile = eapi.NewTile(staticBody, srcPos, srcSize, util.radial, z)
	local screen = actor.FillScreen(util.white, z + 10, util.invisible)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, 1, 0)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dstPos, 1, 0)
	eapi.PlaySound(gameWorld, "sound/charge.ogg", 0, 1, 1)
	eapi.SetDepth(mob.obj.tile, z + 20)
	actor.DeleteShape(mob.obj)
	eapi.FadeMusic(1.0)
	ball.Sweep()
	hud.Reset()

	local function FadeTo(color, duration)
		eapi.AnimateColor(screen, eapi.ANIM_CLAMP, color, duration, 0)
	end
	eapi.AddTimer(staticBody, 0.5, function()
		FadeTo({ r = 1, g = 1, b = 1, a = 1 }, 0.5)
		mob.Expand()
	end)
	eapi.AddTimer(staticBody, 1.0, function()
		FadeTo({ r = 0, g = 0, b = 0, a = 1 }, 5.0)
		mob.Explode()
	end)
	eapi.AddTimer(staticBody, 6.0, function()
		FadingText(0, "The End", util.bigFontset)	
	end)
	eapi.AddTimer(staticBody, 7.0, function()
		FadingText(-32, "Thank you for playing!", util.defaultFontset)
	end)
	eapi.AddTimer(staticBody, 14.0, function()
		LightsOut()
	end)
	eapi.AddTimer(staticBody, 16.0, function()
		util.Goto("startup")
	end)
end

pattern.Register(hud.Delay(2.0))
pattern.Register(Sprinkler())
pattern.Register(hud.Level("Beautiful"))
pattern.Register(ZigZag())
pattern.Register(hud.Level("Great"))
pattern.Register(AimAtMe())
pattern.Register(hud.Level("Superb"))
pattern.Register(ThousandSuns())
pattern.Register(hud.Level("Splendid"))
pattern.Register(FloatingIslands())
pattern.Register(hud.Level("Wonderful"))
pattern.Register(ArcsOfChange())
pattern.Register(hud.Level("Excellent"))
pattern.Register(RaysOfViolence())
pattern.Register(hud.Level("Awesome"))
pattern.Register(mob.Bounce)
pattern.Register(TailOfRetribution())
pattern.Register(hud.Level("Brilliant"))
pattern.Register(mob.Circle)
pattern.Register(ForkOfDespair())
pattern.Register(hud.Level("Amazing"))
pattern.Register(SideEffectsOfDoom())
pattern.Register(hud.Level("Fantastic"))
pattern.Register(mob.Uncircle)
pattern.Register(mob.Loom)
pattern.Register(MenaceFromAbove())
pattern.Register(hud.Level("Terrific"))
pattern.Register(FabricOfAnnihilation())
pattern.Register(hud.Level("Magnificent"))
pattern.Register(RadiationOfSenselessness())
pattern.Register(hud.Level("Miraculous"))
pattern.Register(CrapOfBitterness())
pattern.Register(hud.Level("Marvelous"))
pattern.Register(RingsOfSadness())
pattern.Register(hud.Level("Glorious"))
pattern.Register(mob.Unloom)
pattern.Register(mob.MoveTo(vector.null))
pattern.Register(TheEnd)
pattern.Schedule(0)

eapi.PlayMusic("sound/music.ogg", nil, 1.0, 1.0)
eapi.Fractal(0, 0, 0, 4, 2) -- generate random table

local dstColor = { r = 0, g = 0, b = 0, a = 0 }
local screen = actor.FillScreen(util.white, 1000, util.Gray(0))
eapi.AnimateColor(screen, eapi.ANIM_CLAMP, dstColor, 1.0, 0)
eapi.AddTimer(staticBody, 1, function() eapi.Destroy(screen) end)

if Cfg.debug then
	local function Test(keyDown)
		if keyDown then hud.Advance() end
	end	
	input.BindKey("F10", false, Test)
end
