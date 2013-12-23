dofile("script/actor.lua")
dofile("script/hud.lua")

local function  GlowTile(tile)
	local color = eapi.GetColor(tile)
	for i, v in pairs(color) do color[i] = color[i] * 0.75 end
	eapi.AnimateColor(tile, eapi.ANIM_REVERSE_LOOP, color, 0.25, 0)
end

local function Glow(tileSet)
	util.Map(GlowTile, tileSet)
end

local title = "H I P N O P O T A M U S"
local under = "======================="
local pos = util.TextCenter(title, util.defaultFontset)
Glow(util.PrintRed(vector.Offset(pos, 0, 216), title, 0, nil, 0.2))
Glow(util.PrintRed(vector.Offset(pos, 0, 200), under, 0, nil, 0.2))

local menu = nil
local menuIndex = 1
local blinkTime = 0.5

local function FadeScreen()
	local dstColor = util.Gray(0)
	local srcColor = { r = 0, g = 0, b = 0, a = 0 }
	local screen = actor.FillScreen(util.white, 1000, srcColor)
	eapi.AnimateColor(screen, eapi.ANIM_CLAMP, dstColor, blinkTime, 0)
end

local function BlinkTiles(tiles, shouldDestroy)
	local total = 0.0
	local alpha = 0.1
	local interval = 0.05
	local function Blink()
		local function ChangeAlpha(tile)
			local color = eapi.GetColor(tile)
			color.a = alpha
			eapi.SetColor(tile, color)
		end
		util.Map(ChangeAlpha, tiles)
		if alpha < 0.99 or total < blinkTime then
			eapi.AddTimer(staticBody, interval, Blink)
			total = total + interval
			alpha = 1.1 - alpha
		elseif shouldDestroy then
			util.Map(eapi.Destroy, tiles)
		end
	end
	Blink()
	eapi.PlaySound(gameWorld, "sound/star.ogg", 0, 0.5)
end

local function Do(Fn, shouldFade)
	return function()
		BlinkTiles(menu[menuIndex].tiles)
		if shouldFade then FadeScreen() end
		eapi.AddTimer(staticBody, blinkTime, function() Fn() end)
	end
end

local function NewGame()
	util.Goto("game")
end

local function Decode(key)
        if type(key) == "number" then
		return eapi.GetKeyName(key)
	else
		return key
	end
end

local function AcquireKeybinding(entry, Next)
	local text = "Player" .. entry.num .. " press " .. entry.name .. "..."
	local pos = util.TextCenter(text, util.defaultFontset)
	pos = vector.Offset(pos, 0, -112)
	local tiles = util.PrintOrange(pos, text, 0, nil, 0.2)
	local acquired = false

	local function CaptureKey(key, pressed)
		if pressed and not acquired then
			acquired = true
			Cfg.controls[entry.key] = Decode(key)
			eapi.AddTimer(staticBody, blinkTime + 0.1, Next)
			eapi.BindKeyboard(util.Noop)
			BlinkTiles(tiles, true)
		end
	end
	input.RestoreNormal(CaptureKey)
end

local keyDesc = {
	{ num = 1, name = "up",     key = "P1_Up" },
	{ num = 1, name = "down",   key = "P1_Down" },
	{ num = 1, name = "left",   key = "P1_Left" },
	{ num = 1, name = "right",  key = "P1_Right" },
	{ num = 1, name = "select/pause", key = "P1_Select" },
	{ num = 1, name = "quit",   key = "P1_Quit" },

	{ num = 2, name = "up",     key = "P2_Up" },
	{ num = 2, name = "down",   key = "P2_Down" },
	{ num = 2, name = "left",   key = "P2_Left" },
	{ num = 2, name = "right",  key = "P2_Right" },
	{ num = 2, name = "select/pause", key = "P2_Select" },
	{ num = 2, name = "quit",   key = "P2_Quit" },
}

local function SaveKeys()
        local f = io.open("setup.lua", "w")
        if f then
		local function Write(entry)
			local var = entry.key
			local val = util.Format(Cfg.controls[var])
			f:write("Cfg.controls." .. var .. "=" .. val .. "\n")
		end
		util.Map(Write, keyDesc)
                io.close(f)
        end
end

