module ManageIQ
  module Release
    class PullRequestBlasterOuter
      module ScriptHelpers
        def expect_env_vars!(*vars)
          missing = vars.flatten.reject { |k| ENV.key?(k) }
          if missing.any?
            puts "ERROR: Expected the following env vars set:\n\t#{missing.join("\n\t")}"
            exit 1
          end
        end

        def system!(*args)
          exit($CHILD_STATUS.exitstatus) unless system(*args)
        end
      end
    end
  end
end
