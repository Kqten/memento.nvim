-- init.lua
local a = vim.api
local MementoConfig = require('memento.config')

local Memento = {}

Memento.View = MementoConfig.default

-- Function to blend two colors without using 'bit32'
local function blend_colors(fg, bg, alpha)
  -- fg and bg are numbers representing colors in RGB
  -- alpha is the opacity of fg over bg (0 = bg, 1 = fg)

  -- Function to extract RGB components from a color
  local function to_rgb(color)
    local r = math.floor(color / 2 ^ 16) % 256
    local g = math.floor(color / 2 ^ 8) % 256
    local b = color % 256
    return { r = r, g = g, b = b }
  end

  -- Function to blend individual color components
  local function blend_component(fg_c, bg_c, alpha)
    return math.floor((alpha * fg_c + (1 - alpha) * bg_c) + 0.5)
  end

  local fg_rgb = to_rgb(fg)
  local bg_rgb = to_rgb(bg)

  local blended_rgb = {
    r = blend_component(fg_rgb.r, bg_rgb.r, alpha),
    g = blend_component(fg_rgb.g, bg_rgb.g, alpha),
    b = blend_component(fg_rgb.b, bg_rgb.b, alpha),
  }

  -- Combine RGB components back into a single color value
  return blended_rgb.r * 2 ^ 16 + blended_rgb.g * 2 ^ 8 + blended_rgb.b
end

-- Check if the Memento window is open.
function Memento.is_win_open()
  for _, win in ipairs(a.nvim_list_wins()) do
    local buf = a.nvim_win_get_buf(win)
    if a.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "Memento" then
      return win       -- Return the window ID if found
    end
  end
  return nil   -- Return nil if not found
end

-- Get the Memento buffer if it exists
function Memento.get_existing_buffer()
  for _, buf in ipairs(a.nvim_list_bufs()) do
    if a.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "Memento" then
      return buf       -- Return the existing buffer if it exists
    end
  end
  return nil
end

-- Get or create a new buffer for the Memento window.
function Memento.get_or_create_buffer()
  local buf = Memento.get_existing_buffer()
  if buf then
    return buf
  end

  local filepath = Memento.View.filepath

  -- Create a new buffer without changing the current window
  buf = a.nvim_create_buf(false, false)   -- Create a listed buffer

  -- Set buffer name to the file path to associate it with the file
  a.nvim_buf_set_name(buf, filepath)

  -- Load the content of the file into the buffer
  a.nvim_buf_call(buf, function()
    vim.cmd('silent! edit ' .. filepath)
  end)

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
  if dir and vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")     -- Create the directory if it doesn't exist
  end
end

-- Save the Memento buffer when Neovim exits
function Memento.save_on_exit()
  local buf = Memento.get_existing_buffer()
  if buf and a.nvim_buf_is_valid(buf) and a.nvim_buf_get_option(buf, 'modified') then
    a.nvim_buf_call(buf, function()
      vim.cmd('silent! write!')
    end)
  end
end

-- Enforce the Memento buffer in the Memento window
function Memento.enforce_buffer(win_id, buf_id)
  -- Check if the window is still valid
  if not a.nvim_win_is_valid(win_id) then
    -- The window is no longer valid; do nothing
    return
  end

  local current_buf = a.nvim_win_get_buf(win_id)

  if current_buf ~= buf_id then
    -- Revert the buffer in the Memento window back to the Memento buffer
    a.nvim_win_set_buf(win_id, buf_id)
    -- Optionally, switch focus to another window
    for _, win in ipairs(a.nvim_list_wins()) do
      if win ~= win_id then
        a.nvim_set_current_win(win)
        break
      end
    end
  end
end

