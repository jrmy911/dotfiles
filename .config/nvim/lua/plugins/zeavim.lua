return {
  "KabbAmine/zeavim.vim",
  init = function()
    vim.g.zv_file_types = { hcl = "terraform", go = "go" }
  end,
}
