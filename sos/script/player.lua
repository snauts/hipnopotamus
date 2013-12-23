local LEFT   = 1
local RIGHT  = 2
local UP     = 3
local DOWN   = 4

actor.Cage("Blocker", 0.55, 0.5)
actor.SimpleCollide("Blocker", "Player", actor.Blocker)

local function GetDirection(moves)
	return { x = moves[RIGHT] - moves[LEFT], y = moves[UP] - moves[DOWN] }
end

local function SetSpeed(player, speed)
	if speed then player.speed = speed end
	local vel = vector.Normalize(player.vel, player.speed)
	vel = vector.Add(vel, player.punishment)
	eapi.SetVel(player.body, vel)
end

local function Move(player, axis)
	return function(keyDown)
		player.moves[axis] = (keyDown and 1) or 0
		player.vel = GetDirection(player.moves)
		SetSpeed(player)
	end
end

local function EnableInput(player)
	local prefix = "P" .. player.index .. "_"
	input.Bind(prefix .. "Left", true, Move(player, LEFT))
	input.Bind(prefix .. "Right", true, Move(player, RIGHT))
	input.Bind(prefix .. "Up", true, Move(player, UP))
	input.Bind(prefix .. "Down", true, Move(player, DOWN))
	return player
end

local xylo = { "sound/xylo1.ogg", "sound/xylo2.ogg" }

local function XyloSound(index)
	util.PlaySound(gameWorld, xylo[index], 0.1, 0, 0.5)
end
		
local function PlayerRunsIntoBall(pShape, bShape)
	local player = actor.store[pShape]
	local victim = actor.store[bShape]

	ball.Burst(victim)

	if player.index == victim.index then
		player.rights = player.rights + 1
		XyloSound(2)
		hud.Inc(1)
	else
		player.wrongs = player.wrongs + 1
		XyloSound(1)
		hud.Dec(7)
	end
end

actor.SimpleCollide("Player", "Ball", PlayerRunsIntoBall)

local function Magnetize(player, victim)
	local speed = player.speed + 100
	victim.magnetized = true
	local function Traction()
		local playerPos = actor.GetPos(player)
		local victimPos = actor.GetPos(victim)
		local vel = vector.Sub(playerPos, victimPos)
		eapi.SetVel(victim.body, vector.Normalize(vel, speed))
		eapi.AddTimer(victim.body, 0.1, Traction)
	end
	Traction()
end

local function TractorBeam(pShape, bShape)
	local player = actor.store[pShape]
	local victim = actor.store[bShape]

	if player.index == victim.index and not victim.magnetized then
		Magnetize(player, victim)
	end
end

actor.SimpleCollide("Magnetic", "Ball", TractorBeam, nil, false)

local function PlayerDir(obj)
	return vector.Sub(actor.GetPos(obj), mob.GetPos())
end

local function AnimateAngle(obj, angle, duration)
        actor.AnimateAngle(obj.tile, angle, duration)
end

local function Recovery(player)
	player.punishment = vector.null
	player.punished = false
end

local shineImg = actor.LoadSprite("image/shine.png", { 128, 128 })

local function Explosion(player)
	local z = player.z + 1
	local pos = actor.GetPos(player)
	local srcSize = { x = 2, y = 2 }
	local srcPos = vector.Offset(pos, -1, -1)
	local dstSize = { x = 512, y = 512 }
	local dstPos = vector.Offset(pos, -256, -256)
	local tile = eapi.NewTile(staticBody, srcPos, srcSize, shineImg, z)
	eapi.AddTimer(player.body, 0.25, function() eapi.Destroy(tile) end)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.invisible, 0.25, 0)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, 0.25, 0)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dstPos, 0.25, 0)
end

local function PlayerRunsIntoMob(pShape, mShape)
	local player = actor.store[pShape]
	if not player.punished then
		eapi.PlaySound(gameWorld, "sound/burst.ogg", 0, 1.0)
		local vel = vector.Sub(actor.GetPos(player), mob.GetPos())
		player.punishment = vector.Normalize(vel, 800)
		eapi.SetVel(player.body, player.punishment)
		util.Delay(player.body, 0.5, Recovery, player)
		player.punished = true
		Explosion(player)
		hud.Reset()
	end
end

