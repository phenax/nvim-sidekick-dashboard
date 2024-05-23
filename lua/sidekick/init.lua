local utils = require('sidekick.utils')

local M = {
  content_file_path = nil,
  clock = require('sidekick.clock'),
  content = require('sidekick.content'),
}

local clock_window = nil
local content_window = nil

function M.setup(c)
  if c.file == nil then
    error('Option file is required')
  end

  M.content_file_path = c.file

  return M
end

function M.open()
  M.setup_windows()
  M.configure_windows()

  -- Start clock updates
  M.clock.start()

  -- Start content buffer
  M.content.start(M.content_file_path)

  -- Reconfigure windows on resize
  vim.api.nvim_create_autocmd('WinResized', { callback = M.configure_windows })

  -- Quit if content buffer is closed
  vim.api.nvim_create_autocmd('BufEnter', {
    nested = true,
    callback = function()
      if not utils.is_buffer_open(M.content.buffer) then
        vim.cmd 'qa'
      end
    end,
  })
end

function M.configure_windows()
  M.clock.update_time()

  local width = vim.api.nvim_get_option('columns')
  local height = vim.api.nvim_get_option('lines')

  vim.api.nvim_win_set_config(clock_window, {
    relative = 'editor',
    width = width,
    height = height,
    row = 0,
    col = 0,
  })
  vim.api.nvim_win_set_hl_ns(clock_window, M.clock.namespace)

  local content_width = width
  local top = M.clock.last_line_number + 3
  vim.api.nvim_win_set_config(content_window, {
    relative = 'editor',
    width = content_width - 1,
    height = height - top,
    row = top,
    col = 1,
  })
  vim.api.nvim_win_set_hl_ns(content_window, M.content.namespace)

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
  vim.api.nvim_set_option_value('winfixbuf', true, { win = clock_window })

  M.content.configure_buffer()
  content_window = content_window or vim.api.nvim_open_win(M.content.buffer, true, {
    relative = 'win',
    style = 'minimal',
    zindex = 50,
    width = 1,
    height = 1,
    row = 0,
    col = 0,
  })
  vim.api.nvim_set_option_value('winfixbuf', true, { win = content_window })

  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none', fg = '#ffffff', bold = false })
end

return M
