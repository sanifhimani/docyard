# frozen_string_literal: true

RSpec.shared_context "with temp directory" do
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  def create_file(relative_path, content = "# Test\n\nContent")
    full_path = File.join(temp_dir, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  def create_config(content)
    File.write(File.join(temp_dir, "docyard.yml"), content)
  end
end

RSpec.shared_context "with docs directory" do
  include_context "with temp directory"

  let(:docs_dir) { File.join(temp_dir, "docs") }

  before { FileUtils.mkdir_p(docs_dir) }

  def create_doc(relative_path, content = "---\ntitle: Test\n---\n\nContent")
    create_file(File.join("docs", relative_path), content)
  end
end
