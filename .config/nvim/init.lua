local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

local opts = {}

require("vimconfig")
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  checker = { enabled = true },
})

local zeavim_path = vim.fn.stdpath("data") .. "/lazy/zeavim.vim/plugin/zeavim.vim"
local lines = vim.fn.readfile(zeavim_path)
for i, line in ipairs(lines) do
  if line:match("^set fileformat=") then
    lines[i] = '" ' .. line -- comment it out
  end
end
vim.fn.writefile(lines, zeavim_path)

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.filetype.add({ extension = { bicepparam = "bicep-params" } })
vim.filetype.add({ extension = { tf = "terraform" } })
