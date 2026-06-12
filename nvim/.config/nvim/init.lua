vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable netrw so alpha-nvim can be the startup screen
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Set font (for GUI clients like Neovide)
vim.o.guifont = 'FiraCode Nerd Font:h12'

-- [[ Setting options ]]
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

-- Custom filetype mappings
vim.filetype.add({
  extension = {
    ifx = "cpp",
    sig = "cpp",
  },
})

-- [[ Basic Keymaps ]]
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic Config & Keymaps
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },

  -- Can switch between these as you prefer
  virtual_text = true,
  virtual_lines = false,

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = { 
    on_jump = function()
      vim.diagnostic.open_float()
    end
  },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Template: TODO comment
vim.keymap.set('n', '<leader>tt', function()
  local user = os.getenv("USER") or "user"
  local date = os.date("%y%m%d")
  local comment = string.format("// TODO (%s) %s ", user, date)
  vim.api.nvim_put({comment}, 'c', true, true)
  vim.cmd('startinsert!')
end, { desc = '[T]emplate [T]odo comment' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ File / Buffer keymaps ]]
vim.keymap.set('n', '<leader>fn', function()
  local filename = vim.fn.input 'New file: '
  if filename ~= '' then vim.cmd('edit ' .. filename) end
end, { desc = '[F]ile [N]ew' })

vim.keymap.set('n', '<leader>fq', '<cmd>bdelete<cr>', { desc = '[F]ile [Q]uit buffer' })

-- Buffer operations
vim.keymap.set('n', '<leader>bn', '<cmd>bnext<cr>', { desc = '[B]uffer [N]ext' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprev<cr>', { desc = '[B]uffer [P]rev' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = '[B]uffer [D]elete' })

-- Buffer splits
vim.keymap.set('n', '<leader>bsh', '<cmd>split<cr>', { desc = '[B]uffer [S]plit [H]orizontal' })
vim.keymap.set('n', '<leader>bsv', '<cmd>vsplit<cr>', { desc = '[B]uffer [S]plit [V]ertical' })
vim.keymap.set('n', '<leader>bsc', '<C-w>q', { desc = '[B]uffer [S]plit [C]lose' })
vim.keymap.set('n', '<leader>bse', '<C-w>=', { desc = '[B]uffer [S]plit [E]qualize' })
vim.keymap.set('n', '<leader>bsH', '<C-w>H', { desc = '[B]uffer [S]plit move left' })
vim.keymap.set('n', '<leader>bsL', '<C-w>L', { desc = '[B]uffer [S]plit move right' })
vim.keymap.set('n', '<leader>bsJ', '<C-w>J', { desc = '[B]uffer [S]plit move down' })
vim.keymap.set('n', '<leader>bsK', '<C-w>K', { desc = '[B]uffer [S]plit move up' })

-- [[ Basic Autocommands ]]
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Soft wrap markdown at 70 columns
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.textwidth = 70
  end,
})

