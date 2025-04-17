# claude-fu.nvim

> Be water, my code

Flow like water between coding and AI assistance

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'mattkubej/claude-fu.nvim',
  config = function()
    require('claude-fu').setup({
      -- optional custom configuration
    })
  end
}
```

```lua
require('claude-fu').setup({
  api = {
    api_key = "your_api_key_here", -- or set ANTHROPIC_API_KEY env variable
  }
})
```

## Usage

Default keybindings:

- `<leader>cc` - Toggle Claude chat window
- `<leader>cb` - Ask about current buffer
- `<leader>cs` - Ask about selected code (visual mode)
- `<leader>ci` - Improve selected code (visual mode)
- `<leader>ce` - Explain selected code (visual mode)
- `<leader>cp` - Implement code from comments (visual mode)
- `<leader>cn` - Analyze selected code (visual mode)

## Configuration

The plugin is highly customizable. Here's an example with default values:

```lua
require('claude-fu').setup({
  -- Legacy API configuration 
  api = {
    -- use Claude API directly
    model = "claude-3-7-sonnet-20250219",
    api_key_env = "ANTHROPIC_API_KEY", -- Environment variable for direct API key
    endpoint = "https://api.anthropic.com/v1/messages",
    max_tokens = 2000,
    temperature = 0.7,

    -- use proxy
    proxy_enabled = os.getenv("LLM_PROXY") ~= nil,
    proxy_url_env = "LLM_PROXY",                 -- Environment variable for proxy URL
    proxy_model = "anthropic:claude-3-7-sonnet", -- Model name when using proxy
    proxy_api_key_env = "OPENAI_API_KEY",        -- API key env var for proxy
  },
  
  -- Provider to use (must be a key in the providers map)
  provider = "default",
  
  -- Multiple providers configuration (recommended)
  providers = {
    -- Default Anthropic provider
    default = {
      endpoint = "https://api.anthropic.com/v1/messages", -- API endpoint
      model = "claude-3-7-sonnet-20250219",               -- Model name 
      max_tokens = 2000,                                  -- Max tokens to generate
      temperature = 0.7,                                  -- Controls randomness (0.0-1.0)
      
      -- API key can be provided in various ways:
      -- 1. String literal (not recommended for security)
      api_key = "your-api-key-here", 
    },
    
    -- Example: Another provider with different settings
    opus = {
      endpoint = "https://api.anthropic.com/v1/messages",
      model = "claude-3-opus-20240229",
      max_tokens = 4000,
      temperature = 0.5,
      
      -- 2. Environment variable 
      api_key = { env = "ANTHROPIC_API_KEY" },
    },
    
    -- Example: Provider that uses a command to fetch the API key
    secure = {
      endpoint = "https://api.anthropic.com/v1/messages",
      model = "claude-3-7-sonnet-20250219",
      max_tokens = 2000,
      temperature = 0.7,
      
      -- 3. Command to generate key
      api_key = { cmd = "op read op://private/anthropic-api-key/credential" },
    },
  },
  
  ui = {
    width = 0.7,             -- Width as a percentage of screen width
    height = 0.6,            -- Height as a percentage of screen height
    border = "rounded",      -- Border style: "none", "single", "double", "rounded", "solid"
    title = " Claude Fu ",   -- Title shown in the popup window border
  },

  keymaps = {
    toggle = "<leader>cc",
    ask_buffer = "<leader>cb",
    ask_selection = "<leader>cs",
    improve_selection = "<leader>ci", 
    explain_selection = "<leader>ce",
    implement_comment = "<leader>cp",
    analyze_selection = "<leader>cn",
  },
})
```

### Default Configuration

You can access and extend the default configuration:

```lua
local claude_fu = require('claude-fu')
local config = vim.tbl_deep_extend("force", claude_fu.default_config, {
  -- Use a different provider
  provider = "opus",
  
  -- Add a new provider
  providers = {
    opus = {
      endpoint = "https://api.anthropic.com/v1/messages",
      model = "claude-3-opus-20240229",
      temperature = 0.8,
      api_key = { env = "ANTHROPIC_API_KEY" },
    },
    -- You can add any number of providers here
  }
})
claude_fu.setup(config)
```

## Development

### Running Tests

To run the test suite, you'll need:

1. [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) installed

Then run:

```bash
make test
```

or manually:

```bash
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ { minimal_init = './tests/minimal_init.lua' }"
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Add tests for your changes
4. Make your changes
5. Run the tests to ensure they pass
6. Commit your changes (`git commit -m 'Add some amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request
