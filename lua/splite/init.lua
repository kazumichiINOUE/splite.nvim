-- vim global is provided by Neovim
---@diagnostic disable: undefined-global

local M = {}

-- プラグインの状態管理
M.mode = false
M.spread_view = false
M.todo_mode = false

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
local enable_todo_mode
local disable_todo_mode
local extract_todo_lines
local sync_todo_scroll
local update_todo_panel

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
  local debug_file = io.open("/tmp/splite_debug.log", "a")
  debug_file:write("Checking dynamic highlight support...\n")
  debug_file:write("color_setup exists: " .. tostring(config.color_setup ~= nil) .. "\n")
  debug_file:write("highlight_function exists: " .. tostring(config.highlight_function ~= nil) .. "\n")
  debug_file:close()

  if config.color_setup and config.highlight_function then
    local debug_file2 = io.open("/tmp/splite_debug.log", "a")
    debug_file2:write("Using dynamic highlight mode\n")
    debug_file2:close()
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
  -- Todo Modeが有効な場合は先に無効化
  if M.todo_mode then
    M.todo_mode = false
    disable_todo_mode()
  end
  
  M.spread_view = not M.spread_view
  if M.spread_view then
    enable_spread_view()
    print("Spread View Mode")
  else
    disable_spread_view()
    print("Normal View Mode")
  end
end

-- Public: Todo Mode切り替え
function M.toggle_todo_mode()
  -- Markdownファイル以外では無効
  if vim.bo.filetype ~= 'markdown' then
    print("Todo mode: Only available for Markdown files")
    return
  end

  -- Spread Viewが有効な場合は先に無効化
  if M.spread_view then
    M.spread_view = false
    disable_spread_view()
  end

  M.todo_mode = not M.todo_mode
  if M.todo_mode then
    enable_todo_mode()
    print("Todo Mode")
  else
    disable_todo_mode()
    print("Normal Mode")
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

  -- Tree-sitterが完全に無効化されるまで少し待ってからシンタックス設定を適用
  vim.defer_fn(function()
    vim.cmd("TSDisable highlight")  -- 再度無効化を確実にする
    setup_literate_syntax(filetype)

    -- Tree-sitterの再度の干渉を防ぐため，継続的に再適用
    local function reapply_highlights()
      -- Literateモードが無効になっていたら処理を停止
      if not M.mode then
        return
      end
      vim.cmd("TSDisable highlight")
      local current_config = load_language_config(filetype)
      if current_config and current_config.color_setup and current_config.highlight_function then
        current_config.color_setup()
        local ns = vim.api.nvim_create_namespace(current_config.namespace)
        local buf = vim.api.nvim_get_current_buf()
        local line_count = vim.api.nvim_buf_line_count(buf)
        current_config.highlight_function(buf, ns, 0, line_count - 1)
      end
    end

    -- 複数回の遅延実行で確実に適用
    vim.defer_fn(reapply_highlights, 500)
    vim.defer_fn(reapply_highlights, 1000)
    vim.defer_fn(reapply_highlights, 2000)
    vim.defer_fn(reapply_highlights, 3000)
    vim.defer_fn(reapply_highlights, 4000)
    vim.defer_fn(reapply_highlights, 5000)
    vim.defer_fn(reapply_highlights, 7000)
    vim.defer_fn(reapply_highlights, 10000)

    -- 保存した色でステータスラインを復元
    vim.cmd(string.format("highlight StatusLine guifg=%s guibg=%s", statusline_fg, statusline_bg))

    -- カーソル位置とスクロール位置を復元
    vim.fn.setpos('.', cursor_pos)
    vim.fn.winrestview(view)
  end, 200)
end

