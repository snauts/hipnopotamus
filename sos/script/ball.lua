local ballSprites = { }
local ballSrcSize = { x = 4, y = 4 }
local ballSrcOffset = { x = -2, y = -2 }
local ballDstSize = { x = 32, y = 32 }
local ballDstOffset = { x = -16, y = -16 }
local ballBoundingBox = actor.Square(6)

local ballColor = {
	{ r = 0.847, g = 0.474, b = 0.752, a = 1.0 },
	{ r = 0.372, g = 0.807, b = 0.701, a = 1.0 },
}

local ballInvisible = {
	{ r = 0.847, g = 0.474, b = 0.752, a = 0.0 },
	{ r = 0.372, g = 0.807, b = 0.701, a = 0.0 },
}

local white = { r = 1, g = 1, b = 1, a = 1 }

local starSize = { x = 16, y = 16 }
local starOffset = { x = -8, y = -8 }

local starImg = actor.LoadSprite("image/twinkle.png", { 64, 64 })

local function CircularJitter(pos, amount)
	local angle = 360 * math.random()
	local distance = amount * math.sqrt(math.random())
	local jitter = vector.Rotate({ x = distance, y = 0 }, angle)
	return vector.Add(pos, jitter)
end

local function SetRandomAngle(tile)
	local speed = 0.25 + 0.25 * math.random()
	if math.random() > 0.5 then speed = -speed end
	util.AnimateRotation(tile, speed, 360 * math.random())
end

local function EmitTwinkle(obj)
	local pos = eapi.GetPos(obj.body)
	pos = CircularJitter(pos, 16)
	local vel = eapi.GetVel(obj.body)
	vel = vector.Rotate(vel, 30 * (1 - 2 * math.random()))

	local body = eapi.NewBody(gameWorld, pos)
	local tile = eapi.NewTile(body, starOffset, starSize, starImg, obj.z)
	eapi.SetColor(tile, ballColor[obj.index])
	local dstColor = ballInvisible[obj.index]
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, dstColor, 1, 0)
	eapi.SetVel(body, vector.Scale(vel, 0.5 + math.random()))
	eapi.SetAcc(body, vector.Scale(vel, -0.5))
	util.DelayedDestroy(body, 1.0)
	SetRandomAngle(tile)
end

local function Burst(obj)
	for i = 1, 20, 1 do EmitTwinkle(obj) end
	actor.Delete(obj)
end

for i = 1, 2, 1 do
	local fileName = "image/ball" .. i .. ".png"
	ballSprites[i] = actor.LoadSprite(fileName, { 32, 32 })
end

local fadeIn = 0.25

local function Emit(vel, index)
	local init = { index = index,
		       class = "Ball",
		       velocity = vel,		       
		       pos = mob.GetPos(),
		       offset = ballSrcOffset,
		       spriteSize = ballSrcSize,
		       bb = ballBoundingBox,
		       z = 20 + ball.z_epsilon,
		       sprite = ballSprites[index], }
	local obj = actor.Create(init)
	eapi.SetColor(obj.tile, util.invisible)
	eapi.Animate(obj.tile, eapi.ANIM_REVERSE_LOOP, 256, 0)
	eapi.AnimateColor(obj.tile, eapi.ANIM_CLAMP, white, fadeIn, 0)
	eapi.AnimateSize(obj.tile, eapi.ANIM_CLAMP, ballDstSize, fadeIn, 0)
	eapi.AnimatePos(obj.tile, eapi.ANIM_CLAMP, ballDstOffset, fadeIn, 0)
	ball.z_epsilon = math.min(ball.z_epsilon + 0.0001, 100)
	return obj
end

local ttl = 0.2
local function Annihilate(obj)
	actor.DeleteShape(obj)
	actor.DelayedDelete(obj, ttl)
	eapi.AnimateSize(obj.tile, eapi.ANIM_CLAMP, ballSrcSize, ttl, 0)
	eapi.AnimatePos(obj.tile, eapi.ANIM_CLAMP, ballSrcOffset, ttl, 0)
	eapi.AnimateColor(obj.tile, eapi.ANIM_CLAMP, util.invisible, ttl, 0)
end

local function Sweep()
	local index = 1
	local balls = { }
	-- collect balls first so we don't have to delete
	-- from table we are iterating over at the same time
	local function CollectBalls(obj)
		if obj.class == "Ball" then
			balls[index] = obj
			index = index + 1
		end
	end
	util.Map(CollectBalls, actor.store)
	util.Map(Annihilate, balls)
end

ball = {
	Emit = Emit,
	speed = 150,
	Sweep = Sweep,
	Burst = Burst,
	z_epsilon = 0,
	starImg = starImg,
	color = ballColor,
	invisible = ballInvisible,

	SetRandomAngle = SetRandomAngle,
}
return ball
