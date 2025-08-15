describe Fastlane::Actions::UploadToPgyerViaCurlAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The upload_to_pgyer_via_curl plugin is working!")

      Fastlane::Actions::UploadToPgyerViaCurlAction.run(nil)
    end
  end
end
