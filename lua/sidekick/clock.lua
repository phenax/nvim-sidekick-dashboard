local font = require('sidekick.font')
local utils = require('sidekick.utils')

local M = {
  buffer = nil,
  timer = nil,
  last_line_number = 0,
  namespace = vim.api.nvim_create_namespace('sk.clock'),
  start_of_day_hour = 8,
  active_day_hour = 12,
  ramp_down_hour = 21,
  end_of_day_hour = 23.5,
  too_early_hour = 5,
}

function M.configure_buffer()
  M.buffer = M.buffer or vim.api.nvim_create_buf(false, true)
end

function M.start()
  M.configure_buffer()
  vim.api.nvim_set_hl(M.namespace, 'Normal', { bg = 'none', fg = '#ffffff', bold = true })
  vim.api.nvim_set_hl(M.namespace, 'SKProgressEmpty', { fg = '#1a1824' })
  vim.api.nvim_set_hl(M.namespace, 'SKProgressDay', { fg = '#2E3440' })
  vim.api.nvim_set_hl(M.namespace, 'SKProgressActive', { fg = '#245f4e' })
  vim.api.nvim_set_hl(M.namespace, 'SKProgressRampDown', { fg = '#713f12' })
  vim.api.nvim_set_hl(M.namespace, 'SKProgressNight', { fg = '#d63031' })

  if M.timer ~= nil then
    M.timer:stop()
  end

  M.timer = M.timer or vim.uv.new_timer()
  M.timer:start(0, 500, vim.schedule_wrap(function()
    M.update_time()
    M.update_progress_bar()
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
  for _ = 1, padding_y do
    table.insert(lines, '')
  end
  for i = 1, #glyphs[1] do
    local line = ''
    for j = 1, #glyphs do
      line = line .. ' ' .. (glyphs[j][i] or '')
    end
    table.insert(lines, line)
  end
  for _ = 1, padding_y do
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

  local width = vim.api.nvim_get_option_value('columns', {})

  -- Clock
  local time = vim.fn.strftime('%I:%M:%S')
  local get_padding_x = function(lines)
    local max_len = math.max(unpack(vim.tbl_map(vim.api.nvim_strwidth, lines)))
    return (width - max_len) / 2
  end
  local glyphs = M.glyph_lines(M.str_to_glyph(time), get_padding_x, 2)
  vim.api.nvim_buf_set_lines(M.buffer, 0, #glyphs, false, glyphs)

  local date = vim.fn.strftime('%A, %d %B')
  date = string.rep(' ', (width - #date) / 2) .. date
  vim.api.nvim_buf_set_lines(M.buffer, #glyphs, #glyphs + 1, false, { date })

  M.last_line_number = #glyphs + 1
end

function M.update_progress_bar()
  local line = M.last_line_number
  local columns = vim.api.nvim_get_option_value('columns', {})
  local padding = 0
  local width = math.floor(columns - padding * 2)

  local progressbar_str = string.rep('█', width)
  local padding_str = string.rep(' ', padding)
  local line_str = padding_str .. progressbar_str

  local function to_idx(n)
    return vim.str_byteindex(line_str, 'utf-16', n, true)
  end

  local function hour_to_cols(hour)
    return math.ceil(width * (hour - M.start_of_day_hour) /
      (M.end_of_day_hour - M.start_of_day_hour))
  end

  local function fill_range(start_col, end_col, hl)
    vim.hl.range(M.buffer, M.namespace, hl,
      { line + 1, to_idx(padding + start_col) },
      { line + 1, to_idx(padding + end_col) },
      { inclusive = true })
  end

  vim.api.nvim_buf_set_lines(M.buffer, line, line + 2, false, { '', line_str })

  local current_minutes = tonumber(os.date('%M'))
  local current_hour = tonumber(os.date('%H')) + (current_minutes / 60)

  -- The day's over
  if current_hour >= M.end_of_day_hour or current_hour <= M.too_early_hour then
    vim.hl.range(M.buffer, M.namespace, 'SKProgressNight', { line + 1, 0 }, { line + 1, 0 }, { regtype = 'V' })
    return
  end

  local current_hour_cols = hour_to_cols(current_hour)

  local ranges = {
    { start_col = current_hour_cols, end_col = columns - 2 * padding, hl = 'SKProgressEmpty' },
    { hour = M.ramp_down_hour,       hl = 'SKProgressRampDown' },
    { hour = M.active_day_hour,      hl = 'SKProgressActive' },
    { hour = M.start_of_day_hour,    hl = 'SKProgressDay' },
  }

  local last_filled_col = current_hour_cols
  for _, range in ipairs(ranges) do
    if range.hour and current_hour > range.hour then
      local cols = hour_to_cols(range.hour)
      fill_range(cols, last_filled_col, range.hl)
      last_filled_col = cols
    elseif range.start_col and range.end_col then
      fill_range(range.start_col, range.end_col, range.hl)
      last_filled_col = range.start_col
    end
  end
end

return M
