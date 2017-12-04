function! JSONify()
  %!python -mjson.tool
  set syntax=json
endfunction
command J :call JSONify()