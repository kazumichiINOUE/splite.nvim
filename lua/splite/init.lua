-- vim global is provided by Neovim
---@diagnostic disable: undefined-global

local M = {}

-- プラグインの状態管理
M.mode = false
M.spread_view = false

-- 言語設定キャッシュ
local language_configs = {}

-- 内部関数の定義
local load_language_config
local setup_literate_syntax
local enable_literate_mode
local disable_literate_mode
local enable_spread_view
local disable_spread_view
local sync_spread_scroll

-- Private: 言語設定の動的読み込み
load_language_config = function(filetype)
  if language_configs[filetype] then
    return language_configs[filetype]
  end
  
  local ok, config = pcall(require, "splite.languages." .. filetype)
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
  
  -- 標準構文のクリア（カスタム定義より先に実行）
  if config.clear_standard then
    pcall(vim.cmd, config.clear_standard)
  end
  
  -- 動的ハイライト対応の新方式
  -- local debug_file = io.open("/tmp/splite_debug.log", "a")
  -- debug_file:write("Checking dynamic highlight support...\n")
  -- debug_file:write("color_setup exists: " .. tostring(config.color_setup ~= nil) .. "\n")
  -- debug_file:write("highlight_function exists: " .. tostring(config.highlight_function ~= nil) .. "\n")
  -- debug_file:close()
  
  if config.color_setup and config.highlight_function then
    -- local debug_file2 = io.open("/tmp/splite_debug.log", "a")
    -- debug_file2:write("Using dynamic highlight mode\n")
    -- debug_file2:close()
    -- ハイライトグループ定義
    config.color_setup()
    
    -- namespace作成
    local ns = vim.api.nvim_create_namespace(config.namespace)
    local buf = vim.api.nvim_get_current_buf()
    
    -- 初回ハイライト適用
    local line_count = vim.api.nvim_buf_line_count(buf)
    config.highlight_function(buf, ns, 0, line_count - 1)
    
    -- バッファ変更時の動的更新
    vim.api.nvim_buf_attach(buf, false, {
      on_lines = function(_, _, _, first, _, last_new)
        config.highlight_function(buf, ns, first, last_new)
      end
    })
  else
    -- 従来方式（rustなど）
    -- シンタックスパターンの設定
    if config.syntax_patterns then
      for category, patterns in pairs(config.syntax_patterns) do
        for _, pattern in ipairs(patterns) do
          vim.cmd(pattern)
        end
      end
    end
    
    -- コメント領域とdelimiterの設定
    vim.cmd(config.comment_region)
    if config.normal_comment then vim.cmd(config.normal_comment) end
    if config.line_comment then vim.cmd(config.line_comment) end
    vim.cmd(config.delimiter)
  end
  
  -- ハイライトグループの設定
  if config.highlight_groups then
    for _, highlight in ipairs(config.highlight_groups) do
      vim.cmd(highlight)
    end
  end
  
  return true
end
  
-- Public: モード切り替え
function M.toggle()
  -- ファイラーでは無効化
  if vim.bo.filetype == 'NvimTree' then
    print("Literate mode: Not available in file explorer")
    return
  end
  
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
  
  -- 実際の色情報も表示
  local fg = vim.fn.synIDattr(trans_id, 'fg')
  local bg = vim.fn.synIDattr(trans_id, 'bg')
  local gui = vim.fn.synIDattr(trans_id, 'gui')
  
  print("Cursor position: " .. line .. "," .. col)
  print("Syntax group: " .. syn_name)  
  print("Highlight group: " .. trans_name)
  print("Colors - fg: " .. (fg or "none") .. ", bg: " .. (bg or "none") .. ", gui: " .. (gui or "none"))
end

-- Public: Spread View切り替え
function M.toggle_spread_view()
  M.spread_view = not M.spread_view
  if M.spread_view then
    enable_spread_view()
    print("Spread View Mode")
  else
    disable_spread_view()
    print("Normal View Mode")
  end
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
  
  -- ファイルタイプを取得してシンタックス設定
  local filetype = vim.bo.filetype
  local config = load_language_config(filetype)
  if not config then
    -- カーソル位置とスクロール位置を復元
    vim.fn.setpos('.', cursor_pos)
    vim.fn.winrestview(view)
    return
  end
  
  -- Tree-sitterを一時無効化
  vim.cmd("TSDisable highlight")
  
  -- シンタックス設定を適用
  setup_literate_syntax(filetype)
  
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
  
  -- nvim-treeのハイライトを強制更新
  if pcall(require, "nvim-tree") then
    vim.cmd("NvimTreeRefresh")
  end
  
  vim.cmd("edit")
  
  -- カーソル位置とスクロール位置を復元
  vim.fn.setpos('.', cursor_pos)
  vim.fn.winrestview(view)
end

-- Private: Spread View有効化
enable_spread_view = function()
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- 3ペイン作成
  vim.cmd("vsplit")
  vim.cmd("vsplit")
  
  -- 各ウィンドウで同じバッファを表示
  local windows = vim.api.nvim_tabpage_list_wins(0)
  for _, win in ipairs(windows) do
    vim.api.nvim_win_set_buf(win, current_buf)
  end
  
  -- 中央ウィンドウにフォーカス
  vim.api.nvim_set_current_win(windows[2])
  
  -- 左右ペインにnowrapと絶対行番号を設定
  vim.api.nvim_set_current_win(windows[1])
  vim.wo.wrap = false
  vim.wo.number = true
  vim.wo.relativenumber = false
  vim.api.nvim_set_current_win(windows[3])
  vim.wo.wrap = false
  vim.wo.number = true
  vim.wo.relativenumber = false
  vim.api.nvim_set_current_win(windows[2])
  vim.wo.wrap = false
  vim.wo.number = true
  vim.wo.relativenumber = false
  
  -- スクロール同期のautocmd設定
  vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
    buffer = current_buf,
    callback = function()
      -- visual mode中はスクロール同期を停止
      if vim.fn.mode():match('[vV]') then
        return
      end
      
      if M.spread_view then
        sync_spread_scroll()
      end
    end
  })
  
  -- 初回同期実行
  sync_spread_scroll()
