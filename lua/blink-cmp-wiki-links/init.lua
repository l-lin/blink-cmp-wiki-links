---@module "blink.cmp"

---@class blink-cmp-wiki-links.Options
---@field filetypes string[] Filetypes to enable this source for (e.g., {"markdown", "md"})
---@field exclude_paths string[] Directories to exclude from search
---@field project_root_marker? unknown Specifies how to find the root of the project where fd search will start from. Accepts the same options as the marker given to `:h vim.fs.root()` which offers many possibilities for configuration. Defaults to ".git".
---@field prefix_min_len number The minimum length of the current word to start searching (if the word is shorter than this, the search will not start)
---@field preview_line_length number The maximum number of lines to show in the preview (default: 20)
---@field kind_icon? string Icon to use for the completion item kind (default: "")
---@field fd_opts blink-cmp-wiki-links.FdOptions # Options for fd search,
---@field rg_opts blink-cmp-wiki-links.RgOptions # Options for ripgrep search,

---@class blink-cmp-wiki-links.FdOptions
---@field additional_fd_options string[] Additional options to pass to the fd command (default: {})

---@class blink-cmp-wiki-links.RgOptions
---@field max_filesize? string # The maximum file size that ripgrep should include in its search. Examples: "1024" (bytes by default), "200K", "1M", "1G"
---@field search_casing? string # The casing to use for the search in a format that ripgrep accepts. Defaults to "--ignore-case". See `rg --help` for all the available options ripgrep supports, but you can try "--case-sensitive" or "--smart-case".
---@field additional_rg_options string[] Additional options to pass to the rg command (default: {})

---@class blink-cmp-wiki-links.WikiLinksSource : blink.cmp.Source
---@field wiki_links_opts blink-cmp-wiki-links.Options
local WikiLinksSource = {}
WikiLinksSource.__index = WikiLinksSource

---@type blink-cmp-wiki-links.Options
WikiLinksSource.wiki_links_opts = {
  filetypes = { "markdown", "md" },
  exclude_paths = { ".git", "node_modules", ".obsidian", ".trash" },
  project_root_marker = ".git",
  prefix_min_len = 3,
  preview_line_length = 20,
  kind_icon = "",
  fd_opts = {
    additional_fd_options = {},
  },
  rg_opts = {
    max_filesize = "1M",
    search_casing = "--ignore-case",
    additional_rg_options = {},
  },
}

---@param input_wiki_links_opts blink-cmp-wiki-links.Options
function WikiLinksSource.new(input_wiki_links_opts)
  local self = setmetatable({}, WikiLinksSource)
  WikiLinksSource.wiki_links_opts =
    vim.tbl_deep_extend("force", WikiLinksSource.wiki_links_opts, input_wiki_links_opts or {})
  return self
end

---Extract the prefix from the context.
---The prefix is the current word being typed in the editor, so it can be in the
---middle of a line.
---@self blink-cmp-wiki-links.WikiLinksSource
---@param context blink.cmp.Context
function WikiLinksSource:get_prefix(context)
  local prefix = ""
  if context.bounds and context.bounds.length > 0 then
    prefix = context.line:sub(
      context.bounds.start_col,
      context.bounds.start_col + context.bounds.length - 1
    )
  end
  return prefix
end


-- Check if the source should be enabled in current context
---@param self blink.cmp.Source
---@return boolean
function WikiLinksSource:enabled()
  local filetype = vim.bo.filetype
  return vim.tbl_contains(WikiLinksSource.wiki_links_opts.filetypes, filetype)
end

-- Main completion method with callback
---@param self blink-cmp-wiki-links.WikiLinksSource
---@param ctx blink.cmp.Context
---@param callback fun(self: blink.cmp.CompletionResponse): nil
function WikiLinksSource:get_completions(ctx, callback)
  local prefix = self:get_prefix(ctx)

  if string.len(prefix) < self.wiki_links_opts.prefix_min_len then
    callback({
      items = {},
      is_incomplete_forward = true,
      is_incomplete_backward = false,
    })
    return
  end

  local backend = require("blink-cmp-wiki-links.combined").new(WikiLinksSource.wiki_links_opts)
  local cancellation_function = backend:get_matches(prefix, callback)
  return cancellation_function
end

-- Resolve completion items before accepting or showing documentation
-- Before accepting the item or showing documentation, blink.cmp will call this function
-- so you may avoid calculating expensive fields (i.e. documentation) for only when they're actually needed
---@param self blink-cmp-wiki-links.WikiLinksSource
---@param item blink.cmp.CompletionItem
---@param callback blink.cmp.CompletionResponse
function WikiLinksSource:resolve(item, callback)
  item = vim.deepcopy(item)

  -- read all file content
  local ok, text = pcall(vim.fn.readfile, item.detail, "", self.wiki_links_opts.preview_line_length)
  text = ok and text or {}
  item.documentation = {
    kind = "markdown",
    value = table.concat(text, "\n"),
  }
  callback(item)
end

return WikiLinksSource
