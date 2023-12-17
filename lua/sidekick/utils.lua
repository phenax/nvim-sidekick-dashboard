local M = {}

function M.lines(str)
  local t = {}
  for line in str:gmatch('[^\r\n]+') do
    table.insert(t, line)
  end
  return t
end

function M.is_buffer_open(bufnr)
  return #vim.fn.getbufinfo(bufnr)[1].windows > 0
end

return M
