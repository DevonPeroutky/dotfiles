-- Use the selected developer tools' default SDK rather than letting build tools
-- discover a newer, incompatible SDK installed alongside it. This also applies
-- to Neovide launched from Finder, which doesn't inherit shell initialization.
if vim.fn.has("macunix") ~= 1 or (vim.env.SDKROOT and vim.env.SDKROOT ~= "") then
  return
end

local result = vim.system({ "xcode-select", "-p" }, { text = true }):wait()
if result.code ~= 0 then
  return
end

local developer = vim.trim(result.stdout)
for _, relative in ipairs({
  "/SDKs/MacOSX.sdk", -- Command Line Tools
  "/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk", -- Xcode
}) do
  local sdk = developer .. relative
  if vim.fn.isdirectory(sdk) == 1 then
    vim.env.SDKROOT = sdk
    break
  end
end
