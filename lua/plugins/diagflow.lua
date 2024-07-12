return {
  "dgagn/diagflow.nvim",
  -- event = 'LspAttach', This is what I use personnally and it works great
  opts = {
    placement = "inline",
    format = function(diagnostic)
      return "●" .. " " .. diagnostic.message
    end,
  },
}
