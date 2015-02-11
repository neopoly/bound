[github]: https://github.com/neopoly/bound
[doc]: http://rubydoc.info/github/neopoly/bound/master/file/README.md
[gem]: https://rubygems.org/gems/bound
[travis]: https://travis-ci.org/neopoly/bound
[codeclimate]: https://codeclimate.com/github/neopoly/bound
[inchpages]: https://inch-ci.org/github/neopoly/bound

# Bound

[![Travis](https://img.shields.io/travis/neopoly/bound.svg?branch=master)][travis]
[![Gem Version](https://img.shields.io/gem/v/bound.svg)][gem]
[![Code Climate](https://img.shields.io/codeclimate/github/neopoly/bound.svg)][codeclimate]
[![Test Coverage](https://codeclimate.com/github/neopoly/bound/badges/coverage.svg)][codeclimate]
[![Inline docs](https://inch-ci.org/github/neopoly/bound.svg?branch=master&style=flat)][inchpages]

[Gem][gem] |
[Source][github] |
[Documentation][doc]

**In short:** The mission: Bring the notion of interfaces to ruby.

**More detailed:** When you build separated or distributed architectures in ruby,
you probably encountered the problem of stale mocks or wrongly mocked interfaces
of specific services at the boundaries of the different domains.

To tackle this problem, we use `Bound`. Instead of providing just a list of
arguments to a poor little boundary method, it will just accept an argument, its
request, to speak in more technical terms. By implementing the request and
response objects through `Bound`, you get validated interfaces and more explicit
and self documenting code for free.

See **Usage** below for more details with a concrete example.

## Installation

Add this line to your application's Gemfile:

    gem 'bound'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bound

## Usage

Consider the folowing scenario:

A generic domain which is responsible for administration and management of user
registrations:

```ruby
module UserDesk
end
```

It will somehow provide access to a registration service which gives you the
possibility to create new user accounts:

```ruby
class UserDesk::RegistrationService
  def register_account(email, password)
    ensure_validity!(email)
    user_uid = do_things_on_a_magical_repository(email, password)

    user_uid
  end

  private
  # ...
end
```

Since the scope of this service can (and will) be very large, it will be painful
to provide consistency around the different other domains, which get an instance
of the registration service injected. Especially order changes in a larger
argument list or added optional arguments could lead to false passing tests and
therefor probably runtime bugs.

By utilizing `Bound`, you could implement this service like following:

```ruby
class UserDesk::RegistrationService
  Registration = Bound.required(
    :email,
    :password
  )

  SuccessfulRegistration = Bound.required(:user_uid)

  def register_account(registration)
    ensure_validity!(registration.email)
    user_uid = do_things_on_a_magical_repository(
      registration.email,
      registration.password
    )

    SuccessfulRegistration.new(:user_uid => user_uid)
  end

  private
  # ...
end
```

The consumer would now instanciate the boundary class instead of just
passing arbitrary arguments to the service:

```ruby
registration = UserDesk::RegistrationService::Registration.new(
  :email => params[:email],
  :password => params[:password]
)

result = registration_service.register_account(registration)

do_stuff_with(result.user_uid)
```

Side note: the `Registration` bound here would also accept any `Object`, which provides the
methods `email` and `password`.

Bound would also loudly fail, if one of the required arguments is omitted or a
unknown argument is provided. (Specific additional features like nested and
optional arguments can be seen in the specs).

By concretinzing the boundaries, the overall structure of your architecture will
become more rigid and solid. The mocking part on the consumer-side would only
occur for the actual `register_account` call, which is fairly trivial now from
the perspective of boundaries (known object in, known object out).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
