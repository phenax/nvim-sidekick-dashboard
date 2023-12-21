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

local months = {
  Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
  Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}

function M.parse_date(date_str)
  local day, month_str, year = date_str:match('(%d+)%s+(%a+)%s*(%d*)')
  local month = months[month_str]
  if year == "" or year == nil then
    year = os.date("%Y")
  end

  if day == nil or month == nil then
    error('Invalid date: ' .. date_str)
  end

  local date = os.time({ year = year, month = month, day = day, hour = 0, min = 0, sec = 0 })
  local days = math.ceil(os.difftime(date, os.time()) / (24 * 60 * 60))

  return {
    timestamp = date,
    raw = date_str,
    days = days,
  }
end

return M
