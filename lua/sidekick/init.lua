local utils = require('sidekick.utils')

local M = {
  content_file_path = nil,
  clock = require('sidekick.clock'),
  content = require('sidekick.content'),
}

local clock_window = nil
local content_window = 0

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

  -- Start clock
  M.clock.start()

  -- Show content
  M.content.start(M.content_file_path)
  vim.api.nvim_set_current_buf(M.content.buffer)

  -- Start org agenda view
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'orgagenda',
    callback = function()
      vim.api.nvim_win_set_height(0, 17)
    end,
  })
  require 'orgmode'.agenda:agenda()

  -- Reconfigure windows on resize
  vim.api.nvim_create_autocmd('WinResized', { callback = M.configure_windows })

  -- Quit key
  vim.keymap.set('n', '<c-q>', '<cmd>wqa<cr>')
end

function M.configure_windows()
  M.clock.update_time()
end

function M.setup_windows()
  vim.opt.signcolumn = 'no'
  vim.opt.laststatus = 0
  vim.opt.showtabline = 0
  vim.opt.cursorline = true
  vim.opt.listchars = {}
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.statuscolumn = ''

  M.clock.configure_buffer()
  M.content.configure_buffer()
  clock_window = vim.api.nvim_open_win(M.clock.buffer, false, {
    vertical = false,
    split = 'above',
  })
  vim.api.nvim_set_option_value('winfixbuf', true, { win = clock_window })
  vim.api.nvim_win_set_height(clock_window, 13)

  vim.api.nvim_win_set_hl_ns(content_window, M.content.namespace)
  vim.api.nvim_win_set_hl_ns(clock_window, M.clock.namespace)

  -- clock_window = clock_window or vim.api.nvim_open_win(M.clock.buffer, false, {
  --   -- relative = 'editor',
  --   -- style = 'minimal',
  --   -- zindex = 40,
  --   noautocmd = true,
  --   focusable = true,
  --   -- width = 1,
  --   -- height = 1,
  --   -- row = 0,
  --   -- col = 0,
  -- })

  -- M.content.configure_buffer()
  -- content_window = content_window or vim.api.nvim_open_win(M.content.buffer, true, {
  --   relative = 'win',
  --   style = 'minimal',
  --   zindex = 50,
  --   width = 1,
  --   height = 1,
  --   row = 0,
  --   col = 0,
  -- })
  -- vim.api.nvim_set_option_value('winfixbuf', true, { win = content_window })

  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none', fg = '#ffffff', bold = false })
end

return M
