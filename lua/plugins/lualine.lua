-- change lualine options (info bar below)

local get_mode = function()
  return vim.api.nvim_get_mode().mode:sub(1, 1):upper()
end

local get_macro = {
  require("noice").api.status.mode.get,
  cond = require("noice").api.status.mode.has,
}

local progress = function()
  local cur = vim.fn.line(".")
  local total = vim.fn.line("$")
  if cur == 1 then
    return "000%%"
  elseif cur == total then
    return "100%%"
  else
    return string.format("%03d%%%%", math.floor(cur / total * 100))
  end
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      sections = {
        lualine_a = {
          { get_mode, separator = "" },
          get_macro,
        },
        lualine_b = {
          { "branch", icon = "", separator = "" },
          {
            "diff",
            colored = true,
            diff_color = {
              added = { fg = "#67fcb1" },
              modified = { fg = "#ead04f" },
              removed = { fg = "#f97763" },
            },
          },
        },
        lualine_c = {
          { "filetype", separator = "" },
          {
            "filename",
            newfile_status = true,
            path = 3,
            symbols = {
              modified = "~",
              readonly = "#",
              unnamed = "?",
              newfile = "!",
            },
          },
        },
        lualine_x = {
          { "location", separator = "" },
          { progress },
        },
        lualine_y = { "tabs" },
        lualine_z = { "diagnostics" },
      },
    },
  },
}
