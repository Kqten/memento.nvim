-- config.lua
local MementoConfig = {}

MementoConfig.default = {
    filepath = "~/.memento.nvim/global.md", -- Path to your notes file
    width = 50,             -- Width of the Memento window
    side = "left",          -- Side of the editor where the window will appear ('left' or 'right')
    autofocus = true,       -- Whether the Memento window should autofocus when opened
    background_darker = true, -- Whether to darken the background of the Memento window
    winopts = {             -- Window options
        winfixwidth = true,
        winfixheight = false,
        number = false,
        relativenumber = false,
        cursorline = false,
        cursorcolumn = false,
        signcolumn = 'no',
        foldcolumn = '0',
        wrap = true,
        linebreak = true,
        spell = true,
        winbar = 'Memento Notepad', -- Custom winbar text
    },
    bufopts = {             -- Buffer options
        buftype = '',
        buflisted = false,
        swapfile = false,
        bufhidden = 'hide',
        modifiable = true,
        readonly = false,
        filetype = 'markdown',
    },
}

return MementoConfig

