gem 'sass-rails'
gem 'slim-rails'

if yes?("Would you like to install Devise?")
  gem "devise"
  generate "devise:install"
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate "devise", model_name
end

file 'app/views/layouts/application.html.slim', <<-CODE
doctype html
html
    meta charset='utf-8'
    meta content='width=device-width, initial-scale=1.0, maximum-scale=1, user-scalable=0' name='viewport'

    = csrf_meta_tags
    = stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload'
    = javascript_include_tag 'application', 'data-turbolinks-track': 'reload'
  body
  	= yield
CODE

file 'app/views/layouts/mailer.html.slim', <<-CODE
doctype html
html
  head
    meta charset='utf-8'
  body
  	= yield
CODE

run 'rm app/views/layouts/application.html.erb'
run 'rm app/views/layouts/mailer.html.erb'
run 'rm public/404.html'
run 'rm public/422.html'
run 'rm public/500.html'

after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial Rails app' }
end