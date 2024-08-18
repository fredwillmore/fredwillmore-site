# Stage 1: Base image with gem dependencies
FROM ruby:3.3.4 AS base

#. Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

# Set the working directory
WORKDIR /app

# Cache and install gems
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

RUN gem install bundler:2.5.17
RUN bundle install --jobs=4 --retry=5

# Stage 2: Application image
FROM base AS app

# Copy the rest of the application code
COPY . .

# Precompile assets (if needed) and set up other steps
RUN bundle exec rake assets:precompile
# RUN bundle exec rake db:migrate
# RUN bundle exec rails runner db/seeds/artists.rb
# RUN bundle exec rails runner db/seeds/tracks.rb
# RUN bundle exec rails runner db/seeds/playlists.rb
# RUN bundle exec rails runner db/seeds/playlist_items.rb

# Expose the port that the app runs on
# EXPOSE 80

# Specify the command to run the app
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
