{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.nvf.homeManagerModules.default ];

  home.packages = with pkgs; [
    #tools required for Telescope
    ripgrep
    fd

    #tools needed for lazyvim
    tree-sitter
    gcc
    luarocks
    lazygit
    trash-cli
    glib

    nixpkgs-fmt # nix formatter
  ];

  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;

      globals = {
        mapleader = " ";
        maplocalleader = "\\";
        autoformat = true;
        snacks_animate = true;
        markdown_recommended_style = 0;
      };

      opts = {
        autowrite = true;
        completeopt = "menu,menuone,noselect";
        conceallevel = 2;
        confirm = true;
        cursorline = true;
        expandtab = true;
        foldlevel = 99;
        foldmethod = "indent";
        foldtext = "";
        formatoptions = "jcroqlnt";
        grepformat = "%f:%l:%c:%m";
        grepprg = "rg --vimgrep";
        ignorecase = true;
        inccommand = "nosplit";
        jumpoptions = "view";
        laststatus = 3;
        linebreak = true;
        list = true;
        mouse = "a";
        number = true;
        pumblend = 10;
        pumheight = 10;
        relativenumber = true;
        ruler = false;
        scrolloff = 4;
        sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds";
        shiftround = true;
        shiftwidth = 2;
        showmode = false;
        sidescrolloff = 8;
        signcolumn = "yes";
        smartcase = true;
        smartindent = true;
        smoothscroll = true;
        spelllang = "en";
        splitbelow = true;
        splitkeep = "screen";
        splitright = true;
        tabstop = 2;
        termguicolors = true;
        timeoutlen = 300;
        undofile = true;
        undolevels = 10000;
        updatetime = 200;
        virtualedit = "block";
        wildmode = "longest:full,full";
        winminwidth = 5;
        wrap = false;
      };

      lsp = {
        enable = true;
        formatOnSave = true;
        trouble.enable = true;
      };

      languages = {
        enableExtraDiagnostics = true;
        enableFormat = true;
        enableTreesitter = true;
        markdown = {
          enable = true;
          extensions.render-markdown-nvim.enable = true;
        };
        nix.enable = true;
        lua.enable = true;
        rust.enable = true;
        go.enable = true;
        zig.enable = true;
        typescript.enable = true;
        tsx.enable = true;
      };

      autocomplete.blink-cmp = {
        enable = true;
        friendly-snippets.enable = true;
        setupOpts = {
          keymap.preset = "enter";
          completion.documentation = {
            auto_show = true;
            auto_show_delay_ms = 200;
          };
        };
      };

      treesitter = {
        enable = true;
        addDefaultGrammars = true;
        highlight.enable = true;
        indent.enable = true;
        textobjects.enable = true;
      };

      mini = {
        ai = {
          enable = true;
          setupOpts.n_lines = 500;
        };
        icons.enable = true;
        pairs = {
          enable = true;
          setupOpts = {
            modes = {
              insert = true;
              command = true;
              terminal = false;
            };
            skip_next = "[%w%%%'%[%\"%.%`%$]";
            skip_ts = [ "string" ];
            skip_unbalanced = true;
            markdown = true;
          };
        };
      };

      binds.whichKey = {
        enable = true;
        setupOpts = {
          preset = "helix";
          spec = lib.generators.mkLuaInline ''
            {
              { "<leader><tab>", group = "tabs" },
              { "<leader>b", group = "buffer" },
              { "<leader>c", group = "code" },
              { "<leader>d", group = "debug" },
              { "<leader>f", group = "file/find" },
              { "<leader>g", group = "git" },
              { "<leader>gh", group = "hunks" },
              { "<leader>q", group = "quit/session" },
              { "<leader>s", group = "search" },
              { "<leader>u", group = "ui" },
              { "<leader>w", group = "windows", proxy = "<c-w>" },
              { "<leader>x", group = "diagnostics/quickfix" },
              { "[", group = "prev" },
              { "]", group = "next" },
              { "g", group = "goto" },
              { "gs", group = "surround" },
              { "z", group = "fold" },
            }
          '';
        };
      };

      utility = {
        grug-far-nvim = {
          enable = true;
          setupOpts.headerMaxWidth = 80;
        };
        motion.flash-nvim.enable = true;
        snacks-nvim = {
          enable = true;
          setupOpts = {
            bigfile.enabled = true;
            dashboard = {
              enabled = true;
              # Snacks' default startup section reads lazy.nvim statistics.
              sections = [
                { section = "header"; }
                {
                  section = "keys";
                  gap = 1;
                  padding = 1;
                }
              ];
              preset.keys = [
                {
                  icon = " ";
                  key = "f";
                  desc = "Find File";
                  action = ":lua Snacks.picker.files()";
                }
                {
                  icon = " ";
                  key = "n";
                  desc = "New File";
                  action = ":ene | startinsert";
                }
                {
                  icon = " ";
                  key = "p";
                  desc = "Projects";
                  action = ":lua Snacks.picker.projects()";
                }
                {
                  icon = " ";
                  key = "g";
                  desc = "Find Text";
                  action = ":lua Snacks.picker.grep()";
                }
                {
                  icon = " ";
                  key = "r";
                  desc = "Recent Files";
                  action = ":lua Snacks.picker.recent()";
                }
                {
                  icon = " ";
                  key = "s";
                  desc = "Restore Session";
                  action = ":lua require('persistence').load()";
                }
                {
                  icon = " ";
                  key = "q";
                  desc = "Quit";
                  action = ":qa";
                }
              ];
            };
            explorer.enabled = true;
            indent.enabled = true;
            input.enabled = true;
            notifier.enabled = true;
            picker.enabled = true;
            quickfile.enabled = true;
            scope.enabled = true;
            scroll.enabled = true;
            statuscolumn.enabled = false;
            words.enabled = true;
          };
        };
      };

      git = {
        enable = true;
        gitsigns = {
          enable = true;
          mappings = {
            toggleBlame = null;
            toggleDeleted = null;
          };
        };
      };

      notes.todo-comments.enable = true;

      tabline.nvimBufferline = {
        enable = true;
        setupOpts.options = {
          always_show_bufferline = false;
          numbers = "none";
        };
      };
      statusline.lualine = {
        enable = true;
        setupOpts = lib.mkForce (
          lib.generators.mkLuaInline ''
            ((function()
                return {
                  options = {
                    theme = "auto",
                    globalstatus = true,
                    disabled_filetypes = {
                      statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" },
                    },
                  },
                  sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch" },
                    lualine_c = {
                      {
                        "diagnostics",
                        symbols = {
                          error = " ",
                          warn = " ",
                          info = " ",
                          hint = " ",
                        },
                      },
                      { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
                      {
                        "filename",
                        path = 1,
                        symbols = {
                          modified = "  ",
                          readonly = "",
                          unnamed = "",
                        },
                      },
                    },
                    lualine_x = {
                      {
                        function()
                          return require("noice").api.status.command.get()
                        end,
                        cond = function()
                          return package.loaded["noice"] and require("noice").api.status.command.has()
                        end,
                      },
                      {
                        function()
                          return require("noice").api.status.mode.get()
                        end,
                        cond = function()
                          return package.loaded["noice"] and require("noice").api.status.mode.has()
                        end,
                      },
                      {
                        "diff",
                        symbols = {
                          added = " ",
                          modified = " ",
                          removed = " ",
                        },
                        source = function()
                          local signs = vim.b.gitsigns_status_dict
                          if signs then
                            return {
                              added = signs.added,
                              modified = signs.changed,
                              removed = signs.removed,
                            }
                          end
                        end,
                      },
                    },
                    lualine_y = {
                      { "progress", separator = " ", padding = { left = 1, right = 0 } },
                      { "location", padding = { left = 0, right = 1 } },
                    },
                    lualine_z = {
                      function()
                        return " " .. os.date("%R")
                      end,
                    },
                  },
                  extensions = { "quickfix" },
                }
            end)())
          ''
        );
      };

      ui.noice = {
        enable = true;
        setupOpts = {
          lsp.override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };
          presets = {
            bottom_search = true;
            command_palette = true;
            long_message_to_split = true;
          };
        };
      };

      extraPlugins = {
        persistence = {
          package = pkgs.vimPlugins.persistence-nvim;
          setup = "require('persistence').setup()";
        };
        ts-comments = {
          package = pkgs.vimPlugins.ts-comments-nvim;
          setup = "require('ts-comments').setup()";
        };
        nvim-ts-autotag = {
          package = pkgs.vimPlugins.nvim-ts-autotag;
          setup = "require('nvim-ts-autotag').setup()";
        };
      };

      luaConfigPost = ''
        -- LazyVim editor defaults that depend on runtime state.
        vim.opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
        vim.opt.fillchars = {
          foldopen = "",
          foldclose = "",
          fold = " ",
          foldsep = " ",
          diff = "╱",
          eob = " ",
        }
        vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })

        local map = function(mode, lhs, rhs, desc, opts)
          opts = vim.tbl_extend("force", { silent = true, desc = desc }, opts or {})
          vim.keymap.set(mode, lhs, rhs, opts)
        end

        -- Better movement, resizing, and line movement.
        map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", "Down", { expr = true })
        map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", "Down", { expr = true })
        map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", "Up", { expr = true })
        map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", "Up", { expr = true })
        map("n", "<C-Up>", "<cmd>resize +2<cr>", "Increase Window Height")
        map("n", "<C-Down>", "<cmd>resize -2<cr>", "Decrease Window Height")
        map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", "Decrease Window Width")
        map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", "Increase Window Width")
        map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", "Move Down")
        map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", "Move Up")
        map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", "Move Down")
        map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", "Move Up")
        map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", "Move Down")
        map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", "Move Up")

        -- Buffers and editing.
        map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", "Prev Buffer")
        map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", "Next Buffer")
        map("n", "[b", "<cmd>BufferLineCyclePrev<cr>", "Prev Buffer")
        map("n", "]b", "<cmd>BufferLineCycleNext<cr>", "Next Buffer")
        map("n", "[B", "<cmd>BufferLineMovePrev<cr>", "Move Buffer Previous")
        map("n", "]B", "<cmd>BufferLineMoveNext<cr>", "Move Buffer Next")
        map("n", "<leader>bb", "<cmd>e #<cr>", "Switch to Other Buffer")
        map("n", "<leader>`", "<cmd>e #<cr>", "Switch to Other Buffer")
        map("n", "<leader>bd", function() Snacks.bufdelete() end, "Delete Buffer")
        map("n", "<leader>bo", function() Snacks.bufdelete.other() end, "Delete Other Buffers")
        map("n", "<leader>bi", function() Snacks.bufdelete.invisible() end, "Delete Invisible Buffers")
        map("n", "<leader>bD", "<cmd>bd<cr>", "Delete Buffer and Window")
        map("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", "Toggle Pin")
        map("n", "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", "Delete Non-Pinned Buffers")
        map("n", "<leader>br", "<cmd>BufferLineCloseRight<cr>", "Delete Buffers to the Right")
        map("n", "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", "Delete Buffers to the Left")
        map("n", "<leader>bj", "<cmd>BufferLinePick<cr>", "Pick Buffer")
        map({ "i", "n", "s" }, "<esc>", function()
          vim.cmd("noh")
          if vim.snippet and vim.snippet.active({ direction = 1 }) then
            vim.snippet.stop()
          end
          return "<esc>"
        end, "Escape and Clear Highlight", { expr = true })
        map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", "Save File")
        map("x", "<", "<gv", "Indent Left")
        map("x", ">", ">gv", "Indent Right")
        map("i", ",", ",<C-g>u", nil)
        map("i", ".", ".<C-g>u", nil)
        map("i", ";", ";<C-g>u", nil)

        -- Files, formatting, diagnostics, and lists.
        map("n", "<leader>fn", "<cmd>enew<cr>", "New File")
        map({ "n", "x" }, "<leader>cf", function()
          require("conform").format({ async = false, lsp_format = "fallback", timeout_ms = 3000 })
        end, "Format")
        map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics")
        local diagnostic_jump = function(count, severity)
          return function()
            vim.diagnostic.jump({ count = count * vim.v.count1, severity = severity, float = true })
          end
        end
        map("n", "]d", diagnostic_jump(1), "Next Diagnostic")
        map("n", "[d", diagnostic_jump(-1), "Prev Diagnostic")
        map("n", "]e", diagnostic_jump(1, vim.diagnostic.severity.ERROR), "Next Error")
        map("n", "[e", diagnostic_jump(-1, vim.diagnostic.severity.ERROR), "Prev Error")
        map("n", "]w", diagnostic_jump(1, vim.diagnostic.severity.WARN), "Next Warning")
        map("n", "[w", diagnostic_jump(-1, vim.diagnostic.severity.WARN), "Prev Warning")
        map("n", "<leader>xl", "<cmd>lopen<cr>", "Location List")
        map("n", "<leader>xq", "<cmd>copen<cr>", "Quickfix List")

        -- Snacks picker and explorer, matching LazyVim's default picker.
        local picker = Snacks.picker
        map("n", "<leader>,", picker.buffers, "Buffers")
        map("n", "<leader>/", picker.grep, "Grep (Root Dir)")
        map("n", "<leader>:", picker.command_history, "Command History")
        map("n", "<leader><space>", picker.files, "Find Files (Root Dir)")
        map("n", "<leader>e", picker.explorer, "Explorer")
        map("n", "<leader>E", function() picker.explorer({ cwd = vim.uv.cwd() }) end, "Explorer (cwd)")
        map("n", "<leader>fe", picker.explorer, "Explorer")
        map("n", "<leader>fE", function() picker.explorer({ cwd = vim.uv.cwd() }) end, "Explorer (cwd)")
        map("n", "<leader>fb", picker.buffers, "Buffers")
        map("n", "<leader>fB", function() picker.buffers({ hidden = true, nofile = true }) end, "Buffers (all)")
        map("n", "<leader>ff", picker.files, "Find Files")
        map("n", "<leader>fF", function() picker.files({ cwd = vim.uv.cwd() }) end, "Find Files (cwd)")
        map("n", "<leader>fg", picker.git_files, "Find Files (git-files)")
        map("n", "<leader>fp", picker.projects, "Projects")
        map("n", "<leader>fr", picker.recent, "Recent")
        map("n", "<leader>fR", function() picker.recent({ filter = { cwd = true } }) end, "Recent (cwd)")
        map("n", "<leader>gd", picker.git_diff, "Git Diff (hunks)")
        map("n", "<leader>gs", picker.git_status, "Git Status")
        map("n", "<leader>gS", picker.git_stash, "Git Stash")
        map("n", "<leader>sb", picker.lines, "Buffer Lines")
        map("n", "<leader>sB", picker.grep_buffers, "Grep Open Buffers")
        map("n", "<leader>sg", picker.grep, "Grep (Root Dir)")
        map("n", "<leader>sG", function() picker.grep({ cwd = vim.uv.cwd() }) end, "Grep (cwd)")
        map({ "n", "x" }, "<leader>sw", picker.grep_word, "Visual Selection or Word")
        map("n", '<leader>s"', picker.registers, "Registers")
        map("n", "<leader>s/", picker.search_history, "Search History")
        map("n", "<leader>sa", picker.autocmds, "Autocmds")
        map("n", "<leader>sc", picker.command_history, "Command History")
        map("n", "<leader>sC", picker.commands, "Commands")
        map("n", "<leader>sd", picker.diagnostics, "Diagnostics")
        map("n", "<leader>sD", picker.diagnostics_buffer, "Buffer Diagnostics")
        map("n", "<leader>sh", picker.help, "Help Pages")
        map("n", "<leader>sH", picker.highlights, "Highlights")
        map("n", "<leader>si", picker.icons, "Icons")
        map("n", "<leader>sj", picker.jumps, "Jumps")
        map("n", "<leader>sk", picker.keymaps, "Keymaps")
        map("n", "<leader>sl", picker.loclist, "Location List")
        map("n", "<leader>sM", picker.man, "Man Pages")
        map("n", "<leader>sm", picker.marks, "Marks")
        map("n", "<leader>sR", picker.resume, "Resume")
        map("n", "<leader>sq", picker.qflist, "Quickfix List")
        map("n", "<leader>su", picker.undo, "Undotree")
        map("n", "<leader>uC", picker.colorschemes, "Colorschemes")

        -- Plugin workflows.
        map({ "n", "x" }, "<leader>sr", function()
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e") or nil
          require("grug-far").open({ transient = true, prefills = { filesFilter = ext ~= "" and "*." .. ext or nil } })
        end, "Search and Replace")
        map({ "n", "x", "o" }, "s", function() require("flash").jump() end, "Flash")
        map({ "n", "o", "x" }, "S", function() require("flash").treesitter() end, "Flash Treesitter")
        map("o", "r", function() require("flash").remote() end, "Remote Flash")
        map({ "o", "x" }, "R", function() require("flash").treesitter_search() end, "Treesitter Search")
        map("c", "<C-s>", function() require("flash").toggle() end, "Toggle Flash Search")
        map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", "Diagnostics (Trouble)")
        map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Buffer Diagnostics (Trouble)")
        map("n", "<leader>cs", "<cmd>Trouble symbols toggle<cr>", "Symbols (Trouble)")
        map("n", "<leader>cS", "<cmd>Trouble lsp toggle<cr>", "LSP Results (Trouble)")
        map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", "Location List (Trouble)")
        map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", "Quickfix List (Trouble)")
        map("n", "]t", function() require("todo-comments").jump_next() end, "Next Todo Comment")
        map("n", "[t", function() require("todo-comments").jump_prev() end, "Previous Todo Comment")
        map("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", "Todo (Trouble)")
        map("n", "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", "Todo/Fix/Fixme (Trouble)")
        map("n", "<leader>st", function() picker.todo_comments() end, "Todo")
        map("n", "<leader>sT", function() picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, "Todo/Fix/Fixme")

        -- Git, terminal, sessions, notifications, and tabs.
        map("n", "<leader>gg", function() Snacks.lazygit() end, "Lazygit")
        map("n", "<leader>gG", function() Snacks.lazygit({ cwd = vim.uv.cwd() }) end, "Lazygit (cwd)")
        map("n", "<leader>gl", picker.git_log, "Git Log")
        map("n", "<leader>gL", function() picker.git_log({ cwd = vim.uv.cwd() }) end, "Git Log (cwd)")
        map("n", "<leader>gb", picker.git_log_line, "Git Blame Line")
        map("n", "<leader>gf", picker.git_log_file, "Git Current File History")
        map("n", "<leader>t", function() Snacks.terminal() end, "Terminal")
        map("n", "<leader>fT", function() Snacks.terminal(nil, { cwd = vim.uv.cwd() }) end, "Terminal (cwd)")
        map({ "n", "t" }, "<C-/>", function() Snacks.terminal.toggle() end, "Terminal")
        map("n", "<leader>qs", function() require("persistence").load() end, "Restore Session")
        map("n", "<leader>qS", function() require("persistence").select() end, "Select Session")
        map("n", "<leader>ql", function() require("persistence").load({ last = true }) end, "Restore Last Session")
        map("n", "<leader>qd", function() require("persistence").stop() end, "Don't Save Current Session")
        map("n", "<leader>n", picker.notifications, "Notification History")
        map("n", "<leader>un", function() Snacks.notifier.hide() end, "Dismiss All Notifications")
        map("n", "<leader>qq", "<cmd>qa<cr>", "Quit All")
        map("n", "<leader><tab>l", "<cmd>tablast<cr>", "Last Tab")
        map("n", "<leader><tab>o", "<cmd>tabonly<cr>", "Close Other Tabs")
        map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", "First Tab")
        map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", "New Tab")
        map("n", "<leader><tab>]", "<cmd>tabnext<cr>", "Next Tab")
        map("n", "<leader><tab>d", "<cmd>tabclose<cr>", "Close Tab")
        map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", "Previous Tab")

        -- Search, windows, UI, and scratch buffers.
        map("n", "n", "'Nn'[v:searchforward].'zv'", "Next Search Result", { expr = true })
        map({ "x", "o" }, "n", "'Nn'[v:searchforward]", "Next Search Result", { expr = true })
        map("n", "N", "'nN'[v:searchforward].'zv'", "Prev Search Result", { expr = true })
        map({ "x", "o" }, "N", "'nN'[v:searchforward]", "Prev Search Result", { expr = true })
        map("n", "<leader>ur", "<cmd>nohlsearch<bar>diffupdate<bar>normal! <C-L><cr>", "Redraw")
        map("n", "<leader>w+", "<C-w>+", "Increase Window Height")
        map("n", "<leader>w-", "<C-w>-", "Decrease Window Height")
        map("n", "<leader>w<", "<C-w><", "Decrease Window Width")
        map("n", "<leader>w>", "<C-w>>", "Increase Window Width")
        map("n", "<leader>wT", "<C-w>T", "Move Window to New Tab")
        map("n", "<leader>wq", "<C-w>q", "Quit Window")
        map("n", "<leader>wx", "<C-w>x", "Swap Window")
        map("n", "<leader>wm", function() Snacks.toggle.zoom():toggle() end, "Toggle Zoom Mode")
        map("n", "<leader>.", function() Snacks.scratch() end, "Toggle Scratch Buffer")
        map("n", "<leader>S", function() Snacks.scratch.select() end, "Select Scratch Buffer")
        map("n", "<leader>dps", function() Snacks.profiler.scratch() end, "Profiler Scratch Buffer")
        map("n", "<leader>ui", vim.show_pos, "Inspect Pos")
        map("n", "<leader>uI", function()
          vim.treesitter.inspect_tree()
          vim.api.nvim_input("I")
        end, "Inspect Tree")
        map("n", "<leader>?", function() require("which-key").show({ global = false }) end, "Buffer Keymaps")
        map("n", "<C-w><space>", function()
          require("which-key").show({ keys = "<c-w>", loop = true })
        end, "Window Hydra Mode")

        -- LSP navigation and actions.
        map("n", "gd", function() picker.lsp_definitions() end, "Goto Definition")
        map("n", "gr", function() picker.lsp_references() end, "References", { nowait = true })
        map("n", "gI", function() picker.lsp_implementations() end, "Goto Implementation")
        map("n", "gy", function() picker.lsp_type_definitions() end, "Goto Type Definition")
        map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
        map("n", "K", vim.lsp.buf.hover, "Hover")
        map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
        map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
        map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
        map("n", "<leader>ss", function() picker.lsp_symbols() end, "LSP Symbols")
        map("n", "<leader>sS", function() picker.lsp_workspace_symbols() end, "LSP Workspace Symbols")
        map("n", "gai", function() picker.lsp_incoming_calls() end, "Calls Incoming")
        map("n", "gao", function() picker.lsp_outgoing_calls() end, "Calls Outgoing")

        -- Gitsigns hunk operations.
        map("n", "]h", function() require("gitsigns").nav_hunk("next") end, "Next Hunk")
        map("n", "[h", function() require("gitsigns").nav_hunk("prev") end, "Prev Hunk")
        map("n", "]H", function() require("gitsigns").nav_hunk("last") end, "Last Hunk")
        map("n", "[H", function() require("gitsigns").nav_hunk("first") end, "First Hunk")
        map({ "n", "x" }, "<leader>ghs", "<cmd>Gitsigns stage_hunk<cr>", "Stage Hunk")
        map({ "n", "x" }, "<leader>ghr", "<cmd>Gitsigns reset_hunk<cr>", "Reset Hunk")
        map("n", "<leader>ghS", "<cmd>Gitsigns stage_buffer<cr>", "Stage Buffer")
        map("n", "<leader>ghu", "<cmd>Gitsigns undo_stage_hunk<cr>", "Undo Stage Hunk")
        map("n", "<leader>ghR", "<cmd>Gitsigns reset_buffer<cr>", "Reset Buffer")
        map("n", "<leader>ghp", "<cmd>Gitsigns preview_hunk_inline<cr>", "Preview Hunk Inline")
        map("n", "<leader>ghb", "<cmd>Gitsigns blame_line full=true<cr>", "Blame Line")
        map("n", "<leader>ghB", "<cmd>Gitsigns blame<cr>", "Blame Buffer")
        map("n", "<leader>ghd", "<cmd>Gitsigns diffthis<cr>", "Diff This")
        map("n", "<leader>ghD", "<cmd>Gitsigns diffthis ~<cr>", "Diff This ~")
        map({ "o", "x" }, "ih", "<cmd>Gitsigns select_hunk<cr>", "Select Hunk")

        -- Noice command and message UI.
        map("c", "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, "Redirect Cmdline")
        map("n", "<leader>snl", function() require("noice").cmd("last") end, "Noice Last Message")
        map("n", "<leader>snh", function() require("noice").cmd("history") end, "Noice History")
        map("n", "<leader>sna", function() require("noice").cmd("all") end, "Noice All")
        map("n", "<leader>snd", function() require("noice").cmd("dismiss") end, "Dismiss All")
        map("n", "<leader>snt", function() require("noice").cmd("pick") end, "Noice Picker")

        -- Core LazyVim autocommands.
        local augroup = function(name)
          return vim.api.nvim_create_augroup("nvf_lazyvim_" .. name, { clear = true })
        end
        vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
          group = augroup("checktime"),
          callback = function() if vim.o.buftype ~= "nofile" then vim.cmd("checktime") end end,
        })
        vim.api.nvim_create_autocmd("TextYankPost", {
          group = augroup("highlight_yank"),
          callback = function() (vim.hl or vim.highlight).on_yank() end,
        })
        vim.api.nvim_create_autocmd("VimResized", {
          group = augroup("resize_splits"),
          callback = function()
            local tab = vim.fn.tabpagenr()
            vim.cmd("tabdo wincmd =")
            vim.cmd("tabnext " .. tab)
          end,
        })
        vim.api.nvim_create_autocmd("BufReadPost", {
          group = augroup("last_loc"),
          callback = function(event)
            if vim.bo[event.buf].filetype == "gitcommit" or vim.b[event.buf].lazyvim_last_loc then return end
            vim.b[event.buf].lazyvim_last_loc = true
            local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
            if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
              pcall(vim.api.nvim_win_set_cursor, 0, mark)
            end
          end,
        })
        vim.api.nvim_create_autocmd("FileType", {
          group = augroup("close_with_q"),
          pattern = {
            "PlenaryTestPopup", "checkhealth", "dap-float", "dbout", "gitsigns-blame",
            "grug-far", "help", "lspinfo", "neotest-output", "neotest-output-panel",
            "neotest-summary", "notify", "qf", "spectre_panel", "startuptime", "tsplayground",
          },
          callback = function(event)
            vim.bo[event.buf].buflisted = false
            vim.schedule(function()
              map("n", "q", function()
                vim.cmd("close")
                pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
              end, "Quit Buffer", { buffer = event.buf })
            end)
          end,
        })
        vim.api.nvim_create_autocmd("FileType", {
          group = augroup("man_unlisted"),
          pattern = "man",
          callback = function(event) vim.bo[event.buf].buflisted = false end,
        })
        vim.api.nvim_create_autocmd("FileType", {
          group = augroup("wrap_spell"),
          pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
          callback = function()
            vim.opt_local.wrap = true
            vim.opt_local.spell = true
          end,
        })
        vim.api.nvim_create_autocmd("FileType", {
          group = augroup("json_conceal"),
          pattern = { "json", "jsonc", "json5" },
          callback = function() vim.opt_local.conceallevel = 0 end,
        })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = augroup("auto_create_dir"),
          callback = function(event)
            if event.match:match("^%w%w+:[\\/][\\/]") then return end
            local file = vim.uv.fs_realpath(event.match) or event.match
            vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
          end,
        })
      '';

      keymaps = [
        {
          key = "<C-h>";
          mode = "n";
          action = "<C-w>h";
          desc = "Go to Left Window";
        }
        {
          key = "<C-j>";
          mode = "n";
          action = "<C-w>j";
          desc = "Go to Lower Window";
        }
        {
          key = "<C-k>";
          mode = "n";
          action = "<C-w>k";
          desc = "Go to Upper Window";
        }
        {
          key = "<C-l>";
          mode = "n";
          action = "<C-w>l";
          desc = "Go to Right Window";
        }
        {
          key = "<leader>wH";
          mode = "n";
          action = "<C-w>H";
          desc = "Move Window to Far Left";
        }
        {
          key = "<leader>wJ";
          mode = "n";
          action = "<C-w>J";
          desc = "Move Window to Far Bottom";
        }
        {
          key = "<leader>wK";
          mode = "n";
          action = "<C-w>K";
          desc = "Move Window to Far Top";
        }
        {
          key = "<leader>wL";
          mode = "n";
          action = "<C-w>L";
          desc = "Move Window to Far Right";
        }
        {
          key = "<leader>wh";
          mode = "n";
          action = "<C-w>h";
          desc = "Go to Left Window";
        }
        {
          key = "<leader>wj";
          mode = "n";
          action = "<C-w>j";
          desc = "Go to Lower Window";
        }
        {
          key = "<leader>wk";
          mode = "n";
          action = "<C-w>k";
          desc = "Go to Upper Window";
        }
        {
          key = "<leader>wl";
          mode = "n";
          action = "<C-w>l";
          desc = "Go to Right Window";
        }
        {
          key = "<leader>ws";
          mode = "n";
          action = "<C-w>s";
          desc = "Split Window Below";
        }
        {
          key = "<leader>wv";
          mode = "n";
          action = "<C-w>v";
          desc = "Split Window Right";
        }
        {
          key = "<leader>wd";
          mode = "n";
          action = "<C-w>c";
          desc = "Delete Window";
        }
        {
          key = "<leader>wo";
          mode = "n";
          action = "<C-w>o";
          desc = "Delete Other Windows";
        }
        {
          key = "<leader>ww";
          mode = "n";
          action = "<C-w>w";
          desc = "Switch Windows";
        }
        {
          key = "<leader>w=";
          mode = "n";
          action = "<C-w>=";
          desc = "Equally Size Windows";
        }
        {
          key = "<leader>w|";
          mode = "n";
          action = "<C-w>|";
          desc = "Maximize Window Width";
        }
        {
          key = "<leader>w_";
          mode = "n";
          action = "<C-w>_";
          desc = "Maximize Window Height";
        }
        {
          key = "<leader>-";
          mode = "n";
          action = "<C-w>s";
          desc = "Split Window Below";
        }
        {
          key = "<leader>|";
          mode = "n";
          action = "<C-w>v";
          desc = "Split Window Right";
        }
      ];

      theme = {
        enable = true;
        name = "tokyonight";
        style = "moon";
      };
    };
  };
}
