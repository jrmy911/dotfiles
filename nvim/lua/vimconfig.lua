vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.g.mapleader = " "

vim.opt.nu = true

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set('n', '<leader>fa', ':set filetype=yaml.ansible<CR>', { desc = 'Set filetype to yaml.ansible' })
vim.keymap.set('n', '[d', function() vim.diagnostic.open_float() end, opts)
