--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>fh" to [f]ind the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Set font (for GUI clients like Neovide)
vim.o.guifont = 'FiraCode Nerd Font:h12'

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-guide-options`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Custom filetype mappings
vim.filetype.add({
  extension = {
    ifx = "cpp",
    sig = "cpp",
  },
})

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic Config & Keymaps
-- See :help vim.diagnostic.Opts
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },

  -- Can switch between these as you prefer
  virtual_text = true, -- Text shows up at the end of the line
  virtual_lines = false, -- Teest shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = { 
    on_jump = function()
      vim.diagnostic.open_float()
    end
  },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Template: TODO comment
vim.keymap.set('n', '<leader>tt', function()
  local user = os.getenv("USER") or "user"
  local date = os.date("%y%m%d")
  local comment = string.format("// TODO (%s) %s ", user, date)
  vim.api.nvim_put({comment}, 'c', true, true)
  vim.cmd('startinsert!')
end, { desc = '[T]emplate [T]odo comment' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

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

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  -- NOTE: Plugins can be added via a link or github org/name. To run setup automatically, use `opts = {}`
  { 'NMAC427/guess-indent.nvim', opts = {} },

  -- Alternatively, use `config = function() ... end` for full control over the configuration.
  -- If you prefer to call `setup` explicitly, use:
  --    {
  --        'lewis6991/gitsigns.nvim',
  --        config = function()
  --            require('gitsigns').setup({
  --                -- Your gitsigns configuration here
  --            })
  --        end,
  --    }
  --
  -- Here is a more advanced example where we pass configuration
  -- options to `gitsigns.nvim`.
  --
  -- See `:help gitsigns` to understand what the configuration keys do
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
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

  -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
  --
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `opts` key (recommended), the configuration runs
  -- after the plugin has been loaded as `require(MODULE).setup(opts)`.

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
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function() return vim.fn.executable 'make' == 1 end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        -- pickers = {}
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
      vim.keymap.set('n', '<leader>fs', builtin.builtin, { desc = '[F]ind [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>fw', builtin.grep_string, { desc = '[F]ind current [W]ord' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind by [G]rep' })
      vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })
      vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
      vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader>fc', builtin.commands, { desc = '[F]ind [C]ommands' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- This runs on LSP attach per buffer (see main LSP attach function in 'neovim/nvim-lspconfig' config for more info,
      -- it is better explained there). This allows easily switching between pickers if you prefer using something else!
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf

          -- Find references for the word under your cursor.
          vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

          -- Jump to the implementation of the word under your cursor.
          -- Useful when your language has ways of declaring types without an actual implementation.
          vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

          -- Jump to the definition of the word under your cursor.
          -- This is where a variable was first declared, or where a function is defined, etc.
          -- To jump back, press <C-t>.
          vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

          -- Fuzzy find all the symbols in your current document.
          -- Symbols are things like variables, functions, types, etc.
          vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

          -- Fuzzy find all the symbols in your current workspace.
          -- Similar to document symbols, except searches over your entire project.
          vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

          -- Jump to the type of the word under your cursor.
          -- Useful when you're not sure what type a variable is and you want to see
          -- the definition of its *type*, not where it was *defined*.
          vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
        end,
      })

      -- Override default behavior and theme when searching
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
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

      -- Shortcut for searching your Neovim configuration files
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
      
      -- Function to build dashboard
      local function build_dashboard()
        local buttons = {}
        local project = require('project')
        local recent_projects = project.get_recent_projects() or {}
        
        -- Get resession sessions
        local resession = require('resession')
        local sessions = resession.list()
        
        -- Convert to table format
        local session_list = {}
        for _, name in ipairs(sessions) do
          table.insert(session_list, { name = name })
        end
        sessions = session_list
        
        -- Sort projects by name
        
        -- Sort projects by name
        table.sort(recent_projects, function(a, b)
          return vim.fn.fnamemodify(a, ":t") < vim.fn.fnamemodify(b, ":t")
        end)
        
        -- Add project slots (always 5)
        for i = 1, 5 do
          if i <= #recent_projects then
            local proj = recent_projects[i]
            local name = vim.fn.fnamemodify(proj, ":t")
            local btn = dashboard.button(tostring(i), "  " .. name, ":cd " .. proj .. " | Telescope find_files<CR>")
            btn.opts.hl = "String"
            btn.opts.hl_shortcut = "Number"
            table.insert(buttons, btn)
          else
            local btn = dashboard.button(tostring(i), "  <empty>", ":Telescope projects<CR>")
            btn.opts.hl = "Comment"
            btn.opts.hl_shortcut = "Number"
            table.insert(buttons, btn)
          end
        end
        table.insert(buttons, dashboard.button("", ""))
        
        -- Sort sessions alphabetically
        table.sort(sessions, function(a, b)
          return a.name < b.name
        end)
        
        -- Add session slots (always 5)
        local session_keys = {"a", "b", "c", "d", "e"}
        
        for i = 1, 5 do
          if i <= #sessions then
            local session = sessions[i]
            local session_name = session.name
            local load_cmd = string.format(":lua require('resession').load('%s', { notify = true })<CR>", session_name)
            local btn = dashboard.button(session_keys[i], "  " .. session_name, load_cmd)
            btn.opts.hl = "Identifier"
            btn.opts.hl_shortcut = "Character"
            table.insert(buttons, btn)
          else
            local btn = dashboard.button(session_keys[i], "  <empty>", ":lua _G.resession_picker()<CR>")
            btn.opts.hl = "Comment"
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
        val = "p:Projects  s:Sessions  f:Files  r:Recent  c:Config  q:Quit",
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
      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
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

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --  See `:help lsp-config` for information about keys and how to configure
      local servers = {
        clangd = {
          root_dir = function() return vim.loop.cwd() end,
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

      -- Ensure the servers and tools above are installed
      --
      -- To check the current status of installed tools and/or manually install
      -- other tools, you can run
      --    :Mason
      --
      -- You can press `g?` for help in this menu.
      
      -- Note: LSP names != Mason package names, so we manually specify Mason packages
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
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        opts = {},
      },
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        --   <c-y> to accept ([y]es) the completion.
        --    This will auto-import if your LSP supports it.
        --    This will expand snippets if the LSP sent a snippet.
        -- 'super-tab' for tab to accept
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- For an understanding of why the 'default' preset is recommended,
        -- you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        --
        -- All presets have the following mappings:
        -- <tab>/<s-tab>: move to right/left of your snippet expansion
        -- <c-space>: Open menu or open docs if already open
        -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
        -- <c-e>: Hide menu
        -- <c-k>: Toggle signature help
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        preset = 'default',

        -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
        --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets' },
      },

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See :h blink-cmp-config-fuzzy for more information
      fuzzy = { implementation = 'lua' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },

  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
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
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end

      -- ... and there is more!
      --  Check out: https://github.com/nvim-mini/mini.nvim
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

  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  -- require 'kickstart.plugins.autopairs',
  -- require 'kickstart.plugins.neo-tree',
  -- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    opts = {},
  },

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  -- { import = 'custom.plugins' },
  --
  -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
  -- Or use telescope!
  -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
  -- you can continue same window with `<space>sr` which resumes last telescope search
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
