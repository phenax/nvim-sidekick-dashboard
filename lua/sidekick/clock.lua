local font = require('sidekick.font')
local utils = require('sidekick.utils')

local M = {
  buffer = nil,
  timer = nil,
  last_line_number = 0,
}

function M.configure_buffer()
  M.buffer = M.buffer or vim.api.nvim_create_buf(false, true)
end

function M.start()
  M.configure_buffer()

  if M.timer ~= nil then
    M.timer:stop()
  end

  M.timer = M.timer or vim.loop.new_timer()
  M.timer:start(0, 500, vim.schedule_wrap(function()
    M.update_time()
  end))
end

function M.str_to_glyph(str)
  local glyphs = {}
  for ch in str:gmatch('.') do
    if font.characters[ch] == nil then
      print('missing glyph for ' .. ch)
      return
    end

    table.insert(glyphs, utils.lines(font.characters[ch]))
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
      line = line .. ' ' .. (glyphs[j][i] or '')
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
  M.configure_buffer()

  local width = vim.api.nvim_get_option('columns')
  local height = vim.api.nvim_get_option('lines')

  -- Clock
  local time = vim.fn.strftime('%I:%M:%S')
  local get_padding_x = function(lines)
    local max_len = math.max(unpack(vim.tbl_map(vim.api.nvim_strwidth, lines)))
    return (width - max_len)/2
  end
  local glyphs = M.glyph_lines(M.str_to_glyph(time), get_padding_x, 2)
  vim.api.nvim_buf_set_lines(M.buffer, 0, #glyphs, false, glyphs)

  local date = vim.fn.strftime('%A, %d %B')
  date = string.rep(' ', (width - #date)/2) .. date
  vim.api.nvim_buf_set_lines(M.buffer, #glyphs, #glyphs + 1, false, { date })

  M.last_line_number = #glyphs + 1
end

return M
