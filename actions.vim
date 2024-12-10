" actions.vim - Manage Actions container

function! UpdateActions()
  let l:code = getline(1, '$')
  let l:actions_bufnr = bufnr('Actions')
  if l:actions_bufnr == -1
    echom "Actions buffer not found. Please run :CodeAssistant to initialize."
    return
  endif

  call setbufvar(l:actions_bufnr, '&modifiable', 1)
  call setbufline(l:actions_bufnr, 1, 'Actions')
  call deletebufline(l:actions_bufnr, 2, '$')
  if len(l:code) > 0
    call appendbufline(l:actions_bufnr, 1, l:code)
  endif
  call setbufvar(l:actions_bufnr, '&modifiable', 0)
endfunction

command! AcceptGPT call ReplaceCodeWithGPT()
command! RejectGPT call RevertToOriginalCode()

function! ReplaceCodeWithGPT()
  let l:actions_bufnr = bufnr('Actions')
  let gpt_code = join(getbufline(l:actions_bufnr, 2, '$'), "\n")
  call setbufline(bufnr('%'), 1, split(gpt_code, "\n"))
  echo "Code has been replaced with GPT-generated code."
endfunction

function! RevertToOriginalCode()
  echo "Changes discarded. Keeping original code."
endfunction
