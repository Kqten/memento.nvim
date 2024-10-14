-- config.lua
local M = {}

M.default = {
  width = 150,
  height = 100,
  side = "left",
  filepath = vim.fn.expand("~") .. "/memento.nvim/global.md",
  background_highlight = "MementoBackground",   -- New option for background highlight
  background_darker = false,
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
    { name = "buftype",    val = "acwrite" },
    { name = "modifiable", val = true },
    { name = "filetype",   val = "Memento" },
    { name = "bufhidden",  val = "hide" },
    { name = "buflisted",  val = false },
  },
}

return M

