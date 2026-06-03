return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup({
      ensure_installed = { "lua", "vim", "markdown", "terraform", "go", "gomod", "gosum", "gowork" },
      auto_install = { enable = true },
    })
    -- Highlight and indent are now handled by Neovim's built-in treesitter
    -- (enabled by default in Neovim 0.10+)
  end,
}
