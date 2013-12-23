local function Box(size, offset, body, z)
	local light = 0.8
	body = body or staticBody
	z = z or 250

	local function Rectangle(size, offset, light)
		local tile = eapi.NewTile(body, offset, size, util.white, z)
		eapi.SetColor(tile, util.SetColorAlpha(util.Gray(light), 0.2))
		return tile
	end

	Rectangle(size, offset, light)
	local sizeA = { x = size.x + 4, y = 2 }
	local sizeB = { x = 2, y = size.y }

	Rectangle(sizeA, vector.Offset(offset, -2, -2), light - 0.3)
	Rectangle(sizeB, vector.Offset(offset, -2,  0), light + 0.3)

	Rectangle(sizeA, vector.Offset(offset, -2, size.y), light + 0.3)
	Rectangle(sizeB, vector.Offset(offset, size.x, 0),  light - 0.3)
end

local function Reset()
	player.Update(0.0)
	hud.amount = 1
end

local function Advance()
	Reset()
	ball.Sweep()
	pattern.Next()
	pattern.Schedule(0.0)
end

local function Repeater(count, Fn)
	if count and count > 1 then Fn(count - 1) end
end

local function Inc(count)
	local index = hud.amount
	util.Map(Stretch, hud.tiles[index])
	hud.amount = math.min(hud.count, hud.amount + 1)
	player.Update(hud.amount / hud.count)
	if hud.count == index then Advance() end
	Repeater(count, Inc)
end

local function Dec(count)
	util.Map(Shrink, hud.tiles[hud.amount])
	hud.amount = math.max(1, hud.amount - 1)
	player.Update(hud.amount / hud.count)
	Repeater(count, Dec)
end

local fadeOut = 1.0
local recovery = 0.2
local textScale = 2
local textFade = 0.8

local light = { r = 0, g = 0, b = 0, a = 0 }
local dark = { r = 0, g = 0, b = 0, a = 0.75 }

local function FadeOutColor(fadeTime)
	return function(tile)
		local color = util.SetColorAlpha(eapi.GetColor(tile), 0)
		eapi.AnimateColor(tile, eapi.ANIM_CLAMP, color, fadeTime, 0)
	end	
end

local function FadeOut(tile, offset)
	eapi.SetSize(tile, vector.Scale(eapi.GetSize(tile), textScale))
	local pos = vector.Scale(eapi.GetPos(tile), textScale)
	pos = vector.Add(pos, offset)
	eapi.SetPos(tile, pos)
	FadeOutColor(textFade)(tile)
end

local function CreateFadeOut(offset)
	return function(tile) FadeOut(tile, offset) end
end

local function JitterText(text, pos)
	local body = eapi.NewBody(gameWorld, pos)
	for i = 0, 3, 1 do
		local FadeOutFn = CreateFadeOut({ x = i, y = i })
		util.Map(FadeOutFn, util.BigTextCenter(text, body, 0, 1010))
	end
	local function Jitter()
		eapi.SetPos(body, vector.Rnd(pos, 8))
		eapi.AddTimer(body, 0.01, Jitter)
	end
	Jitter()
	util.DelayedDestroy(body, textFade)
end

local textPos = { x = 0, y = 120 }

local function DarkFade(name)
	local tile = actor.FillScreen(util.white, 1000, light)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, dark, fadeOut, 0)
	eapi.PlaySound(gameWorld, "sound/charge.ogg", 0, 1, 1)

	local function Destroy() eapi.Destroy(tile) end

	local function Reverse()
		eapi.AnimateColor(tile, eapi.ANIM_CLAMP, light, recovery, 0)
		eapi.AddTimer(staticBody, recovery, Destroy)
		eapi.PlaySound(gameWorld, "sound/beat.ogg")
		JitterText(name, textPos)
	end

	eapi.AddTimer(staticBody, fadeOut, Reverse)
end

local starVector = { x = 0, y = 200 }

local starOffset = { x = -16, y = -16 }
local starSize = { x = 32, y = 32 }

