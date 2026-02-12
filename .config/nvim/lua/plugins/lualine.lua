return {
  "nvim-lualine/lualine.nvim",
  config = function()
    require('lualine').setup({
      options = {
        theme = 'rose-pine',
      },
      sections = {
        lualine_a = {
          {
            'buffers',
            show_modified_status = true
          }
        }
      }
    })
  end
}