actor.SimpleCollide("Player", "Mob", PlayerRunsIntoMob)

local playerSprites = { }

for i = 1, 2, 1 do
	local fileName = "image/player" .. i .. ".png"
	playerSprites[i] = actor.LoadSprite(fileName, { 64, 64 })
end

local flowImg = actor.LoadSprite("image/flow.png", { 64, 64 })

local ttl = 0.5
local function AddTrailingTrail(obj)
	local size = { x = 16, y = 16 }
	local offset = { x = -8, y = -8 }
	local dstSize = { x = 256, y = 256 }
	local dstOffset = { x = -128, y = -128 }
	local baseVel = { x = 250, y = 0 }
	local srcColor = util.CopyTable(ball.color[obj.index])
	local dstColor = ball.invisible[obj.index]
	util.SetColorAlpha(srcColor, 0.2)
	local progress = 0
	local function Trail()
		local z = obj.z - 1
		local body = eapi.NewBody(gameWorld, eapi.GetPos(obj.body))
		local tile = eapi.NewTile(body, offset, size, flowImg, z)
		eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, ttl, 0)
		eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dstOffset, ttl, 0)
		eapi.Animate(tile, eapi.ANIM_CLAMP, 32, progress)
		eapi.AddTimer(body, ttl, function() eapi.Destroy(tile) end)
		eapi.AddTimer(obj.body, 0.01, Trail)
		util.RotateTile(tile, obj.angle)
		util.DelayedDestroy(body, ttl)
		progress = (progress + 0.01) % 1.0
		
		local vel = vector.Rotate(baseVel, obj.angle)
		eapi.SetVel(body, vel)

		eapi.SetColor(tile, srcColor)
		eapi.AnimateColor(tile, eapi.ANIM_CLAMP, dstColor, ttl, 0)
	end
	Trail()
end

local function CreateProgressIndicator(obj, angle)
	local z = obj.z - 1.5
	local size = { x = 4, y = 24 }
	local offset = { x = 0, y = 32 }
	local tile = eapi.NewTile(obj.body, offset, size, util.triangle, z)	
	eapi.SetColor(tile, ball.invisible[obj.index])
	util.RotateTile(tile, angle)
	return tile
end

local function CreateRingOfProgress(obj)
	obj.pCount = 0
	obj.progress = { }
	for angle = 0, 359.9, (360.0 / 50.0) do
		obj.pCount = obj.pCount + 1
		obj.progress[obj.pCount] = CreateProgressIndicator(obj, angle)
	end
	obj.pBit = 1.0 / obj.pCount
end

local function Progress(obj, amount)
	local color = util.CopyTable(ball.color[obj.index])
	for i = 1, obj.pCount, 1 do
		local alpha = math.min(1.0, amount / obj.pBit)
		color = util.SetColorAlpha(color, alpha)
		eapi.SetColor(obj.progress[i], color)
		amount = math.max(0.0, amount - obj.pBit)
	end
end

local function Update(amount)
	util.Map(function(obj) Progress(obj, amount) end, player.objs)
end

local function Create(pos, index)
	local obj = { z = 0,
		      pos = pos,
		      angle = 0,
		      rights = 0,
		      wrongs = 0,
		      speed = 300,
		      index = index,
		      class = "Player",
		      vel = vector.null,
		      GetDir = PlayerDir,
		      moves = { 0, 0, 0, 0 },
		      punishment = vector.null,
		      offset = { x = -32, y = -32 },
		      spriteSize = { x = 64, y = 64 },
		      sprite = playerSprites[index],
		      bb = actor.Square(4) }
	local obj = actor.Create(obj)
	actor.AnimateToVelocity(obj, 1, AnimateAngle)
	eapi.Animate(obj.tile, eapi.ANIM_LOOP, 32, 0)
	actor.MakeShape(obj, actor.Square(16), "Magnetic")
	player.objs[index] = obj
	AddTrailingTrail(obj)
	CreateRingOfProgress(obj)
	return EnableInput(obj)
end

local function Reset()
	local function ResetPlayer(obj)
		obj.rights = 0
		obj.wrongs = 0
	end
	util.Map(ResetPlayer, player.objs)
end

player = {
	Update = Update,
	Create = Create,
	Reset = Reset,
	objs = { },
}
return player
