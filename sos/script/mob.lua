local bounceSpeed = 150

local spiralImg = actor.LoadSprite("image/spiral.png", { 128, 128 })

local function Create()
	local init = { z = 200,
		       class = "Mob",
		       pos = vector.null,
		       sprite = spiralImg,
		       bb = actor.Square(16),
		       offset = { x = -64, y = -64 }, }
	local obj = actor.Create(init)	
	eapi.Animate(obj.tile, eapi.ANIM_REVERSE_LOOP, 32, 0)
	util.AnimateRotation(obj.tile, 2, 0)
	mob.obj = obj
end

local function GetValue(Fn, body, arg)
	return (arg and Fn(body, arg)) or Fn(body)
end

local function GetStat(obj, Fn, arg)
	return (obj.destroyed and vector.null) or GetValue(Fn, obj.body, arg)
end

local function GetPos()
	return GetStat(mob.obj, eapi.GetPos, gameWorld)
end

local function GetVel()
	return GetStat(mob.obj, eapi.GetVel)
end

local ttl = 10.0

local starSize = { x = 16, y = 16 }
local starOffset = { x = -8, y = -8 }

local gravity = { x = 0, y = -400 }

local function EmitTwinkle()
	local index = math.random(1, 2)
	local angle = 360 * math.random()
	local distance = 40 * math.sqrt(math.random()) + 0.01
	local pos = vector.Rotate({ x = distance, y = 0 }, angle)

	local sprite = ball.starImg
	local body = eapi.NewBody(gameWorld, pos)
	local tile = eapi.NewTile(body, starOffset, starSize, sprite, 540)
	eapi.SetColor(tile, ball.color[index])
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, ball.invisible[index], ttl, 0)
	
	ball.SetRandomAngle(tile)

	local vel = vector.Scale(pos, 40)
	eapi.SetVel(body, vel)
	local acc = vector.Add(gravity, vector.Scale(pos, -80))
	eapi.SetAcc(body, acc)
	return body
end

local function StopAcc(body)
	eapi.SetAcc(body, vector.null)
end

local function Explode()
	local store = { }
	actor.Delete(mob.obj)
	for i = 1, 1000, 1 do
		store[i] = EmitTwinkle()
	end
	eapi.AddTimer(staticBody, 0.45, function()				
		util.Map(StopAcc, store)
	end)	
	eapi.AddTimer(staticBody, ttl, function()
		util.Map(eapi.Destroy, store)
	end)	
	eapi.PlaySound(gameWorld, "sound/beat.ogg")
end

local function Expand()
	local dstPos = { x = -128, y = -128 }
	local dstSize = { x = 256, y = 256 }
	eapi.AnimatePos(mob.obj.tile, eapi.ANIM_CLAMP, dstPos, 1, 0)
	eapi.AnimateSize(mob.obj.tile, eapi.ANIM_CLAMP, dstSize, 1, 0)
end

local function ChangeDirection(axis, amount, pos, vel)
	if math.abs(pos[axis]) > amount then 
		vel[axis] = -bounceSpeed * util.Sign(pos[axis])
	end 
end

local function MobHitsWall(bShape, mShape)
	local vel = eapi.GetVel(mob.obj.body)
	local pos = actor.GetPos(mob.obj)
	ChangeDirection("x", 380, pos, vel)
	ChangeDirection("y", 220, pos, vel)
	eapi.SetVel(mob.obj.body, vel) 
end

actor.SimpleCollide("Blocker", "Mob", MobHitsWall)

local function Bounce()	
	pattern.Next()
	pattern.Schedule(0.0)
	eapi.SetVel(mob.obj.body, { x = bounceSpeed, y = bounceSpeed })
end

local function MoveTo(pos, FollowUp)
	local function Next()
		pattern.Next()
		pattern.Schedule(0.0)
		eapi.SetVel(mob.obj.body, vector.null)
		util.MaybeCall(FollowUp)
	end
	return function()
		local vel = vector.Sub(pos, mob.GetPos())
		eapi.AddTimer(mob.obj.body, 1, Next)
		eapi.SetVel(mob.obj.body, vel)
	end
end

local function Circle()	
	local function Encircle()
		eapi.SetStepC(mob.obj.body, eapi.STEPFUNC_ROT, 1)
	end
	MoveTo({ x = 0, y = 180 }, Encircle)()
end

local function Uncircle()
	pattern.Next()
	pattern.Schedule(0.0)
	eapi.SetStepC(mob.obj.body, eapi.STEPFUNC_STD)
	eapi.SetVel(mob.obj.body, vector.null)
	eapi.SetAcc(mob.obj.body, vector.null)
end

local function Loom()
	local x = 380
	local y = 220
	local body = mob.obj.body
	local function BackAndForth()
		if mob.shouldLoom then
			local dst = { x = -x, y = y }
			local pos = eapi.GetPos(body)	
			eapi.SetVel(body, vector.Sub(dst, pos))
			eapi.AddTimer(body, 1, BackAndForth)
			x = -x
		end
	end
	mob.MoveTo({ x = x, y = y }, BackAndForth)()
	mob.shouldLoom = true
end

local function Unloom()
	pattern.Next()
	pattern.Schedule(0.0)
	mob.shouldLoom = false
end

mob = {
	Create = Create,
	GetPos = GetPos,
	GetVel = GetVel,
	Explode = Explode,
	Expand = Expand,
	Bounce = Bounce,
	Circle = Circle,
	Uncircle = Uncircle,
	MoveTo = MoveTo,
 	Unloom = Unloom,
	Loom = Loom,
}
return mob