local function AnimateStarColor(tile, time, amount)
	local color = util.Mix(util.yellow, util.orange, amount)
	eapi.SetColor(tile, util.SetColorAlpha(color, 0))
	color = util.SetColorAlpha(color, 1.0)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, color, time, 0)
	return util.SetColorAlpha(color, 0)
end

local function MakeStarTile(body)
	return eapi.NewTile(body, starOffset, starSize, ball.starImg, 1020)
end

local function EmitStar(time, textSize)
	local xR = math.random()
	local x = (xR - 0.5) * textSize.x
	local yR = math.random()
	local y = (yR - 0.5) * textSize.y

	local ratio = textSize.y / textSize.x
	local angle = vector.Degrees(math.atan2(x * ratio, -y))
	local way = vector.Rotate(starVector, angle)

	local dst = vector.Offset(textPos, x, y)
	local src = vector.Sub(dst, way)
	
	local body = eapi.NewBody(gameWorld, src)
	local tile = MakeStarTile(body)
	local color = AnimateStarColor(tile, time, yR)	
	ball.SetRandomAngle(tile)

	eapi.SetVel(body, vector.Scale(way, 1 / time))

	local function Reverse()
		local variation = 1 + 3 * math.random()
		eapi.SetVel(body, vector.Scale(way, -variation))
		eapi.AnimateColor(tile, eapi.ANIM_CLAMP, color, recovery, 0)
	end
	eapi.AddTimer(body, time, Reverse)

	util.DelayedDestroy(body, time + recovery)
end

local function AllStar(name)
	local textSize = util.TextCenter(name, util.bigFontset)
	textSize = vector.Scale(textSize, -2 * textScale)

	local time = fadeOut
	local function Emit()
		for i = 1, 20, 1 do
			EmitStar(time, textSize)
		end
		time = time - 0.05		
		if time > 0 then
			eapi.AddTimer(staticBody, 0.05, Emit)
		end
	end
	Emit()	
end

local textHeight = 112

local textOffset = { 
	{ x = 0, y = 48 }, 
	{ x = 0, y = 0 }
}

local function TextWidth(text)
	return util.bigFontset.size.x * string.len(text)
end

local function StatPos(obj, text)
	if obj.index == 2 then
		return { x = -384, y = -240 - textHeight }
	else
		local width = 0
		for i = 1, #text, 1 do 
			width = math.max(width, TextWidth(text[i]))
		end
		return { x = 384 - width, y = -240 - textHeight }
	end
end

local function ShowStats(obj)
	local textTiles = { }
	local color = ball.color[obj.index]
	local text = { "Right:" .. obj.rights,
		       "Wrong:" .. obj.wrongs }
	local body = eapi.NewBody(gameWorld, StatPos(obj, text))
	for i = 1, #text, 1 do
		local pos = textOffset[i]
		local tileSet = util.PrintShadow(pos, text[i], color, 1030,
						 body, 0.0, util.bigFontset)
		textTiles = util.JoinTables(textTiles, tileSet)
	end
	local speed = 2 * textHeight + 16
	eapi.SetVel(body, { x = 0, y = speed })
	eapi.SetAcc(body, { x = 0, y = -speed })
	local fadeTime = 2
	local function StopAndFade()
		eapi.SetVel(body, vector.null)
		eapi.SetAcc(body, vector.null)
		util.Map(FadeOutColor(fadeTime), textTiles)
		util.DelayedDestroy(body, fadeTime)
	end
	eapi.AddTimer(body, 1, StopAndFade)
end

local function Statistics()
	util.Map(ShowStats, player.objs)
	player.Reset()
end

local function Level(name)
	return function()
		AllStar(name)
		DarkFade(name)
		Statistics()
		pattern.Next()
		pattern.Schedule(2.0)
	end
end

local function Delay(timeout)
	return function() 
		pattern.Next()
		pattern.Schedule(timeout)
	end
end

hud = {
	amount = 0,
	spacing = 4,
	count = 150,
	tiles = { },
	Advance = Advance,
	Create = Create,
	Level = Level,
	Reset = Reset,
	Delay = Delay,
	Inc = Inc,
	Dec = Dec,
	Box = Box,
}
return hud
