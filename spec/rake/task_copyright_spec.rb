# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Rake::Task, :copyright do
  include_context "rake" do
    let(:task_path) { "lib/tasks/copyright" }
  end

  let(:copyright_text) do
    <<~COPYRIGHT.chomp
      OpenProject copyright.

      Released under the GPL.
    COPYRIGHT
  end

  let(:canonical_header) do
    <<~HEADER.chomp
      //-- copyright
      // OpenProject copyright.
      //
      // Released under the GPL.
      //++
    HEADER
  end

  around do |example|
    Dir.mktmpdir do |directory|
      Dir.chdir(directory) do
        File.write("COPYRIGHT_short", copyright_text)
        example.run
      end
    end
  end

  def write_source(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def expect_canonical_header(path, source)
    expect(File.read(path)).to eq("#{canonical_header}\n\n#{source}")
  end

  describe "copyright:update_typescript" do
    let(:task_name) { "copyright:update_typescript" }

    it "adds the canonical header to TypeScript and TSX files" do
      write_source("source.ts", "export const source = true;\n")
      write_source("component.tsx", "export const Component = () => null;\n")
      write_source(".config/rule.ts", "export const rule = true;\n")

      subject.invoke(".")

      expect_canonical_header("source.ts", "export const source = true;\n")
      expect_canonical_header("component.tsx", "export const Component = () => null;\n")
      expect_canonical_header(".config/rule.ts", "export const rule = true;\n")
    end

    it "normalizes spaced line and block headers" do
      write_source("spaced.ts", <<~TYPESCRIPT)
        // -- copyright
        // Old copyright.
        // ++

        export const spaced = true;
      TYPESCRIPT
      write_source("block.ts", <<~TYPESCRIPT)
        /*
         * -- copyright
         * Old copyright.
         * ++
         */

        export const block = true;
      TYPESCRIPT

      subject.invoke(".")

      expect_canonical_header("spaced.ts", "export const spaced = true;\n")
      expect_canonical_header("block.ts", "export const block = true;\n")
    end

    it "leaves an existing canonical header unchanged" do
      content = "#{canonical_header}\n\nexport const canonical = true;\n"
      write_source("canonical.ts", content)

      subject.invoke(".")

      expect(File.read("canonical.ts")).to eq(content)
    end

    it "only updates files below the provided path" do
      write_source("selected/source.ts", "export const selected = true;\n")
      write_source("outside.ts", "export const outside = true;\n")

      subject.invoke("selected")

      expect_canonical_header("selected/source.ts", "export const selected = true;\n")
      expect(File.read("outside.ts")).to eq("export const outside = true;\n")
    end

    it "preserves existing exclusions" do
      source = "export const gitlab = true;\n"
      write_source("modules/gitlab_integration/frontend/source.ts", source)

      subject.invoke(".")

      expect(File.read("modules/gitlab_integration/frontend/source.ts")).to eq(source)
    end

    it "is idempotent" do
      write_source("source.ts", "export const source = true;\n")

      subject.invoke(".")
      first_result = File.read("source.ts")
      subject.reenable
      subject.invoke(".")

      expect(File.read("source.ts")).to eq(first_result)
    end
  end

  describe "copyright:update_js" do
    let(:task_name) { "copyright:update_js" }

    it "adds the canonical header to JavaScript module variants" do
      write_source("source.js", "export const source = true;\n")
      write_source("config.mjs", "export default {};\n")
      write_source("config.cjs", "module.exports = {};\n")
      write_source(".config/rule.js", "export const rule = true;\n")

      subject.invoke(".")

      expect_canonical_header("source.js", "export const source = true;\n")
      expect_canonical_header("config.mjs", "export default {};\n")
      expect_canonical_header("config.cjs", "module.exports = {};\n")
      expect_canonical_header(".config/rule.js", "export const rule = true;\n")
    end

    it "preserves a shebang when adding the header" do
      write_source("executable.js", "#!/usr/bin/env node\nconsole.log('OpenProject');\n")

      subject.invoke(".")

      expect(File.read("executable.js"))
        .to eq("#!/usr/bin/env node\n#{canonical_header}\n\nconsole.log('OpenProject');\n")
    end
  end
end
