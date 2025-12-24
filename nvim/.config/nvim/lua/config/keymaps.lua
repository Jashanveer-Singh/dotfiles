-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "n", "v", "o" }, "E", "$", { desc = "End of line" })
vim.keymap.set("n", "<leader>ue", function()
  vim.g.cmp_disabled = not vim.g.cmp_disabled
  local msg = ""
  if vim.g.cmp_disabled == true then
    msg = "Autocompletion (cmp) disabled"
  else
    msg = "Autocompletion (cmp) enabled"
  end
  vim.notify(msg, vim.log.levels.INFO)
end, { desc = "toggle autocompletion" })
