# frozen_string_literal: true

module RspecLoggerHelpers
  def expect_log_lines_to_equal(expected_lines)
    lines = read_logs_lines
    expect(lines.count).to eq(expected_lines.count),
      "log_lines is not as expected: expected #{expected_lines.count} lines, got:\n - #{lines.join "\n - "}"
    expected_lines.each_with_index do |(type, string), i|
      expect(lines[i]).to match(/^#{type[0].upcase}, \[[^\]]+\]\s+#{type.upcase} -- : #{Regexp.escape string}$/),
        "Unexpected line ##{i}.\nExpected: #{type.upcase} -- #{string}\n     Got: #{lines[i]}"
    end
  end

  private

  def read_logs_lines
    logs.rewind
    logs.read.split "\n"
  end
end
