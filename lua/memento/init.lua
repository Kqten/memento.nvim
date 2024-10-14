local Memento = {}
Memento.options = {
    bufnr = nil,
    tabpages = {},
    width = 30,
    side = "left",
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
        { name = "swapfile", val = false },
        { name = "buftype", val = "nofile" },
        { name = "modifiable", val = false },
        { name = "filetype", val = "SidebarNvim" },
        { name = "bufhidden", val = "hide" },
    },
}

-- Function to create the notepad window
function Memento.create_window()
    local width = Memento.options.width
    local height = 20

    -- Create a new split window on the left
    vim.cmd('vsplit')
    vim.cmd('resize ' .. height)
    
    -- Set window options
    for key, value in pairs(Memento.options.winopts) do
        vim.wo[key] = value
    end

    -- Set buffer options
    vim.api.nvim_buf_set_name(0, "Memento")
    for _, opt in ipairs(Memento.options.bufopts) do
        vim.api.nvim_buf_set_option(0, opt.name, opt.val)
    end

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

-- Create the user command and setup options
function Memento.setup(user_options)
    if user_options then
        for key, value in pairs(user_options) do
            Memento.options[key] = value
        end
    end
    vim.api.nvim_create_user_command('ToggleMemento', Memento.toggle, {})
end

return Memento

