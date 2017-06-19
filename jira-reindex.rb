#!/usr/bin/env ruby

#
# There are 2 ways of using this script:
#
# 1)
#     git clone https://github.com/serge-name/jira-reindex
#     cd jira-reindex
#     bundle install --path=.
#     bundle exec ./jira-reindex.rb [options]
#
# 2)
#     apt-get install ruby ruby-iniparse ruby-mechanize
#     wget -O /usr/local/bin/jira-reindex https://github.com/serge-name/jira-reindex/raw/master/jira-reindex.rb
#     chmod 755 /usr/local/bin/jira-reindex
#     jira-reindex -p/etc/jira.reindex.ini
#

require 'optparse'
require 'iniparse'
require 'mechanize'

INI_PATH = './jira-reindex.ini'
INI_SECTION = 'default'

Options = Struct.new(:path, :section, :lock_jira)

class MyOptParser
  def self.parse(options, defaults = {})
    args = Options.new(defaults[:path], defaults[:section])

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-pPATH", "--path=PATH", "INI path") do |p|
        args.path = p
      end

      opts.on("-sSECTION", "--section=SECTION", "INI section name") do |s|
        args.section = s
      end

      opts.on("-l", "--lock", "Lock JIRA during the reindexing") do |s|
        args.lock_jira = true
      end

      opts.on("-h", "--help", "Prints this help") do
        STDERR.puts(opts)
        exit
      end
    end

    opt_parser.parse!(options)

    return args
  end
end

class MyReindexToggler
  def initialize(url, user, password, cert_no_check: false)
    @url = URI::join(url, reindex_uri)
    @user = user
    @password = password
    @cert_no_check = cert_no_check
    @a = Mechanize.new { |agent|
      agent.verify_mode = cert_no_check ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
    }
  end

  def reindex(lock_jira = false)
    result = nil

    @a.get(@url) do |page|
      result = start_reindex(authorize(authorize(page)), lock_jira)
    end

    if result && result.uri.to_s =~ %r{/IndexProgress\.jspa\?}
      result.uri.to_s
    else
      nil
    end
  end

  private

  def reindex_uri
    'secure/admin/IndexAdmin.jspa'
  end

  def authorize(page)
    updated = page.form_with(:id => 'login-form') { |f|
        f.fields_with(:name => 'os_username').each { |field| field.value = @user }
        f.fields_with(:name => 'os_password').each { |field| field.value = @password }
        f.fields_with(:name => 'webSudoPassword').each { |field| field.value = @password }
    }

    updated ? updated.submit : page
  end

  def start_reindex(page, lock_jira)
    updated = page.form_with(:id => 'indexing') { |f|
      if lock_jira
        f.radiobutton_with(:id => 'reindex-foreground').check
      else
        f.radiobutton_with(:id => 'reindex-background').check
      end

    }

    updated ? updated.submit : nil
  end
end

def is_true_relaxed?(arg)
  !arg.nil? && (arg == 1 || arg == true || arg == 'yes' || arg == 'on')
end

options = MyOptParser.parse(ARGV, path: INI_PATH, section: INI_SECTION)

ini_content = IniParse.parse(File.read(options.path))[options.section]
url = ini_content[:url]
user = ini_content[:user]
password = ini_content[:password]
cert_no_check = is_true_relaxed?(ini_content[:cert_no_check])
lock_jira = !!options.lock_jira

puts "Going to reindex JIRA at '#{url}' as user '#{user}' ..."

rt = MyReindexToggler.new(url, user, password, cert_no_check: cert_no_check)
result = rt.reindex(lock_jira)

if result.nil?
  puts 'failed'
  exit 1
end

puts "success: #{result}"
