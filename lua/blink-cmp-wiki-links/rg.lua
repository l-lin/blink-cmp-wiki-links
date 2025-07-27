---@class blink-cmp-wiki-links.RgBackend : blink-cmp-wiki-links.Backend
---@field wiki_links_opts blink-cmp-wiki-links.Options
local RgBackend = {}

---@param wiki_links_opts blink-cmp-wiki-links.Options
---@return blink-cmp-wiki-links.RgBackend
function RgBackend.new(wiki_links_opts)
  local self = setmetatable({}, { __index = RgBackend })
  self.wiki_links_opts = wiki_links_opts
  return self
end

---Build rg command with options and prefix
---@param self blink-cmp-wiki-links.RgBackend
---@param prefix string|nil the prefix to search for
---@param root string the root directory to search in
---@return string[] the fd command array
function RgBackend:build_rg_command(prefix, root)
  local cmd = {
    "rg",
    "--only-matching",
    "--line-number",
    "--no-heading",
    "--no-config",
    "--word-regexp",
    "--max-filesize=" .. self.wiki_links_opts.rg_opts.max_filesize,
    self.wiki_links_opts.rg_opts.search_casing,
  }

  for _, option in ipairs(self.wiki_links_opts.rg_opts.additional_rg_options) do
    table.insert(cmd, option)
  end

  -- Add file extensions
  for _, filetype in ipairs(self.wiki_links_opts.filetypes) do
    table.insert(cmd, "--glob")
    table.insert(cmd, "*." .. filetype)
  end

  -- Add exclusions
  for _, exclude in ipairs(self.wiki_links_opts.exclude_paths) do
    table.insert(cmd, "--glob")
    table.insert(cmd, "!" .. exclude)
  end

  table.insert(cmd, "--")
  table.insert(cmd, "\\[\\[" .. prefix .. "[^\\]]*\\]\\]")

  table.insert(cmd, root)

  return cmd
end

---@class blink-cmp-wiki-links.RgOutput
---@field filepath string the file path
---@field line_number integer the line number
---@field match string the matched text

---@param self blink-cmp-wiki-links.RgBackend
---@param line string the line to parse, in the format "filepath:line_number:match"
---@return blink-cmp-wiki-links.RgOutput|nil
function RgBackend:parse_line(line)
  local filepath, line_number, match = line:match("^(.-):(%d+):(.*)$")
  if not filepath or not line_number or not match then
    return nil
  end

  return {
    filepath = filepath:gsub(
      "^" .. vim.pesc(self.wiki_links_opts.project_root_marker) .. "/",
      ""
    ),
    line_number = tonumber(line_number),
    -- Remove the leading [[ and trailing ]] returned by rg
    match = match:gsub("^%[%[", ""):gsub("%]%]$", ""),
  }
end

---@param self blink-cmp-wiki-links.RgBackend
---@param lines string[] the lines to parse
---@return blink-cmp-wiki-links.RgOutput[] unique outputs
function RgBackend:parse_lines(lines)
  local outputs = {}
  local seen = {}

  for _, line in ipairs(lines) do
    if line ~= "" then
      local output = self:parse_line(line)
      if output and not seen[output.match] then
        seen[output.match] = true
        table.insert(outputs, output)
      end
    end
  end

  return outputs
end

---@param self blink-cmp-wiki-links.RgBackend
---@param prefix string the prefix to search for
---@param callback fun(response?: blink.cmp.CompletionResponse) callback to resolve the completion response
function RgBackend:get_matches(prefix, callback)
  local root = vim.fs.root(0, self.wiki_links_opts.project_root_marker) or vim.fn.getcwd()

  local cmd = self:build_rg_command(prefix, root)

  -- Execute the command and process results
  local rg = vim.system(cmd, { cwd = root }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback()
        return
      end

      local outputs = self:parse_lines(vim.split(result.stdout, "\n"))

      local items = {}
      for _, output in ipairs(outputs) do
        table.insert(items, {
          label = output.match,
          kind = vim.lsp.protocol.CompletionItemKind.File,
          kind_icon = self.wiki_links_opts.kind_icon,
          insertText = "[[" .. output.match .. "]]",
          insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
          detail = output.filepath,
        })
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
    rg:kill(9)
  end
end

return RgBackend
