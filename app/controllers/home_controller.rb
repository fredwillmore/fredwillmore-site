require 'net/http'

class HomeController < ApplicationController
  def index
    @view_info = view_info
  end

  private

  def view_info
    git_repositories.map do |key, title|
      git_info = git_api_response.dig('data', key)
      { 
        title: title,
        collapse_id: "collapse#{ git_info['name'].titleize.remove(' ') }",
        git_info: git_info, # I don't think I need this
        project_url: git_info['homepageUrl'],
        git_url: git_info['url'],
        readme: git_info['readme']['text'],
        commits: git_info['commits']['history']['nodes'],
        issues: git_info['issues']['nodes'],
      }
    end
  end

  def git_repositories
    {
      'climatecontrol' => "Climate Control",
      'billboardreact' => "Billboard Charts",
      'datatablesdemo' => "Datatables Demo",
      'primesrails' => "Prime Numbers",
      'congressionaldisclosures' => "Congressional Disclosures",
    }
  end

  def git_api_token
    ENV['GIT_API_TOKEN']
  end

  def git_api_url
    "https://api.github.com/graphql"
  end

  def git_api_response
    return @git_api_response if @git_api_response

    uri = URI(git_api_url)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{git_api_token}"
    request.content_type = "application/json"

    request.body = JSON.dump({ query: compose_graphql_query })

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    if response.is_a?(Net::HTTPSuccess)
      @git_api_response = JSON::parse(response.body)
    else
      raise StandardError.new "HTTP request failed with status code #{response.code}"
    end
    @git_api_response
  end

  private

  def compose_graphql_query
    query_components = [
      "climate-control",
      "billboard-react",
      "datatables-demo",
      "primes-rails",
      "primes",
      "congressional-disclosures",
    ].map do |repo|
      branch = case repo
      when "billboard-react", "primes-rails", "congressional-disclosures"
        "main"
      else
        "master"
      end

      <<-GRAPHQL
        #{repo.remove('-')}: repository(owner: "fredwillmore", name: "#{repo}") {
          name
          description
          url
          homepageUrl
          readme: object(expression: "HEAD:README.md") {
            ... on Blob {
              text
            }
          }
          issues(first: 10) {
            nodes {
              id
              title
              bodyText
              url
            }
          }
          commits: object(expression: "#{branch}") {
            ... on Commit {
              history(first: 10) {
                nodes {
                  message
                  additions
                  deletions
                  changedFiles
                  url
                  oid
                }
              }
            }
          }
        }
      GRAPHQL
    end.join

    <<-GRAPHQL
      {
        #{query_components}
      }
    GRAPHQL
  end
end
