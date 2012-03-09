require "active_record"
require "active_record/version"
require "action_view"
RAILS_3 = ::ActiveRecord::VERSION::MAJOR >= 3

ActiveSupport.on_load(:active_record) do
  $LOAD_PATH.unshift(File.dirname(__FILE__))

  require "acts_as_taggable_on/compatibility/active_record_backports" unless RAILS_3

  require "acts_as_taggable_on/utils"

  require "acts_as_taggable_on/acts_as_taggable_on"
  require "acts_as_taggable_on/acts_as_taggable_on/core"
  require "acts_as_taggable_on/acts_as_taggable_on/collection"
  require "acts_as_taggable_on/acts_as_taggable_on/cache"
  require "acts_as_taggable_on/acts_as_taggable_on/ownership"
  require "acts_as_taggable_on/acts_as_taggable_on/related"

  #require "acts_as_taggable_on/utils"
  require "acts_as_taggable_on/acts_as_tagger"
  require "acts_as_taggable_on/tag"
  require "acts_as_taggable_on/tag_list"
  require "acts_as_taggable_on/tagging"

  $LOAD_PATH.shift

  extend ActsAsTaggableOn::Taggable
  include ActsAsTaggableOn::Tagger

end

ActiveSupport.on_load(:action_view) do
  require "acts_as_taggable_on/tags_helper"
  include ActsAsTaggableOn::TagsHelper
end
