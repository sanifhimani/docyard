# frozen_string_literal: true

require_relative "lib/docyard/version"

Gem::Specification.new do |spec|
  spec.name = "docyard"
  spec.version = Docyard::VERSION
  spec.authors = ["Sanif Himani"]
  spec.email = ["sanifhimani92@gmail.com"]

  spec.summary = "Generate beautiful documentation sites from Markdown"
  spec.description = spec.summary
  spec.homepage = "https://docyard.dev"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sanifhimani/docyard"
  spec.metadata["changelog_uri"] = "https://github.com/sanifhimani/docyard/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://docyard.dev"
  spec.metadata["bug_tracker_uri"] = "https://github.com/sanifhimani/docyard/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ docs/ dist/ sig/ .github/ .rspec .rubocop .gitignore spec/ Gemfile]) ||
        %w[docyard.yml Rakefile CODE_OF_CONDUCT.md CONTRIBUTING.md SECURITY.md].include?(f)
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "cssminify", "~> 1.0"
  spec.add_dependency "kramdown", "~> 2.5"
  spec.add_dependency "kramdown-parser-gfm", "~> 1.1"
  spec.add_dependency "listen", "~> 3.0"
  spec.add_dependency "logger", "~> 1.6"
  spec.add_dependency "parallel", "~> 1.26"
  spec.add_dependency "puma", "~> 7.0"
  spec.add_dependency "rack", "~> 3.0"
  spec.add_dependency "rouge", "~> 4.0"
  spec.add_dependency "ruby-vips", "~> 2.2"
  spec.add_dependency "terser", "~> 1.2"
  spec.add_dependency "thor", "~> 1.4"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
