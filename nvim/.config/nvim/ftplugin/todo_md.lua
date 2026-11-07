-- ftplugin for TODO.md
-- Features: checkbox management, subtask indentation, Done section, tag highlighting

local buf = vim.api.nvim_get_current_buf()

-- ── Highlighting ─────────────────────────────────────────────────────────────
vim.cmd [[
  syntax match TodoTag /\<[A-Z][A-Z_]\+\>/ containedin=ALL
  syntax match TodoDeepIndent /^\s\{4,\}- \[.\].*/ containedin=ALL
  highlight default link TodoTag Keyword
  highlight default TodoDeepIndent guifg=#ff5555
]]

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function get_lines() return vim.api.nvim_buf_get_lines(buf, 0, -1, false) end
local function set_lines(l) vim.api.nvim_buf_set_lines(buf, 0, -1, false, l) end
local function uncheck(l) return l:gsub('%- %[x%]', '- [ ]'):gsub('%- %[X%]', '- [ ]') end
local function check(l)   return l:gsub('%- %[.%]', '- [x]') end
local function is_task(l) return l:match('^%s*%- %[.%]') ~= nil end
local function is_checked(l) return l:match('^%s*%- %[[xX]%]') ~= nil end
local function indent_level(l) return math.floor(#(l:match('^( *)') or '') / 2) end

-- Find "# Done" header index (1-based) or nil
local function find_done(lines)
  for i, l in ipairs(lines) do if l:match('^# Done') then return i end end
end

-- Find the top-level parent task of row (searching upward), returns row index or nil
local function find_parent(lines, row)
  for i = row - 1, 1, -1 do
    if is_task(lines[i]) and indent_level(lines[i]) == 0 then return i end
    if lines[i]:match('^# ') then return nil end
  end
end

-- Collect block starting at `start`: task line + following subtasks/blanks
-- Stops before next top-level task or section header. Returns block, end_row.
local function collect_block(lines, start)
  local block = { lines[start] }
  local i = start + 1
  while i <= #lines do
    local l = lines[i]
    if l:match('^# ') or (is_task(l) and indent_level(l) == 0) then break end
    table.insert(block, l)
    i = i + 1
  end
  return block, i - 1
end

-- Find mirror of a top-level task text inside Done section.
-- Returns the row index of the mirror header, or nil.
local function find_mirror(lines, parent_line, done_i)
  if not done_i then return nil end
  local bare = parent_line:gsub('%- %[.%]', '- [ ]')  -- compare ignoring check state
  for i = done_i + 1, #lines do
    local l = lines[i]
    if is_task(l) and indent_level(l) == 0 then
      if l:gsub('%- %[.%]', '- [ ]') == bare then return i end
    end
  end
end

-- Remove mirror block from Done if it has no subtasks (only blank lines left)
local function cleanup_mirror(lines, mirror_row)
  local _, block_end = collect_block(lines, mirror_row)
  -- Check if any subtask remains in block
  for i = mirror_row + 1, block_end do
    if is_task(lines[i]) then return end  -- still has subtasks, keep
  end
  -- Remove the whole mirror block
  for _ = mirror_row, block_end do table.remove(lines, mirror_row) end
  -- Remove trailing blank line before next entry if any
  if mirror_row <= #lines and lines[mirror_row] == '' then
    table.remove(lines, mirror_row)
  end
end

-- ── Enter key: auto-insert checkbox prefix ───────────────────────────────────

local function on_enter()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
  local prefix = line:match('^  %- %[') and '  - [ ] '
              or line:match('^%- %[')   and '- [ ] '
              or nil
  if prefix then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n', false)
    vim.schedule(function()
      local r = vim.api.nvim_win_get_cursor(0)[1]
      local cur = vim.api.nvim_buf_get_lines(buf, r - 1, r, false)[1]
      vim.api.nvim_buf_set_lines(buf, r - 1, r, false, { prefix .. cur:gsub('^%s*', '') })
      vim.api.nvim_win_set_cursor(0, { r, #prefix })
    end)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n', false)
  end
end

-- ── Toggle ────────────────────────────────────────────────────────────────────

local function toggle_checkbox()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = get_lines()
  local line = lines[row]
  if not is_task(line) then return end

  local done_i = find_done(lines)
  local in_done = done_i ~= nil and row > done_i
  local level = indent_level(line)

  -- ── Top-level task ──
  if level == 0 then
    if in_done then
      -- Move whole block back above Done, uncheck parent
      lines[row] = uncheck(lines[row])
      local block, block_end = collect_block(lines, row)
      block[1] = lines[row]
      for _ = row, block_end do table.remove(lines, row) end
      local di = find_done(lines)
      local insert_at = di and di - 1 or #lines
      for j = #block, 1, -1 do table.insert(lines, insert_at, block[j]) end
      set_lines(lines)
      vim.api.nvim_win_set_cursor(0, { insert_at, 0 })
    else
      -- Move whole block to Done, check parent
      lines[row] = check(lines[row])
      local block, block_end = collect_block(lines, row)
      block[1] = lines[row]
      for _ = row, block_end do table.remove(lines, row) end
      local di = find_done(lines)
      if not di then
        table.insert(lines, '') ; table.insert(lines, '# Done')
        di = #lines
      end
      for j = #block, 1, -1 do table.insert(lines, di + 1, block[j]) end
      set_lines(lines)
      vim.api.nvim_win_set_cursor(0, { di + 1, 0 })
    end
    return
  end

  -- ── Subtask ──
  if in_done then
    -- Find mirror header first (before any removal) to identify the parent
    local di = find_done(lines)
    local mirror_row = nil
    for i = row - 1, (di or 0) + 1, -1 do
      if is_task(lines[i]) and indent_level(lines[i]) == 0 then
        mirror_row = i ; break
      end
    end
    local mirror_text = mirror_row and lines[mirror_row]:gsub('%- %[.%]', '- [ ]')

    -- Remove and uncheck the subtask
    lines[row] = uncheck(lines[row])
    local subtask = table.remove(lines, row)

    -- Clean up mirror if now empty (subtask removed, mirror_row index unchanged since row > mirror_row)
    if mirror_row then cleanup_mirror(lines, mirror_row) end

    -- Find parent above Done by matching mirror text
    local parent_row = nil
    if mirror_text then
      local di2 = find_done(lines)
      local search_end = di2 and di2 - 1 or #lines
      for i = 1, search_end do
        if is_task(lines[i]) and indent_level(lines[i]) == 0
          and lines[i]:gsub('%- %[.%]', '- [ ]') == mirror_text then
          parent_row = i ; break
        end
      end
    end

    if parent_row then
      local _, pblock_end = collect_block(lines, parent_row)
      table.insert(lines, pblock_end + 1, subtask)
      set_lines(lines)
      vim.api.nvim_win_set_cursor(0, { pblock_end + 1, 0 })
    else
      local insert_at = (find_done(lines) or #lines + 1) - 1
      table.insert(lines, insert_at, subtask)
      set_lines(lines)
      vim.api.nvim_win_set_cursor(0, { insert_at, 0 })
    end
  else
    -- Complete subtask: check it, mirror parent into Done, add subtask there
    lines[row] = check(lines[row])
    local subtask_done = lines[row]
    local parent_row = find_parent(lines, row)
    if not parent_row then
      vim.notify('todo: no parent found for subtask at row ' .. row, vim.log.levels.WARN)
      set_lines(lines) ; return
    end
    local parent_line = lines[parent_row]

    -- Remove subtask from current position
    table.remove(lines, row)

    -- Recompute done_i after removal (row may have been before it)
    local di = find_done(lines)
    if not di then
      table.insert(lines, '') ; table.insert(lines, '# Done')
      di = #lines
    end

    -- Find or create mirror of parent in Done
    local mirror_row = find_mirror(lines, parent_line, di)
    if not mirror_row then
      table.insert(lines, di + 1, parent_line)
      mirror_row = di + 1
    end

    -- Insert subtask after last subtask of mirror block
    local _, mblock_end = collect_block(lines, mirror_row)
    table.insert(lines, mblock_end + 1, subtask_done)
    set_lines(lines)
    vim.api.nvim_win_set_cursor(0, { mblock_end + 1, 0 })
  end
end

-- ── Keymaps ───────────────────────────────────────────────────────────────────

local opts = { buffer = buf, silent = true }
vim.keymap.set('n', '<leader>x', toggle_checkbox, vim.tbl_extend('force', opts, { desc = 'Toggle TODO checkbox' }))
vim.keymap.set('i', '<CR>', on_enter, opts)

-- ── Options ───────────────────────────────────────────────────────────────────
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.autoindent = true
