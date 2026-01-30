# frozen_string_literal: true

module Docyard
  module EditorLauncher
    EDITORS = {
      vscode: {
        patterns: ["code", "Code", "Visual Studio Code"],
        command: ->(f, l) { ["code", "--goto", "#{f}:#{l}"] }
      },
      cursor: { patterns: %w[cursor Cursor], command: ->(f, l) { ["cursor", "--goto", "#{f}:#{l}"] } },
      zed: { patterns: %w[zed Zed], command: ->(f, l) { ["zed", "#{f}:#{l}"] } },
      webstorm: { patterns: %w[webstorm idea], command: ->(f, l) { ["webstorm", "--line", l.to_s, f] } },
      rubymine: { patterns: %w[rubymine mine], command: ->(f, l) { ["rubymine", "--line", l.to_s, f] } },
      vim: { patterns: %w[vim nvim], command: ->(f, l) { [detect_vim, "+#{l}", f] } },
      emacs: { patterns: %w[emacs], command: ->(f, l) { ["emacs", "+#{l}", f] } }
    }.freeze

    class << self
      def available?
        !detect.nil?
      end

      def detect
        detect_from_env || detect_from_process
      end

      def open(file, line = 1)
        editor = detect
        return false unless editor

        command = EDITORS[editor][:command].call(file, line)
        spawn(*command, %i[out err] => File::NULL)
        true
      rescue StandardError => e
        Docyard.logger.warn("Failed to open editor: #{e.message}")
        false
      end

      private

      def detect_from_env
        %i[VISUAL EDITOR].each do |var|
          editor_cmd = ENV.fetch(var.to_s, nil)
          next unless editor_cmd

          EDITORS.each do |name, config|
            return name if config[:patterns].any? { |p| editor_cmd.include?(p) }
          end
        end
        nil
      end

      def detect_from_process
        return detect_windows_apps if Gem.win_platform?
        return nil unless command_exists?("pgrep")

        EDITORS.each do |name, config|
          config[:patterns].each do |pattern|
            return name if process_running?(pattern)
          end
        end

        detect_macos_apps
      end

      def process_running?(pattern)
        system("pgrep", "-x", pattern, out: File::NULL, err: File::NULL)
      end

      def detect_macos_apps
        return nil unless RUBY_PLATFORM.include?("darwin")

        macos_apps = {
          vscode: "Visual Studio Code",
          cursor: "Cursor",
          zed: "Zed"
        }

        macos_apps.each do |editor, app_name|
          return editor if macos_app_running?(app_name)
        end

        nil
      end

      def macos_app_running?(app_name)
        system("pgrep", "-f", app_name, out: File::NULL, err: File::NULL)
      end

      def detect_windows_apps
        windows_apps = {
          vscode: "Code.exe",
          cursor: "Cursor.exe",
          zed: "zed.exe",
          webstorm: "webstorm64.exe",
          rubymine: "rubymine64.exe"
        }

        windows_apps.each do |editor, exe|
          return editor if windows_process_running?(exe)
        end

        nil
      end

      def windows_process_running?(exe)
        system("tasklist /FI \"IMAGENAME eq #{exe}\" 2>NUL | find /I \"#{exe}\" >NUL")
      end

      def command_exists?(cmd)
        system("which", cmd, out: File::NULL, err: File::NULL)
      end

      def detect_vim
        command_exists?("nvim") ? "nvim" : "vim"
      end
    end
  end
end
