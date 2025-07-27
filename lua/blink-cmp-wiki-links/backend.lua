---A backend defines how to fetch wiki links.
---@class blink-cmp-wiki-links.Backend
---@field wiki_links_opts blink-cmp-wiki-links.Options
local Backend = {}

--- start a search process. Return an optional cancellation function that kills
--- the search in case the user has canceled the completion.
---@param prefix string
---@param callback fun(response?: blink.cmp.CompletionResponse)
---@return nil | fun(): nil
-- selene: allow(unused_variable)
---@diagnostic disable-next-line: unused-local
function Backend:get_matches(prefix, callback)
  -- This function should be overridden by the backend
  error("get_matches not implemented in backend")
end
