local M = {
  clock = require('sidekick.clock'),
}

local clock_ns = vim.api.nvim_create_namespace('clock')
local clock_window = nil

local content_window = nil
local content_buffer = vim.api.nvim_create_buf(true, false)

function M.setup()
  M.clock.configure()
end

function M.open()
  M.clock.update_time()

  M.setup_windows()
  M.configure_windows()

  M.clock.start()

  -- Load file
  vim.api.nvim_buf_set_name(content_buffer, './tasks.norg')
  vim.api.nvim_buf_call(content_buffer, vim.cmd.edit)

  vim.api.nvim_create_autocmd("WinResized", { callback = M.configure_windows })
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

  vim.opt.signcolumn = 'no'
end

function M.setup_windows()
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

  local clockhl = { bg = "none", fg = "#ffffff", bold = true }
  vim.api.nvim_set_hl(clock_ns, "NormalFloat", clockhl)

  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none", fg = "#ffffff" })
end

return M
