" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

nmap <F8> :TagbarToggle<CR>

command J :call JSONify()

nnoremap ni :call GoToNextIndent(1)<CR>
nnoremap pi :call GoToNextIndent(-1)<CR>
