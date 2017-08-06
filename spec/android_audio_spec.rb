require 'spec_helper'
require 'device_api/android'

describe DeviceAPI::Android::Plugin::Audio do
  describe 'Audio functions' do
    it 'should return volume' do
      out = <<-EOF
          volume steps: 19
        - STREAM_SYSTEM:
          Mute count: 0
          Current: 2: 19, 40000000: 7,
      EOF
      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      audio = DeviceAPI::Android::Plugin::Audio.new('B0180706345401F5')
      expect(audio.volume).to eq(100)
    end

    it 'should handle arbitrary volumes' do
      volumes = {
        '20' => 100,
        '15' => 75,
        '10' => 50,
        '5'  => 25
      }

      random = rand(volumes.count)
      out = <<-EOF
        volume steps: 20
        - STREAM_SYSTEM:
          Mute count: 0
          Current: 2: #{volumes.keys[random]}, 400000000: 7,
      EOF

      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      audio = DeviceAPI::Android::Plugin::Audio.new('B0180706345401F5')
      expect(audio.volume).to eq(volumes.values[random])
    end

    it 'should handle a muted device' do
      out = <<-EOF
        - STREAM_SYSTEM:
          Mute count: 1
          Current: 2: 0, 40000000: 7,
      EOF
      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      audio = DeviceAPI::Android::Plugin::Audio.new('1234567890')
      expect(audio.is_muted?).to eq(true)
    end

    it 'should handle a device with no volume' do
      out = <<-EOF
          volume steps: 19
        - STREAM_SYSTEM:
          Mute count: 0
          Current: 2: 0, 40000000: 7,
      EOF
      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      audio = DeviceAPI::Android::Plugin::Audio.new('1234567890')
      expect(audio.volume).to eq(0)
    end
  end
end
