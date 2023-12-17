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

function M.foreach_ts_capture(opts)
  local parser = vim.treesitter.get_parser(opts.bufnr, opts.ft)
  local root = parser:parse()[1]:root()

  for _pat, match, _meta in opts.query:iter_matches(root, opts.bufnr, 0, -1) do
    local capture = {}
    for id, node in pairs(match) do
      local name = opts.query.captures[id]
      if vim.tbl_contains(opts.names, name) then
        capture[name] = {
          text = vim.treesitter.get_node_text(node, opts.bufnr),
          node = node,
        }
      end
    end

    if opts.callback(capture) == true then
      return true
    end
  end

  return false
end

return M
