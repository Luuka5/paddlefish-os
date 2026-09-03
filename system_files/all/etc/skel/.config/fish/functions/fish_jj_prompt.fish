function fish_jj_prompt --description 'Write out the jj prompt'
    # Check if jj is installed
    if not command -sq jj
        return 1
    end

    # Fast-check if we are in a jj repository without mutating state
    if not jj root --quiet --ignore-working-copy >/dev/null 2>&1
        return 1
    end

    # Fetch the formatted prompt string using proven core syntax
    set -l jj_prompt (jj log --ignore-working-copy --no-graph --color never -r @ -T '
        surround("(", ")",
            separate(" ",
                change_id.short(),
                bookmarks.join(", "),
                if(conflict, "conflicted"),
                coalesce(
                    surround("\"", "\"", description.first_line().substr(0, 24)),
                    "(empty)"
                )
            )
        )
    ' 2>/dev/null)

    if test -n "$jj_prompt"
        echo -n $jj_prompt
    end
end

