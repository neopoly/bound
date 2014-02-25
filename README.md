# Bound

[![Build Status](https://travis-ci.org/neopoly/bound.png)](https://travis-ci.org/neopoly/bound) [![Gem Version](https://badge.fury.io/rb/bound.png)](http://badge.fury.io/rb/bound) [![Code Climate](https://codeclimate.com/github/neopoly/bound.png)](https://codeclimate.com/github/neopoly/bound)

*In short:* The mission: Bring the notion of interfaces to ruby.

*More detailed:* When you buil separated or distributed architectures in ruby,
you probably encountered the problem of stale mocks or wrongly mocked interfaces
of specific services at the boundaries of the different domains.

To tackle this problem, we use `Bound`. Instead of providing just a list of
arguments to a poor little boundary method, it will just accept on argument, its
request, to speak in more technical terms. By implementing the request and
response objects through `Bound`, you get validated interfaces and more explicit
and self documenting code for free.

See *Usage* below for more details with a concrete example.

## Installation

Add this line to your application's Gemfile:

    gem 'bound'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bound

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
