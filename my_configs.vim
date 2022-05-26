"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Chuck's Mods 
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set foldmethod=marker
set clipboard=unnamed
nnoremap <leader>1  :tabnext<CR>
nnoremap <leader>2  <C-W><C-W>
nnoremap <leader>3  :bnext<CR>

" underline spelling issues
hi SpellBad cterm=underline

" prevent motion
let g:comfortable_motion_no_default_key_mappings = 1

" prevent golang error
let g:go_version_warning = 0

" """"""""""""""""""""""""""""""""
" things to remember
" """"""""""""""""""""""""""""""""
"
" Get rid of the scratch buffer with :bd!
"
" see all mappings
" https://stackoverflow.com/questions/27458206/is-there-a-way-to-see-all-vim-keybindings
" :map     -- shows all
" :map ,   -- shows all leader
" :verbose nmap   -- shows all mappins and where they are defined
"
" copy to clipboard
" "+yw - copy word
" "+yy - copy line
" 
" ctrl+r to paste from register in command
" "" is default register
" "+ is the system copy/paste register - only works if gvim is installed
" "a is a register 
" "b is a register 
" etc...
"
" ,q for new quick buffer
" :bd! to detele current buffer
"
" read in command output
" :r !<somecommand>
" example:
" :r !ls -la
"
" Execute a command and view results in a new split
" https://superuser.com/questions/868920/open-the-output-of-a-shell-command-in-a-split-pane
" :new | 0read ! <command>
"
