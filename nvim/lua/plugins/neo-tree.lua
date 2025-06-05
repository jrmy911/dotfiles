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
		vim.keymap.set("n", "<C-b>", ":Neotree toggle left<CR>")
		vim.keymap.set("n", "<leader>q", ":Neotree action=close<CR>")
		vim.keymap.set("n", "<leader>g", ":Neotree source=git_status<CR>")
	end,
}
