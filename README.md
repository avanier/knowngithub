# Knowngithub

> ### _"It's not paranoia if they're out to get you."_
>
> _- Some Wise Man_

Have you hit the problem where you're trying bootstrapping new containers or VMs and git will refuse to clone stuff because it doesn't trust GitHub? This gem answers the scenario where you believe that manually burning the known hosts into whatever you're making doesn't scale, and blindly trusting any host to provide you with legitimiate code is insufficient.

While the solution is not elegant, and the implementation is fragile, I'm hoping it proves the following point : a diagonal chain of trust is better than blind trust.

The idea behind this gem is that by calling GitHub's web pages and API through https, the answers will be certified through it's CA and cannot be tampered with unbeknownst to us. Thus, one can call GitHub's SSH endpoint, and verify its key fingerprint is valid against a dynamic trustable source of truth.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'knowngithub'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install knowngithub

## Usage

The main goal of this gem is for use in automation scripts, specifically [Chef](https://www.chef.io/chef/) cookbooks.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/avanier/knowngithub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
