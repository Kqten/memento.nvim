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
    if a.nvim_buf_is_valid(buf) and vim.b[buf].is_memento_buffer then
      return win -- Return the window ID if found
    end
  end
  return nil -- Return nil if not found
end

-- Get the Memento buffer if it exists
function Memento.get_existing_buffer()
  for _, buf in ipairs(a.nvim_list_bufs()) do
    if a.nvim_buf_is_valid(buf) and vim.b[buf].is_memento_buffer then
      return buf -- Return the existing buffer if it exists
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
  buf = a.nvim_create_buf(false, false)   -- Create an unlisted buffer

  -- Mark the buffer as the Memento buffer
  vim.b[buf].is_memento_buffer = true

  -- Set buffer options from configuration
  local bufopts = Memento.View.bufopts or {}
  for opt, val in pairs(bufopts) do
    a.nvim_buf_set_option(buf, opt, val)
  end

  -- Set the buffer name to distinguish it
  a.nvim_buf_set_name(buf, '[Memento]')

  -- Read the content of the file into the buffer, if it exists
  if vim.fn.filereadable(filepath) == 1 then
    local lines = vim.fn.readfile(filepath)
    a.nvim_buf_set_lines(buf, 0, -1, false, lines)
  else
    -- If the file doesn't exist, start with an empty buffer
    a.nvim_buf_set_lines(buf, 0, -1, false, {})
  end

  -- Set up an autocommand to handle writing the buffer to the file
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      require("memento").save_buffer(buf)
    end,
  })

  return buf
end

-- Function to save the buffer to the file
function Memento.save_buffer(buf)
  local filepath = Memento.View.filepath
  local lines = a.nvim_buf_get_lines(buf, 0, -1, false)
  local ok, err = pcall(vim.fn.writefile, lines, filepath)
  if not ok then
    print('Error saving Memento buffer:', err)
  else
    -- Mark the buffer as not modified
    a.nvim_buf_set_option(buf, 'modified', false)
    print('Memento buffer saved to', filepath)
  end
end

-- Ensure the directory for the file exists
function Memento.ensure_directory()
  local filepath = Memento.View.filepath
  local dir = filepath:match("(.*/)")
  if dir and vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p") -- Create the directory if it doesn't exist
  end
end

-- Save the Memento buffer when Neovim exits
function Memento.save_on_exit()
  local buf = Memento.get_existing_buffer()
  if buf and a.nvim_buf_is_valid(buf) and a.nvim_buf_get_option(buf, 'modified') then
    Memento.save_buffer(buf)
  end
end

-- Create the Memento window.
function Memento.create_window()
  local width = Memento.View.width

  Memento.ensure_directory()                 -- Ensure the directory exists
  local buf = Memento.get_or_create_buffer() -- Get or create the Memento buffer

  -- Check if the window is already open
  local existing_win = Memento.is_win_open()
  if existing_win and a.nvim_win_is_valid(existing_win) then
    -- Memento window already exists, focus it
    a.nvim_set_current_win(existing_win)
    return
  end

  -- Save the current window to return focus to it later
  local prev_win = a.nvim_get_current_win()

  -- Create a vertical split based on the specified side
  if Memento.View.side == "left" then
    vim.cmd('topleft vsplit')  -- Open the split on the left
  else
    vim.cmd('botright vsplit') -- Open the split on the right
  end

  -- Resize the window's width
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

  -- Set window options from configuration
  local winopts = Memento.View.winopts or {}
  for opt, val in pairs(winopts) do
    a.nvim_win_set_option(win, opt, val)
  end

  -- Apply background highlight to the Memento window
  if Memento.View.background_darker then
    -- Get the current 'Normal' highlight group background color
    local normal_hl = vim.api.nvim_get_hl_by_name('Normal', true)
    local normal_bg = normal_hl and normal_hl.background or 0x000000

    local blended_bg = blend_colors(0x000000, normal_bg, 0.2)

    vim.api.nvim_set_hl(0, 'MementoDarkerBackground', { bg = blended_bg })

    a.nvim_win_set_option(win, 'winhighlight', 'Normal:MementoDarkerBackground')
  end

  -- Automatically focus the Memento window when created
  a.nvim_set_current_win(win)

  -- Return focus to the previous window if autofocus is disabled
  if not Memento.View.autofocus and a.nvim_win_is_valid(prev_win) then
    a.nvim_set_current_win(prev_win)
  end
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
    else
      -- Switch to an empty buffer instead of closing the window
      vim.api.nvim_set_current_win(win_id)
      vim.cmd('enew') -- Open a new empty buffer
      print("Cannot close the Memento window because it is the last window open.")
    end
  else
    print("Memento window is not open.")
  end
end

-- Toggle the Memento window.
function Memento.toggle()
  if Memento.is_win_open() then
    Memento.close()         -- Close the window if it's open
  else
    Memento.create_window() -- Create a new window
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

-- Toggle focus between the Memento window and the previous window.
function Memento.focus()
  local memento_win_id = Memento.is_win_open()
  if not memento_win_id then
    -- Memento window is not open; create it and focus it
    Memento.create_window()
    -- No previous window to remember in this case
    return
  end

  local current_win_id = a.nvim_get_current_win()

  if current_win_id == memento_win_id then
    -- Memento window is currently focused
    if Memento.previous_win_id and a.nvim_win_is_valid(Memento.previous_win_id) then
      -- Switch back to the previous window
      a.nvim_set_current_win(Memento.previous_win_id)
      Memento.previous_win_id = nil -- Clear the previous window ID
    else
      -- No valid previous window; focus the first non-Memento window
      for _, win in ipairs(a.nvim_list_wins()) do
        if win ~= memento_win_id then
          a.nvim_set_current_win(win)
          break
        end
      end
    end
  else
    -- Memento window is not focused; focus it
    Memento.previous_win_id = current_win_id -- Remember the current window
    a.nvim_set_current_win(memento_win_id)
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
      if key == 'winopts' or key == 'bufopts' then
        -- Merge the tables
        for opt, val in pairs(value) do
          Memento.View[key][opt] = val
        end
      else
        Memento.View[key] = value
      end
    end
    -- Resize the window if it's open to reflect new values
    if Memento.is_win_open() then
      Memento.resize_window()
    end
  end
end

-- Resize the Memento window to the configured width.
function Memento.resize_window()
  local win = Memento.is_win_open()
  if win then
    a.nvim_win_set_width(win, Memento.View.width)
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
  vim.api.nvim_create_user_command('MementoSave', function() Memento.save_buffer(Memento.get_existing_buffer()) end, {})
  vim.api.nvim_create_user_command('MementoStatus', Memento.status, {})
  vim.api.nvim_create_user_command('MementoFocus', Memento.focus, {})

  -- Set up an autocommand to save the Memento buffer before quitting
  vim.api.nvim_create_autocmd("QuitPre", {
    callback = function()
      Memento.save_on_exit()
    end,
  })
end

return Memento
