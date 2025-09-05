-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin setup
require("lazy").setup({
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "akinsho/bufferline.nvim", version = "*", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "xiyaowong/transparent.nvim" },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "saadparwaiz1/cmp_luasnip" },  -- Added missing luasnip source
  { "L3MON4D3/LuaSnip" },
  { "neovim/nvim-lspconfig" },
  -- Mason plugins
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
})

-- Basic settings
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"
vim.cmd.colorscheme("habamax")
vim.cmd("set ls=2")
vim.cmd("set cmdheight=0")
vim.g.loaded_matchparen = 2
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.o.updatetime = 25

require("transparent").setup({ enable = true })

-- Diagnostics UI
vim.diagnostic.config({
  virtual_text = true,
  update_in_insert = true,
  float = { focusable = false, border = "rounded" },
})

-- Keymaps
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }
keymap('v', '<C-s>', '"+y', opts)
keymap('n', '<C-n>', ':NvimTreeToggle<CR>', opts)
keymap('n', '<S-l>', ':BufferLineCycleNext<CR>', opts)
keymap('n', '<S-h>', ':BufferLineCyclePrev<CR>', opts)

-- Treesitter
require("nvim-treesitter.configs").setup({
  ensure_installed = { "rust", "cpp", "python", "go" },
  highlight = { enable = true },
})

-- UI Plugins
require("nvim-tree").setup({
  sort_by = "case_sensitive",
  renderer = { group_empty = true },
  filters = { dotfiles = true },
  view = { width = 61 },
})

require("bufferline").setup({
  options = {
    diagnostics = "nvim_lsp",
    offsets = { { filetype = "NvimTree", text = "File Explorer", padding = 2 } },
  },
})

-- Mason Setup
require("mason").setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
})

-- Mason LSP Config
require("mason-lspconfig").setup({
  ensure_installed = {
    "gopls",
    "clangd", 
    "ruff",
    "rust_analyzer",
  },
  automatic_installation = true,
})

-- CMP Setup
local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-3),
    ["<C-f>"] = cmp.mapping.scroll_docs(5),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
    ["<Tab>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    ["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
    { name = "path" },
  }),
})

-- LSP Setup
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
local servers = {
  gopls = {},
  clangd = {
    cmd = { "clangd", "--completion-style=bundled", "--all-scopes-completion", "--suggest-missing-includes" }
  },
  html = {},
  cssls = {},
  ts_ls = {  -- typescript-language-server under this name
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "typescript", "typescriptreact", "typescript.tsx", "javascript", "javascriptreact", "javascript.jsx" },
    root_dir = lspconfig.util.root_pattern("tsconfig.json", "package.json", "jsconfig.json", ".git"),
    capabilities = capabilities,
  },
  pyright = {},
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        checkOnSave = { command = "check" },
        inlayHints = { lifetimeElision = { enable = true } },
      },
    },
  },
}
for name, config in pairs(servers) do
  config.capabilities = capabilities
  lspconfig[name].setup(config)
end
