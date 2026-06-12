return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    spec = {
      { '<leader>f', group = '[F]ind', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle/[T]emplate' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { '<leader>b', group = '[B]uffer' },
      { '<leader>bs', group = '[B]uffer [S]plit' },
      { '<leader>p', group = '[P]roject' },
      { '<leader>ps', group = '[P]roject [S]ession' },
    },
  },
}
