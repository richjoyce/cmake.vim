" File:             autoload/ctags.vim
" Description:      Options to use ctags with CMake.
" Author:           Jacky Alciné <me@jalcine.me>
" License:          MIT
" Website:          https://jalcine.github.io/cmake.vim
" Version:          0.4.0

func! cmake#ctags#invoke(args)
  let command = g:cmake_ctags.executable . " " . a:args
  call cmake#util#shell_bgexec(l:command)
endfunc

func! cmake#ctags#cache_directory()
  let l:dir = fnamemodify(cmake#util#binary_dir() . 'tags', ':p')
  if !isdirectory(l:dir) | call mkdir(l:dir) | endif
  return l:dir
endfunc

func! cmake#ctags#filename(target)
  return simplify(cmake#ctags#cache_directory() . '/' .  a:target . '.tags')
endfunc

func! cmake#ctags#generate_for_target(target)
  let l:tag_file = cmake#ctags#filename(a:target)
  let l:files = cmake#targets#files(a:target)
  let l:args = '--append --excmd=mixed --extra=+fq --totals=no --file ' . l:tag_file

  if type(l:files) != type([])
    return
  endif

  for file in files
    let l:command = l:args . ' ' . l:file
    call cmake#ctags#invoke(l:command)
  endfor

  let g:cmake_cache.targets[a:target].tags_file = l:tag_file
endfunc

func! cmake#ctags#refresh()
  " TODO: Add the ctags for this target.
  let l:cache_dir = cmake#ctags#cache_directory()
  let l:tag_file = cmake#ctags#filename(b:cmake_target)
  let l:paths = split(&tags, ',')
  call filter(l:paths, 'strridx(v:val, l:cache_dir,0) == -1')
  if !filereadable(l:tag_file)
    call cmake#ctags#generate_for_target(b:cmake_target)
  endif
  let l:paths += [ l:tag_file ]
  let tags = join(l:paths, ',')
endfunc
