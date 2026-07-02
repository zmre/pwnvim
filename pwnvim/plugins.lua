-- Plugin configuration lives in per-concern modules under pwnvim/plugins/
-- (ui, diagnostics, llms, llmcli, picker, completions, notes, grammar,
-- misc, pick_folder). This module just re-exports them so callers can keep
-- using require('pwnvim.plugins').ui() etc.
local M = {}

M.ui = require("pwnvim.plugins.ui")
M.diagnostics = require("pwnvim.plugins.diagnostics")
M.llms = require("pwnvim.plugins.llms")
M.llmcli = require("pwnvim.plugins.llmcli")
M.picker = require("pwnvim.plugins.picker")
M.completions = require("pwnvim.plugins.completions")
M.notes = require("pwnvim.plugins.notes")
M.grammar_check = require("pwnvim.plugins.grammar")
M.misc = require("pwnvim.plugins.misc")
M.pick_folder = require("pwnvim.plugins.pick_folder")

return M
