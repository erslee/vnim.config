return {
  {
    dir = "~/dev/nvim/smart-definition",
    config = function()
      require("smart-definition").setup({
        -- Add your configuration here
        -- Example: enable logging
        log_level = "debug",
      })
    end,
  },
}