-- Private: 通常モード復元
disable_literate_mode = function ()
  -- カーソル位置とスクロール位置を保存
  local cursor_pos = vim.fn.getcurpos()
  local view = vim.fn.winsaveview()

  -- namespaceをクリア
  local filetype = vim.bo.filetype
  local config = load_language_config(filetype)
  if config and config.namespace then
    local ns = vim.api.nvim_create_namespace(config.namespace)
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end

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

  vim.cmd("edit!")

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

  -- Spread View中の:q を :qa の動作にするautocmd設定
  vim.api.nvim_create_autocmd('CmdlineEnter', {
    buffer = current_buf,
    callback = function()
      vim.keymap.set('c', '<CR>', function()
        local cmdline = vim.fn.getcmdline()
        if M.spread_view and cmdline == 'q' then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, false, true), 'n', false)
          vim.defer_fn(function()
            vim.cmd('qa')
          end, 10)
          return ''
        else
          return '<CR>'
        end
      end, { expr = true, buffer = current_buf })
    end
  })
end

-- Private: 通常表示復帰
disable_spread_view = function()
  -- 行番号設定を保存（Spread View前の設定に戻す）
  local original_number = vim.wo.number
  local original_relativenumber = vim.wo.relativenumber

  -- Spread View中の:q 関連のキーマップとautocmdを削除
  pcall(vim.keymap.del, 'c', '<CR>', { buffer = vim.api.nvim_get_current_buf() })

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

