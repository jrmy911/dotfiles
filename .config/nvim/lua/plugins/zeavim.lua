return {
  "KabbAmine/zeavim.vim",
  init = function()
    vim.g.zv_file_types = { hcl = "terraform", go = "go" }
    if vim.fn.has("wsl") == 1 then
      vim.g.zv_zeal_executable = "/mnt/c/Program Files/Zeal/zeal.exe"
    elseif vim.fn.has("win32") == 1 then
      vim.g.zv_zeal_executable = os.getenv("ProgramFiles") .. "\\Zeal\\zeal.exe"
    else
      vim.g.zv_zeal_executable = "zeal"
    end
  end,
}
