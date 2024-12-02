local M = {}

M.error = SimpleUI and "🛑" or ""
M.warn = SimpleUI and "⚠️" or ""
M.hint = SimpleUI and "" or ""
M.info = SimpleUI and "❓" or ""
M.signs = {
  { name = "DiagnosticSignError", text = M.error },
  { name = "DiagnosticSignWarn",  text = M.warn },
  { name = "DiagnosticSignHint",  text = M.hint },
  { name = "DiagnosticSignInfo",  text = M.info }
}
if SimpleUI then
  M.kind_icons = {
    Text = "T",
    Method = "m",
    Function = "f",
    Constructor = "c",
    Field = "f",
    Variable = "v",
    Class = "",
    Interface = "i",
    Module = "m",
    Property = "p",
    Unit = "u",
    Value = "v",
    Enum = "e",
    Keyword = "",
    Snippet = "s",
    Color = "",
    File = "F",
    Reference = "r",
    Folder = "🖿",
    EnumMember = "em",
    Constant = "c",
    Struct = "s",
    Event = "e",
    Operator = "o",
    TypeParameter = "t"
  }
else
  M.kind_icons = {
    Text = "",
    Method = "m",
    Function = "",
    Constructor = "",
    Field = "",
    Variable = "",
    Class = "",
    Interface = "",
    Module = "",
    Property = "",
    Unit = "",
    Value = "",
    Enum = "",
    Keyword = "",
    Snippet = "",
    Color = "",
    File = "",
    Reference = "",
    Folder = "",
    EnumMember = "",
    Constant = "",
    Struct = "",
    Event = "",
    Operator = "",
    TypeParameter = ""
  }
end

for _, sign in ipairs(M.signs) do
  vim.fn.sign_define(sign.name,
    { texthl = M.name, text = M.text, numhl = "" })
end


return M
