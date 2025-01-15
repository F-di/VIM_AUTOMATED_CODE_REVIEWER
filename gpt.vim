" gpt.vim - GPT Integration

function! CallGPT(suggestions, user_code) abort
  py3 << EOF
import openai
import os
import vim
import re

def call_gpt():
    # Fetch API key from the environment
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        vim.command('echom "Error: OPENAI_API_KEY is not set."')
        return

    # Set OpenAI API key
    openai.api_key = api_key

    # Fetch suggestions, user code, and file type
    suggestions = vim.eval("a:suggestions")
    user_code = vim.eval("a:user_code")
    filetype = vim.eval("&filetype")

    # Construct the prompt with a strict response format
    prompt = f"""Here is the {filetype} code:
{user_code}

Here are the suggestions:
{suggestions}
Please update the code based on the suggestions also refactor the code for better programing practices. If there are no suggestions, rewrite the code with some useful comments, your task is to refactor the code and make it more readable, maintainable, efficient, and follow best practices and coupling free code.If required, you can also add new functions or classes to improve the code also can remove unnecessary code,comments, or functions and variables,also rename the variables and functions if required or unmeaningfull names, you also have to reduce Cyclomatic Complexity, Cohesion & Coupling and Maintainability Index and Code Duplication.
Rules you have to work for every language;
For Python : 1. Check for incorrect indentation, 2. Maximum line length - Check for lines longer than 79 characters, 3. Check for unused imports, 4. Check for missing docstrings in functions and classes, 5. Check for wildcard imports, 6. Check for bare `except` clauses, 7. Check for mutable default arguments in functions, 8. Check for print statements in production code, 9. Ensure main guard exists, 10. Remove unnecessary or unused imports, 11. Remove unnecessary or unused class, Functions and variables.
For C : 1. Check for missing braces, 2. Check for semicolons at the end of statements, 3. Avoid using magic numbers, 4. Check for null pointer dereference.
For Cpp : 1. Check for `std::` namespace usage, 2. Check for use of smart pointers. 
Note: Your response should only be  code because your response will be executed directly, so please write only  code and Make sure you check all the rules and return all the bed smell free code make sure in python you never use "import * or from this import *" this should not be added
Please refactor the code based on the suggestions. Return the refactored code in the following format:

<CODE>
[Your refactored code here]
</CODE>

Do not include any explanations or comments outside the <CODE> tags."""

    try:
        # Call the GPT model
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=1024,
            temperature=0.7
        )

        # Extract GPT response content
        updated_code = response.choices[0].message.content.strip()

        # Extract code between <CODE> and </CODE> tags
        code_match = re.search(r"<CODE>\s*([\s\S]*?)\s*</CODE>", updated_code)
        if code_match:
            updated_code_cleaned = code_match.group(1).strip()
        else:
            # Log raw GPT response if format is incorrect
            
            return

        # Escape the cleaned code for Vim
        updated_code_escaped = updated_code_cleaned.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        vim.command(f'let g:updated_code = "{updated_code_escaped}"')

    except openai.error.OpenAIError as api_error:
        vim.command(f'echom "OpenAI API error: {str(api_error)}"')
    except Exception as e:
        vim.command(f'echom "Unexpected error: {str(e)}"')

# Execute the GPT function
call_gpt()
EOF
endfunction

function! UpdateActionsWithGPT()
  " Get the current code and suggestions
  let user_code = join(getline(1, '$'), "\n")
  let suggestions = join(getbufline('Suggestions', 2, '$'), "\n")

  " Call GPT to process the code and suggestions
  call CallGPT(suggestions, user_code)

  " Check if GPT returned any code
  if !exists('g:updated_code') || g:updated_code ==# ''
    echo "Error: GPT did not return any code."
    return
  endif

  " Fetch the GPT-provided code
  let gpt_code = g:updated_code

  " Get the buffer number of the Actions buffer
  let l:actions_bufnr = bufnr('Actions')
  if l:actions_bufnr == -1
    echom "Actions buffer not found. Please run :CodeAssistant to initialize."
    return
  endif

  " Make the Actions buffer modifiable
  call setbufvar(l:actions_bufnr, '&modifiable', 1)

  " Update the Actions buffer with GPT-provided code
  call setbufline(l:actions_bufnr, 1, 'Actions (GPT-suggested code)')
  call deletebufline(l:actions_bufnr, 2, '$')
  call appendbufline(l:actions_bufnr, 1, split(gpt_code, "\n"))

  " Make the Actions buffer read-only again
  call setbufvar(l:actions_bufnr, '&modifiable', 0)

  " Confirm update in the Actions buffer
  echom "Actions container successfully updated with GPT code."
endfunction
