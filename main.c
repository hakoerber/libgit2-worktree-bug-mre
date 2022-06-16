#include<stdio.h>
#include<git2.h>

int main(int argc, char *argv[]) {
    char *worktree_name = argv[1];
    printf("Creating worktree %s\n", worktree_name);

    git_libgit2_init();

    git_repository *repo = NULL;
    int error = git_repository_open(&repo, ".");
    if (error < 0) {
        return 1;
    }

    git_worktree *worktree = NULL;
    error = git_worktree_add(&worktree, repo, worktree_name, worktree_name, NULL);
    if (error < 0) {
        const git_error *e = git_error_last();
        printf("Error: %s\n", e->message);
        return 1;
    }

    git_libgit2_shutdown();
    printf("Done\n");
    return 0;
}
