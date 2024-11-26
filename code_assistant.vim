" Code Assistant Vim Plugin with GPT Integration

" Initialize the Code Assistant plugin
function! CodeAssistantInit()
  " Close other windows and open a vertical split
  only
  vsplit

  " Set the width of the right pane
  vertical resize 40

  " Move to the right pane
  wincmd l

  " Create the top container (Actions) with heading
  split
  enew
  setlocal buftype=nofile bufhidden=hide noswapfile
  " Name the buffer
  file Actions
  setlocal nomodified

  " Make the buffer modifiable to add content
  setlocal modifiable
  call setline(1, 'Actions')
  " Set the buffer to read-only
  setlocal nomodifiable

  " Move to the bottom container (Suggestions) with heading
  wincmd j
  enew
  setlocal buftype=nofile bufhidden=hide noswapfile
  " Name the buffer
  file Suggestions
  setlocal nomodified

  " Make the buffer modifiable to add content
  setlocal modifiable
  call setline(1, 'Suggestions')
  " Set the buffer to read-only
  setlocal nomodifiable

  " Return to the left pane (main coding area)
  wincmd h
endfunction

" Command to activate the plugin
command! CodeAssistant call CodeAssistantInit()

" Function to update Actions container with current code
function! UpdateActions()
  " Get the code from the main buffer
  let l:code = getline(1, '$')

  " Get the buffer number of Actions buffer
  let l:actions_bufnr = bufnr('Actions')
  if l:actions_bufnr == -1
    echom "Actions buffer not found. Please run :CodeAssistant to initialize."
    return
  endif

  " Make the Actions buffer modifiable
  call setbufvar(l:actions_bufnr, '&modifiable', 1)

  " Clear previous content and display code
  call setbufline(l:actions_bufnr, 1, 'Actions')
  call deletebufline(l:actions_bufnr, 2, '$')
  if len(l:code) > 0
    call appendbufline(l:actions_bufnr, 1, l:code)
  endif

  " Make the Actions buffer read-only again
  call setbufvar(l:actions_bufnr, '&modifiable', 0)
endfunction

" Function to call GPT and update code
function! CallGPT(suggestions, user_code) abort
  " Use Python3 interface to call OpenAI API
  py3 << EOF
import openai
import os
import vim
import json
import re
import logging
import traceback

# Configure logging
logging.basicConfig(level=logging.INFO)

def call_gpt():
    """Call OpenAI GPT to update code based on suggestions."""
    # Load API key from environment variable
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        vim.command('echom "Error: OPENAI_API_KEY is not set. Please set it as an environment variable."')
        return

    openai.api_key = api_key

    # Get the suggestions and user code
    suggestions = vim.eval("a:suggestions")
    user_code = vim.eval("a:user_code")

    # Prepare the prompt for GPT
    prompt = f"""Here is the Python code:
{user_code}

And here are the suggestions:
{suggestions}

Please update the code based on the suggestions also refactor the code for better programing practices. If there are no suggestions, rewrite the code with some useful comments, your task is to refactor the code and make it more readable, maintainable, efficient, and follow best practices and coupling free code.If required, you can also add new functions or classes to improve the code also can remove unnecessary code,comments, or functions and variables,also rename the variables and functions if required or unmeaningfull names, you also have to reduce Cyclomatic Complexity, Cohesion & Coupling and Maintainability Index and Code Duplication.
Note: Your response should only be Python code because your response will be executed directly, so please write only Python code."""

    try:
        # Call GPT using the ChatCompletion API
        response = openai.ChatCompletion.create(
            model="gpt-4o",  # Use "gpt-4" if you have access
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=1024,
            temperature=0.7
        )

        # Extract the updated code properly from the response
        updated_code = response.choices[0].message.content.strip()

        updated_code_cleaned = re.sub(r"```python|```", "", updated_code).strip()

        # Log the cleaned-up code for debugging
        logging.info("Cleaned Updated Code:\n%s", updated_code_cleaned)

        # Properly escape the updated code before passing it back to Vim
        updated_code_escaped = updated_code_cleaned.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

        # Send the updated code back to Vim
        vim.command(f'let g:updated_code = "{updated_code_escaped}"')

    except Exception as e:
        error_message = ''.join(traceback.format_exception(None, e, e.__traceback__))
        vim.command(f'echom "Error during GPT request: {error_message}"')

