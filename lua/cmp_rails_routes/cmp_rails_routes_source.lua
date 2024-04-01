local debounce = require('telescope.debounce').debounce_leading
local Job = require 'plenary.job'
local script_path = vim.fn.stdpath 'config' .. '/scripts/rails_routes_to_json.rb'
local items = {}
local w = vim.loop.new_fs_event()

local function create_text_label_with_params(base_label, params)
  if #params == 0 then
    return base_label
  end

  local label = base_label .. '('

  for i, param in ipairs(params) do
    label = label .. ':' .. param
    if i < #params then
      label = label .. ', '
    end
  end

  return label .. ')'
end

local function create_snippet_label_with_params(base_label, params)
  if #params == 0 then
    return base_label
  end

  local label = base_label .. '(${1:' .. params[1] .. '}'

  for i = 2, #params do
    label = label .. ', ${' .. i .. ':' .. params[i] .. '}'
  end
  return label .. ')'
end

local function start_watching_routes()
  if w then
    w:stop()
  else
    w = vim.loop.new_fs_event()
  end

  local on_change, watch_file
  on_change = debounce(function(err)
    if err then
      w:stop()
      return
    end

    Job:new({
      command = 'bundle',
      args = { 'exec', 'ruby', script_path },
      on_exit = function(j, return_val)
        if return_val == 0 then
          local ok, routes = pcall(vim.json.decode, table.concat(j:result(), '\n'))
          if ok then
            items = {}
            for _, route in ipairs(routes) do
              local url_menu_label = create_text_label_with_params(string.format('%s_url', route.route), route.required_parts)
              local url_insert_text = create_snippet_label_with_params(string.format('%s_url', route.route), route.required_parts)
              table.insert(items, {
                label = url_menu_label,
                kind = vim.lsp.protocol.CompletionItemKind.Method,
                insertText = url_insert_text,
                insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
              })
              local path_menu_label = create_text_label_with_params(string.format('%s_path', route.route), route.required_parts)
              local path_insert_text = create_snippet_label_with_params(string.format('%s_path', route.route), route.required_parts)
              table.insert(items, {
                label = path_menu_label,
                kind = vim.lsp.protocol.CompletionItemKind.Method,
                insertText = path_insert_text,
                insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
              })
            end
          else
            print 'Fehler beim Decodieren der JSON-Ausgabe'
          end
        else
          print('Ruby-Skript fehlgeschlagen mit return_val: ', return_val)
        end
      end,
    }):start()
  end, 1000)

  watch_file = function(fname)
    local fullpath = vim.api.nvim_call_function('fnamemodify', { fname, ':p' })
    w:start(fullpath, { recursive = true }, on_change)
  end

  on_change(nil)
  watch_file 'config/'
end

local function stop_watching_routes()
  w:stop()
  w = nil
end

local source = {}

source.complete = function(self, _, callback)
  callback(items)
end

source.is_available = function()
  return vim.bo.filetype == 'eruby' or vim.bo.filetype == 'slim'
end

vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Searching for rails routes to provide helper names',
  group = vim.api.nvim_create_augroup('rails-route-helpers', { clear = true }),
  callback = function()
    if vim.fn.filereadable 'Gemfile' > 0 then
      start_watching_routes()
    end
  end,
})

require('cmp').register_source('rails_route_helpers', source)
