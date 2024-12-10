" rules.vim - Language-Specific Rules

function! ProvidePythonSuggestions(code_lines)
  let l:suggestions = []

  " Rule 1: Indentation - Check for incorrect indentation (not multiples of 4 spaces)
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '^\s\+'
      let indent = matchstr(line, '^\s\+')
      let spaces = substitute(indent, '\t', '    ', 'g')
      if (len(spaces) % 4) != 0
        call add(l:suggestions, 'Line ' . (idx+1) . ': Indentation should be a multiple of 4 spaces.')
      endif
    endif
  endfor

  " Rule 2: Maximum line length - Check for lines longer than 79 characters
  for idx in range(len(a:code_lines))
    if strdisplaywidth(a:code_lines[idx]) > 79
      call add(l:suggestions, 'Line ' . (idx+1) . ': Line exceeds 79 characters.')
    endif
  endfor

  " Rule 3: Check for unused imports
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '^\s*import ' && getline(idx+1, '$') !~ line[7:]
      call add(l:suggestions, 'Line ' . (idx+1) . ': Imported module "' . line[7:] . '" is not used.')
    endif
  endfor

  " Rule 4: Check for missing docstrings in functions and classes
  let in_def = 0
  let def_line = 0
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '^\s*\(def\|class\)\s\+\k\+'
      let in_def = 1
      let def_line = idx
    elseif in_def
      let stripped_line = substitute(line, '^\s\+', '', '')
      if stripped_line !~ '^"""'
        call add(l:suggestions, 'Line ' . (def_line+1) . ': Missing docstring in function or class definition.')
      endif
      let in_def = 0
    endif
  endfor

  " Rule 5: Check for wildcard imports
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '^\s*from\s+\k\+\s+import\s+\*'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Avoid wildcard imports. Use explicit imports.')
    endif
  endfor

  " Rule 6: Check for bare `except` clauses
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '^\s*except\s*:$'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Avoid using bare except. Specify the exception type.')
    endif
  endfor

  " Rule 7: Check for mutable default arguments in functions
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '^\s*def\s\+\k\+.*\(.*=.*\[\|\{.*\)\):'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Avoid using mutable default arguments in function definitions.')
    endif
  endfor

  " Rule 8: Check for print statements in production code
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '^\s*print\s*\('
      call add(l:suggestions, 'Line ' . (idx+1) . ': Remove print statements from production code.')
    endif
  endfor

  " Rule 9: Ensure main guard exists
  if join(a:code_lines, "\n") !~ 'if __name__ == "__main__":'
    call add(l:suggestions, 'Add "if __name__ == \"__main__\":" guard for script execution.')
  endif

  return l:suggestions
endfunction


function! ProvideCSuggestions(code_lines)
  let l:suggestions = []

  " Rule 1: Check for missing braces
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '\b(if|for|while|else)\b' && line !~ '{'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Missing opening brace for control structure.')
    endif
  endfor

  " Rule 2: Check for semicolons at the end of statements
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '[^{};]\s*$' && line !~ '^\s*(#|//)'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Missing semicolon at the end of the statement.')
    endif
  endfor

  " Rule 3: Avoid using magic numbers
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '\d+' && line !~ '#define'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Avoid using magic numbers. Use named constants.')
    endif
  endfor

  " Rule 4: Check for null pointer dereference
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '\*\s*\w+\s*=' && getline(idx-1, idx+1) !~ '!= NULL'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Possible null pointer dereference.')
    endif
  endfor

  return l:suggestions
endfunction


function! ProvideCppSuggestions(code_lines)
  let l:suggestions = ProvideCSuggestions(a:code_lines)

  " Rule 1: Check for `std::` namespace usage
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '\bcout\b' && line !~ 'std::'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Use `std::cout` explicitly.')
    endif
  endfor

  " Rule 2: Check for use of smart pointers
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '\b(new|delete)\b' && line !~ '<memory>'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Prefer smart pointers (e.g., std::shared_ptr, std::unique_ptr) over raw pointers.')
    endif
  endfor

  return l:suggestions
endfunction


function! ProvideJavaSuggestions(code_lines)
  let l:suggestions = []

  " Rule 1: Check for missing semicolons
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '[^;]\s*$' && line !~ '^\s*(//|/\*|\*)'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Missing semicolon at the end of the statement.')
    endif
  endfor

  " Rule 2: Check for missing access modifiers
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ 'class\s+\w+' && line !~ '\b(public|protected|private)\b'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Classes should explicitly define access modifiers.')
    endif
  endfor

  return l:suggestions
endfunction


function! ProvideCSharpSuggestions(code_lines)
  let l:suggestions = []

  " Rule 1: Check for `using` directive
  let has_using_directive = 0
  for line in a:code_lines
    if line =~ '^\s*using\s'
      let has_using_directive = 1
    endif
  endfor
  if !has_using_directive
    call add(l:suggestions, 'C# files must include necessary `using` directives.')
  endif

  " Rule 2: Check for proper method declarations
  for idx in range(len(a:code_lines))
    let line = a:code_lines[idx]
    if line =~ '^\s*public\s+\w+\s+\w+\(' && line !~ '{'
      call add(l:suggestions, 'Line ' . (idx+1) . ': Missing opening brace for method declaration.')
    endif
  endfor

  return l:suggestions
endfunction
