---@class blink-cmp-wiki-links.CombinedBackend : blink-cmp-wiki-links.Backend
---@field wiki_links_opts blink-cmp-wiki-links.Options
---@field fd_backend blink-cmp-wiki-links.FdBackend
---@field rg_backend blink-cmp-wiki-links.RgBackend
local CombinedBackend = {}

---@param wiki_links_opts blink-cmp-wiki-links.Options
---@return blink-cmp-wiki-links.CombinedBackend
function CombinedBackend.new(wiki_links_opts)
  local self = setmetatable({}, { __index = CombinedBackend })
  self.wiki_links_opts = wiki_links_opts

  self.fd_backend = require("blink-cmp-wiki-links.fd").new(wiki_links_opts)
  self.rg_backend = require("blink-cmp-wiki-links.rg").new(wiki_links_opts)

  return self
end

---@param self blink-cmp-wiki-links.CombinedBackend
---@param prefix string the prefix to search for
---@param callback fun(response?: blink.cmp.CompletionResponse) callback to resolve the completion response
function CombinedBackend:get_matches(prefix, callback)
  local items_by_label = {}
  local completed_backends = 0
  local total_backends = 2
  local cancel_functions = {}

  local function check_completion()
    completed_backends = completed_backends + 1
    if completed_backends == total_backends then
      -- Convert map back to array
      local combined_items = {}
      for _, item in pairs(items_by_label) do
        table.insert(combined_items, item)
      end

      callback({
        is_incomplete_forward = true,
        is_incomplete_backward = true,
        items = combined_items,
      })
    end
  end

  -- Get fd results first, its priority is higher than rg results
  local fd_cancel = self.fd_backend:get_matches(prefix, function(fd_response)
    if fd_response and fd_response.items then
      for _, item in ipairs(fd_response.items) do
        items_by_label[item.label] = item
      end
    end
    check_completion()
  end)

  if fd_cancel then
    table.insert(cancel_functions, fd_cancel)
  end

  -- Get rg results (lower priority, don't overwrite existing)
  local rg_cancel = self.rg_backend:get_matches(prefix, function(rg_response)
    if rg_response and rg_response.items then
      for _, item in ipairs(rg_response.items) do
        -- Only add if not already present (fd has priority)
        if not items_by_label[item.label] then
          items_by_label[item.label] = item
        end
      end
    end
    check_completion()
  end)

  if rg_cancel then
    table.insert(cancel_functions, rg_cancel)
  end

  -- Return combined cancellation function
  return function()
    for _, cancel_fn in ipairs(cancel_functions) do
      if cancel_fn then
        cancel_fn()
      end
    end
  end
end

return CombinedBackend

