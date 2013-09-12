require "thor"

module Ciborg
  class ConfigurationWizard < ::Thor
    include Actions

    DESCRIPTION_TEXT = "Sets up ciborg through a series of questions"

    default_task :setup

    desc "setup", DESCRIPTION_TEXT
    def setup
      return unless yes?("It looks like you're trying to set up a CI Box. Can I help? (Yes/No)")
      prompt_for_build
      prompt_for_github_key
      prompt_for_ssh_key
      prompt_for_platform
      if config.platform == 'hpcs'
        prompt_for_hpcs
      else
        prompt_for_aws
      end
      prompt_for_security_group
      prompt_for_basic_auth
      config.save
      say config.reload.display
      if user_wants_to_create_instance?
        if (config.platform == 'hpcs')
          create_hpcs_instance
        else
          create_instance
        end
        provision_server
      end
    end

    no_tasks do
      def ask_with_default(statement, default)
        question = default ? "#{statement} [#{default}]:" : "#{statement}:"
        answer = ask(question) || ""
        answer.empty? ? default : answer
      end

      def prompt_for_platform
        config.platform = ask_with_default("What platform would you like to use? (Amazon = 'aws', HP Cloud = 'hpcs')", config.platform)
      end

      def prompt_for_aws
        say("For your AWS Access Key and Secret, see https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key")
        config.aws_key = ask_with_default("Your AWS key", config.aws_key)
        config.aws_secret = ask_with_default("Your AWS secret key", config.aws_secret)
      end

      def prompt_for_hpcs
        say("For your HPCS Connection attributes, see https://account.hpcloud.com/account/api_keys")
        config.hpcs_key = ask_with_default("Your HPCS key", config.hpcs_key)
        config.hpcs_secret = ask_with_default("Your HPCS secret key", config.hpcs_secret)
        config.hpcs_identity = ask_with_default("Your HPCS identity URL", config.hpcs_identity)
        config.hpcs_zone = ask_with_default("Your HPCS zone", config.hpcs_zone)
        config.hpcs_tenant = ask_with_default("Your HPCS tenant ID", config.hpcs_tenant)
        config.instance_size = "102"
      end

      def prompt_for_security_group
        config.security_group = ask_with_default("What Security Group would you like to use?", config.security_group)
      end

      def prompt_for_basic_auth
        config.node_attributes.nginx.basic_auth_user = ask_with_default("Your CI username", config.node_attributes.nginx.basic_auth_user)
        config.node_attributes.nginx.basic_auth_password = ask_with_default("Your CI password", config.node_attributes.nginx.basic_auth_password)
      end

      def prompt_for_ssh_key
        config.server_ssh_key = ask_with_default("Path to CI server SSH key", config.server_ssh_key_path)
      end

      def prompt_for_github_key
        config.github_ssh_key = ask_with_default("Path to a SSH key authorized to clone the repository", config.github_ssh_key_path)
      end

      def prompt_for_build
        build = config.node_attributes.jenkins.builds.first || {}

        repository = ask_with_default("What is the address of your git repository?", build["repository"])
        name = ask_with_default("What would you like to name your build?", build["name"])

        if this_is_a_rails_project? && prompt_for_default_rails_script
          command = "script/ci_build.sh"
          copy_file("default_rails_build_script.sh", command)
        else
          command = ask_with_default("What command should be run during the build?", build["command"]).to_s
        end

        branch = "master"
        config.add_build name, repository, branch, command
      end

      def user_wants_to_create_instance?
        return unless config.master.nil?
        yes?("Would you like to start a cloud instance now? (Yes/No)")
      end

      def create_instance
        say("Creating instance #{config.instance_size}")
        cli.create
        say("Instance launched.")
      end

      def create_hpcs_instance
        say("Creating HPCS instance #{config.instance_size}")
        cli.create_hpcs
        say("Instance launched.")
      end

      def provision_server
        return if config.reload.master.nil?
        cli.bootstrap
        cli.chef
      end

      def config
        @config ||= Ciborg::Config.from_file(ciborg_config_path)
      end
    end

    private

    def source_paths
      [File.join(File.expand_path(File.dirname(__FILE__)), "templates")] + super
    end

    def prompt_for_default_rails_script
      return false if File.exists?('script/ci_build.sh')
      yes?("It looks like this is a Rails project.  Would you like to use the default Rails build script? (Yes/No)")
    end

    def this_is_a_rails_project?
      File.exists?('script/rails')
    end

    def ciborg_config_path
      FileUtils.mkdir_p(File.join(Dir.pwd, "config"))
      File.expand_path("config/ciborg.yml", Dir.pwd)
    end

    def cli
      Ciborg::CLI.new
    end
  end
end
