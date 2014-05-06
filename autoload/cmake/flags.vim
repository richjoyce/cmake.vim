" File:             autoload/cmake/flags.vim
" Description:      Handles the act of injecting flags into Vim.
" Author:           Jacky Alciné <me@jalcine.me>
" License:          MIT
" Website:          https://jalcine.github.io/cmake.vim
" Version:          0.4.0

function! s:sort_out_flags(val)
  let l:good_flags = ['-i', '-I', '-W', '-f']
  for a_good_flag in l:good_flags
  if stridx(a:val, a_good_flag, 0) == 0
    return 1
  endif

  return 0
endfunction

function! cmake#flags#filter(flags)
  let l:flags = []
  if g:cmake_filter_flags == 1
    let l:flags = copy(a:flags)
    if !empty(l:flags)
      call filter(flags, "s:sort_out_flags(v:val) != 1")
    endif
  endif

  return l:flags
endfunction!

function! cmake#flags#inject()
  if !exists('b:cmake_target')
    let b:cmake_target = cmake#targets#for_file(expand('%'))
    if b:cmake_target == 0
      return
    else
      let target = b:cmake_target
    endif
  endif

  if !exists('b:cmake_flags')
    let b:cmake_flags = cmake#targets#flags(b:cmake_target)[&ft]
    " Do what is right.
    call cmake#flags#inject_to_ycm(b:cmake_target)
    call cmake#flags#inject_to_syntastic(b:cmake_target)
  endif
endfunc

function! cmake#flags#inject_to_syntastic(target)
  if g:cmake_inject_flags.syntastic != 1 | return | endif

  let l:flags = cmake#targets#flags(a:target)
  for l:language in keys(l:flags)
    let {'g:syntastic_' .l:language . '_compiler_options'} = join(l:flags[l:language], ' ')
  endfor
endfunction!

function! cmake#flags#inject_to_ycm(target)
  if g:cmake_inject_flags.ycm != 0
    call cmake#flags#prep_ycm()
  endif
endfunc

function! cmake#flags#collect(flags_file, prefix)
  let l:flags = split(system("grep '" . a:prefix . "_FLAGS = ' " . a:flags_file .
    \ ' | cut -b ' . (strlen(a:prefix) + strlen('_FLAGS = ')) . '-'))
  let l:flags = cmake#flags#filter(l:flags)

  let l:defines = split(system("grep '" . a:prefix . "_DEFINES = ' " . a:flags_file
    \ . ' | cut -b ' . (strlen(a:prefix) + strlen('_DEFINES = ')) . '-'))

  let l:params = l:flags + l:defines
  return l:params
endfunction!

function! cmake#flags#prep_ycm()
  if g:cmake_inject_flags.ycm == 0
    return 0
  endif

  let l:flags_to_inject = ['b:cmake_binary_dir', 'b:cmake_root_binary_dir',
        \ 'b:cmake_flags']

  for flags in l:flags_to_inject
    if index(g:ycm_extra_conf_vim_data, flag) == -1 && exists(flag)
      let g:ycm_extra_conf_vim_data += [flag]
    endif
  endfor
endfunction!
