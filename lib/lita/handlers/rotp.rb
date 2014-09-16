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

require 'rotp'

module Lita
  # Lita Handler
  module Handlers
    # The ROTP wrapper for Lita
    #
    # @author Tim Heckman <tim@pagerduty.com>
    class ROTP < Handler
      route(
        /^(?:token|otp)\s+?(?<name>[a-zA-Z0-9_\-]+)(?<counter>\s+?\d+)?.*$/,
        :otp,
        command: true,
        help: {
          'otp tim' => 'generate a TOTP with the name "tim"',
          'otp doug 1401' => 'generate an HTOP with the name "doug" and a counter of 1401'
        }
      )

      route(
        /^totp\s+?(?<name>[a-zA-Z0-9_]+).*$/,
        :totp,
        command: true,
        help: {
          'totp tim' => 'generate a TOTP with the name "tim"'
        }
      )

      route(
        /^hotp\s+?(?<name>[a-zA-Z0-9_]+)(?<counter>\s+?\d+)?.*$/,
        :hotp,
        command: true,
        help: {
          'hotp doug 1401' => 'generate an HTOP with the name "doug" and a counter of 1401'
        }
      )

      def self.default_config(config)
        config.secret_pairs = {}
      end

      def otp(response)
        md = response.match_data
        name, counter = [md['name'], md['counter']]
        counter = counter.strip.to_i if counter.is_a?(String)

        reply = ''

        if counter.nil?
          secret = config.secret_pairs[name.to_sym]
          return response.reply(t('not_found', n: name)) if secret.nil?
          reply = totp_generate(secret)
        else
          secret = config.secret_pairs[name.to_sym]
          return response.reply(t('not_found', n: name)) if secret.nil?
          reply = hotp_generate(secret, counter)
        end

        response.reply(reply)
      end

      def totp(response)
        name = response.match_data['name']
        secret = config.secret_pairs[name.to_sym]

        return response.reply(t('not_found', n: name)) if secret.nil?

        response.reply(totp_generate(secret))
      end

      def hotp(response)
        md = response.match_data
        name, counter = [md['name'], md['counter']]

        counter = counter.strip.to_i if counter.is_a?(String)

        secret = config.secret_pairs[name.to_sym]

        return response.reply(t('not_found', n: name)) if secret.nil?

        response.reply(hotp_generate(secret, counter))
      end

      private

      def totp_generate(secret)
        t('token', t: ::ROTP::TOTP.new(secret).now)
      rescue StandardError => e
        t('boom', m: e.message)
      end

      def hotp_generate(secret, counter)
        t('token', t: ::ROTP::HOTP.new(secret).at(counter.to_i))
      rescue StandardError => e
        t('boom', m: e.message)
      end
    end

    Lita.register_handler(ROTP)
  end
end
