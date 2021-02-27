# frozen_string_literal: true

module RspecIntegrationHelpers
  def expect_log_lines_to_equal(expected_lines)
    lines = read_logs_lines
    expect(lines.count).to eq(expected_lines.count),
      "log_lines is not as expected: expected #{expected_lines.count} lines, got:\n - #{lines.join "\n - "}"
    expected_lines.each_with_index do |(type, string), i|
      expect(lines[i]).to match(/^#{type[0].upcase}, \[[^\]]+\]\s+#{type.upcase} -- : #{Regexp.escape string}$/),
        "Unexpected line ##{i}.\nExpected: #{type.upcase} -- #{string}\n     Got: #{lines[i]}"
    end
  end

  def itly_default_options(options, logs)
    options.logger = ::Logger.new logs
    options.validation = Itly::Options::Validation::ERROR_ON_INVALID
    options.plugins.acceptance_plugin = { required_version: 4 }
  end

  private

  def read_logs_lines
    logs.rewind
    logs.read.split "\n"
  end
end
