local M = {}

local function get_root()
  return vim.fs.root(0, { ".git" }) or vim.fn.getcwd()
end

local function get_rel_path(root)
  local abs = vim.api.nvim_buf_get_name(0)
  if abs == "" then
    return nil
  end
  local rel = vim.fn.fnamemodify(abs, ":.")
  -- If fnamemodify didn't relativize (different drive on Windows, etc.), do it manually
  if vim.startswith(rel, root) then
    rel = rel:sub(#root + 2)
  end
  return rel
end

local function format_entry(rel_path, start_line, end_line, comment)
  local location
  if start_line == end_line then
    location = string.format("%s:L%d", rel_path, start_line)
  else
    location = string.format("%s:L%d-L%d", rel_path, start_line, end_line)
  end
  return string.format("## %s\n\n%s\n\n", location, comment)
end

local function append_to_review(root, entry)
  local review_path = root .. "/REVIEW.md"
  local stat = vim.uv.fs_stat(review_path)
  local is_new = stat == nil or stat.size == 0
  local fh = io.open(review_path, "a")
  if not fh then
    vim.notify("review.lua: could not open " .. review_path, vim.log.levels.ERROR)
    return
  end
  if is_new then
    fh:write("# Review comments\n\n")
  end
  fh:write(entry)
  fh:close()
  vim.notify("Appended to REVIEW.md", vim.log.levels.INFO)
end

function M.prompt(mode)
  local root = get_root()
  local rel_path = get_rel_path(root)
  if not rel_path then
    vim.notify("review.lua: buffer has no file name", vim.log.levels.ERROR)
    return
  end

  local start_line, end_line
  if mode == "v" then
    local s = vim.api.nvim_buf_get_mark(0, "<")
    local e = vim.api.nvim_buf_get_mark(0, ">")
    start_line = math.min(s[1], e[1])
    end_line = math.max(s[1], e[1])
  else
    start_line = vim.fn.line(".")
    end_line = start_line
  end

  Snacks.input({
    prompt = "Review comment",
    win = { title = " Review comment " },
  }, function(value)
    if not value or value == "" then
      return
    end
    local entry = format_entry(rel_path, start_line, end_line, value)
    append_to_review(root, entry)
  end)
end

return M
