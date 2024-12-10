function! ProvideSuggestions()
  let l:code_lines = getline(1, '$')
  let l:filetype = &filetype
  let l:suggestions = []

  " Detect language and apply corresponding rules
  if l:filetype ==# 'python'
    let l:suggestions = ProvidePythonSuggestions(l:code_lines)
  elseif l:filetype ==# 'c'
    let l:suggestions = ProvideCSuggestions(l:code_lines)
  elseif l:filetype ==# 'cpp'
    let l:suggestions = ProvideCppSuggestions(l:code_lines)
  elseif l:filetype ==# 'java'
    let l:suggestions = ProvideJavaSuggestions(l:code_lines)
  elseif l:filetype ==# 'cs'
    let l:suggestions = ProvideCSharpSuggestions(l:code_lines)
  else
    call add(l:suggestions, 'No rules available for filetype: ' . l:filetype)
  endif

  " Get the buffer number of Suggestions buffer
  let l:suggestions_bufnr = bufnr('Suggestions')
  if l:suggestions_bufnr == -1
    echom "Suggestions buffer not found. Please run :CodeAssistant to initialize."
    return
  endif

  " Update Suggestions buffer
  call setbufvar(l:suggestions_bufnr, '&modifiable', 1)
  call setbufline(l:suggestions_bufnr, 1, 'Suggestions')
  call deletebufline(l:suggestions_bufnr, 2, '$')
  if !empty(l:suggestions)
    call appendbufline(l:suggestions_bufnr, 1, l:suggestions)
  else
    call setbufline(l:suggestions_bufnr, 2, 'No suggestions. Your code looks good!')
  endif
  call setbufvar(l:suggestions_bufnr, '&modifiable', 0)
endfunction