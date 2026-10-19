-- Language servers, Mason integration and formatting.
--
-- mason.nvim installs servers into the per-project home volume on first use.
-- Servers that the language toolchains already provide system-wide
-- (rust-analyzer, gopls, clangd) are still managed here for consistency, but
-- Mason will reuse/download them into its own prefix.

return {
  { "williamboman/mason.nvim", opts = {} },

  { "neovim/nvim-lspconfig", lazy = false },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = {
        "bashls",
        "clangd",
        "cssls",
        "gopls",
        "html",
        "jsonls",
        "lua_ls",
        "rust_analyzer",
        "tailwindcss",
        "vtsls",
        "yamlls",
      },
      automatic_enable = true,
    },
    config = function(_, opts)
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
      end
      require("mason-lspconfig").setup(opts)
    end,
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "stylua" },
    },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
        fish = { "fish_indent" },
        go = { "gofmt" },
        lua = { "stylua" },
        rust = { "rustfmt" },
      },
      format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
    },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        desc = "Format buffer",
      },
    },
  },
}
