def source_paths
  Array(super) + [File.expand_path(File.dirname(__FILE__))]
end

# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
if __FILE__ =~ %r{\Ahttps?://}
  source_paths.unshift(tempdir = Dir.mktmpdir("muxu-rails-template-"))
  at_exit { FileUtils.remove_entry(tempdir) }
  git :clone => [
    "--quiet",
    "https://github.com/muxumuxu/muxu-rails-template.git",
    tempdir
  ].map(&:shellescape).join(" ")
else
  source_paths.unshift(File.dirname(__FILE__))
end

# Replace README.md
template "README.md.tt", :force => true

copy_file "Guardfile"

# Configure Gemfile
remove_file "Gemfile"
run "touch Gemfile"
add_source "https://rubygems.org"

gem "rails", "#{Rails.version}"
gem "pg"
gem "puma"
gem "rollbar"
gem "uglifier"
gem "turbolinks"
gem "jbuilder"
gem "sass-rails"
gem "slim-rails"
gem 'uglifier'
gem 'jquery-rails'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem_group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "capybara"
  gem "selenium-webdriver"
  gem "pry-rails"
  gem "pry-rescue"
  gem "rubocop"
end

gem_group :development do
  gem "web-console"
  gem "better_errors"
  gem "listen"
  gem "spring"
  gem "spring-watcher-listen"
  gem "guard"
  gem "guard-minitest"
  gem "better_errors"
  gem "rails_layout"
end

gem_group :test do
  gem "minitest-reporters"
  gem "minitest-rails"
  gem "shoulda"
  gem "factory_girl_rails"
  gem "faker"
  gem "vcr"
  gem "webmock"
  gem "rails-controller-testing"
end

use_devise = yes?("Would you like to configure devise?")

gem "devise" if use_devise

# Generate the ruby version file
file ".ruby-version", RUBY_VERSION

# Create .env file
copy_file ".env"

# Configure Docker
template "Dockerfile.tt"
template "docker-compose.yml.tt"
copy_file '.dockerignore'

# Configure database
inside "config" do
  remove_file "database.yml"
  template "database.yml.tt"
end

# Replace .gitignore
remove_file '.gitignore'
copy_file '.gitignore'

# Add initializers
inside "config/initializers" do
  copy_file "rollbar.rb"
end

use_heroku = yes?("Would you like to configure Heroku?")

if use_heroku
  # Add deployment scripts
  run "mkdir scripts"
  inside "scripts" do
    copy_file "deploy"
    run "chmod +x deploy"
  end

  append_file 'README.md', <<-EOF
## Heroku deployment

```
./scripts/deploy
```
  EOF
end

after_bundle do
  if use_devise
    run "spring stop"
    generate "devise:install"
    generate "devise", "user"
    generate "devise:views"
  end

  run "gem install html2slim"
  run "erb2slim -d ."
  run "html2slim -d ."

  # Launch bundle install & migrations in docker container
  run "docker-compose build"
  run "docker-compose run web bundle exec rails db:create db:migrate"

  git :init
  git add: "."
  git commit: %Q{ -m "Initial Rails app" }

  # Configure heroku
  if use_heroku
    sanitized_name = app_name.gsub('_', '-').gsub('.', '-')
    run "heroku plugins:install heroku-container-registry"
    run "heroku apps:create #{sanitized_name}"
    run "heroku addons:create heroku-postgresql:hobby-dev"
    run "heroku addons:create rollbar"
    run "scripts/deploy"
    run "heroku ps:scale web=1"
  end
end
