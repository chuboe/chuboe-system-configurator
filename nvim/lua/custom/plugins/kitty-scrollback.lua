-- Kitty terminal scrollback integration
-- https://github.com/mikesmithgh/kitty-scrollback.nvim

vim.pack.add { 'https://github.com/mikesmithgh/kitty-scrollback.nvim' }

-- Only meaningful when running inside the kitty terminal; the plugin's own commands
-- (e.g. :KittyScrollbackGenerateKittens) and `:checkhealth` integration are a no-op
-- elsewhere.
require('kitty-scrollback').setup {
  paste_window = {
    -- Disable the vim yank-register bridge so kitty-scrollback doesn't shadow the
    -- normal kitty paste behavior.
    yank_register_enabled = false,
  },
  callbacks = {
    -- Mark the scrollback buffer as scratch (`buftype=nofile`) so :w never writes
    -- it to disk and :q doesn't complain about unsaved changes.
    after_ready = function(_, _)
      vim.api.nvim_set_option_value('buftype', 'nofile', { buf = 0 })
    end,
  },
}