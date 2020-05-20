module ManageIQ
  module Release
    class GitMirror
      module StringFormatting
        def red;    "\e[31m#{self}\e[0m" end
        def green;  "\e[32m#{self}\e[0m" end
        def yellow; "\e[33m#{self}\e[0m" end
        def cyan;   "\e[36m#{self}\e[0m" end
        def bold;   "\e[1m#{self}\e[22m" end
      end

      def initialize
        require 'manageiq/release/settings'
        ::String.prepend(StringFormatting)
      end

      def mirror_all
        Settings.git_mirror.repos_to_mirror.each { |repo, remote_source| mirror(repo.to_s, remote_source) }
      end

      def mirror(repo, remote_source)
        with_repo(repo, remote_source) do
          send("mirror_#{remote_source}_repo", repo)
        end
      end

      private

      def mirror_branches_for(repo)
        Settings.git_mirror.branch_mirror_defaults.to_h.merge(Settings.git_mirror.branch_mirror_overrides[repo].to_h || {}).each_with_object({}) { |(k, v), h| h[k.to_s] = v }
      end

      def mirror_branches(repo, source_remote, dest_remote)
        mirror_branches_for(repo).each do |source_name, dest_name|
          sync_branch(source_remote, source_name, dest_remote, dest_name)
        end
      end

      def mirror_upstream_repo(repo)
        mirror_remote_refs("upstream", "downstream")
        mirror_branches(repo, "upstream", "downstream")
        mirror_remote_refs("downstream", "backup")
      end

      def mirror_downstream_repo(repo)
        mirror_branches(repo, "downstream", "downstream")
        mirror_remote_refs("downstream", "backup")
      end

      def dry_run?
        return @dry_run if defined?(@dry_run)
        @dry_run = ARGV.include?("--dry-run")
      end

      def downstream_repo_name(repo)
        repo.sub("manageiq", Settings.git_mirror.productization_name)
      end

      def system(*args)
        puts "+ #{"dry_run: " if dry_run?}#{args.join(" ")}"
        return true if dry_run?

        args << {} unless args.last.is_a?(Hash)
        args.last[[:out, :err]] = ["/tmp/mirror_helper_out", "w"]

        super.tap do |result|
          puts "!!! An error has occurred:\n#{File.read("/tmp/mirror_helper_out")}".bold.red unless result
        end
      end

      def with_repo(repo, remote_source)
        repo_name = downstream_repo_name(repo)
        puts "\n==== Mirroring #{repo_name} ====".bold.cyan

        path = "#{Settings.git_mirror.working_directory}/#{repo_name}"
        clone_repo(repo, repo_name, path, remote_source) unless File.directory?(path)

        Dir.chdir(path) do
          puts "\n==== Fetching for #{repo_name} ====".bold.green
          # Enforce an order for remote fetching to ensure that moved
          #   tags prefer what is on upstream
          system("git fetch backup --prune --tags") if remote_exists?("backup")
          system("git fetch downstream --prune --tags")
          system("git fetch upstream --prune --tags") if [:red_hat_cloudforms, :upstream].include?(remote_source)

          yield
        end

        puts
      end

      def clone_repo(upstream_repo, downstream_repo, path, remote_source)
        system("git clone #{Settings.git_mirror.remotes[remote_source]}/#{upstream_repo}.git #{path} -o upstream")
        Dir.chdir(path) do
          system("git remote add downstream #{Settings.git_mirror.remotes.downstream}/#{downstream_repo}.git") unless remote_exists?("downstream")
          system("git remote add backup #{Settings.git_mirror.remotes.backup}/#{downstream_repo}.git") if Settings.git_mirror.remotes.backup && !remote_exists?("backup")
        end
      end

      def remote_refs(remote)
        return unless remote_exists?(remote)

        `git ls-remote #{remote} | grep "heads"`.split("\n").collect do |line|
          branch = line.split("/").last
          next if remote == "upstream" && !upstream_branch?(branch)
          "#{remote}/#{branch}:refs/heads/#{branch}"
        end.compact.join(" ")
      end

      def remote_exists?(remote)
        `git ls-remote #{remote} --exit-code 2>/dev/null`
        $? == 0
      end

      def upstream_branch?(branch)
        (Settings.git_mirror.branch_mirror_defaults.keys.collect(&:to_s) + ["master"]).include?(branch)
      end

      def remote_branch?(branch)
        !`git branch -r | grep #{branch}`.strip.empty?
      end

      def sync_branch(source_remote, source_name, dest_remote, dest_name, include_backup = true)
        return unless dest_remote && dest_name

        source_fq_name = "#{source_remote}/#{source_name}"
        dest_fq_name   = "#{dest_remote}/#{dest_name}"

        puts "\n==== Syncing #{source_name} to #{dest_name} ====".bold.green
        unless remote_branch?(source_fq_name)
          puts "! Skipping sync of #{source_name} to #{dest_name} since #{source_fq_name} branch does not exist".yellow
          return
        end

        start_point = remote_branch?(dest_fq_name) ? dest_fq_name : source_fq_name
        system("git rebase --abort || true") # `git rebase --abort` will exit non-zero if there's nothing to abort
        system("git reset --hard")

        success =
          system("git checkout -B #{dest_name} #{start_point}") &&
          system("git pull --rebase=preserve #{source_remote} #{source_name}") &&
          system("git push -f #{dest_remote} #{dest_name}")

        if include_backup
          if success && remote_exists?("backup")
            success = system("git push -f backup #{dest_name}")
          else
            puts "! Skipping sync of #{source_name} to backup/#{dest_name} since backup remote does not exist".yellow
          end
        end

        success
      end

      def mirror_remote_refs(source_remote, dest_remote)
        puts "\n==== Mirroring #{source_remote} to #{dest_remote} ====".bold.green
        unless remote_exists?(dest_remote)
          puts "! Skipping mirror of #{source_remote} to #{dest_remote} since #{dest_remote} does not exist".yellow
          return
        end

        refs = remote_refs(source_remote)
        if refs.to_s.strip.empty?
          puts "! Skipping mirror of #{source_remote} to #{dest_remote} since there are no refs to mirror".yellow
          return
        end

        system("git push #{dest_remote} #{remote_refs(source_remote)}") &&
          system("git push -f #{dest_remote} --tags")
      end
    end
  end
end
