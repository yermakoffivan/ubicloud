# frozen_string_literal: true

require_relative "../lib/toml"

RSpec.describe Toml do
  subject(:toml) { Class.new { include Toml }.new }

  describe "#toml_string" do
    # A document shaped like the config-v2 secrets file: several [secrets.*]
    # tables with dotted keys and base64 values.
    let(:text) {
      toml.toml_section("secrets.xts-key", {"source.inline" => "eHRz+a2V5/AA==", "encoding" => "base64", "encrypted_by.ref" => "kek"}) +
        toml.toml_section("secrets.kek", {"source.file" => "/run/kek.pipe", "encoding" => "base64"}) +
        toml.toml_section("secrets.archive-psk", {"source.inline" => "cHNr", "encoding" => "base64"})
    }

    it "reads a dotted key's base64 value from the requested table" do
      expect(toml.toml_string(text, "secrets.xts-key", "source.inline")).to eq("eHRz+a2V5/AA==")
    end

    it "reads from the requested table when the same key exists in several" do
      expect(toml.toml_string(text, "secrets.archive-psk", "source.inline")).to eq("cHNr")
    end

    it "matches the key literally, so a dot is not a wildcard" do
      spoofed = toml.toml_section("secrets.xts-key", {"sourceXinline" => "nope"})
      expect(toml.toml_string(spoofed, "secrets.xts-key", "source.inline")).to be_nil
    end

    it "does not match a key that is only a prefix of a longer one" do
      expect(toml.toml_string(text, "secrets.kek", "source")).to be_nil
    end

    it "round-trips a value containing spaces, = and / written by toml_section" do
      doc = toml.toml_section("t", {"k" => "a value with spaces and = and /"})
      expect(toml.toml_string(doc, "t", "k")).to eq("a value with spaces and = and /")
    end

    it "returns nil when the key is absent from an existing table" do
      expect(toml.toml_string(text, "secrets.kek", "source.inline")).to be_nil
    end

    it "returns nil when the table does not exist" do
      expect(toml.toml_string(text, "secrets.nope", "source.inline")).to be_nil
    end
  end
end
