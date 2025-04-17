-- Tests for claude-fu using Plenary
local test_utils = require('plenary.test_harness')
local assert = require('luassert')

-- Create a mock environment for the tests
local function setup_mocks()
  local mocks = {}
  
  -- Store original functions
  mocks.original = {
    getenv = os.getenv,
    popen = io.popen,
    open = io.open,
    jobstart = vim.fn.jobstart,
  }
  
  -- Mock os.getenv
  os.getenv = function(name)
    if name == "TEST_API_KEY" then
      return "env-var-key"
    elseif name == "PROVIDER_API_KEY" then
      return "provider-env-key" 
    end
    return mocks.original.getenv(name)
  end
  
  -- Mock io.popen
  io.popen = function(cmd)
    if cmd == "echo 'cmd-key'" then
      return {
        read = function() return "cmd-key" end,
        close = function() end
      }
    elseif cmd == "op read key" then
      return {
        read = function() return "provider-cmd-key" end,
        close = function() end
      }
    end
    return mocks.original.popen(cmd)
  end
  
  -- Mock io.open
  io.open = function(file, mode)
    return {
      write = function() end,
      read = function() return "{}" end,
      close = function() end
    }
  end
  
  -- Mock vim.fn.jobstart
  vim.fn.jobstart = function(cmd, opts)
    mocks.last_jobstart_cmd = cmd
    if opts and opts.on_exit then
      -- Call the on_exit callback with exit code 0
      opts.on_exit(nil, 0)
    end
    return 123 -- Return a fake job ID
  end
  
  -- Mock vim.notify to capture messages
  mocks.notifications = {}
  mocks.original_notify = vim.notify
  vim.notify = function(msg, level)
    table.insert(mocks.notifications, {msg = msg, level = level})
  end
  
  return mocks
end

-- Restore mocked functions
local function restore_mocks(mocks)
  os.getenv = mocks.original.getenv
  io.popen = mocks.original.popen
  io.open = mocks.original.open
  vim.fn.jobstart = mocks.original.jobstart
  vim.notify = mocks.original_notify
end

-- Test suite
describe("claude-fu", function()
  local claude_fu
  local mocks
  
  before_each(function()
    -- Reset the module before each test
    package.loaded["claude-fu"] = nil
    claude_fu = require("claude-fu")
    
    -- Set up mocks
    mocks = setup_mocks()
  end)
  
  after_each(function()
    restore_mocks(mocks)
  end)
  
  describe("configuration", function()
    it("should use legacy API configuration", function()
      -- Set up with legacy config
      claude_fu.setup({
        api = {
          model = "claude-test-model",
          api_key = "test-legacy-key",
          endpoint = "https://test-endpoint.com",
          max_tokens = 1000,
          temperature = 0.5,
        }
      })
      
      -- Test provider config
      local config = claude_fu.get_provider_config()
      assert.equal("https://test-endpoint.com", config.endpoint)
      assert.equal("claude-test-model", config.model)
      assert.equal(1000, config.max_tokens)
      assert.equal(0.5, config.temperature)
      
      -- Test API key
      local api_key = claude_fu.get_api_key(false)
      assert.equal("test-legacy-key", api_key)
    end)
    
    it("should use single provider configuration", function()
      claude_fu.setup({
        provider = {
          endpoint = "https://single-provider.com",
          api_key = "single-provider-key",
          model = "claude-single-model",
          max_tokens = 1500,
          temperature = 0.3,
        }
      })
      
      -- Test provider config
      local config = claude_fu.get_provider_config()
      assert.equal("https://single-provider.com", config.endpoint)
      assert.equal("claude-single-model", config.model)
      assert.equal(1500, config.max_tokens)
      assert.equal(0.3, config.temperature)
      
      -- Test API key
      local api_key = claude_fu.get_api_key(false)
      assert.equal("single-provider-key", api_key)
    end)
    
    it("should use provider with env var API key", function()
      claude_fu.setup({
        provider = {
          endpoint = "https://env-provider.com",
          api_key = { env = "TEST_API_KEY" },
          model = "claude-env-model",
        }
      })
      
      -- Test API key
      local api_key = claude_fu.get_api_key(false)
      assert.equal("env-var-key", api_key)
    end)
    
    it("should use provider with command API key", function()
      claude_fu.setup({
        provider = {
          endpoint = "https://cmd-provider.com",
          api_key = { cmd = "echo 'cmd-key'" },
          model = "claude-cmd-model",
        }
      })
      
      -- Test API key
      local api_key = claude_fu.get_api_key(false)
      assert.equal("cmd-key", api_key)
    end)
    
    it("should use the specified provider from providers map", function()
      claude_fu.setup({
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
      
      -- Test provider config
      local config = claude_fu.get_provider_config()
      assert.equal("https://test-provider.com", config.endpoint)
      assert.equal("claude-test-provider-model", config.model)
      assert.equal(2000, config.max_tokens)
      assert.equal(0.4, config.temperature)
      
      -- Test API key
      local api_key = claude_fu.get_api_key(false)
      assert.equal("test-provider-key", api_key)
    end)
    
    it("should handle provider with env var API key from providers map", function()
      claude_fu.setup({
        provider = "env-provider",
        providers = {
          ["env-provider"] = {
            endpoint = "https://env-var-provider.com",
            api_key = { env = "PROVIDER_API_KEY" },
            model = "claude-env-var-model",
          }
        }
      })
      
      -- Test API key
      local api_key = claude_fu.get_api_key(false)
      assert.equal("provider-env-key", api_key)
    end)
    
    it("should handle provider with command API key from providers map", function()
      claude_fu.setup({
        provider = "cmd-provider",
        providers = {
          ["cmd-provider"] = {
            endpoint = "https://cmd-provider.com",
            api_key = { cmd = "op read key" },
            model = "claude-cmd-provider-model",
          }
        }
      })
      
      -- Test API key
      local api_key = claude_fu.get_api_key(false)
      assert.equal("provider-cmd-key", api_key)
    end)
    
    it("should handle nonexistent provider", function()
      claude_fu.setup({
        provider = "nonexistent",
        providers = {
          ["real-provider"] = {
            endpoint = "https://real-provider.com",
            api_key = "real-key",
          }
        }
      })
      
      -- Test provider config - should return nil and show error
      local config = claude_fu.get_provider_config()
      assert.is_nil(config)
      
      -- Check that an error notification was shown
      assert.is_true(#mocks.notifications > 0)
      assert.truthy(mocks.notifications[1].msg:match("Provider 'nonexistent' not found"))
    end)
  end)
  
  describe("API interaction", function()
    it("should use the correct provider configuration for API calls", function()
      -- Setup with test provider
      claude_fu.setup({
        state = { waiting_response = false }, -- Mock state for testing
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
      
      -- Create stub for handle_api_response
      local original_handle_api_response = claude_fu.handle_api_response
      claude_fu.handle_api_response = function() end
      
      -- Define a mock remove_thinking_indicator function if needed
      claude_fu.remove_thinking_indicator = function() end
      
      -- Run a fake API call
      claude_fu.send_via_direct_api({}, "fake-api-key", "/tmp/output.json", function() end)
      
      -- Check that the curl command uses the correct endpoint
      assert.truthy(mocks.last_jobstart_cmd:match("https://test%-api%-endpoint%.com"))
      
      -- Restore original function
      claude_fu.handle_api_response = original_handle_api_response
    end)
  end)
end)