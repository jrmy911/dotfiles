return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local treesitter = require("nvim-treesitter")
    treesitter.setup()
    treesitter.install { 'lua', 'vim', 'vimdoc', 'yaml', 'go', 'terraform' }

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'lua', 'vim', 'vimdoc', 'yaml', 'go', 'terraform' },
      callback = function()
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end
}
