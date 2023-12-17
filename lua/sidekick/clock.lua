local font = require('sidekick.font')

local M = {
  buffer = nil,
  timer = nil,
  last_line_number = 0,
}

function M.configure(c)
  M.buffer = c.buffer
end

function M.start()
  if M.timer ~= nil then
    M.timer:stop()
  end

  M.timer = M.timer or vim.loop.new_timer()
  M.timer:start(0, 500, vim.schedule_wrap(function()
    M.update_time()
  end))
end

local function lines(str)
  local t = {}
  for line in str:gmatch('[^\r\n]+') do
    table.insert(t, line)
  end
  return t
end

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

function M.glyph_lines(glyphs, get_padding_x, padding_y)
  local lines = {}
  for i = 1, padding_y do
    table.insert(lines, '')
  end
  for i = 1, #glyphs[1] do
    local line = ''
    for j = 1, #glyphs do
      line = line .. ' ' .. glyphs[j][i]
    end
    table.insert(lines, line)
  end
  for i = 1, padding_y do
    table.insert(lines, '')
  end

  local padding = string.rep(' ', get_padding_x(lines))
  for i, g in pairs(lines) do
    lines[i] = padding .. g
  end

  return lines
end

function M.update_time()
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  -- Clock
  local time = vim.fn.strftime('%H:%M:%S')
  local get_padding_x = function(lines)
    local max_len = math.max(unpack(vim.tbl_map(vim.api.nvim_strwidth, lines)))
    return (width - max_len)/2
  end
  local glyphs = M.glyph_lines(M.str_to_glyph(time), get_padding_x, 2)
  vim.api.nvim_buf_set_lines(M.buffer, 0, #glyphs, false, glyphs)

  -- Seperator
  vim.api.nvim_buf_set_lines(M.buffer, #glyphs, #glyphs + 1, false, { string.rep('⎯', width) })

  M.last_line_number = #glyphs + 1
end

return M