-- [[ Install lazy.nvim ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Plugins ]]
require('lazy').setup({
  { 'NMAC427/guess-indent.nvim', opts = {} },

  { -- Adds git related signs to the gutter
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  { -- Side-by-side diffs, file history, merge conflict resolution
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = '[G]it [D]iff view' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = '[G]it file [H]istory' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = '[G]it branch [H]istory' },
      { '<leader>gq', '<cmd>DiffviewClose<cr>', desc = '[G]it diff [Q]uit' },
    },
    opts = {},
  },

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },

      -- Document existing key chains
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
  },

  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    -- By default, Telescope is included and acts as your picker for everything.

    -- If you would like to switch to a different picker (like snacks, or fzf-lua)
    -- you can disable the Telescope plugin by setting enabled to false and enable
    -- your replacement picker by requiring it explicitly (e.g. 'custom.plugins.snacks')

    -- Note: If you customize your config for yourself,
    -- it’s best to remove the Telescope plugin config entirely
    -- instead of just disabling it here, to keep your config clean.
    enabled = true,
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function() return vim.fn.executable 'make' == 1 end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        defaults = {
          layout_strategy = 'vertical',
          layout_config = {
            vertical = {
              preview_height = 0.4,
            },
          },
          mappings = {
            i = {
              ['<C-CR>'] = function(prompt_bufnr)
                local action_state = require('telescope.actions.state')
                local actions = require('telescope.actions')
                local input = action_state.get_current_line()
                actions.close(prompt_bufnr)
                if input and input ~= '' then
                  vim.cmd('edit ' .. input)
                end
              end,
            },
          },
        },
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })
      vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind [K]eymaps' })
      vim.keymap.set('n', '<leader>ff', function() builtin.find_files { hidden = true } end, { desc = '[F]ind [F]iles' })
      vim.keymap.set('n', '<leader>fa', function()
        builtin.find_files {
          hidden = true,
          search_dirs = {
            '/home/USER/.kiro',
            '/home/USER/dotfiles',
            '/home/USER/Code',
            '/proj/lmr_usr/USER',
            '/repo/USER/rpcppg2/rpc/bb_ue',
            '/repo/USER/gojirago',
            '/repo/USER/flow',
          },
          file_ignore_patterns = { 'node_modules/', '%.git/' },
        }
      end, { desc = '[F]ind [A]ll (everywhere)' })
      vim.keymap.set('n', '<leader>fs', builtin.builtin, { desc = '[F]ind [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>fw', builtin.grep_string, { desc = '[F]ind current [W]ord' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind by [G]rep' })
      vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })
      vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
      vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader>fc', builtin.commands, { desc = '[F]ind [C]ommands' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf

          vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
          vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
          vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
          vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
          vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
        end,
      })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set(
        'n',
        '<leader>f/',
        function()
          builtin.live_grep {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          }
        end,
        { desc = '[F]ind [/] in Open Files' }
      )

      vim.keymap.set('n', '<leader>fn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[F]ind [N]eovim files' })

      -- Load possession extension if available
      pcall(require('telescope').load_extension, 'possession')
    end,
  },

  -- NvimTree
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = {
      view = {
        adaptive_size = true,
      }
    },
    keys = {
      { "<leader>ft", "<cmd>NvimTreeToggle<cr>", desc = "Toggle NvimTree" },
    }
  },

  -- Project management
  {
    'DrKJeff16/project.nvim',
    config = function()
      require('project').setup {
        detection_methods = { "pattern", "lsp" },
        patterns = { ".git", "Makefile", "CMakeLists.txt", "package.json", "go.mod", "Cargo.toml" },
        silent_chdir = true,
      }
      require('telescope').load_extension('projects')
      
      -- Project keymaps
      vim.keymap.set('n', '<leader>pf', '<cmd>Telescope projects<cr>', { desc = '[P]roject [F]ind' })
      vim.keymap.set('n', '<leader>pp', '<cmd>Telescope projects<cr>', { desc = '[P]roject [P]icker' })
    end
  },

  -- Resession session manager
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
      
      -- Create Telescope picker for sessions
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
      
      -- Make picker globally available
      _G.resession_picker = session_picker
      
      -- Auto-save on exit
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          local current = resession.get_current()
          if current then
            resession.save(current, { notify = false })
          end
        end,
      })
      
      -- Session keymaps
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

  -- Dashboard/Startup screen
  {
    'goolord/alpha-nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons', 'DrKJeff16/project.nvim' },
    config = function()
      local alpha = require('alpha')
      local dashboard = require('alpha.themes.dashboard')
      
      -- Helper to wrap text to max width
      local function wrap_text(text, max_width)
        local lines = {}
        local current_line = ""
        for word in text:gmatch("%S+") do
          if #current_line + #word + 1 <= max_width then
            current_line = current_line .. (current_line == "" and "" or " ") .. word
          else
            table.insert(lines, current_line)
            current_line = word
          end
        end
        if current_line ~= "" then
          table.insert(lines, current_line)
        end
        return lines
      end
      
      -- Friendly display names for sessions (raw name → display name)
      local session_display_names = {
        ['_repo_USER_rpcppg2_rpc_bb_ue'] = 'bb-ue',
        ['_home_USER_dotfiles'] = 'dotfiles',
        ['_home_USER_Code_vault'] = 'vault',
        ['_repo_USER_ran_sysdoc'] = 'ran-sysdoc',
        ['_repo_USER_tc-docs'] = 'tc-docs',
      }
      
      local function session_display(name)
        return session_display_names[name] or name:gsub('^_', ''):gsub('_', '/')
      end
      
      -- Function to build dashboard
      local function build_dashboard()
        local buttons = {}
        local resession = require('resession')
        local sessions = resession.list()
        
        -- Sort sessions by display name
        table.sort(sessions, function(a, b)
          return session_display(a) < session_display(b)
        end)
        
        -- Sessions as primary slots (1-5)
        for i = 1, 5 do
          if i <= #sessions then
            local name = sessions[i]
            local display = session_display(name)
            local load_cmd = string.format(":lua require('resession').load('%s', { notify = true })<CR>", name)
            local btn = dashboard.button(tostring(i), "  " .. display, load_cmd)
            btn.opts.hl = "Identifier"
            btn.opts.hl_shortcut = "Number"
            table.insert(buttons, btn)
          else
            local btn = dashboard.button(tostring(i), "  <empty>", ":lua _G.resession_picker()<CR>")
            btn.opts.hl = "Comment"
            btn.opts.hl_shortcut = "Number"
            table.insert(buttons, btn)
          end
        end
        
        -- Compact project list
        table.insert(buttons, dashboard.button("", ""))
        local project = require('project')
        local recent_projects = project.get_recent_projects(true) or {}
        table.sort(recent_projects, function(a, b)
          local pa = type(a) == 'table' and a.path or a
          local pb = type(b) == 'table' and b.path or b
          return vim.fn.fnamemodify(pa, ":t") < vim.fn.fnamemodify(pb, ":t")
        end)
        
        local project_keys = {"a", "b", "c"}
        for i = 1, 3 do
          if i <= #recent_projects then
            local entry = recent_projects[i]
            local path = type(entry) == 'table' and entry.path or entry
            local name = type(entry) == 'table' and entry.name or vim.fn.fnamemodify(path, ":t")
            local btn = dashboard.button(project_keys[i], "  " .. name, ":cd " .. path .. " | Telescope find_files<CR>")
            btn.opts.hl = "String"
            btn.opts.hl_shortcut = "Character"
            table.insert(buttons, btn)
          end
        end
        
        return buttons
      end
      
      -- Load random quote
      local quotes_file = vim.fn.stdpath('config') .. '/quotes.json'
      local quote_header = {}
      if vim.fn.filereadable(quotes_file) == 1 then
        local quotes = vim.fn.json_decode(vim.fn.readfile(quotes_file))
        if quotes and #quotes > 0 then
          math.randomseed(os.time())
          local quote = quotes[math.random(#quotes)]
          local wrapped_lines = { "" }
          vim.list_extend(wrapped_lines, wrap_text(quote[1], 60))
          vim.list_extend(wrapped_lines, wrap_text(quote[2], 60))
          table.insert(wrapped_lines, "")
          quote_header = {
            type = "text",
            val = wrapped_lines,
            opts = { position = "center", hl = "Comment" }
          }
        end
      end
      
      -- Add compact menu hint
      local hint = {
        type = "text",
        val = "s:Sessions  p:Projects  f:Files  r:Recent  c:Config  q:Quit",
        opts = { position = "center", hl = "Comment" }
      }
      
      -- Build initial dashboard
      dashboard.section.buttons.val = build_dashboard()
      
      -- Refresh dashboard on BufEnter to alpha
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          if vim.bo.filetype == "alpha" then
            dashboard.section.buttons.val = build_dashboard()
            require('alpha').redraw()
          end
        end
      })
      
      -- Set up keymaps for alpha buffer
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "alpha",
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          vim.keymap.set('n', 'p', '<cmd>Telescope projects<CR>', { buffer = buf, nowait = true })
          vim.keymap.set('n', 's', _G.resession_picker, { buffer = buf, nowait = true })
          vim.keymap.set('n', 'f', '<cmd>Telescope find_files<CR>', { buffer = buf, nowait = true })
          vim.keymap.set('n', 'r', '<cmd>Telescope oldfiles<CR>', { buffer = buf, nowait = true })
          vim.keymap.set('n', 'c', '<cmd>e $MYVIMRC<CR>', { buffer = buf, nowait = true })
          vim.keymap.set('n', 'q', '<cmd>qa<CR>', { buffer = buf, nowait = true })
        end
      })
      
      -- Add quote and hint as header if available
      if quote_header.val then
        dashboard.config.layout = {
          { type = "padding", val = 2 },
          dashboard.section.header,
          { type = "padding", val = 2 },
          quote_header,
          { type = "padding", val = 2 },
          dashboard.section.buttons,
          { type = "padding", val = 1 },
          hint,
          dashboard.section.footer,
        }
      else
        dashboard.config.layout = {
          { type = "padding", val = 2 },
          dashboard.section.header,
          { type = "padding", val = 2 },
          dashboard.section.buttons,
          { type = "padding", val = 1 },
          hint,
          dashboard.section.footer,
        }
      end
      
      alpha.setup(dashboard.config)

      -- Open alpha when nvim is started with a directory argument
      vim.api.nvim_create_autocmd('VimEnter', {
        callback = function()
          if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
            vim.cmd('bd')           -- close the empty directory buffer
            vim.cmd('cd ' .. vim.fn.argv(0))
            require('alpha').start()
          end
        end,
      })
    end
  },

  -- LSP Plugins
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      { 'mason-org/mason.nvim', opts = {} },
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by blink.cmp
      'saghen/blink.cmp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      local capabilities = require('blink.cmp').get_lsp_capabilities()
      local servers = {
        clangd = {
          cmd = {
            "clangd",
            "-j=10",
            "--background-index",
            "--clang-tidy",
            "--log=info",
          },
        },
        gopls = {},
        pyright = {},
        bashls = {},
      }

      -- Erlang LS not in Mason - configure separately if installed on system
      if vim.fn.executable('erlang_ls') == 1 then
        servers.erlangls = {}
      end

      -- Load work-specific overrides if available
      local ok, work = pcall(require, 'custom.work')
      if ok and work.servers then
        servers = vim.tbl_deep_extend('force', servers, work.servers)
      end

      -- Note: LSP names != Mason package names
      local ensure_installed = {
        'lua-language-server',
        'stylua',
        'gofumpt',
        'goimports',
        'black',
        'isort',
        'shfmt',
        'bash-language-server',
        'clangd',
        'gopls',
        'pyright',
      }

      require('mason-tool-installer').setup { 
        ensure_installed = ensure_installed,
        auto_update = false,
        run_on_start = true,
      }

      for name, server in pairs(servers) do
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end

      -- Special Lua Config, as recommended by neovim help docs
      vim.lsp.config('lua_ls', {
        on_init = function(client)
          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
          end

          client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
              version = 'LuaJIT',
              path = { 'lua/?.lua', 'lua/?/init.lua' },
            },
            workspace = {
              checkThirdParty = false,
              -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
              --  See https://github.com/neovim/nvim-lspconfig/issues/3189
              library = vim.api.nvim_get_runtime_file('', true),
            },
          })
        end,
        settings = {
          Lua = {},
        },
      })
      vim.lsp.enable 'lua_ls'
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function() require('conform').format { async = true, lsp_format = 'fallback' } end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable format_on_save for specific filetypes if needed
        local disable_filetypes = {}
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        cpp = { 'clang-format' },
        c = { 'clang-format' },
        go = { 'goimports', 'gofumpt' },
        python = { 'isort', 'black' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
      },
    },
  },

  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
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

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },

  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      require('catppuccin').setup {}
      vim.cmd.colorscheme 'catppuccin-mocha'
    end,
  },

  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  { -- Collection of various small independent plugins/modules
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end
    end,
  },

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      local filetypes = { 
        'bash', 'c', 'cpp', 'cmake', 'diff', 'erlang', 'go', 'html', 
        'lua', 'luadoc', 'make', 'markdown', 'markdown_inline', 
        'python', 'query', 'starlark', 'vim', 'vimdoc' 
      }
      
      -- Install parsers silently
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
  },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    opts = {},
  },

  { import = 'custom.plugins' },
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- Force redraw when regaining focus (fixes rendering in Zellij)
vim.api.nvim_create_autocmd('FocusGained', {
  callback = function()
    vim.cmd('mode')
  end,
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
