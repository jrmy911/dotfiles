return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    vim.keymap.set("n", "<C-n>", ":Neotree toggle float<CR>")
    vim.keymap.set("n", "<C-l>", ":Neotree toggle left<CR>")
    vim.keymap.set("n", "<C-o>", ":Neotree focus<CR>")
    vim.keymap.set("n", "<leader>q", ":Neotree action=close<CR>")

    require("neo-tree").setup({
      close_if_last_window = true,
      enable_git_status = false,
      enable_diagnostics = true,
      default_component_configs = {
        git_status = {
          symbols = {
            added = "",
            modified = "",
            deleted = "✖",
            renamed = "󰁕",
            untracked = "",
            ignored = "",
            unstaged = "󰄱",
            staged = "",
            conflict = "",
          }
        }
      }
    })
  end,
}
