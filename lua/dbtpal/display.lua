local M = {}

local function popup(data, opts)
    local name = "dbtpalConsole"
    local cur = vim.fn.bufnr(name)

    if cur and cur ~= -1 then vim.api.nvim_buf_delete(cur, { force = true }) end

    local columns = vim.o.columns
    local lines = vim.o.lines
    local width = math.ceil(columns * 0.8)
    local height = math.ceil(lines * 0.8 - 4)
    local left = math.ceil((columns - width) * 0.5)
    local top = math.ceil((lines - height) * 0.5 - 1)

    -- TODO: merge this table with config
    local win_opts = vim.tbl_deep_extend("force", {
        relative = "editor",
        style = "minimal",
        border = "double",
        width = width,
        height = height,
        col = left,
        row = top,
    }, opts or {})

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, win_opts)
    vim.api.nvim_buf_set_name(buf, name)
    local chan = vim.api.nvim_open_term(buf, {})

    local push = function(line) vim.api.nvim_chan_send(chan, line) end

    for _, line in ipairs(data) do
        push(string.format("%s\r\n", line))
    end

    push "\r\n ---- Press q to quit ----- \r\n"
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", {})

    return win, buf
end

local function floating(lines, ft)
    -- If empty table, just return
    if #lines == 0 then return end

    -- Create a new buffer that is unlisted and not associated with a file
    local buf = vim.api.nvim_create_buf(false, true)

    -- Instructions to close
    table.insert(lines, "")
    table.insert(lines, "Press 'q' to close the window")

    -- Ensure the buffer contains the provided text lines
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Calculate the window size based on the longest line and number of lines
    local width = 0
    for _, line in ipairs(lines) do
        if #line > width then width = #line end
    end
    local height = #lines

    -- Define the maximum size for the window (80% of the screen)
    local max_width = math.floor(vim.o.columns * 0.8)
    local max_height = math.floor(vim.o.lines * 0.8)

    -- Ensure the window size does not exceed the screen limits
    width = math.min(width, max_width)
    height = math.min(height, max_height)

    -- Calculate the starting position for the floating window (centered)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Set up window options
    local opts = {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "double",
    }

    -- Create the floating window with the specified options
    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Make the buffer unmodifiable and no save prompts
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = "nofile"

    -- Set filetype
    vim.bo[buf].filetype = ft

    -- Set keybinding to close the window with `q`
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>bd!<CR>", { noremap = true, silent = true })

    -- Optionally, set transparency and other window options
    vim.wo[win].winblend = 10

    return buf, win
end

local function floating_file(path)
    -- Find filetype
    local ft = path:match "^.+%.(.+)$"

    -- Read file
    local lines = {}
    local file = io.open(path, "r")
    if file then
        for line in file:lines() do
            table.insert(lines, line)
        end
        file:close()
    else
        -- Handle error if the file can't be read
        table.insert(lines, "Error: Unable to open the file.")
    end

    floating(lines, ft)
end

M.floating = floating
M.floating_file = floating_file
M.popup = popup
return M
