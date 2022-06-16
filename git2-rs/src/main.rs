use std::env;
use std::path::Path;

use git2::Repository;

fn main() {
    let repo = Repository::open(".").unwrap();
    let worktree_name = env::args().last().unwrap();
    repo.worktree(&worktree_name, Path::new(&worktree_name), None)
        .unwrap();
}