-- Private: TODO行の抽出
extract_todo_lines = function(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local todo_items = {}
  
  for i, line in ipairs(lines) do
    -- TODO形式の行を検出 (- [ ] または - [x])
    if line:match("^%s*-%s*%[[ x]%]") then
      table.insert(todo_items, {
        line_num = i,
        content = line:gsub("^%s*", "") -- 先頭の空白を除去
      })
    end
  end
  
  return todo_items
end

-- Private: Todo Mode有効化
enable_todo_mode = function()
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- 3ペイン作成
  vim.cmd("vsplit")
  vim.cmd("vsplit")
  
  local windows = vim.api.nvim_tabpage_list_wins(0)
  
  -- デバッグ: ウィンドウの順序を確認
  print("Debug: Total windows: " .. #windows)
  for i, win_id in ipairs(windows) do
    print("Debug: Window " .. i .. " ID: " .. win_id)
  end
  
  local left_win = windows[1]
  local center_win = windows[2] 
  local right_win = windows[3]
  
  -- TODO行を抽出（デバッグ用出力付き）
  local todo_items = extract_todo_lines(current_buf)
  
  -- デバッグ: 抽出されたTODO数を表示
  print("Debug: Found " .. #todo_items .. " TODO items")
  for i, item in ipairs(todo_items) do
    print("Debug: Line " .. item.line_num .. ": " .. item.content)
  end
  
  -- 左ペイン: TODO専用バッファ作成
  local todo_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(todo_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(todo_buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(todo_buf, 'filetype', '')  -- ファイルタイプを空にして通常色に
  vim.api.nvim_buf_set_option(todo_buf, 'modifiable', true)
  
  -- TODO行を右揃えで表示
  local win_width = vim.api.nvim_win_get_width(left_win)
  local todo_lines = {}
  
  -- TODO行を整形して表示（タスク内容 + 右端にチェックボックス）
  if #todo_items > 0 then
    for _, item in ipairs(todo_items) do
      local content = item.content
      -- チェックボックスとタスク内容を分離
      local checkbox = content:match("^-%s*(%[[ x]%])")
      local task_text = content:gsub("^-%s*%[[ x]%]%s*", "")
      
      if checkbox and task_text then
        -- タスク内容 + スペース + チェックボックスの形式
        local formatted = task_text .. " " .. checkbox
        local padding = win_width - vim.fn.strdisplaywidth(formatted) - 2
        if padding > 0 then
          formatted = string.rep(" ", padding) .. formatted
        end
        table.insert(todo_lines, formatted)
      end
    end
  else
    local msg = "No TODOs found"
    local padding = win_width - vim.fn.strdisplaywidth(msg) - 2
    if padding > 0 then
      msg = string.rep(" ", padding) .. msg
    end
    table.insert(todo_lines, msg)
  end
  
  -- デバッグ: 設定する行数を表示
  print("Debug: Setting " .. #todo_lines .. " lines to todo buffer")
  
  vim.api.nvim_buf_set_lines(todo_buf, 0, -1, false, todo_lines)
  
  -- TODOバッファを読み取り専用に設定
  vim.api.nvim_buf_set_option(todo_buf, 'modifiable', false)
  
  -- 左ペインの設定（バッファ設定前に実行）
  vim.api.nvim_set_current_win(left_win)
  vim.wo.wrap = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  
  -- バッファを設定
  vim.api.nvim_win_set_buf(left_win, todo_buf)
  
  -- 完了済みTODO用のハイライト設定
  local ns_id = vim.api.nvim_create_namespace('splite_todo')
  
  -- ハイライトを適用
  for i, item in ipairs(todo_items) do
    local checkbox = item.content:match("^-%s*(%[[ x]%])")
    if checkbox and checkbox:match("x") then
      -- 完了済み（[x]）の行をCommentハイライトで暗く表示
      vim.api.nvim_buf_add_highlight(todo_buf, ns_id, 'Comment', i-1, 0, -1)
    end
  end
  
  -- 強制的に画面を更新
  vim.cmd("redraw!")
  
  -- 最初のウィンドウに移動（一番左のペイン）
  vim.cmd("1wincmd w")
  vim.fn.cursor(1, 1)
  
  -- 現在のウィンドウを確認
  local current_win = vim.api.nvim_get_current_win()
  print("Debug: Current window after move: " .. current_win)
  
  -- デバッグ: 左ペインの状態確認
  print("Debug: Left window ID: " .. left_win)
  print("Debug: Todo buffer ID: " .. todo_buf)
  print("Debug: Left window buffer: " .. vim.api.nvim_win_get_buf(left_win))
  
  -- 強制的にバッファ内容を確認
  local check_lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
  print("Debug: Buffer has " .. #check_lines .. " lines")
  if #check_lines > 0 then
    print("Debug: First line: " .. check_lines[1])
  end
  
  -- 中央・右ペイン: 元ファイルのSpread View表示（左ペインには影響しない）
  vim.api.nvim_set_current_win(center_win)
  if vim.api.nvim_win_get_buf(center_win) ~= current_buf then
    vim.api.nvim_win_set_buf(center_win, current_buf)
  end
  
  vim.api.nvim_set_current_win(right_win)
  if vim.api.nvim_win_get_buf(right_win) ~= current_buf then
    vim.api.nvim_win_set_buf(right_win, current_buf)
  end
  
  -- 左ペインのバッファが正しく保持されているか再確認
  print("Debug: Final left window buffer: " .. vim.api.nvim_win_get_buf(left_win))
  print("Debug: Expected todo buffer: " .. todo_buf)
  
  -- 中央ペインの設定
  vim.api.nvim_set_current_win(center_win)
  vim.wo.wrap = false
  vim.wo.number = true
  vim.wo.relativenumber = false
  
  -- 右ペインの設定  
  vim.api.nvim_set_current_win(right_win)
  vim.wo.wrap = false
  vim.wo.number = true
  vim.wo.relativenumber = false
  
  -- 中央ペインにフォーカス
  vim.api.nvim_set_current_win(center_win)
  
  -- TODOモード用スクロール同期（左ペインは除外）
  vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
    buffer = current_buf,
    callback = function()
      if vim.fn.mode():match('[vV]') then
        return
      end
      
      if M.todo_mode then
        -- 中央・右ペインのみ同期（左ペインのTODOバッファは保護）
        local windows = vim.api.nvim_tabpage_list_wins(0)
        if #windows == 3 then
          local current_win = vim.api.nvim_get_current_win()
          -- 左ペイン以外でカーソル移動があった場合のみ同期
          if current_win ~= windows[1] then
            sync_todo_scroll()
          end
        end
      end
    end
  })

  -- リアルタイムTODO更新（ファイル変更時）
  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    buffer = current_buf,
    callback = function()
      if M.todo_mode then
        -- 少し遅延させて更新（連続入力時の負荷軽減）
        vim.defer_fn(function()
          if M.todo_mode then -- 再度チェック（モードが変更されていないか）
            update_todo_panel(current_buf)
          end
        end, 100)
      end
    end
  })
end

-- Private: Todo Mode無効化
disable_todo_mode = function()
  -- 通常表示に戻る
  vim.cmd("only")
end

-- Private: TODO専用スクロール同期（左ペインは保護）
sync_todo_scroll = function()
  local windows = vim.api.nvim_tabpage_list_wins(0)
  if #windows ~= 3 then return end

  local center_win = windows[2]
  local right_win = windows[3]

  -- 中央ウィンドウの表示範囲を取得
  vim.api.nvim_set_current_win(center_win)
  local center_top = vim.fn.line('w0')
  local win_height = vim.api.nvim_win_get_height(center_win)

  -- 右ウィンドウのみ同期（左ペインは触らない）
  vim.api.nvim_set_current_win(right_win)
  local right_top = center_top + win_height
  local original_buf = vim.api.nvim_win_get_buf(center_win)
  local total_lines = vim.api.nvim_buf_line_count(original_buf)

  if right_top <= total_lines then
    -- 表示すべき内容がある場合
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

-- Private: TODOパネルの更新
update_todo_panel = function(source_buf)
  local windows = vim.api.nvim_tabpage_list_wins(0)
  if #windows ~= 3 then return end

  local left_win = windows[1]
  local left_buf = vim.api.nvim_win_get_buf(left_win)
  
  -- 左ペインがTODO専用バッファか確認
  local buf_type = vim.api.nvim_buf_get_option(left_buf, 'buftype')
  if buf_type ~= 'nofile' then return end
  
  -- 最新のTODO項目を抽出
  local todo_items = extract_todo_lines(source_buf)
  
  -- ウィンドウ幅を取得
  local win_width = vim.api.nvim_win_get_width(left_win)
  
  -- TODO行を整形して更新（タスク内容 + 右端にチェックボックス）
  local todo_lines = {}
  if #todo_items > 0 then
    for _, item in ipairs(todo_items) do
      local content = item.content
      -- チェックボックスとタスク内容を分離
      local checkbox = content:match("^-%s*(%[[ x]%])")
      local task_text = content:gsub("^-%s*%[[ x]%]%s*", "")
      
      if checkbox and task_text then
        -- タスク内容 + スペース + チェックボックスの形式
        local formatted = task_text .. " " .. checkbox
        local padding = win_width - vim.fn.strdisplaywidth(formatted) - 2
        if padding > 0 then
          formatted = string.rep(" ", padding) .. formatted
        end
        table.insert(todo_lines, formatted)
      end
    end
  else
    local msg = "No TODOs found"
    local padding = win_width - vim.fn.strdisplaywidth(msg) - 2
    if padding > 0 then
      msg = string.rep(" ", padding) .. msg
    end
    table.insert(todo_lines, msg)
  end
  
  -- 左ペインのバッファを更新
  vim.api.nvim_buf_set_option(left_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(left_buf, 0, -1, false, todo_lines)
  vim.api.nvim_buf_set_option(left_buf, 'modifiable', false)
  
  -- ハイライトをクリアして再適用
  local ns_id = vim.api.nvim_create_namespace('splite_todo')
  vim.api.nvim_buf_clear_namespace(left_buf, ns_id, 0, -1)
  
  -- 完了済みTODOにハイライト適用
  for i, item in ipairs(todo_items) do
    local checkbox = item.content:match("^-%s*(%[[ x]%])")
    if checkbox and checkbox:match("x") then
      -- 完了済み（[x]）の行をCommentハイライトで暗く表示
      vim.api.nvim_buf_add_highlight(left_buf, ns_id, 'Comment', i-1, 0, -1)
    end
  end
  
  -- 画面を更新
  vim.cmd("redraw")
end

return M