# Call the function
call_gpt()
EOF
endfunction

" Function to update Actions buffer with GPT code
function! UpdateActionsWithGPT()
  " Get the current code and suggestions
  let user_code = join(getline(1, '$'), "\n")
  let suggestions = join(getbufline('Suggestions', 2, '$'), "\n")

  " Call GPT with the code and suggestions
  call CallGPT(suggestions, user_code)

  " Check if the GPT response was successful
  if !exists('g:updated_code')
    echo "Error: GPT did not return any code. Please check your API call."
    return
  endif

  " Update the Actions buffer with GPT-provided code
  let gpt_code = g:updated_code
  let l:actions_bufnr = bufnr('Actions')

  " Make the Actions buffer modifiable
  call setbufvar(l:actions_bufnr, '&modifiable', 1)

  " Clear previous content and display GPT-provided code
  call setbufline(l:actions_bufnr, 1, 'Actions (GPT-suggested code)')
  call deletebufline(l:actions_bufnr, 2, '$')
  call appendbufline(l:actions_bufnr, 1, split(gpt_code, "\n"))

  " Make the Actions buffer read-only again
  call setbufvar(l:actions_bufnr, '&modifiable', 0)

  " Show options to the user
  echo "GPT has provided updated code. Run :AcceptGPT or :RejectGPT to apply or discard the changes."
endfunction

" Command to accept the GPT-generated code and replace the original code
command! AcceptGPT call ReplaceCodeWithGPT()

" Command to reject the GPT-generated code and keep the original
command! RejectGPT call RevertToOriginalCode()

function! ReplaceCodeWithGPT()
  " Get the GPT-generated code from Actions buffer
  let l:actions_bufnr = bufnr('Actions')
  let gpt_code = join(getbufline(l:actions_bufnr, 2, '$'), "\n")

  " Replace the user's original code with the GPT-generated code
  call setbufline(bufnr('%'), 1, split(gpt_code, "\n"))
  echo "Code has been replaced with GPT-generated code."
endfunction

function! RevertToOriginalCode()
  " Clear the GPT-generated code and keep the original
  echo "Changes discarded. Keeping original code."
endfunction

