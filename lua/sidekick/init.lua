local M = {
  clock = require('sidekick.clock'),
}

-- TODO: Use namespaces
local main_window = nil
local content_window = nil
local clock_buffer = vim.api.nvim_create_buf(false, true)
local tasks_buffer = vim.api.nvim_create_buf(true, false)

function M.setup()
  M.clock.configure({ buffer = clock_buffer })
end

function M.open()
  M.clock.update_time()

  M.setup_windows()
  M.on_resize()

  M.clock.start()

  vim.api.nvim_buf_set_name(tasks_buffer, './tasks.norg')
  vim.api.nvim_buf_call(tasks_buffer, vim.cmd.edit)

  vim.api.nvim_create_autocmd("WinResized", { callback = M.on_resize })
end

function M.on_resize()
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  vim.api.nvim_win_set_config(main_window, {
    relative = 'editor',
    width = width,
    height = height,
    row = 0,
    col = 0,
  })

  M.clock.update_time()
  local content_width = math.floor(width * 0.9)
  local top = M.clock.last_line_number + 3
  vim.api.nvim_win_set_config(content_window, {
    relative = 'win',
    width = content_width,
    height = height - top,
    row = top,
    col = (width - content_width)/2,
  })

  vim.opt.signcolumn = 'no'
end

function M.setup_windows()
  main_window = main_window or vim.api.nvim_open_win(clock_buffer, false, {
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
  content_window = content_window or vim.api.nvim_open_win(tasks_buffer, true, {
    relative = 'win',
    style = 'minimal',
    zindex = 50,
    width = 1,
    height = 1,
    row = 0,
    col = 0,
  })
  vim.api.nvim_set_hl(0, "Normal", { bg = "none", fg = "#ffffff" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none", fg = "#ffffff" })
end

return M
