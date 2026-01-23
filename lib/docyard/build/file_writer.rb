# frozen_string_literal: true

module Docyard
  module Build
    module FileWriter
      def safe_file_write(path)
        yield
      rescue Errno::EACCES => e
        raise BuildError, "Permission denied writing to #{path}: #{e.message}"
      rescue Errno::ENOSPC => e
        raise BuildError, "Disk full, cannot write to #{path}: #{e.message}"
      rescue Errno::EROFS => e
        raise BuildError, "Read-only filesystem, cannot write to #{path}: #{e.message}"
      rescue SystemCallError => e
        raise BuildError, "Failed to write #{path}: #{e.message}"
      end
    end
  end
end
