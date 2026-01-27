# frozen_string_literal: true

module Docyard
  class Doctor
    Issue = Struct.new(:file, :line, :target, keyword_init: true)
  end
end
