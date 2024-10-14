local Memento = {}

function Memento.create_window()
  local width = 30
  local height = 20

  vim.cmd('vsplit')
  vim.cmd('resize ' .. height)
  vim.cmd('setlocal buftype=nofile')
  vim.cmd('setlocal bufhidden=wipe')
  vim.cmd('setlocal noswapfile')

  vim.api.nvim_buf_set_name(0, "Memento")

  vim.wo.number = true
  vim.wo.relativenumber = true
  vim.wo.foldmethod = 'expr'
  vim.wo.foldexpr = '0'

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# Your notes go here..." })
end

function Memento.toggle()
  if vim.fn.bufexists('Memento') == 1 then
    vim.cmd('b Memento')
    vim.cmd('wincmd p') -- Go back to the previous window
  else
    Memento.create_window()
  end
end

return Memento
