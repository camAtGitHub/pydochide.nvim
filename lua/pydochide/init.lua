-- File: py_doc_hide.lua

-- Prevent multiple loads
if vim.g.loaded_py_doc_hide then
    return
end
vim.g.loaded_py_doc_hide = true

local M = {}

-- Function to create folds around Python docstrings
function M.PyDocHide()
    -- Ensure the current buffer is a Python file
    if vim.bo.filetype ~= 'python' then
        vim.api.nvim_echo({{"[PyDocHide] Not a Python file.", "WarningMsg"}}, false, {})
        return
    end

    -- Set foldmethod to manual
    vim.wo.foldmethod = 'manual'

    -- Clear existing manual folds
    vim.cmd('normal! zE')

    -- Get the parser for the current buffer
    local parser = vim.treesitter.get_parser(0, 'python')
    if not parser then
        vim.api.nvim_echo({{"[PyDocHide] Tree-sitter parser not found for Python.", "ErrorMsg"}}, false, {})
        return
    end

    local tree = parser:parse()[1]
    if not tree then
        vim.api.nvim_echo({{"[PyDocHide] Failed to parse the buffer.", "ErrorMsg"}}, false, {})
        return
    end

    local root = tree:root()

    -- Function to recursively traverse the tree and find docstrings
    local function traverse(node)
        local node_type = node:type()

        if node_type == 'function_definition' or node_type == 'class_definition' then
            -- Get the body of the function or class
            local body = nil
            for child in node:iter_children() do
                if child:type() == 'block' then
                    body = child
                    break
                end
            end

            if body then
                -- The first child of the body might be the docstring
                local first_child = body:child(0)
                if first_child and first_child:type() == 'expression_statement' then
                    local string_node = first_child:child(0)
                    if string_node and string_node:type() == 'string' then
                        -- Get the range of the docstring
                        local start_row, _, end_row, _ = string_node:range()

                        -- Tree-sitter uses 0-based indexing for rows
                        local start_line = start_row + 1
                        local end_line = end_row + 1

                        -- Create a fold from start_line to end_line
                        -- Ensure start_line is less than end_line
                        if start_line < end_line then
                            vim.cmd(string.format('%d,%dfold', start_line, end_line))
                        end
                    end
                end
            end
        end

        -- Recursively traverse children
        for child in node:iter_children() do
            traverse(child)
        end
    end

    -- Start traversal from the root
    traverse(root)
end

-- Define the :PyDocHide command
vim.api.nvim_create_user_command('PyDocHide', M.PyDocHide, {})

-- Optionally, you can disable the automatic runnning of PyDocHide when a Python file is opened
-- Comment the following lines if desired

vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
        M.PyDocHide()
    end
})

return M
