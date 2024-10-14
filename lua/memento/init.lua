local Memento = {}

-- Function to create the notepad window
function Memento.create_window()
  local width = 30
  local height = 20

  -- Create a new split window on the left
  vim.cmd('vsplit')
  vim.cmd('resize ' .. height)
  vim.cmd('setlocal buftype=nofile')
  vim.cmd('setlocal bufhidden=wipe')
  vim.cmd('setlocal noswapfile')
  
  -- Set the buffer name
  vim.api.nvim_buf_set_name(0, "Memento")

  -- Set options for the window
  vim.wo.number = true
  vim.wo.relativenumber = true
  vim.wo.foldmethod = 'expr'
  vim.wo.foldexpr = '0'

  -- Optionally set some initial content
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {"# Your notes go here..."})
end

-- Command to toggle the notepad window
function Memento.toggle()
  if vim.fn.bufexists('Memento') == 1 then
    vim.cmd('b Memento')
    vim.cmd('wincmd p')  -- Go back to the previous window
  else
    Memento.create_window()
  end
end

-- Create the user command within the module
function Memento.setup()
  vim.api.nvim_create_user_command('ToggleMemento', Memento.toggle, {})
end

return Memento

