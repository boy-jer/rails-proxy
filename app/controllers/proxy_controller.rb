class ProxyController < ApplicationController
  def hook
    begin
      @payload = JSON.parse(params[:payload])

      render :text => "not authenticate" and return unless RAILSBP_CONFIG["token"] == params[:token]
      Rails.logger.info "authenticated"

      render :text => "skip" and return unless @payload["ref"] =~ %r|#{RAILSBP_CONFIG["branch"]}$|
      Rails.logger.info "match branch"

      FileUtils.mkdir_p(build_path) unless File.exist?(build_path)
      FileUtils.cd(build_path)
      g = Git.clone(repository_url, build_name)
      Dir.chdir(analyze_path) { g.reset_hard(last_commit_id) }
      Rails.logger.info "cloned"
      FileUtils.cp(config_file_path, "#{analyze_path}/config/rails_best_practices.yml")

      rails_best_practices = RailsBestPractices::Analyzer.new(analyze_path,
                                                              "format"         => "html",
                                                              "silent"         => true,
                                                              "output-file"    => output_file,
                                                              "with-github"    => true,
                                                              "github-name"    => RAILSBP_CONFIG["github_name"],
                                                              "last-commit-id" => last_commit_id,
                                                              "with-git"       => true,
                                                              "template"       => template_file
                                                             )
      rails_best_practices.analyze
      rails_best_practices.output
      Rails.logger.info "analyzed"

      send_request(:result => File.read(output_file))
      Rails.logger.info "request sent"
      render :text => "success"
    rescue Exception => e
      Rails.logger.error e.message
      send_request(:error => e.message)
      render :text => "failure"
    ensure
      FileUtils.rm_rf(analyze_path)
    end
  end

  def configs
    File.open(config_file_path, "w+") do |file|
      file.write(params[:configs])
    end
    render :nothing => true
  end

  def send_request(extra_params)
    http = Net::HTTP.new('railsbp.com', 443)
    http.use_ssl = true
    http.post("/sync_proxy", request_params.merge(extra_params).map { |key, value| "#{key}=#{value}" }.join("&"))
  end

  def request_params
    {
      :token => RAILSBP_CONFIG["token"],
      :repository_url => @payload["repository"]["url"],
      :last_commit => JSON.generate(@payload["commits"].last),
      :ref => @payload["ref"]
    }
  end

  def build_path
    RAILSBP_CONFIG["build_path"]
  end

  def build_name
    last_commit_id
  end

  def last_commit_id
    @payload["commits"].last["id"]
  end

  def config_file_path
    "#{build_path}/config/rails_best_practices.yml"
  end

  def repository_url
    "git@github.com:#{RAILSBP_CONFIG["github_name"]}.git"
  end

  def analyze_path
    "#{build_path}/#{build_name}"
  end

  def output_file
    "#{build_path}/output.json"
  end

  def template_file
    File.join(File.dirname(__FILE__), '..', 'assets', 'template.json.erb')
  end
end
