# blink-cmp-wiki-links

A [blink.cmp](https://github.com/Saghen/blink.cmp) completion source that provides fuzzy matching for markdown file names and automatically formats them as wiki links (`[[filename]]`).

## ✨ Features

- **Always-on completion**: No need to type `[[` - completions appear as you type
- **Fuzzy matching**: Powered by blink.cmp's performance-optimized fuzzy matcher  
- **Auto wiki-link formatting**: Accepted completions become `[[filename]]`
- **Smart workspace detection**: Automatically finds your notes workspace
- **Performance optimized**: Uses `fd` if available, with intelligent caching
- **Configurable**: Customize search paths, file patterns, and exclusions
- **Markdown-only**: Only activates in markdown files

## 📦 Installation
### 📝 Requirements

- Neovim 0.9+
- [blink.cmp](https://github.com/Saghen/blink.cmp)

__Optional dependencies__

- `fd`: For faster file discovery (highly recommended)
- `rg`: Alternative fast file discovery


### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "saghen/blink.cmp",
  dependencies = { "l-lin/blink-cmp-wiki-links" },
  opts = {
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "wiki_links" },
      providers = {
        wiki_links = {
          name = "WikiLinks",
          module = "blink-cmp-wiki-links",
          score_offset = 85, -- High priority for wiki links
        },
      },
    },
  },
}
```

### Using other plugin managers

1. Install the plugin using your preferred method
2. Add the wiki_links provider to your blink.cmp configuration

## ⚙️ Configuration

### Basic Setup

```lua
require('blink-cmp-wiki-links').setup({
  -- File patterns to search for
  file_patterns = { "*.md", "*.markdown" },

  -- Directories to search in (relative to workspace root)
  search_paths = { "." },
 
  -- Directories to exclude
  exclude_paths = { ".git", "node_modules", ".obsidian" },

  -- Maximum number of files to cache
  max_files = 1000,

  -- Whether to show file extensions in completion labels
  show_extensions = false,

  -- Whether to show full paths in details
  show_full_paths = true,
})
```

### Advanced Configuration

```lua
{
  "saghen/blink.cmp",
  dependencies = {
    "your-username/blink-cmp-wiki-links",
  },
  opts = {
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "wiki_links" },
      providers = {
        wiki_links = {
          name = "WikiLinks",
          module = "blink-cmp-wiki-links",
          opts = {
            -- Custom file patterns
            file_patterns = { "*.md", "*.txt", "*.org" },

            -- Multiple search directories
            search_paths = { "notes", "docs", "journal" },

            -- More exclusions
            exclude_paths = { ".git", ".obsidian", "assets", "images" },

            -- Custom workspace detection
            get_workspace_root = function()
              -- Look for .obsidian directory first
              local obsidian_root = vim.fs.find(".obsidian", { upward = true })[1]
              if obsidian_root then
                return vim.fs.dirname(obsidian_root)
              end
              -- Fallback to git root
              return vim.fs.find(".git", { upward = true })[1] and 
                     vim.fs.dirname(vim.fs.find(".git", { upward = true })[1]) or
                     vim.fn.getcwd()
            end,
          },
          score_offset = 85,
          min_keyword_length = 2,
        },
      },
    },
  },
}
```

## 🚀 Usage

1. Open any markdown file in your workspace
2. Start typing a filename
3. Select from the fuzzy-matched completions
4. The selected filename becomes `[[filename]]` automatically

## 🔧 Workspace Detection

The plugin automatically detects your workspace using these indicators (in order):

1. `.git` directory (Git repository)
2. `README.md` file
3. Current working directory (fallback)

You can override this behavior with a custom `get_workspace_root` function.

## ⚡ Performance

- **Caching**: File list cached for 5 seconds to avoid repeated scans
- **Smart commands**: Uses `fd` if available, falls back to `find`
- **Configurable limits**: Set `max_files` to control memory usage
- **Efficient exclusions**: Directory exclusions applied during scanning

## 📃 TODO

- [ ] display only 10 elements (configurable)
- [ ] add GIF in README
- [ ] display relative path in the preview
- [ ] display 20 lines of the preview (check how `path` source is implemented)
- [ ] add another icon (configurable)

## 📄 License

MIT License - see LICENSE file for details.

