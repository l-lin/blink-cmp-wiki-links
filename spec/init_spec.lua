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
  },
  deepcopy = function(tbl)
    return tbl
  end,
}

local WikiLinksSource = require("blink-cmp-wiki-links")

describe("WikiLinksSource", function()
  local source

  before_each(function()
    source = WikiLinksSource.new()
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
end)

