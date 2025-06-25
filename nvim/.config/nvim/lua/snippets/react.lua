local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node
local f = ls.function_node

local function filename_to_component_name()
  local filename = vim.fn.expand "%:t:r"
  local parts = vim.split(filename, "[-_]", { plain = false })
  for i, part in ipairs(parts) do
    parts[i] = part:sub(1, 1):upper() .. part:sub(2)
  end
  return table.concat(parts, "")
end

return {
  s("rcomp", {
    t "import React from 'react'",
    t { "", "" },
    t { "", "" },
    t "export const ",
    f(filename_to_component_name, {}),
    t " = () => {",
    t { "", "  return <div>" },
    f(filename_to_component_name, {}),
    t "</div>",
    t { "", "}" },
  }),
}
