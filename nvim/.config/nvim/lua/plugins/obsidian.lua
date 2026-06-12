return {
  'epwalsh/obsidian.nvim',
  version = '*',
  lazy = true,
  ft = 'markdown',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  opts = {
    workspaces = {
      {
        name = 'vault',
        path = '~/Code/vault',
      },
    },

    daily_notes = {
      folder = 'daily',
      date_format = '%Y-%m-%d',
      template = nil,
    },

    wiki_link_func = 'use_alias_only',
    preferred_link_style = 'wiki',

    note_id_func = function(title)
      return title
    end,

    disable_frontmatter = true,

    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },

    follow_url_func = function(url)
      vim.fn.jobstart({ 'xdg-open', url })
    end,

    mappings = {
      ['gf'] = {
        action = function()
          return require('obsidian').util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      ['<cr>'] = {
        action = function()
          return require('obsidian').util.smart_action()
        end,
        opts = { buffer = true, expr = true },
      },
    },

    ui = {
      enable = false,
    },
  },

  keys = {
    { '<leader>on', '<cmd>ObsidianNew<cr>', desc = '[O]bsidian [N]ew note' },
    { '<leader>oo', '<cmd>ObsidianQuickSwitch<cr>', desc = '[O]bsidian [O]pen note' },
    { '<leader>os', '<cmd>ObsidianSearch<cr>', desc = '[O]bsidian [S]earch' },
    { '<leader>od', '<cmd>ObsidianToday<cr>', desc = '[O]bsidian [D]aily note' },
    { '<leader>ob', '<cmd>ObsidianBacklinks<cr>', desc = '[O]bsidian [B]acklinks' },
    { '<leader>ol', '<cmd>ObsidianLinks<cr>', desc = '[O]bsidian [L]inks' },
    { '<leader>ot', '<cmd>ObsidianTags<cr>', desc = '[O]bsidian [T]ags' },
  },
}
