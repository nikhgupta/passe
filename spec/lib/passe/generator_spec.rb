RSpec.describe Passe::Generator do
  let(:size)   { Passe::Generator::GRID_SIZE }
  let(:secret) { "dummy" }
  let(:passe)  { described_class.new(secret) }
  let(:reader) { Passe::Reader.new(secret, passe.run) }
  let(:grid)   { reader.grid }

  context "behaviour" do
    it "can be run more than once" do
      expect{ passe.run }.not_to raise_error
      expect{ passe.run }.not_to raise_error
    end

    it "does not save the secret key in instance variable" do
      expect{ passe.secret }.to raise_error NoMethodError

      secret = passe.instance_variable_get("@secret")
      expect(secret).not_to eq "dummy"

      passe.run
      expect(passe.instance_variable_get("@secret")).not_to eq "dummy"
      expect(passe.instance_variable_get("@secret")).to eq secret
    end

    it "does not generate same key with the same secret on multiple runs" do
      token = Random.new.bytes(16)
      key1 = described_class.new(token).run
      key2 = described_class.new(token).run
      expect(key1).not_to eq key2

      grid1 = Passe.decrypt!(token.sha512, key1)["grid"]
      grid2 = Passe.decrypt!(token.sha512, key2)["grid"]
      expect(grid1).not_to eq grid2
    end

    it "does not generate same grid with some other seed" do
      key1 = described_class.new("ab").run
      key2 = described_class.new("ba").run
      expect(key1).not_to eq key2

      grid1 = Passe.decrypt!("ab".sha512, key1)["grid"]
      grid2 = Passe.decrypt!("ba".sha512, key2)["grid"]
      expect(grid1).not_to eq grid2
    end
  end

  context "with default configuration" do
    it "generates a grid of #{Passe::GRID_SIZE.join('x')} using alphabets, numbers and symbols" do
      expect(grid.size).to eq Passe::GRID_SIZE
      expect(grid.length).to eq Passe::GRID_SIZE.inject(1, :*)
      expect(grid.chars - (" ".."~").to_a).to be_empty
      expect(grid.gsub(/[a-z0-9]+/i, '')).not_to be_empty
    end

    it "generated grid comprises of a subgrid of #{Passe::NUMERIC_GRID.join('x')} numbers" do
      expect(reader.numeric_grid).to be_a_passe_grid.with_size(Passe::NUMERIC_GRID)
      expect(reader.numeric_grid.to_str).to match(/\A\d+\z/)
    end

    it "generated grid comprises of a minigrid of #{Passe::ALPHA_GRID.join('x')} alphanumeric chars" do
      expect(reader.alpha_grid).to be_a_passe_grid.with_size(Passe::ALPHA_GRID)
      expect(reader.alpha_grid.to_str).to match(/\A[a-z0-9]+\z/i)
    end
  end

  context "custom configuration" do
    it "can be customized to use a particular charset" do
      charset = ('a'..'f').to_a.join
      passe = described_class.new(secret, "charset" => charset)
      grid  = Passe::Reader.new(secret, passe.run).grid
      expect(grid).to match(/\A[a-f0-9]+\z/)
      expect(grid.length).to eq Passe::GRID_SIZE.inject(1, :*)
    end

    it "can work with unicode charsets, as well" do
      charset = "αβγδεζηθ"
      passe = described_class.new(secret, "charset" => charset)
      grid  = Passe::Reader.new(secret, passe.run).grid
      expect(grid).to match(/\A[a-z0-9α-θ]+\z/i)
      expect(grid.length).to eq Passe::GRID_SIZE.inject(1, :*)
    end
  end

  describe ".create_key_file" do
    before(:each) do
      @io = StringIO.new
      allow(FileUtils).to receive(:mkdir_p)
      expect(File).to receive(:open).with("some/path/file", 'w').and_yield(@io)
    end

    it "adds a header to the generated Passe key" do
      described_class.create_key_file("secret", "some/path/file")
      expect(@io.string.split("\n").first).to match(/\A-+ BEGIN PASSE KEY -+\z/)
    end

    it "adds a footer to the generated Passe key" do
      described_class.create_key_file("secret", "some/path/file")
      expect(@io.string.split("\n").last).to match(/\A-+ END PASSE KEY -+\z/)
    end

    it "creates the directory path, if required" do
      expect(FileUtils).to receive(:mkdir_p).with("some/path")
      described_class.create_key_file("secret", "some/path/file")
    end

    it "saves the generated encrypted grid in the file" do
      passe, opts = double("passe-generator"), double("options")
      expect(described_class).to receive(:new).with("secret", opts).and_return(passe)
      allow(passe).to receive(:run).and_return "- THIS IS THE ENCRYPTED DATA -"
      described_class.create_key_file("secret", "some/path/file", opts)
      expect(@io.string).to include("- THIS IS THE ENCRYPTED DATA -")
    end
  end
end
