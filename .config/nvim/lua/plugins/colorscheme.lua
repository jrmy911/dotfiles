return {
  {
    "ember-theme/nvim",
    name = "ember",
    priority = 1000,
    config = function()
      require("ember").setup({
        variant = "ember", -- "ember" | "ember-soft" | "ember-light"
      })
      vim.cmd("colorscheme ember")
    end,
  },
  {
    "somerocketeer/bauhaus.nvim",
    name = "bauhaus-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("bauhaus").setup({ transparent = false })
      vim.cmd.colorscheme("bauhaus")
    end,
  },
}
