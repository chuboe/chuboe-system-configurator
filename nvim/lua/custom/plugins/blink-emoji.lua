-- GitHub-style emoji completion for blink.cmp
-- https://github.com/moyiz/blink-emoji.nvim

vim.pack.add { 'https://github.com/moyiz/blink-emoji.nvim' }

-- blink-emoji.nvim registers itself as a blink.cmp source automatically on load,
-- so no explicit `setup()` call is needed. Just opening nvim is enough to wire it
-- up alongside the blink.cmp install handled in the main init.lua.