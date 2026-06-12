return {
  'saghen/blink.cmp',
  event = 'VimEnter',
  version = '1.*',
  dependencies = {
    {
      'L3MON4D3/LuaSnip',
      version = '2.*',
      build = (function()
        if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
        return 'make install_jsregexp'
      end)(),
      dependencies = {},
      opts = {},
    },
    { 'saghen/blink.compat', version = '*', opts = {} },
  },
  --- @module 'blink.cmp'
  --- @type blink.cmp.Config
  opts = {
    keymap = { preset = 'default' },
    appearance = { nerd_font_variant = 'mono' },
    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets' },
      per_filetype = {
        markdown = { 'lsp', 'path', 'snippets', 'obsidian', 'obsidian_new', 'obsidian_tags' },
      },
      providers = {
        obsidian = { name = 'cmp_obsidian', module = 'blink.compat.source' },
        obsidian_new = { name = 'cmp_obsidian_new', module = 'blink.compat.source' },
        obsidian_tags = { name = 'cmp_obsidian_tags', module = 'blink.compat.source' },
      },
    },
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'lua' },
    signature = { enabled = true },
  },
}
