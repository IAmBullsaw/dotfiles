return {
  'goolord/alpha-nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons', 'DrKJeff16/project.nvim' },
  config = function()
    local alpha = require('alpha')
    local dashboard = require('alpha.themes.dashboard')

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

    local ok, work = pcall(require, 'work')
    local session_display_names = ok and work.session_display_names or {}

    local function session_display(name)
      return session_display_names[name] or name:gsub('^_', ''):gsub('_', '/')
    end

    local function build_dashboard()
      local buttons = {}
      local resession = require('resession')
      local sessions = resession.list()

      table.sort(sessions, function(a, b)
        return session_display(a) < session_display(b)
      end)

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

    local hint = {
      type = "text",
      val = "s:Sessions  p:Projects  f:Files  r:Recent  c:Config  q:Quit",
      opts = { position = "center", hl = "Comment" }
    }

    dashboard.section.buttons.val = build_dashboard()

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*",
      callback = function()
        if vim.bo.filetype == "alpha" then
          dashboard.section.buttons.val = build_dashboard()
          require('alpha').redraw()
        end
      end
    })

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

    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
          vim.cmd('bd')
          vim.cmd('cd ' .. vim.fn.argv(0))
          require('alpha').start()
        end
      end,
    })
  end
}
