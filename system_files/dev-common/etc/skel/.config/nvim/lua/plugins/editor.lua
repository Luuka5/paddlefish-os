-- Editor, search, UI and completion plugins.

return {
  { "nvim-lua/plenary.nvim", lazy = true },

  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "<leader>sh", desc = "[S]earch [H]elp" },
      { "<leader>sk", desc = "[S]earch [K]eymaps" },
      { "<leader>sf", desc = "[S]earch [F]iles" },
      { "<leader>ss", desc = "[S]earch [S]elect Telescope" },
      { "<leader>sw", desc = "[S]earch current [W]ord" },
      { "<leader>sg", desc = "[S]earch by [G]rep" },
      { "<leader>sd", desc = "[S]earch [D]iagnostics" },
      { "<leader>sr", desc = "[S]earch [R]esume" },
      { "<leader>s.", desc = "[S]earch recent files" },
      { "<leader>sc", desc = "[S]earch [C]ommands" },
      { "<leader><leader>", desc = "[ ] Find existing buffers" },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      local b = require("telescope.builtin")
      local map = vim.keymap.set
      map("n", "<leader>sh", b.help_tags, { desc = "[S]earch [H]elp" })
      map("n", "<leader>sk", b.keymaps, { desc = "[S]earch [K]eymaps" })
      map("n", "<leader>sf", b.find_files, { desc = "[S]earch [F]iles" })
      map("n", "<leader>ss", b.builtin, { desc = "[S]earch [S]elect Telescope" })
      map("n", "<leader>sw", b.grep_string, { desc = "[S]earch current [W]ord" })
      map("n", "<leader>sg", b.live_grep, { desc = "[S]earch by [G]rep" })
      map("n", "<leader>sd", b.diagnostics, { desc = "[S]earch [D]iagnostics" })
      map("n", "<leader>sr", b.resume, { desc = "[S]earch [R]esume" })
      map("n", "<leader>s.", b.oldfiles, { desc = "[S]earch recent files" })
      map("n", "<leader>sc", b.commands, { desc = "[S]earch [C]ommands" })
      map("n", "<leader><leader>", b.buffers, { desc = "[ ] Find existing buffers" })
      map("n", "<leader>/", function()
        b.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown { winblend = 10 })
      end, { desc = "Fuzzily search in current buffer" })
      map("n", "<leader>s/", function()
        b.live_grep { grep_open_files = true }
      end, { desc = "Search in open files" })
      map("n", "<leader>sn", function()
        b.find_files { cwd = vim.fn.stdpath "config", follow = true }
      end, { desc = "Search Neovim files" })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "c", "cpp", "css", "go", "html", "javascript", "json",
          "lua", "markdown", "python", "rust", "toml", "tsx", "typescript",
          "vim", "vimdoc", "yaml",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  { "lewis6991/gitsigns.nvim", opts = {} },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  {
    "stevearc/oil.nvim",
    opts = { view_options = { show_hidden = true } },
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
      },
    },
  },

  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = true } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
  },
}
