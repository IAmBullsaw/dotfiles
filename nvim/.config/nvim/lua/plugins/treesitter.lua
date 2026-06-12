return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  config = function()
    local filetypes = {
      'bash', 'c', 'cpp', 'cmake', 'diff', 'erlang', 'go', 'html',
      'lua', 'luadoc', 'make', 'markdown', 'markdown_inline',
      'python', 'query', 'starlark', 'vim', 'vimdoc'
    }

    vim.schedule(function()
      for _, lang in ipairs(filetypes) do
        pcall(vim.cmd, 'TSInstallSync ' .. lang)
      end
    end)

    vim.api.nvim_create_autocmd('FileType', {
      pattern = filetypes,
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
