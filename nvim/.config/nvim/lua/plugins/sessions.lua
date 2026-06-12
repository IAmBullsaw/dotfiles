return {
  {
    'DrKJeff16/project.nvim',
    config = function()
      require('project').setup {
        detection_methods = { "pattern", "lsp" },
        patterns = { ".git", "Makefile", "CMakeLists.txt", "package.json", "go.mod", "Cargo.toml" },
        silent_chdir = true,
      }
      require('telescope').load_extension('projects')

      vim.keymap.set('n', '<leader>pf', '<cmd>Telescope projects<cr>', { desc = '[P]roject [F]ind' })
      vim.keymap.set('n', '<leader>pp', '<cmd>Telescope projects<cr>', { desc = '[P]roject [P]icker' })
    end
  },

  {
    'stevearc/resession.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      local resession = require('resession')
      resession.setup({
        autosave = {
          enabled = true,
          interval = 60,
          notify = false,
        },
      })

      local function session_picker()
        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local conf = require('telescope.config').values
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')

        pickers.new({}, {
          prompt_title = 'Sessions',
          finder = finders.new_table {
            results = resession.list(),
          },
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                resession.load(selection[1], { notify = true })
              end
            end)
            return true
          end,
        }):find()
      end

      _G.resession_picker = session_picker

      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          local current = resession.get_current()
          if current then
            resession.save(current, { notify = false })
          end
        end,
      })

      vim.keymap.set('n', '<leader>pss', session_picker, { desc = '[P]roject [S]ession [S]elect' })
      vim.keymap.set('n', '<leader>psw', function()
        resession.save(vim.fn.getcwd(), { notify = true })
      end, { desc = '[P]roject [S]ession [W]rite/Save' })
      vim.keymap.set('n', '<leader>psq', function()
        resession.delete(nil, { notify = true })
      end, { desc = '[P]roject [S]ession [Q]uit/Delete' })
      vim.keymap.set('n', '<leader>psl', function()
        resession.load(vim.fn.getcwd(), { notify = true })
      end, { desc = '[P]roject [S]ession [L]oad last' })
      vim.keymap.set('n', '<leader>psr', function()
        local current = resession.get_current()
        if not current then
          vim.notify('No session loaded', vim.log.levels.WARN)
          return
        end
        vim.ui.input({ prompt = 'New session name: ', default = current }, function(name)
          if name and name ~= '' and name ~= current then
            resession.save(name, { notify = true })
            resession.delete(current, { notify = true })
          end
        end)
      end, { desc = '[P]roject [S]ession [R]ename' })
      vim.keymap.set('n', '<leader>psa', function()
        vim.ui.input({ prompt = 'Session name: ' }, function(name)
          if name and name ~= '' then
            resession.save(name, { notify = true })
          end
        end)
      end, { desc = '[P]roject [S]ession [A]dd/Save as' })
    end
  },
}
