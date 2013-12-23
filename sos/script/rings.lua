local img = actor.LoadSprite("image/ring.png", { 512, 512 })

local function Create()
	local depth = -100
	local speed = 32
	local scale = 1024
	local alpha = 1.0
	local step = 240
	local count = 16
	local sign = 1
	
	for i = 1, count, 1 do
		local size = { x = scale, y = scale }
		local offset = vector.Scale(size, -0.5)
		local tile = eapi.NewTile(staticBody, offset, size, img, depth)
		eapi.Animate(tile, eapi.ANIM_LOOP, 16, math.random())
		util.AnimateRotation(tile, sign * speed)
		eapi.SetColor(tile, util.Gray(alpha))
		alpha = alpha - (1 / count)
		scale = scale - step
		speed = speed - 1
		depth = depth - 1
		step = 0.76 * step 
		sign = -sign
	end
end

rings = {
	Create = Create,
}
return rings
