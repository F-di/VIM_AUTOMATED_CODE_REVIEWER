" code_assistant.vim - Main plugin file

" Import external scripts
source ~/.vim/code_assistant/init.vim
source ~/.vim/code_assistant/actions.vim
source ~/.vim/code_assistant/suggestions.vim
source ~/.vim/code_assistant/rules.vim
source ~/.vim/code_assistant/gpt.vim


" Command to activate the plugin
command! CodeAssistant call CodeAssistantInit()

" Auto-update Actions container when text is changed for supported file types
autocmd TextChanged,TextChangedI *.py,*.c,*.cpp,*.java,*.cs call UpdateActions()

" Provide suggestions and call GPT when file is saved for supported file types
autocmd BufWritePost *.py,*.c,*.cpp,*.java,*.cs call ProvideSuggestions() | call UpdateActionsWithGPT()
