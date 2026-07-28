{...}: {
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      -- ── Bidirectional text ────────────────────────────────────────────
      -- Required for Persian: without it, RTL runs render in logical order
      -- rather than visual order, so the line reads backwards.
      config.bidi_enabled = true
      config.bidi_direction = "AutoLeftToRight"

      -- ── Fonts ─────────────────────────────────────────────────────────
      -- Ligatures off: in a terminal they turn != and -> into glyphs that
      -- no longer line up with the cell grid, which is worse next to RTL text.
      config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

      -- Latin first, then Persian. Sahel is the heaviest maintained Persian
      -- family, so it stays legible when squeezed into terminal cells;
      -- Vazirmatn is the fallback for glyphs Sahel lacks.
      config.font = wezterm.font_with_fallback {
        { family = "JetBrainsMono Nerd Font", weight = "Regular" },
        { family = "Sahel",     weight = "Bold",    scale = 1.05 },
        { family = "Vazirmatn", weight = "Medium",  scale = 1.05 },
        { family = "Noto Sans Arabic" },
        "Twitter Color Emoji",
      }
      -- 12.5 sits between the original 12.0 (Latin looked fine, Persian was
      -- cramped) and 13.0 (everything oversized). With the 1.05 Persian
      -- scale below, Persian lands at ~13.1 — a nudge above Latin rather
      -- than the ~15 that 13.0 x 1.15 produced.
      config.font_size = 12.5

      -- Bold Persian at small sizes fills in and becomes a blob. Using the
      -- Black weight only for bold keeps the contrast visible.
      config.font_rules = {
        {
          intensity = "Bold",
          font = wezterm.font_with_fallback {
            { family = "JetBrainsMono Nerd Font", weight = "Bold" },
            { family = "Sahel", weight = "Black", scale = 1.05 },
          },
        },
        {
          italic = true,
          font = wezterm.font_with_fallback {
            { family = "JetBrainsMono Nerd Font", italic = true },
            { family = "Sahel", weight = "Bold", scale = 1.05 },
          },
        },
      }

      -- Minimal extra leading for Persian ascenders and descenders. Larger
      -- values stretch the cell without enlarging the glyphs, which reads
      -- as Latin shrinking.
      config.line_height = 1.03
      config.cell_width = 1.0

      config.freetype_load_target = "Light"
      config.freetype_render_target = "HorizontalLcd"

      config.window_padding = {
        left = 10,
        right = 10,
        top = 10,
        bottom = 10,
      }
      config.window_background_opacity = 0.85
      config.enable_tab_bar = false
      config.colors = {
        foreground = "#e0e0e0",
        background = "#0b0b0e",
        cursor_bg = "#f5e0dc",
        cursor_fg = "#1e1e2e",
        selection_bg = "#f5e0dc",
        selection_fg = "#1e1e2e",
        ansi = {"#161617","#eb6f92","#a6e3a1","#f9e2af","#89b4fa","#cba6f7","#94e2d5","#cdd6f4"},
        brights = {"#3b3b3b","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#cba6f7","#94e2d5","#bac2de"},
      }

      return config
    '';
  };

  # Kitty is the primary terminal (Mod+Return). Its BiDi support is weaker
  # than WezTerm's — it has no reordering engine, so a mixed Persian/Latin
  # line can still come out in logical order. For heavy Persian work, and
  # for talking to agents in Persian, prefer WezTerm.
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12.5;
    };

    # Persian fallback. Kitty resolves these in order for codepoints the
    # primary font lacks; Sahel Bold is used because the regular weight
    # looks hollow once squeezed into terminal cells.
    extraConfig = ''
      symbol_map U+0600-U+06FF,U+0750-U+077F,U+FB50-U+FDFF,U+FE70-U+FEFF Sahel
      font_features Sahel +ss01
      modify_font cell_height 103%
      text_composition_strategy legacy
    '';

    settings = {
      background_opacity = "0.85";
      dynamic_background_opacity = "yes";
      background = "#0b0b0e";
      foreground = "#e0e0e0";
      window_padding_width = 10;
      confirm_os_window_close = 0;
      cursor_shape = "beam";
      repaint_delay = 10;
      input_delay = 3;
      scrollback_lines = 10000;
      enable_audio_bell = false;
      visual_bell_duration = 0;
      disable_ligatures = "never";
      color0 = "#161617";
      color1 = "#eb6f92";
      color2 = "#a6e3a1";
      color3 = "#f9e2af";
      color4 = "#89b4fa";
      color5 = "#cba6f7";
      color6 = "#94e2d5";
      color7 = "#cdd6f4";
      color8 = "#3b3b3b";
      color9 = "#f38ba8";
      color10 = "#a6e3a1";
      color11 = "#f9e2af";
      color12 = "#89b4fa";
      color13 = "#cba6f7";
      color14 = "#94e2d5";
      color15 = "#bac2de";
      cursor = "#f5e0dc";
      cursor_text_color = "#1e1e2e";
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";
    };
    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+up" = "scroll_line_up";
      "ctrl+shift+down" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
      "ctrl+shift+f" = "show_scrollback";
    };
  };
}
