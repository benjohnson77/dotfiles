local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Create a single workspace indicator for the current workspace
local current_workspace = sbar.add("item", "current_workspace", {
  position = "left",
  icon = {
    font = { family = settings.font.numbers },
    string = "?",
    padding_left = 7,
    padding_right = 3,
    color = colors.white,
  },
  label = {
    padding_right = 12,
    color = colors.white,
    font = "Symbols Nerd Font:Regular:16.0",
    y_offset = -1,
    string = " —",
  },
  padding_right = 1,
  padding_left = 1,
  background = {
    color = colors.bg1,
    border_width = 1,
    height = 26,
    border_color = colors.black,
  },
  update_freq = 1, -- Update every 1 second
})

local workspace_bracket = sbar.add("bracket", { current_workspace.name }, {
  background = {
    color = colors.transparent,
    border_color = colors.grey,
    height = 28,
    border_width = 2
  }
})

-- Padding
local workspace_padding = sbar.add("item", "workspace.padding", {
  script = "",
  width = settings.group_paddings,
})

-- Function to update the current workspace display
local function update_current_workspace()
  sbar.exec("aerospace list-workspaces --focused", function(focused_workspace)
    local workspace_name = focused_workspace:gsub("\n", "")
    
    -- Update workspace name
    current_workspace:set({
      icon = { string = workspace_name }
    })
    
    -- Get and display apps in current workspace
    sbar.exec("aerospace list-windows --format %{app-name} --workspace " .. workspace_name, function(windows)
      local no_app = true
      local icon_line = ""
      
      -- Simple icon mapping using Unicode symbols
      local simple_icons = {
        ["Cursor"] = "󰢒", -- Code editor icon
        ["Warp"] = "󰆘", -- Terminal icon  
        ["Code"] = "󰢒", -- VS Code
        ["Google Chrome"] = "󰖞", -- Browser icon
        ["Firefox"] = "󰖟", -- Firefox
        ["Safari"] = "󰖝", -- Safari
        ["Finder"] = "󰃡", -- Folder icon
        ["Spotify"] = "󰕵", -- Music icon
        ["Discord"] = "󰣯", -- Chat icon
        ["Slack"] = "󰣯", -- Chat icon
        ["Terminal"] = "󰆘", -- Terminal
        ["iTerm2"] = "󰆘", -- Terminal
        ["kitty"] = "󰆘", -- Terminal
      }
      
      for app in windows:gmatch("[^\r\n]+") do
        no_app = false
        local icon = simple_icons[app] or "󰇾" -- Default app icon
        icon_line = icon_line .. " " .. icon
      end

      if (no_app) then
        icon_line = " —"
      end
      
      sbar.animate("tanh", 10, function()
        current_workspace:set({ label = icon_line })
      end)
    end)
  end)
end

-- Subscribe to workspace changes
current_workspace:subscribe("aerospace_workspace_change", update_current_workspace)
current_workspace:subscribe("space_windows_change", update_current_workspace)

-- Add periodic update as fallback (every 5 seconds)
current_workspace:subscribe("routine", update_current_workspace)

-- Initial update
update_current_workspace()
