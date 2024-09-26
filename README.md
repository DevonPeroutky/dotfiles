# 💤 LazyVim

Based on the starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation).

# Notes
- [ ] Requires FD. `brew install fd`


# Areas of Improvement
- [ ] Quickfix list + Macros 
- [ ] View all errors in telescope --> Send to quickfix list?


# Current Issues
## Getting a debugger that uses the local venv for packages
Install for debugger is weird. As far as I can tell it involves:
- Mason
- Mason-nvim-dap
- nvim-dap
- nvim-dap-ui (Just the UI)
- nvim-dap-python (Just the UI)
- debugpy (THE ACTUAL DEBUGGER)

All of this is very obfuscated in LazyVim. Just "extras" with no configuration stored anywhere accessible. 

I'm able to have the debugger installed and run easily via the extras, however, not sure how to configure that to use the venv.



# Wants
- [ ] Refactor? `grug-far`?
- [ ] Tests?
- [ ] Persistent Terminal?
- [ ] Avante integration?
- [ ] aider.chat integration?