local function SetupKeys()
	local index = 1
	local function Aquire()
		if keyDesc[index] then
			AcquireKeybinding(keyDesc[index], Aquire)
			index = index + 1
		else
			SaveKeys()
			input.UnbindAll()
			startup.EnableInput()
			input.RestoreNormal()
		end
	end
	Aquire()
end

local menuSpacing = 24
local menuHeight = -128

menu = { { name = "Game", Action = Do(NewGame, true) }, 
	 { name = "Keys", Action = Do(SetupKeys, false) }, 
	 { name = "Quit", Action = Do(eapi.Quit, true) }, }

for i = 1, #menu, 1 do
	local pos = { x = -16, y = menuHeight - i * menuSpacing }
	menu[i].tiles = util.PrintOrange(pos, menu[i].name, 0, nil, 0)
end

hud.Box({ x = 128, y = 80 }, { x = -64, y = menuHeight - 80 }, nil, -100)

local function Wobble(dir, tileSet)
	local function WobbleTile(tile)
		local pos = eapi.GetPos(tile)
		pos = vector.Offset(pos, 8 * dir, 0)
		eapi.AnimatePos(tile, eapi.ANIM_REVERSE_LOOP, pos, 0.25, 0)
	end
	util.Map(WobbleTile, tileSet)
	return tileSet
end

local cursorTiles = { }

local cPos = { x = 0, y = menuHeight - menuSpacing }
local cBody = eapi.NewBody(gameWorld, cPos)

local function AddWobblingCursor(xOffset, dir, text)
	local pos = { x = xOffset, y = 0 }
	local tileSet = Wobble(dir, util.PrintOrange(pos, text, 0, cBody, 0))
	cursorTiles = util.JoinTables(cursorTiles, tileSet)
end

AddWobblingCursor(-48, 1, "=>")
AddWobblingCursor(32, -1, "<=")

local function UpdateCursorPosition(yOffset)
	local pos = eapi.GetPos(cBody)
	pos = vector.Offset(pos, 0, -yOffset)
	eapi.SetPos(cBody, pos)
end

local function Move(dir)
	return function(keyDown)
		if keyDown then
			local oldIndex = menuIndex
			menuIndex = (((menuIndex - 1) + dir) % #menu) + 1
			local yOffset = (menuIndex - oldIndex) * menuSpacing
			eapi.PlaySound(gameWorld, "sound/xylo1.ogg", 0, 0.25)
			UpdateCursorPosition(yOffset)
		end
	end
end

local function Disable(prefix)
	input.Bind(prefix .. "Up")
	input.Bind(prefix .. "Down")
	input.Bind(prefix .. "Select")
end

local function Select(keyDown)
	if keyDown then
		Disable("P1_")
		Disable("P2_")
		menu[menuIndex].Action()
	end
end

local function Enable(prefix)
	input.Bind(prefix .. "Up", true, Move(-1))
	input.Bind(prefix .. "Down", true, Move(1))
	input.Bind(prefix .. "Select", true, Select)
end

local function EnableInput()
	Enable("P1_")
	Enable("P2_")
	actor.Quit(eapi.Quit)
end

local function Jitter(tileSet)
	local i = -math.random()
	local j = 0.5 + 0.5 * math.random()
	local x = math.random(-1, 1)
	local y = math.random(-1, 1)
	local function JitterTile(tile)
		local pos = eapi.GetPos(tile)
		pos = vector.Offset(pos, x, y)
		local color = eapi.GetColor(tile)
		color = util.Map(function(x) return x * j end, color)
		eapi.AnimatePos(tile, eapi.ANIM_REVERSE_LOOP, pos, 0.1, i)
		eapi.AnimateColor(tile, eapi.ANIM_REVERSE_LOOP, color, 0.1, i)
	end
	util.Map(JitterTile, tileSet)
end

for x = -8, 7, 1 do
	for y = -16, 15, 1 do
		local pos = { x = x * 8, y = y * 8 + 40 }
		Jitter(util.PrintOrange(pos, "*", 0, nil, 0.2))
	end
end

local hints = {
	"Invite a good old friend.",
	"Collect beads of same color.",
	"Dodge beads of opposite color.",
}

for i = 1, 3, 1  do	
	local pos = { x = 112, y = 128 - i * 32 }
	util.PrintOrange(pos, hints[i], 0, nil, 0.2)
end

eapi.FadeMusic(0.5)
EnableInput()

startup = {
	EnableInput = EnableInput,
}
