" Show line numbers
set number
" Show statusline
set laststatus=2

" Case-insensitive search
set ignorecase

" Highlight search results
set hlsearch

" Default to soft tabs, 2 spaces
set expandtab
set sw=2
set sts=2
" Except for Makefiles: Hard tabs of width 2
autocmd FileType make set ts=2
" And Markdown
autocmd FileType mkd set sw=4
autocmd FileType mkd set sts=4
autocmd BufRead,BufNewFile *.md set filetype=markdown
autocmd BufRead,BufNewFile *.cql set filetype=cql
" And Java
autocmd FileType java set sw=2

" Default to Unix LF line endings
set ffs=unix

" Folding
set foldmethod=syntax
set foldcolumn=1
set foldlevelstart=20

let g:vim_markdown_folding_disabled=1 " Markdown
let javaScript_fold=1                 " JavaScript
let perl_fold=1                       " Perl
let php_folding=1                     " PHP
let r_syntax_folding=1                " R
let ruby_fold=1                       " Ruby
let sh_fold_enabled=1                 " sh
let vimsyn_folding='af'               " Vim script
let xml_syntax_folding=1              " XML
let fortran_free_source=1
let fortran_have_tabs=1
let fortran_more_precise=1
let fortran_do_enddo=1

" Solarized Syntax
syntax enable
set background=dark
colorscheme solarized
if has('gui_running')
    set background=light
else
    set background=dark
endif

" Encoding
set encoding=utf8
" Font
set guifont=DroidSansMonoForPowerline\ Nerd\ Font:h11

" Keybinds
map <C-n> :NERDTreeToggle<CR>
if filereadable(expand("~/.vimrc_background"))
  let base16colorspace=256
  source ~/.vimrc_background
endif
" Terminal 256 
set t_Co=256
hi Normal guibg=NONE ctermbg=NONE
