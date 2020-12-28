" ignore files vim doesnt use
set wildignore+=.git,.hg,.svn
set wildignore+=*.aux,*.out,*.toc
set wildignore+=*.o,*.obj,*.exe,*.dll,*.manifest,*.rbc,*.class
set wildignore+=*.ai,*.bmp,*.gif,*.ico,*.jpg,*.jpeg,*.png,*.psd,*.webp
set wildignore+=*.avi,*.divx,*.mp4,*.webm,*.mov,*.m2ts,*.mkv,*.vob,*.mpg,*.mpeg
set wildignore+=*.mp3,*.oga,*.ogg,*.wav,*.flac
set wildignore+=*.eot,*.otf,*.ttf,*.woff
set wildignore+=*.doc,*.pdf,*.cbr,*.cbz
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz,*.kgb
set wildignore+=*.swp,.lock,.DS_Store,._*

" persistent undo
if has('persistent_undo')
  set undofile
  set undodir=$HOME/.vim/undo
endif

" case insensitive search
set ignorecase
set smartcase
set infercase

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

let g:vim_markdown_folding_disabled=1 " Markdown
let javaScript_fold=1                 " JavaScript
let perl_fold=1                       " Perl
let php_folding=1                     " PHP
let r_syntax_folding=1                " R
let ruby_fold=1                       " Ruby
let sh_fold_enabled=1                 " sh
let vimsyn_folding='af'               " Vim script
let xml_syntax_folding=1              " XML
let fortran_free_source=1             " Fortran
let fortran_have_tabs=1
let fortran_more_precise=1
let fortran_do_enddo=1

syntax on

" Encoding
" Stick with the UTF-8 encoding.
if has('multi_byte')
  " Encoding used for the terminal.
  if empty(&termencoding)
    let &termencoding = &encoding
  endif

  " Encoding used in buffers, registers, strings in expressions, "viminfo"
  " file, etc.
  set encoding=utf-8

  " Encoding used for writing files.
  setglobal fileencoding=utf-8
endif

" Use both Unix and DOS file formats, but favor the Unix one for new files.
set fileformats=unix,dos

" remove trailing whitespaces and ^M chars
augroup ws
  au!
  autocmd FileType c,cpp,java,php,js,json,css,scss,sass,py,rb,coffee,python,twig,xml,yml autocmd BufWritePre <buffer> :call setline(1,map(getline(1,"$"),'substitute(v:val,"\\s\\+$","","")'))
augroup end
