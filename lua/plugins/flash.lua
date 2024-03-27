-- change flash config (advanced search)

return {
  {
    "folke/flash.nvim",
    opts = {
      labels = "qwertasdfgzxcvb",
      search = { mode = "search" }, -- use regex
      jump = {
        history = true,
        nohlsearch = true,
      },
      label = {
        after = false,
        before = true,
        style = "inline",
      },
      modes = {
        search = { enabled = false }, -- disable for '/' and '?'
        char = { enabled = false }, -- disable for 'f', 'F', 't' and 'T'
      },
      prompt = {
        prefix = { { "  ", "FlashPromptIcon" } },
      },
    },
  },
}
