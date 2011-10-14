module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    include ActsAsTaggableOn::ActiveRecord::Backports if ::ActiveRecord::VERSION::MAJOR < 3
    include ActsAsTaggableOn::Utils
      
    attr_accessible :name

    ### ASSOCIATIONS:

    has_many :taggings, :dependent => :destroy, :class_name => 'ActsAsTaggableOn::Tagging'

    ### VALIDATIONS:

    validates_presence_of :name
    validates_uniqueness_of :name

    ### SCOPES:
    
    def self.named(name)
      where(["name #{like_operator} ?", normalise(name)])
    end
  
    def self.named_any(list)
      where(list.map { |tag| sanitize_sql(["name #{like_operator} ?", normalise(tag)]) }.join(" OR "))
    end
  
    def self.named_like(name)
      where(["name #{like_operator} ?", "%#{normalise(name)}%"])
    end

    def self.named_like_any(list)
      where(list.map { |tag| sanitize_sql(["name #{like_operator} ?", "%#{normalise(tag)}%"]) }.join(" OR "))
    end

    ### CLASS METHODS:

    def self.find_or_create_with_like_by_name(name)
      named_like(name).first || create(:name => name)
    end

    def self.find_or_create_all_with_like_by_name(*list)
      list = [list].flatten

      return [] if list.empty?

      existing_tags = Tag.named_any(list).all
      new_tag_names = list.reject do |name| 
                        name = normalise(name)
                        existing_tags.any? { |tag| tag.name == name }
                      end
      created_tags  = new_tag_names.map { |name| Tag.create(:name => name) }

      existing_tags + created_tags
    end

    # generate a normalised (clean) tag from a crazy one
    # downcase
    # strip all non a-z0-9 chars (allowing for '-' and '+' mostly just for a 'c++' tag
    # trim the edges
    def self.normalise( tag )
      return unless tag
      normalised = ActiveSupport::Inflector.transliterate(comparable_name(tag)).to_s.strip.gsub(/[^-+a-z0-9 ]/,'').gsub(/ +/, " ")
      result = normalised.present? ? normalised : tag # if we just obliterated a non-ascii tag, stick with the original
      result.strip
    rescue NoMethodError
      # Normalizing crazy text (say, "ÓîÖ\303\246") results in undefined method `normalize' for String.
      # It's not clear where these tag-requests come from - I think it tends to be search engines - but let's not error out because of that.
      tag
    end

    ### INSTANCE METHODS:

    def ==(object)
      super || (object.is_a?(Tag) && name == object.name)
    end

    def to_s
      name
    end

    def name=(value)
      super(self.class.normalise(value))
    end

    def count
      read_attribute(:count).to_i
    end
    
    def safe_name
      name.gsub(/[^a-zA-Z0-9]/, '')
    end
    
    class << self
      private        
        def comparable_name(str)
          RUBY_VERSION >= "1.9" ? str.downcase : str.mb_chars.downcase
        end
    end
  end
end
