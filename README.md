lita-rotp
===========
[![Build Status](https://img.shields.io/travis/PagerDuty/lita-rotp/master.svg)](https://travis-ci.org/PagerDuty/lita-rotp)
[![Code Climate Coverage](http://img.shields.io/codeclimate/coverage/github/PagerDuty/lita-rotp.svg)](https://codeclimate.com/github/PagerDuty/lita-rotp)
[![RubyGems :: lita-rotp Gem Version](http://img.shields.io/gem/v/lita-rotp.svg)](https://rubygems.org/gems/lita-rotp)
[![Apache 2.0 License](https://img.shields.io/badge/license-Apache%202.0-brightgreen.svg)](https://tldrlegal.com/license/apache-license-2.0-(apache-2.0))

Copyright 2014 PagerDuty, Inc.

Lita handler for TOTP & HOTP token generation; uses Ruby One-Time Password (ROTP) library.

We use plenty of external services that require you to share a login while supporting two-factor authentication. There
are plenty of tools available to share passwords, but nothing great for sharing/generating TOTP tokens. This handler
was built so that you can store your shared account secrets in your Lita config and generate two-factor auth tokens
using Lita.

**NOTE:** The secrets you store in the configuration file should be treated as secret. No others should be able to see
them. Consider making the read permissions of your Lita configuration file very restrictive (so that only the user
running Lita should be able to see the contents)

INSTALLATION
------------

Add `lita-rotp` to your Lita instance's Gemfile:

``` ruby
gem 'lita-rotp', '~> 0.1'
```

LICENSE
-------
**lita-rotp** is released under the
[Apache License 2.0](http://opensource.org/licenses/Apache-2.0). The full text of the license canbe found in the
`LICENSE` file. The summary can be found [here](https://tldrlegal.com/license/apache-license-2.0-(apache-2.0)) courtesy
of tldrlegal.

CONFIGURATION
-------------
`lita-rotp` uses a Hash of key pairs to get the secrets:

```Ruby
config.handlers.rotp.secret_pairs = { tim: '4QGNYPZ7OSBHCWWL', heckman: 'IR5IYN4G5HB66BOA' }
```

You then use the name `heckman` to use the secret for heckman.

USAGE
-----
```
> totp heckman
596049

# or

> hotp tim 42
368274

# or

> token heckman
386015

> token tim 42
549634
```
