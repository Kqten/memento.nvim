local M = {}

M.default = {
  width = 150,                                                  -- Default width set to 150
  height = 100,                                                 -- Default height set to 100
  side = "left",                                                -- Configurable side
  filepath = vim.fn.expand("~") .. "/memento.nvim/global.md",   -- Updated default file path
  winopts = {
    relativenumber = false,
    number = false,
    list = false,
    winfixwidth = true,
    winfixheight = true,
    foldenable = false,
    spell = false,
    signcolumn = "yes",
    foldmethod = "manual",
    foldcolumn = "0",
    cursorcolumn = false,
    colorcolumn = "0",
  },
  bufopts = {
    { name = "swapfile",   val = false },
    { name = "buftype",    val = "acwrite" }, -- Regular file behavior
    { name = "modifiable", val = true },
    { name = "filetype",   val = "Memento" },
    { name = "bufhidden",  val = "hide" }, -- Allows buffer to be hidden without saving
  },
}

return M

