-- Program configuration.

local eapi = eapi or { }

Cfg = {
        name = "Shmupacabra",
	version = "devel",

	-- Display.
	fullscreen	= false,
	windowWidth	= 800,
	windowHeight	= 480,
	screenBPP	= 0,
	
	-- Sound.
	channels	= 16,
	frequency	= 22050,
	chunksize	= 512,
	stereo		= true,

	-- Debug things.
	debug		= true,
	useDesktop	= true,
	screenWidth	= 800,
	screenHeight	= 480,
	printExtensions = false,
	FPSUpdateInterval = 1000,
	gameSpeed = 0,
        defaultShapeColor = {r=0,g=1,b=0},

	-- Default control scheme: actions mapped to keys.
	controls = {
		P1_Left   = { "Left" },
		P1_Right  = { "Right" },
		P1_Up     = { "Up" },
		P1_Down   = { "Down" },
		P1_Quit   = { "Escape" },
		P1_Select = { "Return" },

		P2_Left   = { "A" },
		P2_Right  = { "D" },
		P2_Up     = { "W" },
		P2_Down   = { "S" },
		P2_Quit   = { "Escape" },
		P2_Select = { "Space" },

		Escape	  = { "Escape" },
	},

        -- Engine config.
        poolsize = {
                world      = 12,
                body       = 4000,
                tile       = 4000,
                shape      = 4000,
                group      = 100,
                camera     = 10,
                texture    = 100,
                spritelist = 200,
                sound      = 100,
                music      = 10,
                timer      = 4000,
                gridcell   = 50000,
                property   = 20000,
                collision  = 1000
        },
        collision_dist = 1,
        cam_vicinity_factor = 0.5
}

return Cfg
