function add_rtp(path)
  vim.opt.rtp:append(vim.fn.expand('$HOME/.local/share/nvim/lazy/' .. path))
end

-- add_rtp('plenary.nvim')
-- add_rtp('nvim-treesitter')
vim.opt.rtp:append(vim.fn.getcwd())

---

require('sidekick').setup({})

require('sidekick').open()

