# encoding: utf-8
require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsTaggableOn::Tag do
  before(:each) do
    clean_database!
    @tag = ActsAsTaggableOn::Tag.new
    @user = TaggableModel.create(:name => "Pablo")
  end

  describe "named like any" do
    before(:each) do
      ActsAsTaggableOn::Tag.create(:name => "Awesome")      
      ActsAsTaggableOn::Tag.create(:name => "awesome")
      ActsAsTaggableOn::Tag.create(:name => "epic")
    end

    it "should find both tags" do
      ActsAsTaggableOn::Tag.named_like_any(["awesome", "epic"]).should have(3).items
    end
  end

  describe "find or create by name" do
    before(:each) do
      @tag.name = "awesome"
      @tag.save
    end

    it "should find by name" do
      ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("awesome").should == @tag
    end

    it "should find by name case insensitive" do
      ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("AWESOME").should == @tag
    end

    it "should create by name" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("epic")
      }.should change(ActsAsTaggableOn::Tag, :count).by(1)
    end
  end

  describe "find or create all by any name" do
    before(:each) do
      @tag.name = "awesome"
      @tag.save
    end

    it "should find by name" do
      ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("awesome").should == [@tag]
    end

    it "should find by name case insensitive" do
      ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("AWESOME").should == [@tag]
    end

    it "should create by name" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("epic")
      }.should change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    it "should find or create by name" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("awesome", "epic").map(&:name).should == ["awesome", "epic"]
      }.should change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    it "should return an empty array if no tags are specified" do
      ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name([]).should == []
    end
  end

  it "should require a name" do
    @tag.valid?
    
    if ActiveRecord::VERSION::MAJOR >= 3
      @tag.errors[:name].should == ["can't be blank"]
    else
      @tag.errors[:name].should == "can't be blank"
    end

    @tag.name = "something"
    @tag.valid?
    
    if ActiveRecord::VERSION::MAJOR >= 3      
      @tag.errors[:name].should == []
    else
      @tag.errors[:name].should be_nil
    end
  end

  it "should equal a tag with the same name" do
    @tag.name = "awesome"
    new_tag = ActsAsTaggableOn::Tag.new(:name => "awesome")
    new_tag.should == @tag
  end

  it "should return its name when to_s is called" do
    @tag.name = "cool"
    @tag.to_s.should == "cool"
  end

  it "have named_scope named(something)" do
    @tag.name = "cool"
    @tag.save!
    ActsAsTaggableOn::Tag.named('cool').should include(@tag)
  end

  it "have named_scope named_like(something)" do
    @tag.name = "cool"
    @tag.save!
    @another_tag = ActsAsTaggableOn::Tag.create!(:name => "coolip")
    ActsAsTaggableOn::Tag.named_like('cool').should include(@tag, @another_tag)
  end
  
  describe "escape wildcard symbols in like requests" do
    before(:each) do
      @tag.name = "cool"
      @tag.save
      @another_tag = ActsAsTaggableOn::Tag.create!(:name => "coo%") 
      @another_tag2 = ActsAsTaggableOn::Tag.create!(:name => "coolish")           
    end
    
    it "return escaped result when '%' char present in tag" do
      if @tag.using_sqlite?
        ActsAsTaggableOn::Tag.named_like('coo%').should include(@tag)     
        ActsAsTaggableOn::Tag.named_like('coo%').should include(@another_tag)
      else
        ActsAsTaggableOn::Tag.named_like('coo%').should_not include(@tag)     
        ActsAsTaggableOn::Tag.named_like('coo%').should include(@another_tag)
      end
    end
    
  end

  describe "tag normalising" do
    it "should remove excess punctuation" do
      @tag.name = " super :  sexy!"
      @tag.name.should == "super sexy"
    end
    it "should downcase the tag" do
      @tag.name = "ThiSISAtest"
      @tag.name.should == "thisisatest"
    end
    it "should strip all non a-z0-9 letters" do
      @tag.name = "test!@£$%^^%£%$@test123"
      @tag.name.should == "testtest123"
    end
    it "should keep spaces intact" do
      @tag.name = "test test2"
      @tag.name.should == "test test2"
    end
    it "should only use one space for blocks of whitespace" do
      @tag.name = "test  test2"
      @tag.name.should == "test test2"
    end
    it "should strip spaces at the start and end of the tag (and not add -)" do
      @tag.name = "  test  "
      @tag.name.should == "test"
    end
    it "should transliterate accented characters" do
      @tag.name = "español"
      @tag.name.should == "espanol"
    end
    it "should stick with the original tag if the normalized variant would be empty" do
      @tag.name = "日本国"
      @tag.name.should == "日本国"
    end

    it "should normalise search terms" do
      @tag.name = "español"
      @tag.save!
      ActsAsTaggableOn::Tag.named('español').should include(@tag)

    end
  end

end
