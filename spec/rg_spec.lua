-- Mock vim global for testing
_G.vim = {
  fn = {
    expand = function()
      return "/test/path"
    end,
    isdirectory = function()
      return 0
    end,
    filereadable = function()
      return 0
    end,
    fnamemodify = function(path)
      if path == "/test/path" then
        return "/"
      end
      return path
    end,
    getcwd = function()
      return "/test/workspace"
    end,
  },
  uv = {
    cwd = function()
      return "/test/workspace"
    end,
  },
  system = function()
    return {}
  end,
  schedule = function(fn)
    fn()
  end,
  split = function()
    return {}
  end,
  lsp = {
    protocol = {
      CompletionItemKind = { File = 1 },
      InsertTextFormat = { PlainText = 1 },
    },
  },
  tbl_values = function(tbl)
    return tbl
  end,
  tbl_contains = function(tbl, value)
    for _, v in ipairs(tbl) do
      if v == value then
        return true
      end
    end
    return false
  end,
  pesc = function(str)
    return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
  end,
  fs = {
    root = function()
      return "/test/workspace"
    end,
  },
}

local RgBackend = require("blink-cmp-wiki-links.rg")

describe("RgBackend", function()
  describe("build_rg_command", function()
    it("should build basic rg command with minimal options", function()
      local opts = {
        filetypes = {},
        exclude_paths = {},
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--ignore-case",
          additional_rg_options = {},
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("test", "/workspace")

      local expected = {
        "rg",
        "--only-matching",
        "--line-number",
        "--no-heading",
        "--no-config",
        "--word-regexp",
        "--max-filesize=1M",
        "--ignore-case",
        "--",
        "\\[\\[test[^\\]]*\\]\\]",
        "/workspace",
      }
      assert.are.same(expected, result)
    end)

    it("should handle different max_filesize values", function()
      local opts = {
        filetypes = {},
        exclude_paths = {},
        rg_opts = {
          max_filesize = "500K",
          search_casing = "--ignore-case",
          additional_rg_options = {},
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("test", "/workspace")

      assert(vim.tbl_contains(result, "--max-filesize=500K"))
    end)

    it("should handle different search casing options", function()
      local opts = {
        filetypes = {},
        exclude_paths = {},
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--case-sensitive",
          additional_rg_options = {},
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("test", "/workspace")

      assert(vim.tbl_contains(result, "--case-sensitive"))
    end)

    it("should add single additional rg option", function()
      local opts = {
        filetypes = {},
        exclude_paths = {},
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--ignore-case",
          additional_rg_options = { "--hidden" },
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("test", "/workspace")

      assert(vim.tbl_contains(result, "--hidden"))
    end)

    it("should add multiple additional rg options", function()
      local opts = {
        filetypes = {},
        exclude_paths = {},
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--ignore-case",
          additional_rg_options = { "--hidden", "--follow", "--max-depth=3" },
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("test", "/workspace")

      assert(vim.tbl_contains(result, "--hidden"))
      assert(vim.tbl_contains(result, "--follow"))
      assert(vim.tbl_contains(result, "--max-depth=3"))
    end)

    it("should add single file extension as glob pattern", function()
      local opts = {
        filetypes = { "md" },
        exclude_paths = {},
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--ignore-case",
          additional_rg_options = {},
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("test", "/workspace")

      local glob_index = nil
      for i, arg in ipairs(result) do
        if arg == "--glob" and result[i + 1] == "*.md" then
          glob_index = i
          break
        end
      end
      assert.is_not_nil(glob_index)
    end)

    it("should add multiple file extensions as glob patterns", function()
      local opts = {
        filetypes = { "md", "markdown", "txt" },
        exclude_paths = {},
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--ignore-case",
          additional_rg_options = {},
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("test", "/workspace")

      local has_md = false
      local has_markdown = false
      local has_txt = false

      for i, arg in ipairs(result) do
        if arg == "--glob" then
          if result[i + 1] == "*.md" then
            has_md = true
          end
          if result[i + 1] == "*.markdown" then
            has_markdown = true
          end
          if result[i + 1] == "*.txt" then
            has_txt = true
          end
        end
      end

      assert.is_true(has_md)
      assert.is_true(has_markdown)
      assert.is_true(has_txt)
    end)

    it("should add single exclusion as negated glob pattern", function()
      local opts = {
        filetypes = {},
        exclude_paths = { ".git" },
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--ignore-case",
          additional_rg_options = {},
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("test", "/workspace")

      local has_exclude = false
      for i, arg in ipairs(result) do
        if arg == "--glob" and result[i + 1] == "!.git" then
          has_exclude = true
          break
        end
      end
      assert.is_true(has_exclude)
    end)

    it("should add multiple exclusions as negated glob patterns", function()
      local opts = {
        filetypes = {},
        exclude_paths = { ".git", "node_modules", ".obsidian" },
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--ignore-case",
          additional_rg_options = {},
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("test", "/workspace")

      local has_git = false
      local has_node_modules = false
      local has_obsidian = false

      for i, arg in ipairs(result) do
        if arg == "--glob" then
          if result[i + 1] == "!.git" then
            has_git = true
          end
          if result[i + 1] == "!node_modules" then
            has_node_modules = true
          end
          if result[i + 1] == "!.obsidian" then
            has_obsidian = true
          end
        end
      end

      assert.is_true(has_git)
      assert.is_true(has_node_modules)
      assert.is_true(has_obsidian)
    end)

    it("should generate correct regex pattern for prefix", function()
      local opts = {
        filetypes = {},
        exclude_paths = {},
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--ignore-case",
          additional_rg_options = {},
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("wiki-link", "/workspace")

      local pattern_index = nil
      for i, arg in ipairs(result) do
        if arg == "\\[\\[wiki-link[^\\]]*\\]\\]" then
          pattern_index = i
          break
        end
      end
      assert.is_not_nil(pattern_index)
    end)

    it("should handle empty string prefix", function()
      local opts = {
        filetypes = {},
        exclude_paths = {},
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--ignore-case",
          additional_rg_options = {},
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("", "/workspace")

      local pattern_index = nil
      for i, arg in ipairs(result) do
        if arg == "\\[\\[[^\\]]*\\]\\]" then
          pattern_index = i
          break
        end
      end
      assert.is_not_nil(pattern_index)
    end)

    it("should add root directory at the end", function()
      local opts = {
        filetypes = {},
        exclude_paths = {},
        rg_opts = {
          max_filesize = "1M",
          search_casing = "--ignore-case",
          additional_rg_options = {},
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("test", "/custom/root")

      assert.are.equal("/custom/root", result[#result])
    end)

    it("should handle complex scenario with all options", function()
      local opts = {
        filetypes = { "md", "markdown" },
        exclude_paths = { ".git", "node_modules" },
        rg_opts = {
          max_filesize = "2M",
          search_casing = "--smart-case",
          additional_rg_options = { "--hidden", "--follow" },
        },
      }
      local backend = RgBackend.new(opts)

      local result = backend:build_rg_command("wiki", "/workspace")

      -- Check basic structure
      assert(vim.tbl_contains(result, "rg"))
      assert(vim.tbl_contains(result, "--only-matching"))
      assert(vim.tbl_contains(result, "--max-filesize=2M"))
      assert(vim.tbl_contains(result, "--smart-case"))
      assert(vim.tbl_contains(result, "--hidden"))
      assert(vim.tbl_contains(result, "--follow"))
      assert.are.equal("/workspace", result[#result])
    end)
  end)

  describe("parse_line", function()
    it(
      "should parse valid line with filepath, line number, and match",
      function()
        local opts = {
          project_root_marker = ".git",
        }
        local backend = RgBackend.new(opts)

        local result = backend:parse_line("path/to/file.md:42:[[wiki-link]]")

        assert.are.same({
          filepath = "path/to/file.md",
          line_number = 42,
          match = "wiki-link",
        }, result)
      end
    )

    it("should remove project root marker from filepath", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line(".git/path/to/file.md:42:[[wiki-link]]")

      assert.are.same({
        filepath = "path/to/file.md",
        line_number = 42,
        match = "wiki-link",
      }, result)
    end)

    it("should remove leading [[ and trailing ]] from match", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line("file.md:1:[[some wiki link]]")

      assert.are.equal("some wiki link", result.match)
    end)

    it("should handle match without brackets", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line("file.md:1:plain text")

      assert.are.equal("plain text", result.match)
    end)

    it("should handle match with only leading brackets", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line("file.md:1:[[partial")

      assert.are.equal("partial", result.match)
    end)

    it("should handle match with only trailing brackets", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line("file.md:1:partial]]")

      assert.are.equal("partial", result.match)
    end)

    it("should parse line with empty filepath", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line(":42:[[wiki-link]]")

      assert.are.same({
        filepath = "",
        line_number = 42,
        match = "wiki-link",
      }, result)
    end)

    it("should return nil for malformed line missing line number", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line("file.md::[[wiki-link]]")

      assert.is_nil(result)
    end)

    it("should parse line with empty match", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line("file.md:42:")

      assert.are.same({
        filepath = "file.md",
        line_number = 42,
        match = "",
      }, result)
    end)

    it("should return nil for completely malformed line", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line("not a valid line format")

      assert.is_nil(result)
    end)

    it("should handle filepath with colons in the name", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result =
        backend:parse_line("path/to/file:with:colons.md:42:[[wiki-link]]")

      assert.are.same({
        filepath = "path/to/file:with:colons.md",
        line_number = 42,
        match = "wiki-link",
      }, result)
    end)

    it("should handle match with colons", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line("file.md:42:[[wiki:link:with:colons]]")

      assert.are.equal("wiki:link:with:colons", result.match)
    end)

    it("should convert line number to integer", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_line("file.md:123:[[wiki-link]]")

      assert.are.equal(123, result.line_number)
      assert.are.equal("number", type(result.line_number))
    end)
  end)

  describe("parse_lines", function()
    it("should parse multiple valid lines", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local lines = {
        "file1.md:1:[[link1]]",
        "file2.md:2:[[link2]]",
        "file3.md:3:[[link3]]",
      }

      local result = backend:parse_lines(lines)

      assert.are.equal(3, #result)
      assert.are.equal("link1", result[1].match)
      assert.are.equal("link2", result[2].match)
      assert.are.equal("link3", result[3].match)
    end)

    it("should skip empty lines", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local lines = {
        "file1.md:1:[[link1]]",
        "",
        "file2.md:2:[[link2]]",
      }

      local result = backend:parse_lines(lines)

      assert.are.equal(2, #result)
      assert.are.equal("link1", result[1].match)
      assert.are.equal("link2", result[2].match)
    end)

    it("should filter out invalid lines", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local lines = {
        "file1.md:1:[[link1]]",
        "invalid line format",
        "file2.md:2:[[link2]]",
      }

      local result = backend:parse_lines(lines)

      assert.are.equal(2, #result)
      assert.are.equal("link1", result[1].match)
      assert.are.equal("link2", result[2].match)
    end)

    it("should deduplicate matches by match content", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local lines = {
        "file1.md:1:[[duplicate-link]]",
        "file2.md:5:[[duplicate-link]]",
        "file3.md:10:[[unique-link]]",
      }

      local result = backend:parse_lines(lines)

      assert.are.equal(2, #result)
      assert.are.equal("duplicate-link", result[1].match)
      assert.are.equal("unique-link", result[2].match)
    end)

    it("should preserve order of first occurrence for duplicates", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local lines = {
        "file1.md:1:[[first-link]]",
        "file2.md:2:[[second-link]]",
        "file3.md:3:[[first-link]]",
      }

      local result = backend:parse_lines(lines)

      assert.are.equal(2, #result)
      assert.are.equal("first-link", result[1].match)
      assert.are.equal("file1.md", result[1].filepath)
      assert.are.equal("second-link", result[2].match)
    end)

    it("should handle empty input", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local result = backend:parse_lines({})

      assert.are.equal(0, #result)
    end)

    it("should handle mixed valid, invalid, and empty lines", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local lines = {
        "file1.md:1:[[valid1]]",
        "",
        "invalid format",
        "file2.md:2:[[valid2]]",
        "",
        "another:invalid",
        "file3.md:3:[[valid1]]",
      }

      local result = backend:parse_lines(lines)

      assert.are.equal(2, #result)
      assert.are.equal("valid1", result[1].match)
      assert.are.equal("valid2", result[2].match)
    end)

    it("should maintain structure of parsed output", function()
      local opts = {
        project_root_marker = ".git",
      }
      local backend = RgBackend.new(opts)

      local lines = {
        "path/to/file.md:42:[[wiki-link]]",
      }

      local result = backend:parse_lines(lines)

      assert.are.equal(1, #result)
      assert.are.same({
        filepath = "path/to/file.md",
        line_number = 42,
        match = "wiki-link",
      }, result[1])
    end)
  end)
end)
