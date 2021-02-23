## New Branch Checklist

### Key

| Code            | Description                | Example     |
|-----------------|----------------------------|-------------|
| `<branch>`      | New branch name            | `lasker`    |
| `<Branch>`      | New branch name titleized  | `Lasker`    |
| `<branch#>`     | New branch number          | `12`        |
| `<nextbranch>`  | Next branch name           | `morphy`    |
| `<NextBranch>`  | Next branch name titleized | `Morphy`    |
| `<nextbranch#>` | Next branch number         | `13`        |
| `<nextbranch>`  | Next branch name           | `morphy`    |
| `<n+2branch>`   | Unnamed N+2 branch         | `N-release` |

### Steps

1. Pause the mirror script

2. Create the new branch

   - [X] In `manageiq-release@master`
     - Update repos.yml file and add section for `<branch>`
   - [X] `bin/release_branch.rb --branch <branch>`

3. Prepare development for the new branch

   - [X] Create release labels: `<branch>/yes`, `<branch>/yes?`, `<branch>/no`, `<branch>/backported`, and `<branch>/conflict`.
     - [X] Update config/labels.yml with the new labels and features.  Note: the new branch label is color #000000, the N-1 branch label color is #555555, the N-M branch label color is #dddddd
     - [X] `bin/update_labels.rb`

4. Code changes for new and master branches

   - [X] In `manageiq@<branch>`
     - [X] Update Gemfile to change the ref for manageiq_plugin, manageiq-gems-pending, and amazon_ssa_support
     - [X] Update Dockerfile to change the ref to `latest-<branch>`
     - [X] Update docker-assets/README.md to change the ref
     - [X] Update VERSION file to `<branch>-pre`
     - [X] Commit and push the changes
   - [X] In `manageiq@master`
     - [X] Update lib/vmdb/appliance.rb CODENAME to `<NextBranch>`
     - [X] Update lib/vmdb/deprecation.rb version to `<n+2branch>`
     - [X] Commit and push the changes
   - [X] In `manageiq-documentation@<branch>`
     - [X] Update _data/site_menu.yml URLs from `latest` to `<branch>`
     - [X] Commit and push the changes
   - [X] In `manageiq-documentation@master`
     - [X] Update _data/site_menu.yml and remove any `prior:` entries if they exist
     - [X] Commit and push the changes if they exist
   - [ ] In `manageiq-api@<branch>`
     - [ ] Update lib/manageiq/api/version.rb and update the version number
     - [ ] Commit and push the changes
   - [ ] In `manageiq-api@master`
     - [ ] Update lib/manageiq/api/version.rb and update the version number
     - [ ] Commit and push the changes
   - [X] In `manageiq-appliance-build@<branch>`
     - [X] Update bin/nightly-build.sh BRANCH to `<branch>`
     - [X] Update config/ova.json `vsphere_product_version` to `<branch>`
     - [X] Commit and push the changes
   - [X] In `manageiq-appliance-build@master`
     - [X] Update kickstarts/partials/main/repos.ks.erb `<branch#>-<branch>` to `<nextbranch#>-<nextbranch>`
     - [X] Update kickstarts/partials/post/repos.ks.erb `<branch#>-<branch>` to `<nextbranch#>-<nextbranch>`, if necessary
     - [X] Commit and push the changes
   - [X] In `manageiq-pods@lasker`
     - [X] Update all files mentioning `latest` (except the operator `pullPolicy`) to `latest-<branch>`
     - [X] Update all files mentioning `master` to `<branch>`
     - [X] Commit and push the changes
   - [X] In `manageiq-pods@master`
     - [X] Update images/manageiq-base/Dockerfile
       - `<branch#>-<branch>` to `<nextbranch#>-<nextbranch>`
       - `manageiq-release-<branch#>` to `manageiq-release-<nextbranch#>`
     - [X] Commit and push the changes
   - [X] In `manageiq-rpm_build@<branch>`
     - [X] Update config/options.yml ref to `<branch>`
     - [X] Ensure config/options.yml rpm.version is `<branch#>.0.0`
     - [X] Commit and push the changes
   - [X] In `manageiq-rpm_build@master`
     - [X] Update Dockerfile
       - `<branch#>-<branch>` to `<nextbranch#>-<nextbranch>`
       - `manageiq-release-<branch#>` to `manageiq-release-<nextbranch#>`
     - [X] Update config/options.yml
       - rpm.version to `<nextbranch#>.0.0`
       - rpm_repository.content `<branch#>-<branch>` to `<nextbranch#>-<nextbranch>`
       - rpms.manageiq and rpms.manageiq-release `<branch#>` in regex with `<nextbranch#>
     - [X] Rename packages/manageiq-release/manageiq-<branch#>-<branch>.repo to manageiq-<nextbranch#>-<nextbranch>.repo
     - [X] Update packages/manageiq-release/manageiq-<nextbranch#>-<nextbranch>.repo
       - `<branch#>-<branch>` to `<nextbranch#>-<nextbranch>`
     - [X] Update packages/manageiq-release/manageiq-release.spec
       - Version to `<nextbranch#>.0`
       - `<branch#>-<branch>` to `<nextbranch#>-<nextbranch>`
       - Update `%changelog`
     - [X] Update rpm_spec/changelog
       - Update `%changelog`
     - [X] Commit and push the changes
   - [X] In `amazon_ssa_support@<branch>`
     - [X] Update Gemfile to change the ref for manageiq-gems-pending
     - [X] Commit and push the changes
   - [X] In `container-amazon-smartstate@<branch>`
     - [X] Update container-assets/Gemfile to change the ref for amazon_ssa_support and manageiq-gems-pending
     - [X] Commit and push the changes
   - [X] In `manageiq-providers-amazon@<branch>`
     - [X] Update config/settings.yml agent_coordinator.docker_image from `latest` to `latest-<branch>`
     - [X] Commit and push the changes

5. Final development changes for the new branch

   - [X] Mark the new branch as protected
     - `bin/update_branch_protection.rb -b <branch>`
   - [ ] Update miq-bot
     - [ ] Add the new branch to each watched repo
     - [ ] Update the unassignable and unremovable labels for the new branch

6. Prepare for the next branch

   - [X] Create the next milestone
     - [X] `bin/update_milestone.rb --title <NextBranch> --due-on "MMM dd, YYYY"`
   - [X] Update https://manageiq.org/roadmap with new column `<NextBranch>`

7. Unpause the mirror script and adjust mirroring for the new branch


---

### Build

- [X] Create a build machine for the new branch
- [ ] Create a yum repository for the next branch for master nightlies

- [ ] Update docker hub autobuilds for manageiq-rpm_build container and container-amazon-smartstate
- [ ] Create a new box on Vagrant Cloud

### OTHER (TODO CLEANUP)

- [ ] Announce to talk.manageiq.org about the new branch

- [ ] translations person to update transifex
- [ ] translations update
- [ ] Lock down ui-classic with yarn.lock
- [ ] Lock down manageiq with Gemfile.lock
- [ ] consolidate the CHANGELOG.md file
- [ ] new documentation needed to be generated for API?
- [ ] webmaster handle new documentation for website

- [ ] ensure that container-httpd is locked down to a specific version of dbus_api_service
- [ ] ensure that httpd_configmap_generator is locked down to a specific version of httpd_configmap_generator

- [ ] should we remove unused Ruby versions from .travis.yml on new branch?
