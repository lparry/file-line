if exists('g:loaded_file_line') | finish | endif
let g:loaded_file_line = 1

augroup file_line
  autocmd!
  autocmd! BufNewFile * nested call s:goto_file_line()
  autocmd! BufRead    * nested call s:goto_file_line()
augroup END

function! s:goto_file_line(...)
  let file_line_col = a:0 > 0 ? a:1 : bufname('%')

  if !filereadable(file_line_col)
    if filereadable("../" . file_line_col)
      let fname = "../" . file_line_col
      let bufnr = bufnr('%')
      exec 'keepalt edit ' . fnameescape(fname)
      exec 'bwipeout ' bufnr

      normal! zv
      normal! zz
      filetype detect
    endif
  endif

  if filereadable(file_line_col) || file_line_col ==# ''
    return file_line_col
  endif

  " Regex to match variants like these:
  " file(10), file(line:col), file:line:column:, file:line:column, file:line
  let matches =  matchlist(file_line_col,
        \ '\(.\{-1,}\)[(:]\(\d\+\)\%(:\(\d\+\):\?\)\?')
  if empty(matches) | return file_line_col | endif

  let fname = matches[1]
  let line  = matches[2] ==# '' ? '0' : matches[2]
  let col   = matches[3] ==# '' ? '0' : matches[3]

  if !filereadable(fname)
    if filereadable("../" . fname)
      let fname = "../" . fname
    endif
  endif

  if filereadable(fname)
    let bufnr = bufnr('%')
    exec 'keepalt edit ' . fnameescape(fname)
    exec 'bwipeout ' bufnr

    exec line
    exec 'normal! ' . col . '|'
    normal! zv
    normal! zz
    filetype detect
    call s:crosshair_flash(3)
  endif

  return fname
endfunction


" Flash crosshairs (reticle) on current cursor line/column to highlight it.
" Particularly useful when the cursor is at head/tail end of file,
" in which case it will not get centered.
" Ref1: https://vi.stackexchange.com/a/3481/29697
" Ref2: https://stackoverflow.com/a/33775128/38281
let g:file_line_crosshairs = get(g:, 'file_line_crosshairs', 1)
function! s:crosshair_flash(n) abort
  if g:file_line_crosshairs
    " Store settings
    let l:cul = &cul | let l:cuc = &cuc
    " Flash
    for i in range(1,a:n)
      set cul cuc | redraw | sleep 200m | set nocul nocuc | redraw | sleep 200m
    endfor
    " Restore settings
    let &cul=l:cul | let &cuc=l:cuc
  endif
endfunction
