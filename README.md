to tell your local repo/machine that the addons folder "still exists" (such that you can safely remove it), run:

git ls-files -z addons/ | xargs -0 git update-index --assume-unchanged