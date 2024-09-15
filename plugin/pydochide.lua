-- Ensure the plugin is loaded only once
if vim.g.loaded_pydochide == true then
  return
end
vim.g.loaded_pydochide = true

-- Load the main module
require('pydochide')
