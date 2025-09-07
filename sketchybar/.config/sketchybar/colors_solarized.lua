-- Solarized Colors

return {
	-- Solarized base colors
	base03 = 0xff002b36,  -- background shade (darkest)
	base02 = 0xff073642,  -- background shade
	base01 = 0xff586e75,  -- content tones (darkest)
	base00 = 0xff657b83,  -- content tones
	base0  = 0xff839496,  -- content tones
	base1  = 0xff93a1a1,  -- content tones (lightest)
	base2  = 0xffeee8d5,  -- background tint
	base3  = 0xfffdf6e3,  -- background tint (lightest)
	
	-- Solarized accent colors
	yellow = 0xffb58900,
	orange = 0xffcb4b16,
	red = 0xffdc322f,
	magenta = 0xffd33682,
	violet = 0xff6c71c4,
	blue = 0xff268bd2,
	cyan = 0xff2aa198,
	green = 0xff859900,
	
	-- Derived/utility colors
	white = 0xfffdf6e3,    -- Using base3 as white
	black = 0xff002b36,    -- Using base03 as black
	dirty_white = 0xddeee8d5, -- Base2 with alpha
	dark_grey = 0xff073642,  -- Base02
	grey = 0xff586e75,      -- Base01
	transparent = 0x00000000,
	
	-- Bar and component colors
	bar = {
		bg = 0xee002b36,     -- Base03 with slight transparency
		border = 0xff073642, -- Base02
	},
	popup = {
		bg = 0xdd073642,     -- Base02 with transparency
		border = 0xdd586e75  -- Base01 with transparency
	},
	spaces = {
		active = 0xff2aa198,  -- Cyan for active
		inactive = 0xbb839496, -- Base0 with transparency
	},
	bg1 = 0x33073642,       -- Base02 with more transparency
	bg2 = 0xff586e75,       -- Base01
	
	-- Function to apply alpha to colors
	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then return color end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
