# blink-cmp-wiki-links

A [blink.cmp](https://github.com/Saghen/blink.cmp) completion source that provides fuzzy matching for markdown file names and automatically formats them as wiki links (`[[filename]]`).

## ✨ Features

- **Always-on completion**: No need to type `[[` - completions appear as you type
- **Fuzzy matching**: Powered by blink.cmp's performance-optimized fuzzy matcher
- **Auto wiki-link formatting**: Accepted completions become `[[filename]]`
- **Smart workspace detection**: Automatically finds your notes workspace
- **Performance optimized**: Uses `fd` for fast file discovery
- **Configurable**: Customize filetypes, exclusions, and workspace detection
- **File preview**: Shows file content preview in documentation
- **Minimum prefix length**: Configurable minimum characters before search starts

## 📦 Installation
### 📝 Requirements

- Neovim 0.9+
- [blink.cmp](https://github.com/Saghen/blink.cmp)

__Required dependencies__

- `fd`: For fast file discovery (required, not optional)

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
2. Add the `wiki_links` provider to your `blink.cmp` configuration

## ⚙️ Configuration

The configuration of blink-cmp-wiki-links needs to be embedded into the
configuration for blink:

```lua
{
  "saghen/blink.cmp",
  dependencies = {
    "l-lin/blink-cmp-wiki-links",
  },
  opts = {
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "wiki_links" },
      providers = {
        wiki_links = {
          name = "WikiLinks",
          module = "blink-cmp-wiki-links",
          opts = {
            -- Enable for additional file types
            filetypes = { "markdown", "md", "txt" },
            -- More exclusions
            exclude_paths = { ".git", ".obsidian", "assets", "images", ".trash" },
            -- Specifies how to find the root of the project where the fd
            -- search will start from. Accepts the same options as the marker
            -- given to `:h vim.fs.root()` which offers many possibilities for
            -- configuration. If none can be found, defaults to Neovim's cwd.
            --
            -- Examples:
            -- - ".git" (default)
            -- - { ".git", "package.json", ".root" }
            project_root_marker = ".git",
            -- Require more characters before searching
            prefix_min_len = 3,
            -- Show more lines in preview
            preview_line_length = 20,
            -- Custom icon for the completion item kind
            kind_icon = "",
            fd_opts = {
              -- Additional options to pass to the fd command
              additional_fd_options = { "--hidden", "--follow", "--max-depth", "3" },
            }
          },
          score_offset = 85,
        },
      },
    },
  },
}
```

## 🚀 Usage

1. Open any file with a supported filetype (markdown, md by default)
2. Start typing a filename (minimum 3 characters by default)
3. Select from the fuzzy-matched completions
4. The selected filename becomes `[[filename]]` automatically
5. Hover over completions to see file content preview

## ⚡ Performance

- **Fast file discovery**: Uses `fd` command for efficient file searching
- **Prefix filtering**: Only searches when minimum prefix length is met
- **Lazy preview loading**: File content loaded only when needed for documentation
- **Efficient exclusions**: Directory exclusions applied during `fd` scanning

## 📃 TODO

- [x] Basic wiki link completion
- [x] File content preview
- [x] Configurable filetypes
- [x] Workspace detection
- [x] Display relative path in the preview
- [x] Add option to add more options to `fd`
- [ ] take into account space in autocompletion
- [ ] Add GIF in README
- [x] Add configurable kind icon
- [ ] Add `rg` to find all references to the prefix having `[[text]]` in another files and that do not have any file
  - [ ] Display preview of the file and display the part where the text was found

## 📄 License

MIT License - see LICENSE file for details.

## 👏 Acknowledgements

- [obsidian-various-complements-plugin](https://github.com/tadashi-aikawa/obsidian-various-complements-plugin) for its ingenious feature of automatically adding wiki links, allowing writers to easily link files without having to remember if a file with that name already exists, and enabling them to maintain their writing flow.
- [blink-ripgrep](https://github.com/mikavilpas/blink-ripgrep.nvim) served as inspiration for this codebase.
