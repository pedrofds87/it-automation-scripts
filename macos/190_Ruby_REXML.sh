#!/bin/bash
# Script: Ruby REXML
# Platform: Mac
# Description: #pstanczyk
# NinjaOne Script ID: 190

brew install ruby
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc  # Apple Silicon
# or /usr/local/opt/ruby/bin for Intel
exec $SHELL
gem install rexml -v '>= 3.3.6' --no-document
ruby -v
ruby -e "require 'rexml'; puts Gem.loaded_specs['rexml'].version"
