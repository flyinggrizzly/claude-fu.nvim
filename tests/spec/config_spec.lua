-- Tests for claude-fu configuration
local mock = require('luassert.mock')

describe("claude-fu configuration", function()
  local m
  local get_api_key_spy
  local get_provider_config_spy
  
  before_each(function()
    -- Load the module fresh for each test
    package.loaded["claude-fu"] = nil
    m = require("claude-fu")
    
    -- Spy on the API key and provider functions
    get_api_key_spy = mock(m, "get_api_key", function() return "test-api-key" end)
    get_provider_config_spy = mock(m, "get_provider_config")
  end)
  
  after_each(function()
    mock.revert(m)
  end)

  describe("legacy configuration", function()
    it("should use direct API configuration", function()
      -- Setup with legacy config
      m.setup({
        api = {
          model = "claude-test-model",
          api_key = "test-legacy-key",
          endpoint = "https://test-endpoint.com",
          max_tokens = 1000,
          temperature = 0.5,
        }
      })
      
      -- Simulate getting config
      local result = m.get_provider_config()
      
      -- Check that it falls back correctly
      assert.are.equal("https://test-endpoint.com", result.endpoint)
      assert.are.equal("claude-test-model", result.model)
      assert.are.equal(1000, result.max_tokens)
      assert.are.equal(0.5, result.temperature)
      
      -- Check API key handling
      local api_key = m.get_api_key(false)
      assert.are.equal("test-legacy-key", api_key)
    end)
  end)
  
  describe("single provider configuration", function()
    it("should use provider object configuration", function()
      m.setup({
        provider = {
          endpoint = "https://single-provider.com",
          api_key = "single-provider-key",
          model = "claude-single-model",
          max_tokens = 1500,
          temperature = 0.3,
        }
      })
      
      -- Simulate getting config
      local result = m.get_provider_config()
      
      -- Check that it uses single provider config
      assert.are.equal("https://single-provider.com", result.endpoint)
      assert.are.equal("claude-single-model", result.model)
      assert.are.equal(1500, result.max_tokens)
      assert.are.equal(0.3, result.temperature)
      
      -- Check API key handling
      local api_key = m.get_api_key(false)
      assert.are.equal("single-provider-key", api_key)
    end)
    
    it("should handle provider with env var API key", function()
      -- Mock os.getenv to return a fake API key
      local original_getenv = os.getenv
      os.getenv = function(name)
        if name == "TEST_API_KEY" then
          return "env-var-key"
        end
        return original_getenv(name)
      end
      
      m.setup({
        provider = {
          endpoint = "https://env-provider.com",
          api_key = { env = "TEST_API_KEY" },
          model = "claude-env-model",
        }
      })
      
      -- Check API key handling
      local api_key = m.get_api_key(false)
      assert.are.equal("env-var-key", api_key)
      
      -- Restore os.getenv
      os.getenv = original_getenv
    end)
    
    it("should handle provider with command API key", function()
      -- Mock io.popen to return a fake handle with API key
      local original_popen = io.popen
      io.popen = function(cmd)
        assert.are.equal("echo 'cmd-key'", cmd)
        return {
          read = function() return "cmd-key" end,
          close = function() end
        }
      end
      
      m.setup({
        provider = {
          endpoint = "https://cmd-provider.com",
          api_key = { cmd = "echo 'cmd-key'" },
          model = "claude-cmd-model",
        }
      })
      
      -- Check API key handling
      local api_key = m.get_api_key(false)
      assert.are.equal("cmd-key", api_key)
      
      -- Restore io.popen
      io.popen = original_popen
    end)
  end)
  
  describe("multiple providers configuration", function()
    it("should use the specified provider", function()
      m.setup({
        provider = "test-provider",
        providers = {
          ["test-provider"] = {
            endpoint = "https://test-provider.com",
            api_key = "test-provider-key",
            model = "claude-test-provider-model",
            max_tokens = 2000,
            temperature = 0.4,
          },
          ["other-provider"] = {
            endpoint = "https://other-provider.com",
            api_key = "other-provider-key",
            model = "claude-other-model",
          }
        }
      })
      
      -- Simulate getting config
      local result = m.get_provider_config()
      
      -- Check that it uses the correct provider
      assert.are.equal("https://test-provider.com", result.endpoint)
      assert.are.equal("claude-test-provider-model", result.model)
      assert.are.equal(2000, result.max_tokens)
      assert.are.equal(0.4, result.temperature)
      
      -- Check API key handling
      local api_key = m.get_api_key(false)
      assert.are.equal("test-provider-key", api_key)
    end)
    
    it("should handle provider with env var API key", function()
      -- Mock os.getenv to return a fake API key
      local original_getenv = os.getenv
      os.getenv = function(name)
        if name == "PROVIDER_API_KEY" then
          return "provider-env-key"
        end
        return original_getenv(name)
      end
      
      m.setup({
        provider = "env-provider",
        providers = {
          ["env-provider"] = {
            endpoint = "https://env-var-provider.com",
            api_key = { env = "PROVIDER_API_KEY" },
            model = "claude-env-var-model",
          }
        }
      })
      
      -- Check API key handling
      local api_key = m.get_api_key(false)
      assert.are.equal("provider-env-key", api_key)
      
      -- Restore os.getenv
      os.getenv = original_getenv
    end)
    
    it("should handle provider with command API key", function()
      -- Mock io.popen to return a fake handle with API key
      local original_popen = io.popen
      io.popen = function(cmd)
        assert.are.equal("op read key", cmd)
        return {
          read = function() return "provider-cmd-key" end,
          close = function() end
        }
      end
      
      m.setup({
        provider = "cmd-provider",
        providers = {
          ["cmd-provider"] = {
            endpoint = "https://cmd-provider.com",
            api_key = { cmd = "op read key" },
            model = "claude-cmd-provider-model",
          }
        }
      })
      
      -- Check API key handling
      local api_key = m.get_api_key(false)
      assert.are.equal("provider-cmd-key", api_key)
      
      -- Restore io.popen
      io.popen = original_popen
    end)
    
    it("should handle nonexistent provider", function()
      -- Mock show_error function to capture errors
      local error_msg
      local original_show_error = m.show_error
      m.show_error = function(msg) error_msg = msg end
      
      m.setup({
        provider = "nonexistent",
        providers = {
          ["real-provider"] = {
            endpoint = "https://real-provider.com",
            api_key = "real-key",
          }
        }
      })
      
      -- Try to get config for nonexistent provider
      local result = m.get_provider_config()
      
      -- Should show error and return nil
      assert.are.equal("Provider 'nonexistent' not found in providers configuration", error_msg)
      assert.is_nil(result)
      
      -- Restore show_error
      m.show_error = original_show_error
    end)
  end)
  
  describe("direct API calls", function()
    it("should use the correct provider configuration", function()
      -- Create a mock for handle_api_response to avoid making real API calls
      local original_handle_api_response = m.handle_api_response
      m.handle_api_response = function() end
      
      -- Mock jobstart to capture the curl command
      local captured_cmd
      local original_jobstart = vim.fn.jobstart
      vim.fn.jobstart = function(cmd, opts)
        captured_cmd = cmd
        return 1 -- Return a fake job ID
      end
      
      -- Mock os.tmpname to return predictable filenames
      local original_tmpname = os.tmpname
      os.tmpname = function() 
        return "/tmp/test-file"
      end
      
      -- Mock io.open to avoid actual file operations
      local original_open = io.open
      io.open = function()
        return {
          write = function() end,
          close = function() end,
        }
      end
      
      -- Setup with test provider
      m.setup({
        provider = "test-api",
        providers = {
          ["test-api"] = {
            endpoint = "https://test-api-endpoint.com",
            model = "test-model",
            max_tokens = 3000,
            temperature = 0.2,
          }
        }
      })
      
      -- Run a fake API call
      m.send_via_direct_api({}, "fake-api-key", "/tmp/output.json", function() end)
      
      -- Check that the curl command uses the correct config
      assert.not_nil(captured_cmd)
      assert.truthy(captured_cmd:match("https://test%-api%-endpoint%.com"))
      
      -- Restore mocked functions
      m.handle_api_response = original_handle_api_response
      vim.fn.jobstart = original_jobstart
      os.tmpname = original_tmpname
      io.open = original_open
    end)
  end)
end)