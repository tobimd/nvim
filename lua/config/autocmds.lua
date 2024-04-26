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

local nty = function()
  local notify = require("notify")
  return function(msg, lvl)
    return notify(msg, lvl, { title = "LatexBuild" })
  end
end

local lvl = vim.log.levels

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
  local target = parent .. "/out"
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
    target = parent .. "/out"
    curr = parent .. "/main.tex"
  end

  return nil
end

-- setup nvim command
vim.api.nvim_create_user_command("LatexBuild", function()
  local log = nty()
  local val = not get_opt("latexbuild", false)
  local str = val and "on" or "off"

  set_opt("latexbuild", val)
  log("LatexBuild set `" .. str .. "`", lvl.INFO)
end, { desc = "Toggle latex build process on file save", nargs = 0 })

vim.api.nvim_create_user_command("LatexWatch", function()
  if not get_opt("latexbuild", false) then
    return
  end

  local log = nty()
  local val = not get_opt("latexwatch", false)
  local str = val and "on" or "off"

  set_opt("latexwatch", val)
  log("LatexWatch set `" .. str .. "`", lvl.INFO)
end, { desc = "Toggle latex watch process on file save", nargs = 0 })

-- setup nvim autocmd
local refresh_web_cmd = function(ctx)
  local job = require("plenary.job")
  job:new({ command = ctx.dir .. "/watch.sh", cwd = ctx.dir }):start()
end

local latexmk_cmd = function(ctx, watch)
  local log = nty()
  local job = require("plenary.job")
  local err = setmetatable({}, { __index = table })

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
        err:insert(data)
      end,
      on_exit = function(_, code)
        if code == 0 then
          log("Successfully built PDF", lvl.INFO)
          if watch then
            refresh_web_cmd(ctx)
          end
        else
          log("Command `latexmk` failed: " .. err:concat("\n"), lvl.ERROR)
        end
      end,
    })
    :start()
end

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*.tex", "*.bib" },
  desc = "Build latex pdf when saving a `.tex` file",
  callback = function()
    if get_opt("latexbuild", false) then
      local log = nty()
      local ctx = context()

      if ctx == nil then
        log("Failed to find root `main.tex` file", lvl.ERROR)
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

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.txt",
  desc = "Set default options for txt files",
  callback = function()
    vim.cmd([[
      set textwidth=70
      set spell
      set spelllang=en,es
    ]])
  end,
})
