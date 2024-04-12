local set_opt = function(name, value)
  return vim.api.nvim_set_var(name, value)
end
local get_opt = function(name, default)
  local value = vim.api.nvim_get_var(name)
  if value == nil and default ~= nil then
    value = default
  end
  return value
end

local parentdir = function(path)
  if path == nil then
    return nil
  end

  if ({ path:gsub("/", "") })[2] < 2 then
    return path
  end

  if path:sub(-1) == "/" then
    path = path:sub(1, -2)
  end

  local dir = path:match(".*/")

  if dir:len() > 1 then
    dir = dir:sub(1, -2)
  end

  return dir
end

local context = function()
  local file = vim.fn.expand("%:p")
  local parent = parentdir(file)
  local target = parent .. "/target"
  local curr = parent .. "/main.tex"

  if file == curr then
    vim.fn.mkdir(target, "p")
    return { src = file, dir = parent, trg = target }
  end

  for _ = 1, 4 do
    if vim.fn.filereadable(curr) ~= 0 then
      vim.fn.mkdir(target, "p")
      return { src = curr, dir = parent, trg = target }
    end

    parent = parentdir(parent)
    target = parent .. "/target"
    curr = parent .. "/main.tex"
  end

  return nil
end

-- setup nvim command
vim.api.nvim_create_user_command("LatexBuild", function()
  local nty = require("notify")
  local val = not get_opt("latexbuild", false)
  local str = val and "on" or "off"

  set_opt("latexbuild", val)
  nty("LatexBuild set `" .. str .. "`")
end, { desc = "Toggle latex build process on file save", nargs = 0 })

vim.api.nvim_create_user_command("LatexWatch", function()
  if not get_opt("latexbuild", false) then
    return
  end

  local nty = require("notify")
  local val = not get_opt("latexwatch", false)
  local str = val and "on" or "off"

  set_opt("latexwatch", val)
  nty("LatexWatch set `" .. str .. "`")
end, { desc = "Toggle latex watch process on file save", nargs = 0 })

-- setup nvim autocmd
local refresh_web_cmd = function(ctx)
  local nty = require("notify")
  local job = require("plenary.job")
  job
    :new({
      command = ctx.dir .. "/watch.sh",
      cwd = ctx.dir,
      -- on_stderr = function(_, data) nty("Command `./watch.sh` failed: " .. data, vim.log.levels.ERROR, { title = "LatexBuild" }) end,
    })
    :start()
end

local latexmk_cmd = function(ctx, watch)
  local nty = require("notify")
  local job = require("plenary.job")
  job
    :new({
      command = "latexmk",
      args = {
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-lualatex",
        "-outdir=" .. ctx.trg,
        ctx.src,
      },
      cwd = ctx.dir,
      on_stderr = function(_, data)
        nty("Command `latexmk` failed: " .. data)
      end,
      on_exit = function(_, code)
        -- nty('DEBUG: signal="' .. tostring(signal) .. '", code="' .. tostring(code) .. '", src="' .. tostring(ctx.src) .. '", dir="' .. tostring(ctx.dir) .. '", trg="' .. tostring(ctx.trg) .. '"')
        if code == 0 then
          nty("Successfully built PDF", vim.log.levels.INFO, { title = "LatexBuild" })

          if watch then
            refresh_web_cmd(ctx)
          end
        end
      end,
    })
    :start()
end

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.tex",
  desc = "Build latex pdf when saving a `.tex` file",
  callback = function()
    if get_opt("latexbuild", false) then
      local nty = require("notify")
      local ctx = context()

      if ctx == nil then
        nty("Failed to find root `main.tex` file", vim.log.levels.ERROR, { title = "LatexBuild" })
        return
      end

      latexmk_cmd(ctx, get_opt("latexwatch", true))
    end
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.tex",
  desc = "Set default options for latex files",
  callback = function()
    set_opt("latexbuild", true)
    set_opt("latexwatch", true)
    vim.cmd([[
      set textwidth=70
      set spell
      set spelllang=es,en
    ]])
  end,
})