" Function to provide suggestions based on rule-based analysis
function! ProvideSuggestions()
  " Get the code from the main buffer
  let l:code_lines = getline(1, '$')
  let l:code = join(l:code_lines, "\n")

  " Initialize suggestions list
  let l:suggestions = []

  " Rule 1: Indentation - Check for incorrect indentation (not multiples of 4 spaces)
  for idx in range(len(l:code_lines))
    let line = l:code_lines[idx]
    if line =~ '^\s\+'
      let indent = matchstr(line, '^\s\+')
      let spaces = substitute(indent, '\t', '    ', 'g')
      if (len(spaces) % 4) != 0
        call add(l:suggestions, 'Line ' . (idx+1) . ': Indentation should be a multiple of 4 spaces.')
      endif
    endif
  endfor

  " Rule 2: Maximum line length - Check for lines longer than 79 characters
  for idx in range(len(l:code_lines))
    if strdisplaywidth(l:code_lines[idx]) > 79
      call add(l:suggestions, 'Line ' . (idx+1) . ': Line exceeds 79 characters.')
    endif
  endfor

  " Rule 3: Blank lines - Check for missing blank lines around top-level functions and classes
  let prev_line = ''
  for idx in range(len(l:code_lines))
    let line = l:code_lines[idx]
    " Check for function or class definitions
    if line =~ '^\s*\(def\|class\)\s\+\k\+'
      " Ensure there are two blank lines before top-level definitions
      if idx >= 2
        let blank_lines = l:code_lines[idx-1] ==# '' && l:code_lines[idx-2] ==# ''
        if !blank_lines
          call add(l:suggestions, 'Line ' . (idx+1) . ': Top-level function or class should be surrounded by two blank lines.')
        endif
      endif
    endif
    let prev_line = line
  endfor

  " Rule 4: Use of logging module - Check if logging is imported when used
  let uses_logging = 0
  let imports_logging = 0
  for line in l:code_lines
    if line =~ 'import logging'
      let imports_logging = 1
    endif
    if line =~ 'logging\.\w\+'
      let uses_logging = 1
    endif
  endfor
  if uses_logging && !imports_logging
    call add(l:suggestions, 'Logging module is used but not imported.')
  endif

  " Rule 5: Check if the user has added proper comments
  let l:comment_count = 0
  for line in l:code_lines
    let stripped_line = substitute(line, '^\s\+', '', '')
    if stripped_line =~ '^#'
      let l:comment_count += 1
    endif
  endfor
  if l:comment_count == 0
    call add(l:suggestions, 'Please add proper comments to your code.')
  endif

  " Rule 6: Docstrings - Check for docstrings in functions and classes
  let in_def = 0
  let def_line = 0
  for idx in range(len(l:code_lines))
    let line = l:code_lines[idx]
    if line =~ '^\s*\(def\|class\)\s\+\k\+'
      let in_def = 1
      let def_line = idx
    elseif in_def
      let stripped_line = substitute(line, '^\s\+', '', '')
      if stripped_line =~ '^"""'
        let in_def = 0
      else
        call add(l:suggestions, 'Line ' . (def_line+1) . ': Missing docstring in function or class definition.')
        let in_def = 0
      endif
    endif
  endfor

  " Rule 7: Naming conventions - Check variable and function names
  for idx in range(len(l:code_lines))
    let line = l:code_lines[idx]
    " Check for function definitions
    if line =~ '^\s*def\s\+\(\k\+\)'
      let func_name = matchstr(line, '^\s*def\s\+\zs\k\+\ze(')
      if func_name !=# tolower(func_name)
        call add(l:suggestions, 'Line ' . (idx+1) . ': Function name "' . func_name . '" should be lowercase with underscores.')
      endif
    endif
    " Check for class definitions
    if line =~ '^\s*class\s\+\(\k\+\)'
      let class_name = matchstr(line, '^\s*class\s\+\zs\k\+\ze\(\|\s*(\)')
      if class_name !=# substitute(class_name, '\<\(\k\)', '\u\1', 'g')
        call add(l:suggestions, 'Line ' . (idx+1) . ': Class name "' . class_name . '" should use CapWords convention.')
      endif
    endif
    " Check for variable assignments
    if line =~ '^\s*\(\k\+\)\s*='
      let var_name = matchstr(line, '^\s*\zs\k\+\ze\s*=')
      if var_name !=# tolower(var_name)
        call add(l:suggestions, 'Line ' . (idx+1) . ': Variable name "' . var_name . '" should be lowercase with underscores.')
      endif
    endif
  endfor

  " Rule 8: Check for variables declared but not used
  let l:variables_declared = []
  let l:variables_used = []
  for idx in range(len(l:code_lines))
    let line = l:code_lines[idx]
    " Find variable assignments
    if line =~ '^\s*\(\k\+\)\s*='
      let var_name = matchstr(line, '^\s*\zs\k\+\ze\s*=')
      call add(l:variables_declared, var_name)
    endif
    " Collect all variable usages
    let words = split(line, '\W\+')
    for word in words
      if word =~ '^\k\+$'
        call add(l:variables_used, word)
      endif
    endfor
  endfor
  " Find variables that are declared but not used
  for var in l:variables_declared
    if count(l:variables_used, var) <= 1 " Variable appears only in declaration
      call add(l:suggestions, 'Variable "' . var . '" is declared but not used.')
    endif
  endfor

  " Get the buffer number of Suggestions buffer
  let l:suggestions_bufnr = bufnr('Suggestions')
  if l:suggestions_bufnr == -1
    echom "Suggestions buffer not found. Please run :CodeAssistant to initialize."
    return
  endif

  " Make the Suggestions buffer modifiable
  call setbufvar(l:suggestions_bufnr, '&modifiable', 1)

  " Clear previous content and display suggestions
  call setbufline(l:suggestions_bufnr, 1, 'Suggestions')
  call deletebufline(l:suggestions_bufnr, 2, '$')
  if !empty(l:suggestions)
    call appendbufline(l:suggestions_bufnr, 1, l:suggestions)
  else
    call setbufline(l:suggestions_bufnr, 2, 'No suggestions. Your code looks good!')
  endif

  " Make the Suggestions buffer read-only again
  call setbufvar(l:suggestions_bufnr, '&modifiable', 0)
endfunction

" Auto-update Actions container when text is changed
autocmd TextChanged,TextChangedI *.py call UpdateActions()

" Provide suggestions when file is saved
autocmd BufWritePost *.py call ProvideSuggestions() | call UpdateActionsWithGPT()
