---@class blink-cmp-wiki-links.FdBackend : blink-cmp-wiki-links.Backend
---@field wiki_links_opts blink-cmp-wiki-links.Options
local FdBackend = {}

---@param wiki_links_opts blink-cmp-wiki-links.Options
---@return blink-cmp-wiki-links.FdBackend
function FdBackend.new(wiki_links_opts)
  local self = setmetatable({}, { __index = FdBackend })
  self.wiki_links_opts = wiki_links_opts
  return self
end

---Build fd command with options and prefix
---@param self blink-cmp-wiki-links.FdBackend
---@param prefix string|nil the prefix to search for
---@return string[] the fd command array
function FdBackend:build_fd_command(prefix)
  local cmd = { "fd" }

  -- Add custom fd options first
  for _, option in ipairs(self.wiki_links_opts.fd_opts.additional_fd_options) do
    table.insert(cmd, option)
  end

  -- Add file extensions
  for _, filetype in ipairs(self.wiki_links_opts.filetypes) do
    table.insert(cmd, "-e")
    table.insert(cmd, filetype)
  end

  -- Add exclusions
  for _, exclude in ipairs(self.wiki_links_opts.exclude_paths) do
    table.insert(cmd, "-E")
    table.insert(cmd, exclude)
  end

  -- Add prefix filter
  if prefix and #prefix > 0 then
    table.insert(cmd, prefix)
  end

  return cmd
end

---@param self blink-cmp-wiki-links.FdBackend
---@param prefix string the prefix to search for
---@param callback fun(response?: blink.cmp.CompletionResponse) callback to resolve the completion response
function FdBackend:get_matches(prefix, callback)
  local cmd = self:build_fd_command(prefix)

  local root = vim.fs.root(0, self.wiki_links_opts.project_root_marker) or vim.fn.getcwd()

  -- Execute the command and process results
  local fd = vim.system(cmd, { cwd = root }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback()
        return
      end

      local lines = vim.split(result.stdout, "\n")

      local items = {}
      for _, file_path in ipairs(lines) do
        if file_path ~= "" then
          local label = vim.fn.fnamemodify(file_path, ":t:r")
          table.insert(items, {
            label = label,
            kind = vim.lsp.protocol.CompletionItemKind.File,
            kind_icon = self.wiki_links_opts.kind_icon,
            insertText = "[[" .. label .. "]]",
            insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
            detail = file_path,
            documentation = "Link to: " .. file_path,
          })
        end
      end

      vim.schedule(function()
        callback({
          is_incomplete_forward = true,
          is_incomplete_backward = true,
          items = vim.tbl_values(items),
        })
      end)
    end)
  end)

  return function()
    fd:kill(9)
  end
end

return FdBackend
