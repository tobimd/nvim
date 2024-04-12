-- change lualine options (info bar below)

local get_buffer = function()
  return "#" .. tostring(vim.fn.bufnr("%"))
end

local get_mode = function()
  return vim.api.nvim_get_mode().mode:sub(1, 1):upper()
end

---@diagnostic disable: undefined-field
local get_macro = {
  require("noice").api.status.mode.get,
  cond = require("noice").api.status.mode.has,
}
---@diagnostic enable: undefined-field

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
      options = {
        component_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { get_mode, get_macro },
        lualine_b = {
          { "branch", icon = "" },
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
          { "filetype" },
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
        lualine_x = { "diagnostics" },
        lualine_y = { "location", progress },
        lualine_z = { get_buffer },
      },
    },
  },
}
