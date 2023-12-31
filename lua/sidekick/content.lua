local utils = require('sidekick.utils')

local M = {
  buffer = nil,
  namespace = vim.api.nvim_create_namespace('sk.content'),
  extmarks = {},
}

function M.configure_buffer()
  M.buffer = M.buffer or vim.api.nvim_create_buf(true, false)
end

function M.start(file)
  M.setup_theme()

  -- Load content buffer
  vim.api.nvim_buf_set_name(M.buffer, file)
  vim.api.nvim_buf_call(M.buffer, vim.cmd.edit)
  vim.opt.conceallevel = 0

  -- Update deadline hints on text change
  M.update()
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged' }, {
    buffer = M.buffer,
    callback = M.update,
  })
end

local get_hl = function(datetime)
  if datetime.days == 0 then return '@sidekick.time.today'
  elseif datetime.days == 1 then return '@sidekick.time.tomorrow'
  elseif datetime.days < 0 then return '@sidekick.time.overdue'
  elseif datetime.days < 7 then return '@sidekick.time.soon'
  else return '@sidekick.time.default'
  end
end

local get_text = function(datetime)
  if datetime.days == 0 then return ' Today '
  elseif datetime.days == 1 then return ' Tomorrow '
  elseif datetime.days < 0 then return '[Overdue: ' .. -datetime.days .. ' days]'
  elseif datetime.days < 7 then return '[' .. datetime.days .. ' days left]'
  else return '[' .. datetime.raw .. ']'
  end
end

function M.show_deadline(deadline_capture)
  local time = deadline_capture.text
  local row = deadline_capture.node:range(false)

  local is_valid, datetime = pcall(utils.parse_date, time)

  local virt_text = nil
  if is_valid then
    virt_text = { get_text(datetime), get_hl(datetime) }
  else
    virt_text = { ':: Invalid format ::', '@sidekick.time.overdue' }
  end

  M.extmarks[row] = vim.api.nvim_buf_set_extmark(M.buffer, M.namespace, row, 0, {
    end_line = row,
    end_col = 0,
    hl_group = 'NormalFloat',
    virt_text = {
      virt_text,
      { ' ', 'NormalFloat' }
    },
    virt_text_pos = 'right_align',
  })
end

function M.clear_exts()
  for _, ext_id in pairs(M.extmarks) do
    vim.api.nvim_buf_del_extmark(M.buffer, M.namespace, ext_id)
  end
end

local task_item_query = vim.treesitter.query.parse('norg', [[
  (detached_modifier_extension
    (timestamp timestamp:(timestamp_data)@_timestamp))
]])

function M.update()
  M.clear_exts()
  utils.foreach_ts_capture({
    query = task_item_query,
    bufnr = M.buffer,
    ft = 'norg',
    names = { '_timestamp' },
    callback = function(capture)
      if capture._timestamp == nil then return end
      local node = capture._timestamp.node:parent()
      if node:prev_sibling() == nil then return end
      local task_type = node:prev_sibling():prev_sibling()
      if task_type ~= nil and not vim.tbl_contains({ 'todo_item_done' }, task_type:type()) then
        M.show_deadline(capture._timestamp)
      end
    end,
  })
end

function M.setup_theme()
  local red = '#dc2626'
  local yellow = '#854d0e'
  local white = '#ffffff'
  local gray = '#888888'

  vim.api.nvim_set_hl(M.namespace, '@sidekick.time.today', { bg = red, fg = 'none', bold = true })
  vim.api.nvim_set_hl(M.namespace, '@sidekick.time.tomorrow', { bg = yellow, fg = 'none', bold = true })
  vim.api.nvim_set_hl(M.namespace, '@sidekick.time.overdue', { bg = 'none', fg = red, bold = true })
  vim.api.nvim_set_hl(M.namespace, '@sidekick.time.soon', { bg = 'none', fg = yellow, bold = true })
  vim.api.nvim_set_hl(M.namespace, '@sidekick.time.default', { bg = 'none', fg = gray, bold = true })
end

return M
