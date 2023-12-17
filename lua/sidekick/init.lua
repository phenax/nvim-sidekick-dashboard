local font = require('sidekick.font')

local function lines(str)
  local t = {}
  for line in str:gmatch('[^\r\n]+') do
    table.insert(t, line)
  end
  return t
end

local M = {}

local win_handle = nil
local buffer = vim.api.nvim_create_buf(false, true)

function M.str_to_glyph(str)
  local glyphs = {}
  for ch in str:gmatch('.') do
    if font[ch] == nil then
      print('missing glyph for ' .. ch)
      return
    end

    table.insert(glyphs, lines(font[ch]))
  end

  return glyphs
end

function M.glyph_lines(glyphs)
  local lines = {}
  for i = 1, #glyphs[1] do
    local line = ''
    for j = 1, #glyphs do
      line = line .. ' ' .. glyphs[j][i]
    end
    table.insert(lines, line)
  end
  return lines
end

function M.setup()
  -- print('setup')
  -- local time = vim.fn.strftime('%H:%M:%S')
  -- local glyphs = M.glyph_lines(M.str_to_glyph(time))
  -- for _, g in pairs(glyphs) do
  --   print(g)
  -- end
end

function M.open()
  print('opening')
  local width = vim.api.nvim_win_get_width(0)
  local height = vim.api.nvim_win_get_height(0)

  local time = vim.fn.strftime('%H:%M:%S')
  local glyphs = M.glyph_lines(M.str_to_glyph(time))

  local str_width = vim.fn.strdisplaywidth(glyphs[1])
  local padding = string.rep(' ', (width - str_width)/2)
  for i, g in pairs(glyphs) do
    glyphs[i] = padding .. g
  end
  vim.api.nvim_buf_set_lines(buffer, 0, #glyphs, false, glyphs)

  if win_handle == nil then
    win_handle = vim.api.nvim_open_win(buffer, true, {
      relative = 'editor',
      width = width,
      height = height,
      row = 0,
      col = 0,
      style = 'minimal',
    })
  end
end

return M
