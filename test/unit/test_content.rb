require 'test_helper'


class ContentTest < Test::Unit::TestCase
  include Spontaneous
  context "Content instances" do
    should "evaluate instance code" do
      @instance = Content.create({
        :instance_code => "def monkey; 'magic'; end"
      })
      @instance.monkey.should == 'magic'
      id = @instance.id
      @instance = Content[id]
      @instance.monkey.should == 'magic'
    end
  end
  context "Entries" do
    setup do
      @instance = Content.new
    end

    should "be initialised empty" do
      @instance.entries.should == []
    end

    should "accept addition of child content" do
      e = Content.new
      @instance << e
      @instance.entries.length.should == 1
      @instance.entries.first.should == e
      @instance.entries.first.container.should == @instance
    end

    should "allow for a deep hierarchy" do
      e = Content.new
      f = Content.new
      e << f
      @instance << e
      @instance.entries.length.should == 1
      @instance.entries.first.should == e
      e.container.should == @instance
      f.container.should == e
    end

    should "persist hierarchy" do
      e = Content.new
      f = Content.new
      e << f
      @instance << e
      @instance.save
      e.save
      f.save

      # p [@instance, e, f]
      i = Content[@instance.id]
      e = Content[e.id]
      f = Content[f.id]

      i.entries.length.should == 1
      i.entries.first.should == e

      e.container.should == i
      f.container.should == e
      e.entry.should == i.entries.first
      f.entry.should == e.entries.first
      e.entries.first.should == f
    end
    should "have a list of child nodes" do
      e = Content.new
      f = Content.new
      e << f
      @instance << e
      @instance.save
      e.save
      f.save

      i = Content[@instance.id]
      e = Content[e.id]
      f = Content[f.id]
      i.nodes.should == [e]
      e.nodes.should == [f]
    end
  end
end