-- Lua language configuration for splite.nvim

return {
  syntax = "lua",
  background = "#011628",
  normal_fg = "#44475a",  -- rustと同じ色
  comment_fg = "#CBE0F0",
  
  -- namespace管理
  namespace = "splite_lua",
  
  -- 標準Lua構文を徹底的に無効化（エラー無視）
  clear_standard = 'silent! syntax clear luaComment | silent! syntax clear luaCommentLong | silent! syntax clear luaCommentDelimiter | ' ..
                   'silent! syntax clear luaString2 | silent! syntax clear luaStringDelimiter | silent! syntax clear luaLongString',
  
  comment_region = 'syntax region lt_lua_Comment start="--\\[\\[lt" end="\\]\\]" ' ..
                   'contains=SpliteLuaDelimiter',
  delimiter = 'syntax match SpliteLuaDelimiter "--\\[\\[lt" contained | syntax match SpliteLuaDelimiter "\\]\\]" contained',
  
  -- ハイライトグループ定義関数  
  color_setup = function()
    local debug_file = io.open("/tmp/splite_debug.log", "a")
    debug_file:write("=== LUA COLOR_SETUP CALLED ===\n")
    debug_file:close()
    -- 基本色設定
    vim.cmd("hi! Normal guifg=#44475a guibg=#011628")
    vim.cmd("hi! Comment guifg=#44475a guibg=#011628 gui=italic")  -- 通常コメントも暗く
    
    -- Lua標準ハイライトを暗くする
    vim.cmd("hi! link Identifier Normal")
    vim.cmd("hi! link Statement Normal") 
    vim.cmd("hi! link Function Normal")
    vim.cmd("hi! link String Normal")
    vim.cmd("hi! link Number Normal")
    vim.cmd("hi! link Operator Normal")
    vim.cmd("hi! link Keyword Normal")
    vim.cmd("hi! link Type Normal")
    vim.cmd("hi! link Special Normal")
    vim.cmd("hi! link PreProc Normal")
    vim.cmd("hi! link Constant Normal")
    vim.cmd("hi! link Variable Normal")
    -- Tree-sitter関連
    vim.cmd("hi! link @variable Normal")
    vim.cmd("hi! link @operator Normal")
    vim.cmd("hi! link @keyword Normal")
    vim.cmd("hi! link @comment Normal")  -- Tree-sitterコメントも暗く
    
    -- Literateハイライト
    vim.cmd("hi! clear SpliteLuaH1")
    vim.cmd("hi! SpliteLuaH1 guifg=#ff79c6 guibg=#011628 gui=bold,underline")
    vim.cmd("hi! clear SpliteLuaH2") 
    vim.cmd("hi! SpliteLuaH2 guifg=#f7768e guibg=#011628 gui=bold")
    vim.cmd("hi! clear SpliteLuaH3")
    vim.cmd("hi! SpliteLuaH3 guifg=#e0af68 guibg=#011628 gui=bold")
    vim.cmd("hi! clear SpliteLuaH4")
    vim.cmd("hi! SpliteLuaH4 guifg=#9ece6a guibg=#011628")
    vim.cmd("hi! clear SpliteLuaBold")
    vim.cmd("hi! SpliteLuaBold guifg=#ff9500 guibg=#011628 gui=bold")
    vim.cmd("hi! clear SpliteLuaItalic")
    vim.cmd("hi! SpliteLuaItalic guifg=#f8f8f2 guibg=#011628 gui=italic")
    vim.cmd("hi! clear SpliteLuaCodeInline")
    vim.cmd("hi! SpliteLuaCodeInline guifg=#50fa7b guibg=#44475a gui=bold")
    vim.cmd("hi! clear SpliteLuaCodeBlock")
    vim.cmd("hi! SpliteLuaCodeBlock guifg=#50fa7b guibg=#2d3748 gui=bold")
    vim.cmd("hi! clear SpliteLuaList")
    vim.cmd("hi! SpliteLuaList guifg=#8be9fd guibg=#011628")
    vim.cmd("hi! clear SpliteLuaText")
    vim.cmd("hi! SpliteLuaText guifg=#CBE0F0 guibg=#011628")  -- Literateコメント内の通常テキスト
    vim.cmd("hi! clear SpliteLuaDelimiter")
    vim.cmd("hi! SpliteLuaDelimiter guifg=#44475a gui=italic")
  end,
  
  -- リアルタイム範囲検出関数
  find_literate_range = function(buf, target_line)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local start_line = -1
    local end_line = -1
    
    local debug_file = io.open("/tmp/splite_debug.log", "a")
    debug_file:write("find_literate_range called for line " .. target_line .. "\n")
    
    -- 上方向に検索してlt開始を探す
    for i = target_line, 1, -1 do
      if string.find(lines[i] or "", "%-%-%[%[lt") then
        start_line = i
        debug_file:write("Found lt start at line " .. i .. "\n")
        break
      elseif string.find(lines[i] or "", "%]%]") then
        -- 別のブロックの終端に当たったら停止
        debug_file:write("Hit block end at line " .. i .. ", stopping upward search\n")
        break
      end
    end
    
    -- 下方向に検索して対応する終了を探す
    if start_line > 0 then
      for i = start_line + 1, #lines do
        if string.find(lines[i] or "", "%]%]") then
          end_line = i
          debug_file:write("Found lt end at line " .. i .. "\n")
          break
        end
      end
    end
    
    debug_file:write("Range result: start=" .. start_line .. ", end=" .. end_line .. "\n")
    debug_file:close()
    
    return start_line, end_line
  end,

  -- 動的ハイライト適用関数
  highlight_function = function(buf, ns, first, last)
    local debug_file = io.open("/tmp/splite_debug.log", "a")
    debug_file:write("highlight_function called: lines " .. first .. " to " .. last .. "\n")
    debug_file:close()
    vim.api.nvim_buf_clear_namespace(buf, ns, first, last + 1)
    
    local lines = vim.api.nvim_buf_get_lines(buf, first, last + 1, false)
    for l, line in ipairs(lines) do
      local lnum = first + l - 1
      local current_line_offset = lnum + 1  -- 1-indexedに変換
      
      -- 改善された範囲検出を使用
      local config = require("splite.languages.lua")
      local lt_start, lt_end = config.find_literate_range(buf, current_line_offset)
      local in_literate = (lt_start > 0 and lt_end > 0 and current_line_offset >= lt_start and current_line_offset <= lt_end)
      
      local debug_file = io.open("/tmp/splite_debug.log", "a")
      debug_file:write("Processing line " .. (lnum + 1) .. " in_literate=" .. tostring(in_literate) .. ": " .. line .. "\n")
      debug_file:close()
      
      -- 装飾要素を最初に適用
      -- 見出しパターンマッチング（H4→H1の順で判定）
      local h4_start, h4_end = string.find(line, "^%s*####.*$")
      if h4_start then
        vim.api.nvim_buf_add_highlight(buf, ns, "SpliteLuaH4", lnum, h4_start-1, h4_end)
      else
        local h3_start, h3_end = string.find(line, "^%s*###[^#].*$")
        if h3_start then
          vim.api.nvim_buf_add_highlight(buf, ns, "SpliteLuaH3", lnum, h3_start-1, h3_end)
        else
          local h2_start, h2_end = string.find(line, "^%s*##[^#].*$")
          if h2_start then
            vim.api.nvim_buf_add_highlight(buf, ns, "SpliteLuaH2", lnum, h2_start-1, h2_end)
          else
            local h1_start, h1_end = string.find(line, "^%s*#[^#].*$")
            if h1_start then
              -- 基本テキストの上に装飾要素を重ねる
              vim.api.nvim_buf_add_highlight(buf, ns, "SpliteLuaH1", lnum, h1_start-1, h1_end)
            end
          end
        end
      end
      
      -- テキスト装飾パターンマッチング
      -- Bold: **text**
      local bold_start = 1
      while true do
        local start_pos, end_pos = string.find(line, "%*%*[^*]+%*%*", bold_start)
        if not start_pos then break end
        vim.api.nvim_buf_add_highlight(buf, ns, "SpliteLuaBold", lnum, start_pos-1, end_pos)
        bold_start = end_pos + 1
      end
      
      -- Italic: *text* (but not **text**)  
      local italic_start = 1
      while true do
        local start_pos, end_pos = string.find(line, "%*[^*%s][^*]*%*", italic_start)
        if not start_pos then break end
        -- **text**内のマッチを除外
        local before_char = start_pos > 1 and string.sub(line, start_pos-1, start_pos-1) or ""
        local after_char = end_pos < #line and string.sub(line, end_pos+1, end_pos+1) or ""
        if before_char ~= "*" and after_char ~= "*" then
          vim.api.nvim_buf_add_highlight(buf, ns, "SpliteLuaItalic", lnum, start_pos-1, end_pos)
        end
        italic_start = end_pos + 1
      end
      
      -- インラインコード: `code`
      local inline_start = 1
      while true do
        local start_pos, end_pos = string.find(line, "`[^`]+`", inline_start)
        if not start_pos then break end
        vim.api.nvim_buf_add_highlight(buf, ns, "SpliteLuaCodeInline", lnum, start_pos-1, end_pos)
        inline_start = end_pos + 1
      end
      
      -- コードブロック: ```
      if string.find(line, "^%s*```") then
        vim.api.nvim_buf_add_highlight(buf, ns, "SpliteLuaCodeBlock", lnum, 0, #line)
      end
      
      -- リスト: - * +
      if string.find(line, "^%s*[-*+]%s+.*$") then
        vim.api.nvim_buf_add_highlight(buf, ns, "SpliteLuaList", lnum, 0, #line)
      end
      
      -- 最後に基本テキストを適用
      if in_literate and not string.find(line, "%-%-%[%[lt") and not string.find(line, "%]%]") then
        local debug_file2 = io.open("/tmp/splite_debug.log", "a")
        debug_file2:write("Applying base text: line " .. (lnum + 1) .. "\n")
        debug_file2:close()
        
        -- 常に基本テキストを適用（装飾要素は後から上書きされている）
        vim.api.nvim_buf_add_highlight(buf, ns, "SpliteLuaText", lnum, 0, #line)
      end
    end
  end,
  
  highlight_groups = {
    'highlight! link SpliteLuaDelimiter Comment'
  }
}
