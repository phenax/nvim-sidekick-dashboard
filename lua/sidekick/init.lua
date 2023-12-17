local M = {
  clock = require('sidekick.clock'),
  tasks = {}
}

local win_handle = nil
local buffer = vim.api.nvim_create_buf(false, true)

function M.setup()
  M.clock.configure({ buffer = buffer })
end

function M.open()
  M.clock.start()

  vim.api.nvim_buf_set_keymap(buffer, 'n', '<Esc>', '<cmd>qa<cr>', { noremap = false, silent = true })

  if win_handle == nil then
    local width = vim.api.nvim_win_get_width(0)
    local height = vim.api.nvim_win_get_height(0)

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
