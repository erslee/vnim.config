vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("t", "<c-h>", "<C-\\><C-n><C-w>h", { noremap = true, silent = true })
vim.keymap.set("t", "<c-j>", "<C-\\><C-n><C-w>j", { noremap = true, silent = true })
vim.keymap.set("t", "<c-k>", "<C-\\><C-n><C-w>k", { noremap = true, silent = true })
vim.keymap.set("t", "<c-l>", "<C-\\><C-n><C-w>l", { noremap = true, silent = true })

-- vim.keymap.set({ "n", "i" }, "<c-h>", "<ESC><C-w>h", { noremap = true, silent = true })
-- vim.keymap.set({ "n", "i" }, "<c-j>", "<ESC><C-w>j", { noremap = true, silent = true })
-- vim.keymap.set({ "n", "i" }, "<c-k>", "<ESC><C-w>k", { noremap = true, silent = true })
-- vim.keymap.set({ "n", "i" }, "<c-l>", "<ESC><C-w>l", { noremap = true, silent = true })
vim.keymap.set("i", "<D-L>", "<ESC>$a", { noremap = true, silent = true })
vim.keymap.set("i", "<D-H>", "<ESC>^i", { noremap = true, silent = true })
vim.keymap.set("i", "<D-l>", "<ESC>ea", { noremap = true, silent = true })
vim.keymap.set("i", "<D-h>", "<ESC>bi", { noremap = true, silent = true })
vim.keymap.set("n", "[b", ":bp<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "]b", ":bn<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<space>bp", ":bp<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<space>bn", ":bn<CR>", { noremap = true, silent = true })
-- vim.keymap.set("n", "<space>bd", ":bdelete<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<space>bQ", ":%bd|e#<CR>", { noremap = true, silent = true, desc = "Delete other buffers" })
vim.keymap.set("n", "<space>br", ":e#<CR>", { noremap = true, silent = true, desc = "Reopen last buffer" })

vim.keymap.set("n", "<space>s", ":split<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<space>v", ":vsplit<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<space>tv", ":vert rightbelow terminal<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<space>ts", ":horizontal rightbelow terminal<CR>", { noremap = true, silent = true })

-- local builtin = require("telescope.builtin")
-- vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
-- vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
-- vim.keymap.set('n', '<leader>bb', builtin.buffers, { desc = 'Telescope buffers' })
-- vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })

vim.keymap.set("n", "<D-b>", ":lua Snacks.explorer()<CR>", { desc = "Open file explorer" })
vim.keymap.set("n", "<leader>f", ":Yazi<CR>", { desc = "Telescope help tags" })
vim.keymap.set("n", "f", ":Yazi<CR>", { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>qq", ":quitall", { desc = "Quit all vim" })

vim.keymap.set("n", "<leader>wq", ":q<CR>", { desc = "Quit all vim" })
vim.keymap.set("n", "<leader>ww", ":w", { desc = "Save changes" })
vim.keymap.set("n", "<D-s>", ":w<CR>", { desc = "Save file changes" })
vim.keymap.set("i", "<D-s>", "<ESC>:w<CR>", { desc = "Save file changes" })
vim.keymap.set("n", "<leader>rr", ":Rest run<CR>", { desc = "Run REST command" })
vim.keymap.set("n", "<D-r>", ":Rest run<CR>", { desc = "Run REST command" })

vim.keymap.set("n", "<leader>=", "<c-w>=<CR>", { desc = "Set all windows same size" })

vim.keymap.set("n", "<F9>", ":lua require'dap'.continue()<CR>")
vim.keymap.set("n", "<F5>", ":lua require'dap'.step_over()<CR>")
vim.keymap.set("n", "<F4>", ":lua require'dap'.toggle_breakpoint()<CR>")
vim.keymap.set("n", "<F8>", ":lua require'dapui'.toggle()<CR>")
vim.keymap.set("n", "<F2>", ":lua require'dapui'.eval()<CR>")

-- vim.keymap.set({ "n", "v" }, "H", "b", { noremap = true, silent = true })
-- vim.keymap.set({ "n", "v" }, "L", "e", { noremap = true, silent = true })
-- vim.keymap.set({ "n", "v" }, "HH", "^", { noremap = true, silent = true })
-- vim.keymap.set({ "n", "v" }, "LL", "$", { noremap = true, silent = true })

-- vim.keymap.set("n", "KK", ":lua vim.diagnostic.open_float()<CR>")

-- vim.api.nvim_set_keymap("n", "<c-c>", '"*y :let @+=@*<CR>', { noremap = true, silent = true })

-- vim.api.nvim_set_keymap("n", "p", '"0p', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("n", "P", '"0P', { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "x", '"_x', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("n", "p", '"_p', { noremap = true, silent = true })

-- vim.keymap.set("n", "<leader>mm", ":mksession! ._Session.vim<CR>", { desc = "Save session" })

-- vim.keymap.set("n", "sasdf<c-w>=", "buffer 1<cr>", { desc = "set all windows same size" })
-- vim.keymap.set("n", "sasdf<c-w>=", "buffer 2<CR>", { desc = "Set all windows same size" })
-- vim.keymap.set("n", "sasdf<c-w>=", "buffer 3<CR>", { desc = "Set all windows same size" })
-- vim.keymap.set("n", "sasdf<c-w>=", "buffer 4<CR>", { desc = "Set all windows same size" })
-- vim.keymap.set("n", "sasdf<c-w>=", "buffer 5<CR>", { desc = "Set all windows same size" })
-- vim.keymap.set("n", "sasdf<c-w>=", "buffer 6<CR>", { desc = "Set all windows same size" })
-- vim.keymap.set("n", "sasdf<c-w>=", "buffer 7<CR>", { desc = "Set all windows same size" })
-- vim.keymap.set("n", "sasdf<c-w>=", "buffer 8<CR>", { desc = "Set all windows same size" })
-- vim.keymap.set("n", "sasdf<c-w>=", "buffer 9<CR>", { desc = "Set all windows same size" })
