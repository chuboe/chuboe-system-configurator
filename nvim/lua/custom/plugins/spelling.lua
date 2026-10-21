-- Spelling: <leader>z for the menu, and spell-on by default for markdown.
--
-- Why this file lives here instead of in init.lua: init.lua is tracked
-- upstream and gets reset to upstream/master whenever the config is
-- refreshed. Personalizations live in this repo under nvim/, and
-- install-kickstart.sh copies them into the config's lua/custom/plugins/,
-- where kickstart's own loader picks them up.
--
-- Editing it here does nothing on its own -- re-run install-kickstart.sh
-- after any change.
--
-- Restore of two things lost in the kickstart rewrite:
--   1. <leader>z -> `z=`  (Neovim's built-in spelling correction menu).
--   2. 'spell' on by default for markdown.

-- 1. <leader>z opens the spelling correction menu.
--    Stock Neovim already binds `z=` in normal mode; mapping it under
--    <leader> makes it discoverable through which-key without conflicting
--    with the `z`-family keys (`zg`, `zw`, `]s`, `[s`, `:set spell`).
vim.keymap.set('n', '<leader>z', 'z=', { desc = '[Spelling] suggestions for word under cursor' })

-- 2. Turn spelling on for markdown by default.
--    `gitcommit` shares the spell-friendliness (commit messages are prose),
--    so we match it in the same autocmd. Other filetypes are left alone so
--    spell stays out of the way in code.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom-spell-on-markdown', { clear = true }),
  pattern = { 'markdown', 'gitcommit' },
  callback = function() vim.opt_local.spell = true end,
})
