# blog-src

:see_no_evil: :books:  My blog source code, built by [hugo](https://github.com/gohugoio/hugo).

- [博客地址](https://shipengqi.github.io)，Deployed on GitHub Pages.

## Usage

Development:

```
# init submodule, set the URLs and paths of the submodules based on the information in the .gitmodules file, 
# but will not download the submodule's content
# after cloning a repository containing submodules, run this command to initialize the submodules.
git submodule init

# Update the submodule's content to the latest commit in the branch specified in the .gitmodules file
# Run this command after initializing a submodule, or when you need to update the contents of a submodule.
git submodule update

# git submodule add git@github.com:0voice/interview_internal_reference.git themes/LoveIt

# start server
hugo serve

# or 
hugo serve --disableFastRender
```

Manually deploy:

```
./deploy.sh
```

> Any changes in the `content` directory will automatically trigger a deployment.

## 主题

[LoveIt](https://github.com/dillonzq/LoveIt)
