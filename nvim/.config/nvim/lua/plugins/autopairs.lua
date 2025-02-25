-- Auto insert character or tag pairs, and indent new lines
return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },
  "windwp/nvim-ts-autotag",
}
