local utils = require('sidekick.utils')

local M = {
  content_file = nil,
  clock = require('sidekick.clock'),
  extmarks = {},
}

local clock_ns = vim.api.nvim_create_namespace('clock')
local clock_window = nil

local content_ns = vim.api.nvim_create_namespace('clock')
local content_window = nil
local content_buffer = vim.api.nvim_create_buf(true, false)

function M.setup(c)
  if c.file == nil then
    error('Option file is required')
  end

  M.content_file = c.file

  return M
end

local task_item_query = vim.treesitter.query.parse('norg', [[
  (detached_modifier_extension
    (timestamp timestamp:(timestamp_data)@_timestamp))
]])

local months = {
  Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
  Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}

local function parse_date(date_str)
  local day, month_str, year = date_str:match('(%d+)%s+(%a+)%s*(%d*)')
  local month = months[month_str]
  if year == "" or year == nil then
    year = os.date("%Y")
  end

  if day == nil or month == nil then
    error('Invalid date: ' .. date_str)
  end

  local date = os.time({ year = year, month = month, day = day })

  local days = math.ceil(os.difftime(date, os.time()) / (24 * 60 * 60))

  return {
    timestamp = date,
    raw = date_str,
    is_today = days == 0,
    is_tomorrow = days == 1,
    days = days,
  }
end

function M.show_deadline(deadline_capture)
  local time = deadline_capture.text
  local row = deadline_capture.node:range(false)

  local get_hl = function(datetime)
    if datetime.is_today then
      return '@sidekick.time.today'
    elseif datetime.is_tomorrow then
      return '@sidekick.time.tomorrow'
    elseif datetime.days < 0 then
      return '@sidekick.time.overdue'
    elseif datetime.days < 5 then
      return '@sidekick.time.soon'
    else
      return '@sidekick.time.default'
    end
  end

  local get_text = function(datetime)
    if datetime.is_today then return 'Today'
    elseif datetime.is_tomorrow then return 'Tomorrow'
    elseif datetime.days < 0 then return 'Overdue (' .. datetime.raw .. ')'
    elseif datetime.days < 5 then return datetime.raw .. ' (' .. datetime.days .. ' days left)'
    else return datetime.raw
    end
  end

  local datetime = parse_date(time)

  M.extmarks[row] = vim.api.nvim_buf_set_extmark(content_buffer, content_ns, row, 0, {
    end_line = row,
    end_col = 0,
    hl_group = 'NormalFloat',
    virt_text = {
      { ' ' .. get_text(datetime) .. ' ', get_hl(datetime) },
      { ' ', 'NormalFloat' }
    },
    virt_text_pos = 'right_align',
  })
end

function M.clear_exts()
  for _, ext_id in pairs(M.extmarks) do
    vim.api.nvim_buf_del_extmark(content_buffer, content_ns, ext_id)
  end
end

function M.update_metadata()
  M.clear_exts()
  utils.foreach_ts_capture({
    query = task_item_query,
    bufnr = content_buffer,
    ft = 'norg',
    names = { '_timestamp' },
    callback = function(capture)
      if capture._timestamp ~= nil then
        M.show_deadline(capture._timestamp)
      end
    end,
  })
end

function M.open()
  M.setup_windows()
  M.configure_windows()

  -- Start clock updates
  M.clock.start()

  -- Load content buffer
  vim.api.nvim_buf_set_name(content_buffer, M.content_file)
  vim.api.nvim_buf_call(content_buffer, vim.cmd.edit)
  vim.opt.conceallevel = 0

  M.update_metadata()
  vim.api.nvim_create_autocmd('InsertLeave', {
    buffer = content_buffer,
    callback = M.update_metadata,
  })
  -- Reconfigure windows on resize
  vim.api.nvim_create_autocmd('WinResized', { callback = M.configure_windows })

  -- Quit if content buffer is closed
  vim.api.nvim_create_autocmd('BufEnter', {
    nested = true,
    callback = function()
      if not utils.is_buffer_open(content_buffer) then
        vim.cmd'qa'
      end
    end,
  })
end

function M.configure_windows()
  local width = vim.api.nvim_get_option('columns')
  local height = vim.api.nvim_get_option('lines')

  vim.api.nvim_win_set_config(clock_window, {
    relative = 'editor',
    width = width,
    height = height,
    row = 0,
    col = 0,
  })
  vim.api.nvim_win_set_hl_ns(clock_window, clock_ns)

  M.clock.update_time()
  local content_width = width
  local top = M.clock.last_line_number + 3
  vim.api.nvim_win_set_config(content_window, {
    relative = 'win',
    width = content_width - 1,
    height = height - top,
    row = top,
    col = 1,
  })
  vim.api.nvim_win_set_hl_ns(content_window, content_ns)

  vim.opt.signcolumn = 'no'
  vim.opt.laststatus = 0
  vim.opt.showtabline = 0
  vim.opt.cursorline = true
end

function M.setup_windows()
  M.clock.configure_buffer()

  clock_window = clock_window or vim.api.nvim_open_win(M.clock.buffer, false, {
    relative = 'editor',
    style = 'minimal',
    zindex = 40,
    noautocmd = true,
    focusable = false,
    width = 1,
    height = 1,
    row = 0,
    col = 0,
  })
  content_window = content_window or vim.api.nvim_open_win(content_buffer, true, {
    relative = 'win',
    style = 'minimal',
    zindex = 50,
    width = 1,
    height = 1,
    row = 0,
    col = 0,
  })

  local clockhl = { bg = 'none', fg = '#ffffff', bold = true }
  vim.api.nvim_set_hl(clock_ns, 'NormalFloat', clockhl)

  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none', fg = '#ffffff' })

  local red = '#dc2626'
  local yellow = '#854d0e'
  local white = '#ffffff'

  vim.api.nvim_set_hl(content_ns, '@sidekick.time.today', { bg = red, fg = 'none', bold = true })
  vim.api.nvim_set_hl(content_ns, '@sidekick.time.tomorrow', { bg = yellow, fg = 'none', bold = true })
  vim.api.nvim_set_hl(content_ns, '@sidekick.time.overdue', { bg = 'none', fg = red, bold = true })
  vim.api.nvim_set_hl(content_ns, '@sidekick.time.soon', { bg = 'none', fg = yellow, bold = true })
  vim.api.nvim_set_hl(content_ns, '@sidekick.time.default', { bg = 'none', fg = white })
end

return M
