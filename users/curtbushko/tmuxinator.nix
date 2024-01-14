{
    programs.tmuxinator = {
        enable = true;
        extraConfig = ''
            name: home
            root: ~/

            windows:
            - code:
                # 2 pane layout 50/50
                layout: 12e7,186x57,0,0{93x57,0,0,0,92x57,94,0,10}
                root: ~/workspace/github.com
                # Synchronize all panes of this window, can be enabled before or after the pane commands run.
                # 'before' represents legacy functionality and will be deprecated in a future release, in favour of 'after'
                # synchronize: after
                panes:
                    - sleep 1; clear
                    - sleep 1; clear
            - codetwo:
                # 2 pane layout 50/50
                layout: 12e7,186x57,0,0{93x57,0,0,0,92x57,94,0,10}
                root: ~/workspace/github.com
                # Synchronize all panes of this window, can be enabled before or after the pane commands run.
                # 'before' represents legacy functionality and will be deprecated in a future release, in favour of 'after'
                # synchronize: after
                panes:
                    - sleep 1; clear
                    - sleep 1; clear
            - shell:
                layout: 54ed,186x57,0,0{105x57,0,0[105x17,0,0,2,105x18,0,18,4,105x20,0,37,5],80x57,106,0,6}
                root: ~/
                # Synchronize all panes of this window, can be enabled before or after the pane commands run.
                # 'before' represents legacy functionality and will be deprecated in a future release, in favour of 'after'
                # synchronize: after
                panes:
                    - sleep 1; clear
                    - sleep 1; clear
                    - sleep 1; clear
                    - sleep 1; clear
            - kb:
                layout: 12e7,186x57,0,0{93x57,0,0,0,92x57,94,0,10}
                root: ~/Sync/KB
                # Synchronize all panes of this window, can be enabled before or after the pane commands run.
                # 'before' represents legacy functionality and will be deprecated in a future release, in favour of 'after'
                # synchronize: after
                panes:
                    - clear;
                    - clear
        '';
    };
}
