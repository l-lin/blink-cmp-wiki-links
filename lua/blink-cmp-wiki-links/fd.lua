---@class blink-ripgrep.FdBackend
---@field opts blink-cmp-wiki-links.Options
local FdBackend = {}

---@param opts blink-cmp-wiki-links.Options
---@return blink-ripgrep.FdBackend
function FdBackend.new(opts)
  local self = setmetatable({}, { __index = FdBackend })
  self.opts = opts
  return self
end

---Get workspace root directory
---@return string
function FdBackend:get_workspace_root()
  if
    self.opts.get_workspace_root
    and type(self.opts.get_workspace_root) == "function"
  then
    return self.opts.get_workspace_root()
  end

  -- Try to find common workspace indicators
  local indicators = { ".git", "README.md" }

  local current_dir = vim.fn.expand("%:p:h")
  while current_dir ~= "/" do
    for _, indicator in ipairs(indicators) do
      if
        vim.fn.isdirectory(current_dir .. "/" .. indicator) == 1
        or vim.fn.filereadable(current_dir .. "/" .. indicator) == 1
      then
        return current_dir
      end
    end
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end

  -- Fallback to current working directory
  return vim.fn.getcwd()
end

---Build fd command with options and prefix
---@param prefix string|nil the prefix to search for
---@return string[] the fd command array
function FdBackend:build_fd_command(prefix)
  local cmd = { "fd" }

  -- Add file extensions
  for _, filetype in ipairs(self.opts.filetypes) do
    table.insert(cmd, "-e")
    table.insert(cmd, filetype)
  end

  -- Add exclusions
  for _, exclude in ipairs(self.opts.exclude_paths) do
    table.insert(cmd, "-E")
    table.insert(cmd, exclude)
  end

  -- Add prefix filter
  if prefix and #prefix > 0 then
    table.insert(cmd, prefix)
  end

  return cmd
end

---@param self blink-ripgrep.FdBackend
---@param prefix string the prefix to search for
---@param callback fun(response?: blink.cmp.CompletionResponse) callback to resolve the completion response
function FdBackend:get_matches(prefix, callback)
  local cmd = self:build_fd_command(prefix)

  -- Execute the command and process results
  local fd = vim.system(cmd, { cwd = vim.uv.cwd() or "" }, function(result)
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
