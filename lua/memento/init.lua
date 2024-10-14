local a = vim.api
local MementoConfig = require('memento.config') -- Require the config file

local Memento = {}

Memento.View = MementoConfig.default -- Use the default config

-- Check if the Memento window is open.
function Memento.is_win_open()
  for _, win in ipairs(a.nvim_list_wins()) do
    local buf = a.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "Memento" then
      return win -- Return the window ID if found
    end
  end
  return nil -- Return nil if not found
end

-- Get or create a new buffer for the Memento window.
function Memento.get_or_create_buffer()
  for _, buf in ipairs(a.nvim_list_bufs()) do
    if a.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "Memento" then
      return buf -- Return the existing buffer if it exists
    end
  end

  -- Create a new buffer if none exists
  local buf = a.nvim_create_buf(false, true)      -- Create a non-listed buffer
  a.nvim_buf_set_name(buf, "Memento") -- Set the buffer's name to the desired file path

  -- Set buffer-local options
  for _, opt in ipairs(Memento.View.bufopts) do
    a.nvim_buf_set_option(buf, opt.name, opt.val)
  end

  -- Set the filetype for the buffer
  a.nvim_buf_set_option(buf, 'filetype', 'Memento')

  return buf
end

-- Ensure the directory for the file exists
function Memento.ensure_directory()
  local filepath = Memento.View.filepath
  local dir = filepath:match("(.*/)")
  if dir and not vim.fn.isdirectory(dir) then
    vim.fn.mkdir(dir, "p") -- Create the directory if it doesn't exist
  end
end

-- Load content from the specified file into the Memento buffer.
function Memento.load_content(buf)
  local filepath = Memento.View.filepath
  local lines = {}

  -- Try to read the content from the file
  local file = io.open(filepath, "r")
  if file then
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()
  end

  -- Set the lines in the buffer
  a.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

-- Save the content of the Memento buffer to the specified file.
function Memento.save_to_file()
    local buf = Memento.get_or_create_buffer()
    if not a.nvim_buf_is_valid(buf) then
        print("Buffer is no longer valid.")
        return
    end
    local filepath = Memento.View.filepath
    local file = io.open(filepath, "w")
    if file then
        local lines = a.nvim_buf_get_lines(buf, 0, -1, false)
        for _, line in ipairs(lines) do
            file:write(line .. "\n")
        end
        file:close()
        -- Mark the buffer as not modified
        a.nvim_buf_set_option(buf, 'modified', false)
    else
        print("Failed to save to " .. filepath)
    end
end


-- Create the Memento window.
function Memento.create_window()
  local width = Memento.View.width
  local height = Memento.View.height

  Memento.ensure_directory()                 -- Ensure the directory exists
  local buf = Memento.get_or_create_buffer() -- Get or create the Memento buffer

  -- Load content from the file into the buffer
  Memento.load_content(buf)

  -- Create a vertical split based on the specified side
  if Memento.View.side == "left" then
    vim.cmd('vsplit')
  else
    vim.cmd('vsplit')
    vim.cmd('wincmd r') -- Move focus to the right side
  end
  vim.cmd('resize ' .. height)

  -- Set window options for the newly created window
  local win = a.nvim_get_current_win()
  for key, value in pairs(Memento.View.winopts) do
    a.nvim_win_set_option(win, key, value)
  end

  -- Set the buffer for the window
  a.nvim_win_set_buf(win, buf)

  -- Automatically switch focus to the new window
  a.nvim_set_current_win(win)

  -- Set some initial content if the buffer is empty
  if a.nvim_buf_line_count(buf) == 0 then
    a.nvim_buf_set_lines(buf, 0, -1, false, { "# Your notes go here..." })
  end

  -- Set up an autocommand to save to the global.md file on write
  vim.cmd('autocmd BufWriteCmd,BufWinLeave <buffer> lua require("memento").save_to_file()')
end

-- Close the Memento window.
function Memento.close()
  local win_id = Memento.is_win_open()
  if win_id then
    a.nvim_win_close(win_id, true) -- Close the existing window
    -- Do not delete the buffer here
  end
end

-- Toggle the Memento window.
function Memento.toggle()
  if Memento.is_win_open() then
    Memento.close()         -- Close the window and buffer if it's open
  else
    Memento.create_window() -- Create a new window
    vim.cmd('wincmd l')     -- Move focus to the new window
  end
end

-- Update configuration values.
function Memento.update_config(user_options)
  if user_options then
    for key, value in pairs(user_options) do
      Memento.View[key] = value
    end
    -- Resize the window if it's open to reflect new values
    if Memento.is_win_open() then
      Memento.resize_window()
    end
  end
end

-- Resize the Memento window to the configured width and height.
function Memento.resize_window()
  local win = Memento.is_win_open()
  if win then
    vim.cmd('resize ' .. Memento.View.height)         -- Resize height
    vim.cmd('vertical resize ' .. Memento.View.width) -- Resize width
  end
end

-- Setup function for user-defined options.
function Memento.setup(user_options)
  if user_options then
    Memento.update_config(user_options) -- Use the update_config function to apply options
  end
  vim.api.nvim_create_user_command('ToggleMemento', Memento.toggle, {})
end

return Memento

