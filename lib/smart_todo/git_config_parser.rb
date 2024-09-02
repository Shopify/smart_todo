class GitConfigParser
  GIT_CONFIG_PATH = ".git/config"

  def initialize
    @config = {}
    parse(GIT_CONFIG_PATH) if File.exist?(GIT_CONFIG_PATH)
  end

  def parse(file_path)
    current_section = nil
    File.readlines(file_path).each do |line|
      line = line.strip

      if line.start_with?("[") && line.end_with?("]")
        current_section = line[1...-1]
        @config[current_section] = {}
      elsif current_section && line.include?("=")
        key, value = line.split("=", 2).map(&:strip)
        @config[current_section][key] = value
      end
    end
  end

  def read_value(section, key)
    return @config[section][key] if @config.key?(section) && @config[section].key?(key)

    nil
  end

  # Github defined as following in repository config
  # git@git.domain.com:organization/repo.git
  # TODO Gitlab and Bitbucket urls are slightly different so it wont work for them as of yet
  def github_repo_url
    "https://" + self.read_value('remote "origin"', 'url').split('@').last.gsub(':', '/').gsub(/\.git$/, "") + "/blob/HEAD/"
  end
end
