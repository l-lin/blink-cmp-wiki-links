-- Mock vim global for testing
_G.vim = {
  fn = {
    expand = function() return "/test/path" end,
    isdirectory = function() return 0 end,
    filereadable = function() return 0 end,
    fnamemodify = function(path)
      if path == "/test/path" then return "/" end
      return path
    end,
    getcwd = function() return "/test/workspace" end
  },
  uv = {
    cwd = function() return "/test/workspace" end
  },
  system = function() return {} end,
  schedule = function(fn) fn() end,
  split = function() return {} end,
  lsp = {
    protocol = {
      CompletionItemKind = { File = 1 },
      InsertTextFormat = { PlainText = 1 }
    }
  },
  tbl_values = function(tbl) return tbl end
}

local FdBackend = require("blink-cmp-wiki-links.fd")

describe("FdBackend", function()
  describe("build_fd_command", function()
    it("should build basic fd command with minimal options", function()
      local opts = {
        filetypes = {},
        exclude_paths = {}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command(nil)

      assert.are.same({"fd"}, result)
    end)

    it("should add single file extension", function()
      local opts = {
        filetypes = {"md"},
        exclude_paths = {}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command(nil)

      assert.are.same({"fd", "-e", "md"}, result)
    end)

    it("should add multiple file extensions", function()
      local opts = {
        filetypes = {"md", "markdown", "txt"},
        exclude_paths = {}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command(nil)

      assert.are.same({"fd", "-e", "md", "-e", "markdown", "-e", "txt"}, result)
    end)

    it("should add single exclusion", function()
      local opts = {
        filetypes = {},
        exclude_paths = {".git"}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command(nil)

      assert.are.same({"fd", "-E", ".git"}, result)
    end)

    it("should add multiple exclusions", function()
      local opts = {
        filetypes = {},
        exclude_paths = {".git", "node_modules", ".obsidian"}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command(nil)

      assert.are.same({"fd", "-E", ".git", "-E", "node_modules", "-E", ".obsidian"}, result)
    end)

    it("should add prefix when provided", function()
      local opts = {
        filetypes = {},
        exclude_paths = {}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command("test")

      assert.are.same({"fd", "test"}, result)
    end)

    it("should not add prefix when nil", function()
      local opts = {
        filetypes = {},
        exclude_paths = {}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command(nil)

      assert.are.same({"fd"}, result)
    end)

    it("should not add prefix when empty string", function()
      local opts = {
        filetypes = {},
        exclude_paths = {}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command("")

      assert.are.same({"fd"}, result)
    end)

    it("should handle complex scenario with all options", function()
      local opts = {
        filetypes = {"md", "markdown"},
        exclude_paths = {".git", "node_modules"}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command("wiki")

      assert.are.same({
        "fd",
        "-e", "md",
        "-e", "markdown",
        "-E", ".git",
        "-E", "node_modules",
        "wiki"
      }, result)
    end)

    it("should preserve order of extensions and exclusions", function()
      local opts = {
        filetypes = {"txt", "md", "org"},
        exclude_paths = {"dist", ".git", "build"}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command("search")

      assert.are.same({
        "fd",
        "-e", "txt",
        "-e", "md",
        "-e", "org",
        "-E", "dist",
        "-E", ".git",
        "-E", "build",
        "search"
      }, result)
    end)

    it("should handle special characters in prefix", function()
      local opts = {
        filetypes = {"md"},
        exclude_paths = {}
      }
      local backend = FdBackend.new(opts)

      local result = backend:build_fd_command("wiki-link")

      assert.are.same({"fd", "-e", "md", "wiki-link"}, result)
    end)
  end)
end)
