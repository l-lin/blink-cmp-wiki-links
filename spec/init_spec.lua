-- Mock vim global for testing
_G.vim = {
  ---@diagnostic disable-next-line: unused-local
  tbl_deep_extend = function(behavior, tbl1, tbl2)
    local result = {}
    for k, v in pairs(tbl1) do
      result[k] = v
    end
    if tbl2 then
      for k, v in pairs(tbl2) do
        result[k] = v
      end
    end
    return result
  end,
  bo = {
    filetype = "markdown",
  },
  tbl_contains = function(tbl, value)
    for _, v in ipairs(tbl) do
      if v == value then
        return true
      end
    end
    return false
  end,
  fn = {
    readfile = function()
      return {}
    end,
    shellescape = function(str)
      -- Simple mock implementation for testing
      return "'" .. str:gsub("'", "'\\''") .. "'"
    end,
    system = function(cmd)
      -- Mock implementation based on command
      if cmd:match("test%-file%.md") then
        if cmd:match("sed %-n '3,7p'") then
          return "line 3\nline 4\nline 5\nline 6\nline 7\n"
        elseif cmd:match("sed %-n '1,5p'") then
          return "line 1\nline 2\nline 3\nline 4\nline 5\n"
        elseif cmd:match("sed %-n '10,14p'") then
          return "" -- Empty result for out of range
        end
      elseif cmd:match("nonexistent%.md") then
        _G.vim.v.shell_error = 1
        return ""
      end
      return ""
    end,
  },
  v = {
    shell_error = 0,
  },
  split = function(str, sep)
    local result = {}
    local pattern = string.format("([^%s]+)", sep)
    for match in str:gmatch(pattern) do
      table.insert(result, match)
    end
    return result
  end,
  deepcopy = function(tbl)
    return tbl
  end,
}

local WikiLinksSource = require("blink-cmp-wiki-links")

describe("WikiLinksSource", function()
  local source

  before_each(function()
    source = WikiLinksSource.new()
    _G.vim.v.shell_error = 0 -- Reset shell error before each test
  end)

  describe("get_prefix", function()
    it("should return empty string when context has no bounds", function()
      local context = {
        line = "some text here",
        bounds = nil,
      }

      local result = source:get_prefix(context)

      assert.are.equal("", result)
    end)

    it("should return empty string when bounds length is 0", function()
      local context = {
        line = "some text here",
        bounds = {
          start_col = 1,
          length = 0,
        },
      }

      local result = source:get_prefix(context)

      assert.are.equal("", result)
    end)

    it("should extract prefix from beginning of line", function()
      local context = {
        line = "hello world",
        bounds = {
          start_col = 1,
          length = 5,
        },
      }

      local result = source:get_prefix(context)

      assert.are.equal("hello", result)
    end)

    it("should extract prefix from middle of line", function()
      local context = {
        line = "hello world test",
        bounds = {
          start_col = 7,
          length = 5,
        },
      }

      local result = source:get_prefix(context)

      assert.are.equal("world", result)
    end)

    it("should extract single character prefix", function()
      local context = {
        line = "a",
        bounds = {
          start_col = 1,
          length = 1,
        },
      }

      local result = source:get_prefix(context)

      assert.are.equal("a", result)
    end)

    it("should extract prefix at end of line", function()
      local context = {
        line = "hello world",
        bounds = {
          start_col = 7,
          length = 5,
        },
      }

      local result = source:get_prefix(context)

      assert.are.equal("world", result)
    end)

    it("should handle partial word extraction", function()
      local context = {
        line = "testing partial word",
        bounds = {
          start_col = 9,
          length = 4,
        },
      }

      local result = source:get_prefix(context)

      assert.are.equal("part", result)
    end)

    it("should handle special characters in prefix", function()
      local context = {
        line = "test [[wiki-link]] more",
        bounds = {
          start_col = 8,
          length = 9,
        },
      }

      local result = source:get_prefix(context)

      assert.are.equal("wiki-link", result)
    end)

    it("should handle simple ascii characters only", function()
      local context = {
        line = "hello world test",
        bounds = {
          start_col = 7,
          length = 5,
        },
      }

      local result = source:get_prefix(context)

      assert.are.equal("world", result)
    end)

    it("should handle bounds that extend to exact end of line", function()
      local context = {
        line = "short",
        bounds = {
          start_col = 1,
          length = 5,
        },
      }

      local result = source:get_prefix(context)

      assert.are.equal("short", result)
    end)
  end)

  describe("get_file_preview", function()
    it("should return lines starting from specified line number", function()
      local result = source:get_file_preview("test-file.md", 3, 5)

      assert.are.same({
        "line 3",
        "line 4",
        "line 5",
        "line 6",
        "line 7",
      }, result)
    end)

    it("should return lines starting from line 1", function()
      local result = source:get_file_preview("test-file.md", 1, 5)

      assert.are.same({
        "line 1",
        "line 2",
        "line 3",
        "line 4",
        "line 5",
      }, result)
    end)

    it("should return empty array when file doesn't exist", function()
      local result = source:get_file_preview("nonexistent.md", 1, 5)

      assert.are.same({}, result)
    end)

    it("should return empty array when line range is out of bounds", function()
      local result = source:get_file_preview("test-file.md", 10, 5)

      assert.are.same({}, result)
    end)

    it("should handle single line request", function()
      -- Mock for single line
      _G.vim.fn.system = function(cmd)
        if cmd:match("sed %-n '2,2p'") then
          return "line 2\n"
        end
        return ""
      end

      local result = source:get_file_preview("test-file.md", 2, 1)

      assert.are.same({ "line 2" }, result)
    end)

    it("should remove trailing empty line from sed output", function()
      -- Mock sed output with trailing newline
      _G.vim.fn.system = function(cmd)
        return "line 1\nline 2\n"
      end

      local result = source:get_file_preview("test-file.md", 1, 2)

      assert.are.same({ "line 1", "line 2" }, result)
    end)

    it("should build correct sed command", function()
      local captured_cmd = nil
      _G.vim.fn.system = function(cmd)
        captured_cmd = cmd
        return "line 1\n"
      end

      source:get_file_preview("path/to/file.md", 5, 3)

      assert.is_not_nil(captured_cmd)
      assert.is_true(captured_cmd:match("sed %-n '5,7p'") ~= nil)
      assert.is_true(captured_cmd:match("'path/to/file%.md'") ~= nil)
    end)

    it("should handle files with spaces in path", function()
      local captured_cmd = nil
      _G.vim.fn.system = function(cmd)
        captured_cmd = cmd
        return "content\n"
      end

      source:get_file_preview("path with spaces/file.md", 1, 1)

      assert.is_not_nil(captured_cmd)
      -- Should be properly escaped
      assert.is_true(captured_cmd:match("'path with spaces/file%.md'") ~= nil)
    end)
  end)
end)
