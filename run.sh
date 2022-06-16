#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# Start from a clean state
rm -rf ./example_with_libgit2
rm -rf ./example_with_git_cli
rm -rf ./example_with_git2-rs

# a.out is just a thin wrapper around `git_worktree_add()`.
make a.out

mkdir ./example_with_libgit2

(
    cd ./example_with_libgit2

    git init >/dev/null
    git commit --allow-empty --no-edit --message "Initial commit" >/dev/null

    LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}:../libgit2/build ../a.out a/foo || true

    # > Creating worktree a/foo
    # > Error: failed to make directory '/tmp/example_with_libgit2/.git/worktrees/a/foo': No such file or directory
    #
    # Hmmm, fails. Let's try to create the base directory manually:
    mkdir -p ./.git/worktrees/a

    LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}:../libgit2/build ../a.out a/foo || true
    # > Creating worktree a/foo
    # > Error: failed to make directory 'a/foo': No such file or directory
    #
    # Still fails, but with a different error message
    #
    # Again, create the directory manually:
    mkdir ./a

    # (Note that we actually have to remove the worktree's configuration
    # directory, otherwise libgit will fail with:
    #
    # Error: failed to make directory '/tmp/example_with_libgit2/.git/worktrees/a/foo': directory exists
    rm -rf ./.git/worktrees/a/foo

    LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}:../libgit2/build ../a.out a/foo

    # That worked!

    ls -l ./.git/worktrees
)

# As a comparison, lets use git CLI
#
# The git CLI will create the worktree's configuration directory inside
# {git_dir}/worktrees/{last_path_component}
mkdir ./example_with_git_cli

(
    cd ./example_with_git_cli

    git init >/dev/null
    git commit --allow-empty --no-edit --message "Initial commit" >/dev/null

    git worktree add a/foo -b a/foo

    ls -l ./.git/worktrees
    # > drwxrwxr-x 3 hannes-private hannes-private 4096 Jun 16 23:59 3
    #
    # Interesting: When adding a worktree with a different name but the same
    # final path component, git starts adding a counter suffix to the worktree
    # directories.

    git worktree add b/foo -b b/foo
    git worktree add c/foo -b c/foo

    ls -l ./.git/worktrees
    # > drwxrwxr-x 3 hannes-private hannes-private 4096 Jun 16 23:59 foo
    # > drwxrwxr-x 3 hannes-private hannes-private 4096 Jun 16 23:59 foo1
    # > drwxrwxr-x 3 hannes-private hannes-private 4096 Jun 16 23:59 foo2

    # I *guess* that the mapping back from the worktree directory under .git to
    # the actual worktree directory is done via the `gitdir` file inside
    # `.git/worktrees/{worktree}.  This means that the actual directory would
    # not matter. You can verify this by just renaming it:

    mv .git/worktrees/foo .git/worktrees/foobar
    git worktree list

    # > /tmp/example_with_git_cli        72cf3d15 [master]
    # > /tmp/example_with_git_cli/a/foo  0986bee2 [a/foo]
    # > /tmp/example_with_git_cli/b/foo  0986bee2 [b/foo]
    # > /tmp/example_with_git_cli/c/foo  0986bee2 [c/foo]
    #
    # As you can see, it still works.
)

mkdir ./example_with_git2-rs

(
    cd ./example_with_git2-rs

    # The rust script is just using git2::Repository::worktree, which wraps
    # `git_add_worktree()`. It shows the same behaviour (as expected).

    git init >/dev/null
    git commit --allow-empty --no-edit --message "Initial commit" >/dev/null

    # This is required, otherwise we get the same errors as with raw libgit2 above.
    mkdir -p ./.git/worktrees/a
    mkdir -p ./a

    cargo run --manifest-path ../git2-rs/Cargo.toml a/foo
)
