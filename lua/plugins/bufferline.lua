return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        groups = {
          items = {
            require("bufferline.groups").builtin.pinned:with({ icon = "󰐃" }),
          },
        },
      },
    },
  },
}
