-- Custom folder picker using snacks.picker

return function(search_folders, depth, callback)
  local Job = require 'plenary.job'

  local full_path_folders = {}
  -- Add base search folders first
  for _, f in ipairs(search_folders) do
    table.insert(full_path_folders, f)
  end

  local args = { '--base-directory', vim.env.HOME, "--min-depth", 1, "--max-depth", depth, "-t", "d", "-L" }
  for _, f in ipairs(search_folders) do
    table.insert(args, "--search-path")
    table.insert(args, f)
  end

  Job:new({
    command = 'fd',
    args = args,
    cwd = vim.env.HOME,
    env = { ['PATH'] = vim.env.PATH },
    on_stderr = function(err, data)
      vim.notify("stderr err: " .. vim.inspect(err) .. " data: " .. vim.inspect(data))
    end,
    on_stdout = function(err, data)
      if (err ~= nil) then
        vim.notify("stdout err: " .. vim.inspect(err) .. " data: " .. vim.inspect(data))
      else
        table.insert(full_path_folders, data)
      end
    end,
  }):sync()

  -- Create items for snacks picker
  local items = {}
  for _, folder in ipairs(full_path_folders) do
    local full_path = vim.env.HOME .. "/" .. folder
    local display = "~/" .. folder
    table.insert(items, {
      text = display,
      file = full_path,
    })
  end

  Snacks.picker.pick({
    source = "custom",
    title = "Pick Folder",
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if item and item.file then
        callback(item.file)
      end
    end,
  })
end
