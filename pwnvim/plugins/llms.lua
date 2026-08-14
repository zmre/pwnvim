----------------------- LLMS --------------------------------
-- CodeCompanion AI chat/inline assistance

return function()
  local constants = {
    LLM_ROLE = "llm",
    USER_ROLE = "user",
    SYSTEM_ROLE = "system",
  }
  local fmt = string.format

  vim.g.codecompanion_adapter = "openai"

  require("codecompanion").setup({
    ignore_warnings = true, -- they have some warning about breaking changes soon to suppress 2025-12-14
    -- action_palette = {
    --   provider = "snacks"
    -- },
    display = {
      chat = {
        render_headers = true,
        show_settings = false, -- can't change models when this is true
      }
    },
    opts = {
      log_level = "TRACE", -- TRACE|DEBUG|ERROR|INFO
      language = "English",
    },
    adapters = {
      acp = {
        gemini_cli = function()
          return require("codecompanion.adapters").extend("gemini_cli", {
            defaults = {
              auth_method = "gemini-api-key", -- "oauth-personal"|"gemini-api-key"|"vertex-ai"
            },
            env = {
              GEMINI_API_KEY = "cmd:security find-generic-password -l geminikey -g -w |tr -d '\n'",
            },
          })
        end,
      },
      http = {
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            env = {
              api_key = "cmd:security find-generic-password -l anthropickey -g -w |tr -d '\n'",
            },
          })
        end,
        openai = function()
          return require("codecompanion.adapters").extend("openai", {
            env = {
              api_key = "cmd:security find-generic-password -l openaikey -g -w |tr -d '\n'"
            }
          })
        end,
        opts = {
          allow_insecure = false, -- Allow insecure connections? yes if we're using ollama
          show_model_choices = true,
        },

      }
    },
    strategies = {
      chat = {
        adapter = "openai",
      },
      inline = {
        adapter = "openai",
      },
      agent = {
        adapter = "gemini_cli",
      },
    },
    prompt_library = {
      ["Summarize"] = {
        strategy = "chat",
        description = "Summarize some text",
        opts = {
          index = 3,
          is_default = true,
          modes = { "v" },
          short_name = "summarize",
          is_slash_cmd = false,
          auto_submit = true,
          user_prompt = false,
          stop_context_insertion = true,
        },
        prompts = {
          {
            role = constants.SYSTEM_ROLE,
            content =
            [[I want you to act as a senior editor at a newspaper whose job is to make short summaries of articles for search engines.]],
            opts = {
              visible = false,
              tag = "system_tag",
            },
          },
          {
            role = constants.USER_ROLE,
            content = function(context)
              local prose = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
              return fmt(
                [[Summarize the contents of the article that starts below the "---". Make your summary be 150 to 170 characters long to fit in a web page meta description:

                ---
                %s

                Summarize that in 150 characters.
                ]], prose
              )
            end
          }
        },
      }
    },
  })
  vim.cmd([[cab cc CodeCompanion]])
end
