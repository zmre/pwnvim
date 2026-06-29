local M = {}

-- Pull a sortable date key out of a transaction block. hledger transactions
-- start (after any leading comment lines) with a date at column 0 in
-- YYYY-MM-DD / YYYY/MM/DD / YYYY.MM.DD form. Returns a zero-padded "YYYYMMDD"
-- string for the first such line, or nil if the block has no transaction date
-- (e.g. it's a comment, an `account`/`commodity` directive, etc.).
local function block_date(lines)
  for _, line in ipairs(lines) do
    local y, mo, d = line:match("^(%d%d%d%d)[-/.](%d%d?)[-/.](%d%d?)")
    if y then
      return string.format("%04d%02d%02d", tonumber(y), tonumber(mo), tonumber(d))
    end
  end
  return nil
end

-- Sort the blank-line-separated blocks within [line1, line2] by transaction
-- date, ascending (oldest first). Designed for the post-import workflow where
-- new transactions land at the end of the file and need to be filed into place.
--
-- * Undated blocks (comments, `account`/`commodity` directives) keep their
--   place by inheriting the date of the block before them, so leading
--   directives stay at the top and a trailing comment stays with its txn.
-- * The sort is stable: blocks sharing a date keep their original order.
-- * Runs of blank lines between blocks are normalized to a single blank line
--   (matching hledger-fmt, which runs on save anyway).
M.sort_blocks = function(line1, line2)
  line1 = line1 or 1
  line2 = line2 or vim.api.nvim_buf_line_count(0)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)

  -- Group non-blank lines into blocks; blank lines are block separators.
  local blocks = {}
  local cur = nil
  for _, line in ipairs(lines) do
    if line:match("^%s*$") then
      cur = nil
    else
      if not cur then
        cur = {}
        table.insert(blocks, cur)
      end
      table.insert(cur, line)
    end
  end

  if #blocks < 2 then return end -- nothing to reorder

  -- Build sort keys, letting undated blocks inherit the previous date.
  local prev = ""
  local keyed = {}
  for i, b in ipairs(blocks) do
    local date = block_date(b) or prev
    prev = date
    keyed[i] = { key = date, idx = i, lines = b }
  end

  table.sort(keyed, function(a, b)
    if a.key ~= b.key then return a.key < b.key end
    return a.idx < b.idx -- stable tie-break preserves original order
  end)

  -- Reassemble with one blank line between blocks.
  local out = {}
  for i, item in ipairs(keyed) do
    if i > 1 then table.insert(out, "") end
    for _, l in ipairs(item.lines) do
      table.insert(out, l)
    end
  end

  vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, out)
end

return M
