----------------------- AGENTIC (ACP AI chat sidebar) -------------------------
-- ACP-based in-editor agent chat. Providers speak the Agent Client Protocol;
-- their connector CLIs are put on PATH via the flake.nix `dependencies` list:
--   claude-agent-acp -> `claude-agent-acp`  (Claude, via the iris wrapper below)
--   codex-acp        -> `codex-acp`         (OpenAI Codex)
--   gemini-acp       -> `gemini --acp`      (gemini-cli)
--   opencode-acp     -> `opencode acp`
-- Distinct from sidekick.nvim (raw terminal CLIs under <leader>cs); agentic is
-- the structured ACP sidebar under <leader>ca.

return function()
  require("agentic").setup({
    provider = "claude-agent-acp",
    diff_preview = {
      enabled = true,
      layout = "inline",
      center_on_navigate_hunks = true
    },
    acp_providers = {
      -- Route Claude through the `iris` PAI wrapper so its settings, mcp config,
      -- plugins, and private-mode routing all apply. claude-agent-acp is an
      -- Agent SDK server: the SDK spawns whatever CLAUDE_CODE_EXECUTABLE points
      -- at, so pointing it at `iris` gives the full PAI environment. `iris` must
      -- be non-interactive when it has no tty (the SDK drives it over a stdin
      -- JSON stream). When `iris` isn't on PATH (e.g. someone running pwnvim
      -- without PAI), fall back to the plugin default so the provider still works.
      ["claude-agent-acp"] = {
        env = vim.fn.executable("iris") == 1
            and { CLAUDE_CODE_EXECUTABLE = "iris" } or {},
      },
      -- gemini-acp/codex-acp/opencode-acp use their default commands, which
      -- resolve from the connector CLIs added to the flake dependencies.
    },
    windows = {
      position = "right",
    },
  })
end
