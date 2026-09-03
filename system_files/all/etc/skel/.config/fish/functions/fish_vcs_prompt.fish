function fish_vcs_prompt --description "Print all vcs prompts"
    # Execute Jujutsu first. If it succeeds, stop and return 0
    fish_jj_prompt
    and return 0

    # Fall back to standard git or hg if no jj environment is active
    fish_git_prompt $argv
    or fish_hg_prompt $argv
end

