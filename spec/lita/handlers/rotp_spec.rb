# -*- coding: UTF-8 -*-
#
# Copyright 2014 PagerDuty, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe Lita::Handlers::ROTP, lita_handler: true do
  # otp routing
  it { routes_command('otp tim 1401').to(:otp) }
  it { routes_command('otp tim').to(:otp) }
  it { routes_command('token tim 1401').to(:otp) }
  it { routes_command('token tim').to(:otp) }

  # totp routing
  it { routes_command('totp tim').to(:totp) }

  # hotp routing
  it { routes_command('hotp tim 1401').to(:hotp) }

  let(:tim_secret) { '4QGNYPZ7OSBHCWWL' }
  let(:heckman_secret) { 'IR5IYN4G5HB66BOA' }
  let(:config) { { tim: tim_secret, heckman: heckman_secret } }
  let(:rotph) { Lita::Handlers::ROTP.new('robot')   }

  before do
    conf = double('Lita::Config', secret_pairs: config)
    allow(rotph).to receive(:config).and_return(conf)
  end

  describe '.default_config' do
    it 'should set secret_pairs to an empty Hash' do
      expect(Lita.config.handlers.rotp.secret_pairs).to eql Hash.new
    end
  end

  describe '.hotp_generate' do
    context 'when generation succeeds' do
      it 'should return the token template' do
        func = rotph.send(:hotp_generate, tim_secret, 1687)
        test = ROTP::HOTP.new(tim_secret).at(1687)
        expect(func).to eql test

        func = rotph.send(:hotp_generate, heckman_secret, 776)
        test = ROTP::HOTP.new(heckman_secret).at(776)
        expect(func).to eql test
      end
    end

    context 'when generation fails' do
      before { allow_any_instance_of(ROTP::HOTP).to receive(:at).and_raise(ROTP::Base32::Base32Error.new) }

      it 'should respond with the error' do
        expect(rotph.send(:hotp_generate, tim_secret, 1)).to eql 'I had a problem :( ... ROTP::Base32::Base32Error'
      end
    end
  end

  describe '.totp_generate' do
    context 'when generation succeeds' do
      it 'should return the token template' do
        func = rotph.send(:totp_generate, tim_secret)
        test = ROTP::TOTP.new(tim_secret).now
        expect(func).to eql test

        func = rotph.send(:totp_generate, heckman_secret)
        test = ROTP::TOTP.new(heckman_secret).now
        expect(func).to eql test
      end
    end

    context 'when generation fails' do
      before { allow_any_instance_of(ROTP::TOTP).to receive(:now).and_raise(ROTP::Base32::Base32Error.new) }

      it 'should respond with the error' do
        expect(rotph.send(:totp_generate, tim_secret)).to eql 'I had a problem :( ... ROTP::Base32::Base32Error'
      end
    end
  end

  describe '.hotp' do
    context 'when secret found' do
      it 'should respond with the token' do
        send_command('hotp tim 42')
        t = ROTP::HOTP.new(tim_secret).at(42)
        expect(replies.last).to eql t
      end
    end

    context 'when secret not found' do
      before do
        conf = double('Lita::Config', secret_pairs: {})
        allow(rotph).to receive(:config).and_return(conf)
      end

      it 'should respond saying it could not find that secret' do
        send_command('hotp tim 42')
        expect(replies.last).to eql 'No secret was found for: tim'
      end
    end
  end

  describe '.totp' do
    context 'when secret found' do
      it 'should respond with the token' do
        send_command('totp heckman')
        t = ROTP::TOTP.new(heckman_secret).now
        expect(replies.last).to eql t
      end
    end

    context 'when secret not found' do
      before do
        conf = double('Lita::Config', secret_pairs: {})
        allow(rotph).to receive(:config).and_return(conf)
      end

      it 'should respond saying it could not find that secret' do
        send_command('totp heckman')
        expect(replies.last).to eql 'No secret was found for: heckman'
      end
    end
  end

  describe '.otp' do
    context 'when secret found' do
      context 'when requesting a totp' do
        it 'should respond with the token' do
          send_command('otp heckman 42')
          t =  ROTP::HOTP.new(heckman_secret).at(42)
          expect(replies.last).to eql t
        end
      end

      context 'when requesting an hotp' do
        it 'should respond with the token' do
          send_command('otp tim')
          t = ROTP::TOTP.new(tim_secret).now
          expect(replies.last).to eql t
        end
      end
    end

    context 'when secret not found' do
      before do
        conf = double('Lita::Config', secret_pairs: {})
        allow(rotph).to receive(:config).and_return(conf)
      end

      context 'when requesting a totp' do
        it 'should respond with the token' do
          send_command('otp heckman 42')
          expect(replies.last).to eql 'No secret was found for: heckman'
        end
      end

      context 'when requesting an hotp' do
        it 'should respond with the token' do
          send_command('otp tim')
          expect(replies.last).to eql 'No secret was found for: tim'
        end
      end
    end
  end
end
