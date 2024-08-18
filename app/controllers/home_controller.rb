require 'net/http'

class HomeController < ApplicationController
  def index
    @git_issues = git_issues
    @git_history = git_history
  end

  private

  def git_api_token
    ENV['GIT_API_TOKEN']    
  end

  def git_issues_url
    "https://api.github.com/graphql"
  end

  def git_issues
    git_api_response['data']['repository']['issues']['nodes']
  end

  def git_history
    git_api_response['data']['repository']['commits']['history']['nodes']
  end

  def git_api_response
    return @git_api_response if @git_api_response

    owner = "fredwillmore"
    name = "climate-control"

    query = <<-GRAPHQL
      {
        repository(owner: "#{owner}", name: "#{name}") {
          issues(first: 10) {
            nodes {
              title
              url
            }
          }
          commits: object(expression: "master") {
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
      }
    GRAPHQL

    uri = URI(git_issues_url)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{git_api_token}"
    request.content_type = "application/json"

    request.body = JSON.dump({ query: query })

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
end
