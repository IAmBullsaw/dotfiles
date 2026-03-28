-- Work-specific neovim overrides
-- This file is loaded by init.lua via pcall. Safe to delete on non-work machines.

local M = {}

-- Clangd with work toolchain paths
M.servers = {
  clangd = {
    cmd = {
      "/app/vbuild/RHEL8-x86_64/clang/16.0.3/bin/clangd",
      "-j=10",
      "--background-index",
      "--clang-tidy",
      "--log=info",
      "--query-driver=/proj/rbsNodeIfStorage/nodeif/**/x86_64-wrs-linux-g*",
    },
  },
}

-- Custom filetypes for work codebase
vim.filetype.add({
  extension = {
    ifx = "cpp",
    sig = "cpp",
  },
})

-- PlantUML needs higher maxmempattern for syntax highlighting
vim.opt.maxmempattern = 10000

return M
