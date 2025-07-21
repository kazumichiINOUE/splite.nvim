local M = {}

-- プラグインの状態管理
M.mode = false

-- 言語設定キャッシュ
local language_configs = {}

-- 内部関数の定義
local load_language_config
local setup_literate_syntax
local enable_literate_mode
local disable_literate_mode

-- Private: 言語設定の動的読み込み
load_language_config = function(filetype)
  if language_configs[filetype] then
    return language_configs[filetype]
  end
  
  local ok, config = pcall(require, "literate_mode.languages." .. filetype)
  if ok then
    language_configs[filetype] = config
    return config
  end
  
  return nil
end

-- Private: 言語別Literateシンタックスの設定
setup_literate_syntax = function(filetype)
  local config = load_language_config(filetype)
  if not config then
    print("Literate mode: Unsupported filetype - " .. filetype)
    return false
  end
  
  -- 基本設定
  vim.cmd("syntax reset")
  vim.cmd("syntax on")
  vim.cmd("set syntax=" .. config.syntax)
  vim.cmd("highlight clear")
  vim.cmd("highlight Normal guifg=" .. config.normal_fg .. " guibg=" .. config.background)
  vim.cmd("highlight Comment guifg=" .. config.comment_fg .. " guibg=" .. config.background .. " gui=bold")
  
  -- シンタックスパターンの設定
  for category, patterns in pairs(config.syntax_patterns) do
    for _, pattern in ipairs(patterns) do
      vim.cmd(pattern)
    end
  end
  
  -- コメント領域とdelimiterの設定
  vim.cmd(config.comment_region)
  vim.cmd(config.normal_comment)
  vim.cmd(config.line_comment)
  vim.cmd(config.delimiter)
  
  -- ハイライトグループの設定
  for _, highlight in ipairs(config.highlight_groups) do
    vim.cmd(highlight)
  end
  
  return true
end
  
-- Public: モード切り替え
function M.toggle()
  M.mode = not M.mode
  if M.mode then
    enable_literate_mode()
    print("Literate Mode")
  else
    disable_literate_mode()
    print("Code Mode")
  end
end

-- Public: デバッグ用：カーソル下の情報表示
function M.debug_highlight()
  local line = vim.fn.line('.')
  local col = vim.fn.col('.')
  local syn_id = vim.fn.synID(line, col, 1)
  local syn_name = vim.fn.synIDattr(syn_id, 'name')
  local trans_id = vim.fn.synIDtrans(syn_id)
  local trans_name = vim.fn.synIDattr(trans_id, 'name')
  
  print("Cursor position: " .. line .. "," .. col)
  print("Syntax group: " .. syn_name)  
  print("Highlight group: " .. trans_name)
end

-- Public: プラグインのセットアップ関数
function M.setup(opts)
  opts = opts or {}
  
  -- 将来の設定オプション用
  -- opts.keymap - キーマップのカスタマイズ
  -- opts.colors - カラーテーマの設定
  -- opts.filetypes - 対象ファイルタイプの指定
  
  -- autocmd for file reload
  vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = "*.rs",
    callback = function()
      if M.mode then
        M.toggle()
        M.toggle()
      end
    end
  })
end

-- Private: Literateモード有効化
enable_literate_mode = function ()
  -- カーソル位置とスクロール位置を保存
  local cursor_pos = vim.fn.getcurpos()
  local view = vim.fn.winsaveview()
  
  -- ステータスバーを保持してからリセット
  local statusline_bg = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "bg")
  local statusline_fg = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "fg")
  
  -- Tree-sitterを一時無効化
  vim.cmd("TSDisable highlight")
  
  -- ファイルタイプを取得してシンタックス設定
  local filetype = vim.bo.filetype
  if not setup_literate_syntax(filetype) then
    -- 非対応言語の場合は処理中止
    vim.fn.setpos('.', cursor_pos)
    vim.fn.winrestview(view)
    return
  end
  
  -- 保存した色でステータスラインを復元
  vim.cmd(string.format("highlight StatusLine guifg=%s guibg=%s", statusline_fg, statusline_bg))
  
  -- カーソル位置とスクロール位置を復元
  vim.fn.setpos('.', cursor_pos)
  vim.fn.winrestview(view)
end

-- Private: 通常モード復元
disable_literate_mode = function ()
  -- カーソル位置とスクロール位置を保存
  local cursor_pos = vim.fn.getcurpos()
  local view = vim.fn.winsaveview()
  
  -- 通常モード：元のカラースキームに戻す  
  vim.cmd("TSEnable highlight")
  vim.cmd([[
    syntax reset
    syntax on
    highlight clear
    colorscheme tokyonight
  ]])
  
  vim.cmd("edit")
  
  -- カーソル位置とスクロール位置を復元
  vim.fn.setpos('.', cursor_pos)
  vim.fn.winrestview(view)
end

return M
