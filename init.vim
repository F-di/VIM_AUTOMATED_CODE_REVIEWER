" init.vim - Plugin initialization

function! CodeAssistantInit()
  " Close other windows and open a vertical split
  only
  vsplit

  " Set the width of the right pane
  vertical resize 80

  " Move to the right pane
  wincmd l

  " Create the top container (Actions) with heading
  split
  enew
  setlocal buftype=nofile bufhidden=hide noswapfile
  file Actions
  setlocal nomodified
  call setline(1, 'Actions')
  setlocal nomodifiable

  " Move to the bottom container (Suggestions) with heading
  wincmd j
  enew
  setlocal buftype=nofile bufhidden=hide noswapfile
  file Suggestions
  setlocal nomodified
  call setline(1, 'Suggestions')
  setlocal nomodifiable

  " Return to the left pane (main coding area)
  wincmd h
endfunction
