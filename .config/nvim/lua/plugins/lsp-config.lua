return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp", -- Required for capabilities
    },
    config = function()
      -- 1. Setup Mason
      require("mason").setup()

      -- 2. Validate Capabilities (Auto-completion support)
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- 3. Setup Mason-LSPConfig
      require("mason-lspconfig").setup({
        -- specific lsp servers (tflint removed as it is not an LSP)
        ensure_installed = {
          "lua_ls",
          "bashls",
          "ansiblels",
          "terraformls",
          "dockerls",
          "docker_compose_language_service",
          "bicep",
          "helm_ls",
          "pylsp",
        },
        -- AUTOMATIC SETUP (The Fix)
        handlers = {
          -- The Default Handler:
          -- Applies to every server in 'ensure_installed' unless overridden below
          function(server_name)
            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
            })
          end,

          -- Example: Overriding specific settings for Lua (optional)
          ["lua_ls"] = function()
            require("lspconfig").lua_ls.setup({
              capabilities = capabilities,
              settings = {
                Lua = {
                  diagnostics = { globals = { "vim" } },
                },
              },
            })
          end,
        },
      })

      -- 4. Keymaps (Best Practice: Only set when LSP attaches)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
        end,
      })
    end,
  },
}
