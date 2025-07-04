return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "bashls",
          "ansiblels",
          "terraformls",
          "tflint",
          "dockerls",
          "docker_compose_language_service",
          "bicep",
          "helm_ls",
          "pylsp",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require("lspconfig")
      local bicep_lsp_bin = "/usr/local/bin/bicep-langserver/Bicep.Langserver.dll"
      lspconfig.lua_ls.setup({
        capabilities = capabilities
      })
      lspconfig.bashls.setup({
        capabilities = capabilities
      })
      lspconfig.ansiblels.setup({
        capabilities = capabilities
      })
      lspconfig.terraformls.setup({
        capabilities = capabilities
      })
      lspconfig.dockerls.setup({
        capabilities = capabilities
      })
      lspconfig.docker_compose_language_service.setup({
        capabilities = capabilities
      })
      lspconfig.bicep.setup({
        capabilities = capabilities
      })
      lspconfig.helm_ls.setup({
        capabilities = capabilities
      })
      lspconfig.pylsp.setup({
        capabilities = capabilities
      })

      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "gr", vim.lsp.buf.references, {})
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
    end,
  },
}
