
You can use this stuff to start the reindexing of Atlassian JIRA periodically.

Inspired by https://github.com/jasonhensler/Atlassian-Scripts/

### There are 2 ways of using this script:

1
```shell
git clone https://github.com/serge-name/jira-reindex
cd jira-reindex
bundle config set --local path ./vendor
bundle install
bundle exec ./jira-reindex.rb [options]
```

2
```shell
apt-get install ruby ruby-iniparse ruby-mechanize
wget -O /usr/local/bin/jira-reindex https://github.com/serge-name/jira-reindex/raw/master/jira-reindex.rb
chmod 755 /usr/local/bin/jira-reindex
jira-reindex -p/etc/jira.reindex.ini
```

### Checked versions:

* JIRA 7.3.7
* Ruby 2.3.3p222
