return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          filetypes = { "tex" }, -- remove 'plaintext' and 'bib'
        },
      },
    },
  },
}
