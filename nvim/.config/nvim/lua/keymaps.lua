-- Clear search highlights
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostics
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  virtual_text = true,
  virtual_lines = false,
  jump = {
    on_jump = function()
      vim.diagnostic.open_float()
    end
  },
}
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Terminal
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Template: TODO comment
vim.keymap.set('n', '<leader>tt', function()
  local user = os.getenv("USER") or "user"
  local date = os.date("%y%m%d")
  local comment = string.format("// TODO (%s) %s ", user, date)
  vim.api.nvim_put({comment}, 'c', true, true)
  vim.cmd('startinsert!')
end, { desc = '[T]emplate [T]odo comment' })

-- Split navigation (ctrl+hjkl)
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- File
vim.keymap.set('n', '<leader>fn', function()
  local filename = vim.fn.input 'New file: '
  if filename ~= '' then vim.cmd('edit ' .. filename) end
end, { desc = '[F]ile [N]ew' })
vim.keymap.set('n', '<leader>fq', '<cmd>bdelete<cr>', { desc = '[F]ile [Q]uit buffer' })

-- Buffers
vim.keymap.set('n', '<leader>bn', '<cmd>bnext<cr>', { desc = '[B]uffer [N]ext' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprev<cr>', { desc = '[B]uffer [P]rev' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = '[B]uffer [D]elete' })

-- Splits
vim.keymap.set('n', '<leader>bsh', '<cmd>split<cr>', { desc = '[B]uffer [S]plit [H]orizontal' })
vim.keymap.set('n', '<leader>bsv', '<cmd>vsplit<cr>', { desc = '[B]uffer [S]plit [V]ertical' })
vim.keymap.set('n', '<leader>bsc', '<C-w>q', { desc = '[B]uffer [S]plit [C]lose' })
vim.keymap.set('n', '<leader>bse', '<C-w>=', { desc = '[B]uffer [S]plit [E]qualize' })
vim.keymap.set('n', '<leader>bsH', '<C-w>H', { desc = '[B]uffer [S]plit move left' })
vim.keymap.set('n', '<leader>bsL', '<C-w>L', { desc = '[B]uffer [S]plit move right' })
vim.keymap.set('n', '<leader>bsJ', '<C-w>J', { desc = '[B]uffer [S]plit move down' })
vim.keymap.set('n', '<leader>bsK', '<C-w>K', { desc = '[B]uffer [S]plit move up' })

-- Autocommands
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.textwidth = 70
  end,
})

-- Force redraw when regaining focus (fixes rendering in Zellij)
vim.api.nvim_create_autocmd('FocusGained', {
  callback = function()
    vim.cmd('mode')
  end,
})
