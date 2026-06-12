return {
  "nvim-tree/nvim-tree.lua",
  cmd = { "NvimTreeToggle", "NvimTreeFocus" },
  opts = {
    view = { adaptive_size = true },
  },
  keys = {
    { "<leader>ft", "<cmd>NvimTreeToggle<cr>", desc = "Toggle NvimTree" },
  },
}