end

-- Private: 通常表示復帰
disable_spread_view = function()
  -- 行番号設定を保存（Spread View前の設定に戻す）
  local original_number = vim.wo.number
  local original_relativenumber = vim.wo.relativenumber
  
  -- Spread Viewウィンドウを閉じる
  vim.cmd("only")
  
  -- 行番号設定を復元
  vim.wo.number = original_number
  vim.wo.relativenumber = original_relativenumber
end

-- Private: スクロール同期処理
sync_spread_scroll = function()
  local windows = vim.api.nvim_tabpage_list_wins(0)
  if #windows ~= 3 then return end
  
  local center_win = windows[2]
  local left_win = windows[1]
  local right_win = windows[3]
  
  -- 中央ウィンドウの表示範囲を取得
  vim.api.nvim_set_current_win(center_win)
  local center_top = vim.fn.line('w0')
  local win_height = vim.api.nvim_win_get_height(center_win)
  
  -- 左ウィンドウ: 中央より前の範囲を表示
  vim.api.nvim_set_current_win(left_win)
  local left_top = math.max(1, center_top - win_height)
  
  
  if left_top < center_top then
    -- 表示すべき内容がある場合
    local original_buf = vim.api.nvim_win_get_buf(center_win)
    local lines_to_show = center_top - left_top
    
    if lines_to_show < win_height then
      -- 専用バッファを作成して必要な行のみコピー
      local left_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(left_buf, 'buftype', 'nofile')
      vim.api.nvim_buf_set_option(left_buf, 'bufhidden', 'wipe')
      
      -- 元バッファから必要な行を取得
      local lines = vim.api.nvim_buf_get_lines(original_buf, left_top - 1, center_top - 1, false)
      
      -- 空行を追加して下部に寄せる
      local empty_lines = {}
      for i = 1, win_height - lines_to_show do
        table.insert(empty_lines, "")
      end
      
      -- 空行 + 実際の内容を設定
      for _, line in ipairs(lines) do
        table.insert(empty_lines, line)
      end
      
      vim.api.nvim_buf_set_lines(left_buf, 0, -1, false, empty_lines)
      vim.api.nvim_win_set_buf(left_win, left_buf)
      
      -- 元バッファのファイルタイプとシンタックス設定をコピー
      local original_ft = vim.api.nvim_buf_get_option(original_buf, 'filetype')
      vim.api.nvim_buf_set_option(left_buf, 'filetype', original_ft)
      
      -- カスタム行番号表示を設定
      vim.wo.number = false
      vim.wo.relativenumber = false
      vim.wo.signcolumn = "yes:2"
      
      -- サイン定義（先に定義）
      for i = left_top, center_top - 1 do
        vim.fn.sign_define("LineNum" .. i, {text = tostring(i), texthl = "LineNr"})
      end
      
      -- 実際のファイル行番号を表示するためのsign配置
      for i = 1, lines_to_show do
        local actual_line_num = left_top + i - 1
        local sign_line = win_height - lines_to_show + i
        vim.fn.sign_place(0, "left_line_nums", "LineNum" .. actual_line_num, left_buf, {lnum = sign_line})
      end
      
      
      -- 最下部にカーソル移動
      vim.fn.cursor(#empty_lines, 1)
    else
      -- 通常の表示（元バッファを使用）
      vim.api.nvim_win_set_buf(left_win, original_buf)
      vim.fn.cursor(left_top, 1)
      vim.cmd("normal! zt")
    end
    
    -- TODO: literate mode シンタックス適用（一時無効化）
    -- if M.mode then
    --   vim.api.nvim_set_current_win(center_win)
    --   local original_ft = vim.api.nvim_buf_get_option(original_buf, 'filetype')
    --   setup_literate_syntax(original_ft)
    -- end
  else
    -- 表示すべき内容がない場合（ファイル先頭）
    local scratch_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(left_win, scratch_buf)
    vim.api.nvim_buf_set_option(scratch_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(scratch_buf, 'bufhidden', 'wipe')
  end
  
  -- 右ウィンドウ: 中央の直後から表示
  vim.api.nvim_set_current_win(right_win)
  local right_top = center_top + win_height
  local original_buf = vim.api.nvim_win_get_buf(center_win)
  local total_lines = vim.api.nvim_buf_line_count(original_buf)
  
  if right_top <= total_lines then
    -- 表示すべき内容がある場合，元のバッファに戻してから表示
    if vim.api.nvim_win_get_buf(right_win) ~= original_buf then
      vim.api.nvim_win_set_buf(right_win, original_buf)
    end
    vim.fn.cursor(right_top, 1)
    vim.cmd("normal! zt")
  else
    -- ファイル末尾を超える場合は空のスクラッチバッファを表示
    local scratch_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(right_win, scratch_buf)
    vim.api.nvim_buf_set_option(scratch_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(scratch_buf, 'bufhidden', 'wipe')
  end
  
  -- 中央ウィンドウに戻る
  vim.api.nvim_set_current_win(center_win)
end

return M
