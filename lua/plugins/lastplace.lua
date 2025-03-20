return {
	"ethanholz/nvim-lastplace",
	lazy = false,
	priority = 1000,
	config = function()
		require("nvim-lastplace").setup()
	end,
}