-- Create the Memento window.
function Memento.create_window()
  local width = Memento.View.width
  local height = Memento.View.height

  Memento.ensure_directory()                   -- Ensure the directory exists
  local buf = Memento.get_or_create_buffer()   -- Get or create the Memento buffer

  -- Create a vertical split based on the specified side
  if Memento.View.side == "left" then
    vim.cmd('topleft vsplit')      -- Open the split on the left
  else
    vim.cmd('botright vsplit')     -- Open the split on the right
  end

  -- Resize the window's height and width
  vim.cmd('resize ' .. height)
  vim.cmd('vertical resize ' .. width)

  -- Get the current window (the new split)
  local win = a.nvim_get_current_win()

  -- Check if win is a valid window ID
  if not win or type(win) ~= 'number' or not a.nvim_win_is_valid(win) then
    error("Memento: Invalid window ID. Cannot proceed.")
    return
  end

  -- Set the buffer for the window
  a.nvim_win_set_buf(win, buf)

  -- Set window options for the newly created window
  for key, value in pairs(Memento.View.winopts) do
    a.nvim_win_set_option(win, key, value)
  end

  -- Additional window options to prevent buffer replacement
  a.nvim_win_set_option(win, 'winfixwidth', true)
  a.nvim_win_set_option(win, 'winfixheight', true)
  a.nvim_win_set_option(win, 'number', false)
  a.nvim_win_set_option(win, 'relativenumber', false)
  a.nvim_win_set_option(win, 'cursorline', false)
  a.nvim_win_set_option(win, 'cursorcolumn', false)
  a.nvim_win_set_option(win, 'signcolumn', 'no')
  a.nvim_win_set_option(win, 'foldcolumn', '0')

  -- Apply background highlight to the Memento window
  if Memento.View.background_darker then
    -- Existing code to apply background highlight
    local normal_hl = vim.api.nvim_get_hl_by_name('Normal', true)
    local normal_bg = normal_hl.background or 0x000000

    local blended_bg = blend_colors(0x000000, normal_bg, 0.2)

    vim.api.nvim_set_hl(0, 'MementoDarkerBackground', { background = blended_bg })

    a.nvim_win_set_option(win, 'winhighlight', 'Normal:MementoDarkerBackground')
  end

  -- Automatically switch focus to the Memento window
  a.nvim_set_current_win(win)

  -- Set syntax highlighting to markdown in the Memento buffer
  a.nvim_buf_set_option(buf, 'syntax', 'markdown')

  -- Set buffer-local options
  for _, opt in ipairs(Memento.View.bufopts) do
    a.nvim_buf_set_option(buf, opt.name, opt.val)
  end

  -- Ensure the buffer is modifiable
  a.nvim_buf_set_option(buf, 'modifiable', true)
  a.nvim_buf_set_option(buf, 'readonly', false)

  -- Set buffer options to prevent it from being wiped when hidden
  a.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  a.nvim_buf_set_option(buf, 'swapfile', false)

  -- Set up an autocommand to enforce the Memento buffer in the Memento window
  -- and prevent other buffers from opening in it
  local memento_bufnr = buf
  local memento_winid = win

  vim.cmd(string.format([[
        augroup MementoEnforceBuffer
            autocmd! * <buffer=%d>
            autocmd BufWinEnter * lua require('memento').enforce_buffer(%d, %d)
        augroup END
    ]], memento_bufnr, memento_winid, memento_bufnr))
end

-- Close the Memento window.
function Memento.close()
  local win_id = Memento.is_win_open()
  if win_id then
    -- Check if there are more than one window open
    local windows = a.nvim_tabpage_list_wins(0)
    if #windows > 1 then
      -- Close the Memento window
      vim.api.nvim_win_close(win_id, true)
      -- Clear the autocommand group associated with the Memento window
      vim.cmd('augroup MementoEnforceBuffer | autocmd! | augroup END')
    else
      -- Switch to an empty buffer instead of closing the window
      vim.api.nvim_set_current_win(win_id)
      vim.cmd('enew')       -- Open a new empty buffer
      print("Cannot close the Memento window because it is the last window open.")
      -- Clear the autocommand group associated with the Memento window
      vim.cmd('augroup MementoEnforceBuffer | autocmd! | augroup END')
    end
  else
    print("Memento window is not open.")
  end
end

-- Toggle the Memento window.
function Memento.toggle()
  if Memento.is_win_open() then
    Memento.close()             -- Close the window if it's open
  else
    Memento.create_window()     -- Create a new window
  end
end

-- Open the Memento window if it's not already open.
function Memento.open()
  if not Memento.is_win_open() then
    Memento.create_window()
  else
    print("Memento window is already open.")
  end
end

-- Focus the Memento window.
function Memento.focus()
  local win_id = Memento.is_win_open()
  if win_id then
    a.nvim_set_current_win(win_id)     -- Focus the Memento window
  else
    Memento.create_window()            -- Open and focus the Memento window if it's not open
  end
end

-- Display the status of the Memento buffer.
function Memento.status()
  local buf = Memento.get_existing_buffer()
  if buf and a.nvim_buf_is_valid(buf) then
    local modified = a.nvim_buf_get_option(buf, 'modified')
    local win_open = Memento.is_win_open() and "Yes" or "No"
    print(string.format("Memento buffer is open: %s, modified: %s", win_open, modified and "Yes" or "No"))
  else
    print("Memento buffer does not exist.")
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
    a.nvim_win_set_width(win, Memento.View.width)
    a.nvim_win_set_height(win, Memento.View.height)
  end
end

-- Setup function for user-defined options.
function Memento.setup(user_options)
  if user_options then
    Memento.update_config(user_options)
  end
  -- Update command names to have 'Memento' as prefix
  vim.api.nvim_create_user_command('MementoToggle', Memento.toggle, {})
  vim.api.nvim_create_user_command('MementoOpen', Memento.open, {})
  vim.api.nvim_create_user_command('MementoClose', Memento.close, {})
  vim.api.nvim_create_user_command('MementoSave', function() vim.cmd('write') end, {})
  vim.api.nvim_create_user_command('MementoStatus', Memento.status, {})
  vim.api.nvim_create_user_command('MementoFocus', Memento.focus, {})

  -- Set up an autocommand to save the Memento buffer before quitting
  vim.cmd('autocmd QuitPre * lua require("memento").save_on_exit()')
end

return Memento

