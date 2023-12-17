vim.opt.rtp:append(vim.fn.getcwd())

require('sidekick').setup({ file = './tasks.norg' }).open()
