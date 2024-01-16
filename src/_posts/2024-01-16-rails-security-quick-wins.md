---
title: Rails security quick wins
date: 2024-01-16
tags:
  - code
  - ruby
  - rails
  - til
  - security
---

I recently launched a major new feature for an application I maintain at *$dayjob*, and I needed to ensure that the application followed current basic security best practices. It took me a couple of hours to track everything down, so I thought I would document it here for future reference. So, let's dig into some quick wins for Rails security.

<!--/summary-->

- - -

The best place to start is to use the free security headers scan provided by [securityheaders.com](https://securityheaders.com/). This will give you a good idea of where you stand, and what you need to do to improve your security posture. When I first ran it against my application, I got a C grade 😬.

<img src="{{ '/images/security-scan-1.png' | relative_url }}" alt="" style="width: 100%" />

But, it immediately showed me the headers that I needed to add to improve my score. In my case, I was completely missing the `Strict-Transport-Security`, `Content-Security-Policy`, and `Permissions-Policy` headers. So, I started by added these to my application.

Luckily, Rails is a mature web application framework, and so it provides tooling for these headers. In fact, in modern Rails applications, you will have initializers created for both the `Content-Security-Policy` and `Permissions-Policy` headers. You just need to uncomment them and configure them to your needs. In my case, the defaults work just fine. For the `Content-Security-Policy`, I simply uncommented the generated code in the `/config/initializers/content_security_policy.rb` file, leaving me with:

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap and inline scripts
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
```

In short, these configures your app to only allow resources to be loaded from your own domain. This is a good starting point, but you will likely need to tweak it to your needs. For example, if you are using a CDN to serve your assets, you will need to add that to the `default_src` and `script_src` directives. To learn more, you can read the [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy) documentation on MDN as well as the short description provided in Rails' [documentation](https://api.rubyonrails.org/classes/ActionDispatch/ContentSecurityPolicy.html).

For the `Permissions-Policy` header, I uncommented the generated code in the `/config/initializers/permissions_policy.rb` file, leaving me with:

```ruby
Rails.application.config.permissions_policy do |f|
  f.camera      :none
  f.gyroscope   :none
  f.microphone  :none
  f.usb         :none
  f.fullscreen  :self
  f.payment     :self, "https://secure.example.com"
end
```

This configures your app as not needing access to the camera, gyroscope, microphone, or USB devices, but it allows fullscreen mode, and payments to be made on your domain or the `https://secure.example.com` domain (yes, I know, not at all needed, but I'm ok with it for now). When I first tried this code, however, my security score barely improved. Digging into the details I learned that [securityheaders.com](https://securityheaders.com/) values the newer `Permissions-Policy` header over the older `Feature-Policy`. Rails has this to say in its documentation:

> The Feature-Policy header has been renamed to Permissions-Policy. The Permissions-Policy requires a different implementation and isn’t yet supported by all browsers. To avoid having to rename this middleware in the future we use the new name for the middleware but keep the old header name and implementation for now.

I wanted a solid score, so I decided to add the `Feature-Policy` header as well. I found [this pull request](https://github.com/rails/rails/pull/41994) and used it as a guide. I added the following to my `/app/controllers/application_controller.rb` file:

```ruby
before_action :permissions_policy_header

def permissions_policy_header
  response.headers['Permissions-Policy'] = Rails.application.config.permissions_policy.directives.map do |directive, sources|
    if sources.include? "'none'"
      "#{directive}=()"
    elsif sources.include? "'self'"
      "#{directive}=(#{sources.join(' ')})"
    elsif sources.include? "'all'"
      "#{directive}=(*)"
    end
  end.compact.join(", ")
end
```

This ensures that the `Permissions-Policy` header is set, but it also ensures that the `Feature-Policy` header is set as well and that they match. This ensures that all browsers will be able to use the headers and enforce the security policies. To learn more, you can read the [Permissions Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Feature-Policy) documentation on MDN as well as the short description provided in Rails' [documentation](https://api.rubyonrails.org/classes/ActionDispatch/PermissionsPolicy.html).

Next, I needed to add the `Strict-Transport-Security` header. In this case, you don't use an initializer, but rather the `ssl_options` configuration object. However, do note that that the `ssl_options` configuration object is only used when `config.force_ssl` is set to `true`. This tripped me up the first time I tried to get everything working. Luckily, Rails' [documentation](https://api.rubyonrails.org/classes/ActionDispatch/SSL.html) proved helpful and the defaults are actually well considered. Since I have `development`, `staging`, and `production` environments, my problem was not setting `force_ssl` in the `staging` and `production` environments. Adding that fixed my problem.

So, by uncommenting a bit of already generated code, I was able to meaningfully improve my security score in just a few minutes. My next improvement was to improve the security of my cookies.

- - -

Rails defaults to relatively lax cookie security. I wanted to tighten this up, so I began by reading the relevant [documentation](https://api.rubyonrails.org/classes/ActionDispatch/Cookies.html). Firstly, I wanted to upgrade my `SameSite` value from the default `lax` to `strict`. This was a simple change in `/config/application.rb`:

```ruby
config.action_dispatch.cookies_same_site_protection = :strict
```

Next, I needed to ensure that the session token cookie that I set was `httponly` and `secure`. This was also a simple change, which I made in my `/app/controllers/concerns/authenticatable.rb` file:

```ruby
cookies.signed.permanent[:session_token] = { value: session.id, httponly: true, secure: true }
```

Again, after finding the relavant information, the changes themselves only took a couple of minutes. But, they greatly improved the security of my application.

Maybe you can take a couple of minutes and improve the security of your application now as well.
