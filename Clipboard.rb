class Clipboard < Formula
  desc "macOS için açık kaynak clipboard yöneticisi"
  homepage "https://github.com/mehmetfiskindal/Clipboard"
  url "https://github.com/mehmetfiskindal/Clipboard/releases/download/v1.0.0/Clipboard.zip"
  sha256 "a04f89503710f5cfe4c19c869bb19e5d153bbae77607c339a7d5bf6db3b08d40" # 'shasum -a 256 dosya.tar.gz' ile alabilirsiniz
  license "MIT"
  def install
    bin.install "Clipboard" # Çalıştırılabilir dosyanın ismi
  end
end
