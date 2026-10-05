# Browser UI colors only; keep the native layout and system-specific controls.
colors: ''
  :root {
    --lwt-accent-color: ${colors.base00} !important;
    --lwt-text-color: ${colors.base05} !important;
    --lwt-toolbar-field-background-color: ${colors.base02} !important;
    --lwt-toolbar-field-color: ${colors.base05} !important;
    --lwt-toolbar-field-border-color: ${colors.base03} !important;
    --lwt-toolbar-field-focus: ${colors.base00} !important;
    --lwt-toolbar-field-focus-color: ${colors.base05} !important;
    --lwt-tab-text: ${colors.base05} !important;
    --lwt-tab-line-color: ${colors.base0D} !important;
    --toolbox-bgcolor: ${colors.base00} !important;
    --toolbox-textcolor: ${colors.base05} !important;
    --toolbar-bgcolor: ${colors.base00} !important;
    --toolbar-color: ${colors.base05} !important;
    --toolbar-field-background-color: ${colors.base02} !important;
    --toolbar-field-color: ${colors.base05} !important;
    --toolbar-field-border-color: ${colors.base03} !important;
    --toolbar-field-focus-background-color: ${colors.base00} !important;
    --toolbar-field-focus-color: ${colors.base05} !important;
    --toolbar-field-focus-border-color: ${colors.base0D} !important;
    --toolbarbutton-icon-fill: ${colors.base05} !important;
    --toolbarbutton-hover-background: ${colors.base02} !important;
    --toolbarbutton-active-background: ${colors.base03} !important;
    --tab-selected-bgcolor: ${colors.base02} !important;
    --tab-selected-textcolor: ${colors.base05} !important;
    --arrowpanel-background: ${colors.base00} !important;
    --arrowpanel-color: ${colors.base05} !important;
    --arrowpanel-border-color: ${colors.base03} !important;
    --panel-background: ${colors.base00} !important;
    --panel-color: ${colors.base05} !important;
    --sidebar-background-color: ${colors.base00} !important;
    --sidebar-text-color: ${colors.base05} !important;
    --sidebar-border-color: ${colors.base03} !important;
    --focus-outline-color: ${colors.base0D} !important;
  }

  #navigator-toolbox, #TabsToolbar, #titlebar {
    background-color: ${colors.base00} !important;
    color: ${colors.base05} !important;
  }

  #nav-bar, #PersonalToolbar, #sidebar-box, #sidebar-main {
    background-color: ${colors.base00} !important;
    color: ${colors.base05} !important;
  }

  #urlbar-background, #searchbar {
    background-color: ${colors.base02} !important;
    color: ${colors.base05} !important;
    border-color: ${colors.base03} !important;
  }

  #urlbar[focused] > #urlbar-background {
    border-color: ${colors.base0D} !important;
  }

  .tabbrowser-tab[selected] .tab-background {
    background-color: ${colors.base02} !important;
    box-shadow: inset 0 -2px ${colors.base0D} !important;
  }
''
