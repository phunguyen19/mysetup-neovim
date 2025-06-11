require("rpn.core")
require("rpn.lazy")

-- Set colorscheme to melange
vim.cmd("colorscheme melange")

-- Make background transparent
vim.cmd([[
  hi Normal       guibg=NONE ctermbg=NONE
  hi NormalNC     guibg=NONE ctermbg=NONE
  hi Pmenu        guibg=NONE ctermbg=NONE
  hi SignColumn   guibg=NONE ctermbg=NONE
  hi VertSplit    guibg=NONE ctermbg=NONE
  hi StatusLineNC guibg=NONE ctermbg=NONE
]])
