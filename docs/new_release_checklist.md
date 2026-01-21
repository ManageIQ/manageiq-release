## New Release Checklist

### Build Changelog

- [ ] Build the changelog pages from the manageiq-release repository, and copy the result into the manageiq.org repository

  ```sh
  multi_repo show_commit_history --from radjabov-2 --to spassky-1 --repo-set spassky --display pr-changelog
  ```

- [ ] Analyze the changelog for important highlights, and be sure to put those highlights in the [Roadmap](https://www.manageiq.org/roadmap/) for the release, setting the column and the milestone.

### Update Website

- [ ] If there are CVEs, prepare them for publishing.
- [ ] Create blog post announcement in manageiq.org repository, highlighting all of the changes that were put into the roadmap, and including the changelog pages.
- [ ] Update the downloads and docs pages accordingly.

### Publish

- [ ] If there are CVEs, publish them.
- [ ] Have the website PR merged and wait for deployment.

### Update other sites

- [ ] Update https://github.com/orgs/ManageIQ/discussions with a new pinned announcement and un-pin the previous announcement.

  ```text
  🎉 ManageIQ Radjabov-1 has been released 🎉

  A huge thank you to everyone in the community! You can read more about it in our blog post:

  https://www.manageiq.org/blog/2025/04/manageiq-radjabov-ga-announcement/

  You can download the Radjabov-1 release on our [downloads page](https://www.manageiq.org/download/).
  ```

- [ ] Post to social media. Be sure to pin the new announcement and un-pin the previous announcement.

  ```text
  🎉 ManageIQ Radjabov-1 has been released 🎉

  A huge thank you to everyone in the community! You can read more about it in our blog post:

  https://www.manageiq.org/blog/2025/04/manageiq-radjabov-ga-announcement/

  You can download the Radjabov-1 release on our [downloads](https://www.manageiq.org/download/) page.
  ```

  - [ ] X
  - [ ] BlueSky
  - [ ] Mastodon
  - [ ] Facebook
  - [ ] LinkedIn

- [ ] Update https://en.wikipedia.org/wiki/ManageIQ with the new release.
- [ ] Drop old branches from triage page in guides repo.
