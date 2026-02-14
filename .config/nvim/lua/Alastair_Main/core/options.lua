vim.cmd("let g:netrw_banner = 0")

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true 
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

vim.opt.incsearch = true
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.backspace = {"start","eol","indent"}

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"

vim.opt.clipboard:append("unnamedplus")
vim.opt.hlsearch = true

vim.opt.mouse = "a"
vim.g.editorconfig = true


vim.env.PATH =
  "/home/alastair_oberon/Shenanigans/Coding_shenanigans/Juplab_env/.venv/bin:"
  .. vim.env.PATH
--MOLTEN.NVIM CONFIGURATION
--I find auto open annoying, keep in mind setting this option will require setting
--a keybind for: noautocmd MoltenEnterOutput to open the output again
vim.g.molten_auto_open_output = false
--this guide will be using image.nvim
--Don't forget to setup and install the plugin if you want to view image outputs
vim.g.molten_image_provider = 'image.nvim'
--optional, I like wrapping, works for virt text and the output window
vim.g.molten_wrap_output = true
--Output as virtual text. Allows outputs to always be shown, works with images, but can
-- be buggy with longer images
vim.g.molten_virt_text_output = true
--this will make it so the output shows up below the \'\'\' cell delimiter
vim.g.molten_virt_lines_off_by_1 = true
--Pointing Neovim at the Virtual Environment for Molten.nvim
vim.g.python3_host_prog = vim.fn.expand '~/Shenanigans/Coding_shenanigans/Juplab_env/.venv/bin/python3'
