# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Modifications" do

  before do
    @now = Time.now
    @site = setup_site
    stub_time(@now)

    Content.delete

    class ::Page
      field :title, :string, :default => "New Page"
      box :things
    end
    class ::Piece
      box :things
    end

    @root = Page.create(:uid => "root")
    count = 0
    2.times do |i|
      c = Page.new(:uid => i, :slug => "p-#{i}")
      @root.things << c
      count += 1
      2.times do |j|
        d = Piece.new(:uid => "#{i}.#{j}", :slug => "p-#{i}-#{j}")
        c.things << d
        count += 1
        2.times do |k|
          d.things << Page.new(:uid => "#{i}.#{j}.#{k}", :slug => "p-#{i}-#{j}-#{k}")
          d.save
          count += 1
        end
      end
      c.save
    end
    @root.save
  end

  after do
    Object.send(:remove_const, :Page) rescue nil
    Object.send(:remove_const, :Piece) rescue nil
    Content.delete
    teardown_site
  end

  it "register creation date of all content" do
    c = Content.create
    c.created_at.to_i.must_equal @now.to_i
    page = Page.create
    page.created_at.to_i.must_equal @now.to_i
  end

  it "update modification date of page when page fields are updated" do
    now = @now + 100
    stub_time(now)
    c = Content.first
    (c.modified_at.to_i - @now.to_i).abs.must_be :<=, 1
    c.label = "changed"
    c.save
    (c.modified_at - now).abs.must_be :<=, 1
  end

  it "update modification date of path when page visibility is changed" do
    now = @now + 100
    stub_time(now)
    c = Page.uid("0")
    (c.modified_at.to_i - @now.to_i).abs.must_be :<=, 1
    c.toggle_visibility!
    (c.modified_at - now).abs.must_be :<=, 1
  end

  it "update page timestamps on modification of its box fields" do
    Page.box :with_fields do
      field :title
    end

    stub_time(@now+3600)
    page = Page.first :uid => "0"
    (page.modified_at.to_i - @now.to_i).abs.must_be :<=, 1
    page.with_fields.title.value = "updated"
    page.save.reload
    page.modified_at.to_i.must_equal @now.to_i + 3600
  end

  it "update page timestamps on modification of a piece" do
    stub_time(@now+3600)
    page = Page.first :uid => "0"
    (page.modified_at.to_i - @now.to_i).abs.must_be :<=, 1
    content = page.contents.first
    content.page.must_equal page
    content.label = "changed"
    content.save
    page.reload
    page.modified_at.to_i.must_equal @now.to_i + 3600
  end

  it "update page timestamps on modification of a piece's box fields" do
    Piece.box :with_fields do
      field :title
    end
    stub_time(@now+3600)
    page = Page.first :uid => "0"
    (page.modified_at.to_i - @now.to_i).abs.must_be :<=, 1
    content = page.contents.first

    content.with_fields.title.value = "updated"
    content.save
    page.reload
    page.modified_at.to_i.must_equal @now.to_i + 3600
  end

  it "update page timestamp on addition of piece" do
    stub_time(@now+3600)
    page = Page.first :uid => "0"
    content = Content[page.contents.first.id]
    content.things << Piece.new
    content.save
    content.modified_at.to_i.must_equal @now.to_i + 3600
    page.reload
    page.modified_at.to_i.must_equal @now.to_i + 3600
  end

  it "not update the parent page's timestamp on addition of a child page yyyy" do
    stub_time(@now+1000)
    page = Page.first :uid => "0"
    page.things << Page.new
    page.save.reload
    page.modified_at.to_i.must_equal @now.to_i
  end

  it "update the parent page's modification time if child pages are re-ordered" do
    page = Page.first :uid => "0.0.0"
    page.things << Page.new(:uid => "0.0.0.0")
    page.things << Page.new(:uid => "0.0.0.1")
    page.save
    page = Page.first :uid => "0.0.0"
    stub_time(@now+1000)
    child = page.things.first
    child.update_position(1)
    page.reload.modified_at.to_i.must_equal @now.to_i + 1000
  end

  it "update a page's timestamp on modification of its slug" do
    stub_time(@now+1000)
    page = Page.first :uid => "0"
    page.slug = "changed"
    page.save.reload
    page.modified_at.to_i.must_equal @now.to_i + 1000
  end

  it "not update child pages timestamps after changing their parent's slug" do
    page = Page.first :uid => "0.0.0"
    modified = page.modified_at.to_i
    stub_time(@now+1000)
    page = Page.first :uid => "0"
    page.slug = "changed"
    page.save.reload
    page.modified_at.to_i.must_equal @now.to_i + 1000
    page = Page.first :uid => "0.0.0"
    page.modified_at.to_i.must_equal modified
  end

  it "update the pages timestamp if a boxes order is changed" do
    stub_time(@now+3600)
    page = Page.first :uid => "0"
    content = Content[page.contents.first.id]
    content.update_position(1)
    page.reload.modified_at.to_i.must_equal @now.to_i + 3600
  end

  it "update the parent page's modification time if the contents of a piece's box are re-ordered" do
    stub_time(@now+3600)
    page = Page.first :uid => "0"
    content = page.things.first.things.first
    content.update_position(1)
    page.reload.modified_at.to_i.must_equal @now.to_i + 3600
  end

  it "update the parent page's modification date if a piece is deleted" do
    stub_time(@now+3600)
    page = Page.first :uid => "0"
    content = Content[page.contents.first.id]
    content.destroy
    page.reload.modified_at.to_i.must_equal @now.to_i + 3600
  end

  it "update the parent page's modification date if a page is deleted" do
    stub_time(@now+3600)
    page = Page.first :uid => "0"
    content = Content[page.things.first.things.first.id]
    content.destroy
    page.reload.modified_at.to_i.must_equal @now.to_i + 3600
  end

  it "add entry to the list of side effects for a visibility change" do
    stub_time(@now+3600)
    page = Page.first :uid => "1"
    old_slug = page.slug
    page.slug = "changed"
    page.save
    page.reload
    page.pending_modifications.length.must_equal 1
    mods = page.pending_modifications(:slug)
    mods.length.must_equal 1
    mod = mods.first
    mod.must_be_instance_of Spontaneous::Model::Core::Modifications::SlugModification
    mod.old_value.must_equal old_slug
    mod.new_value.must_equal "changed"
    mod.created_at.to_i.must_equal @now.to_i + 3600
  end

  it "serialize page modifications" do
    stub_time(@now+3600)
    page = Page.first :uid => "1"
    page.slug = "changed"
    page.save
    page.pending_modifications.length.must_equal 1
    mod = page.pending_modifications(:slug).first
    page = Page.first :id => page.id
    page.pending_modifications.length.must_equal 1
    page.pending_modifications(:slug).first.must_equal mod
    page.pending_modifications(:slug).first.created_at.to_i.must_equal @now.to_i + 3600
  end

  it "concatenate multiple slug modifications together" do
    stub_time(@now+3600)
    page = Page.first :uid => "1"
    old_slug = page.slug
    page.slug = "changed"
    page.save
    page.pending_modifications.length.must_equal 1
    page.slug = "changed-again"
    page.save
    mod = page.pending_modifications(:slug).first
    mod.old_value.must_equal old_slug
    mod.new_value.must_equal "changed-again"
  end

  it "know the number of pages affected by slug modification" do
    stub_time(@now+3600)
    page = Page.first :uid => "1"
    page.slug = "changed"
    page.save
    mod = page.pending_modifications(:slug).first
    mod.count.must_equal 4
  end

  it "show the number of pages whose visibility is affected in the case of a visibility change" do
    stub_time(@now+3600)
    page = Page.first :uid => "1"
    page.hide!
    page.reload
    mods = page.pending_modifications(:visibility)
    mods.length.must_equal 1
    mod = mods.first
    mod.count.must_equal 4
    mod.owner.must_equal page
  end

  it "record visibility changes that originate from a content piece" do
    stub_time(@now+3600)
    page = Page.first :uid => "1"
    page.things.first.hide!
    page.reload
    mods = page.pending_modifications(:visibility)
    mods.length.must_equal 1
    mod = mods.first
    mod.count.must_equal 2
    mod.owner.must_equal page.things.first
  end

  it "show number of pages that are to be deleted in the case of a deletion" do
    stub_time(@now+3600)
    page = Page.first(:uid => "1")
    owner = page.owner
    page.destroy
    page = Page.first(:uid => "root")
    mods = page.pending_modifications(:deletion)
    mod = mods.first
    # count is number of children of deleted page + 1 (for deleted page)
    mod.count.must_equal 5
    mod.owner.must_equal owner.reload
  end

  it "show number of pages deleted if piece with pages is deleted" do
    stub_time(@now+3600)
    page = Page.first(:uid => "1")
    piece = page.things.first
    owner = piece.owner
    piece.destroy
    page = Page.first(:uid => "1")
    mods = page.pending_modifications(:deletion)
    mod = mods.first
    mod.count.must_equal 2
    mod.owner.must_equal owner.reload
  end

  it "show number of pages deleted if page belonging to piece is deleted" do
    stub_time(@now+3600)
    page = Page.first(:uid => "1")
    child = page.things.first.things.first
    owner = child.owner
    child.destroy
    page = Page.first(:uid => "1")
    mods = page.pending_modifications(:deletion)
    mod = mods.first
    mod.count.must_equal 1
    mod.owner.must_equal owner.reload
  end

  it "have an empty modification if the slug has been reverted to original value" do
    stub_time(@now+3600)
    page = Page.first :uid => "1"
    old_slug = page.slug
    page.slug = "changed"
    page.save
    page.pending_modifications.length.must_equal 1
    page.slug = "changed-again"
    page.save
    page.slug = old_slug
    page.save
    mods = page.reload.pending_modifications(:slug)
    mods.length.must_equal 0
  end

  it "have an empty modification if the visibility has been reverted to original value xxx" do
    stub_time(@now+3600)
    page = Page.first :uid => "1"
    page.things.first.hide!
    page.reload
    page.things.first.show!
    page.reload
    mods = page.pending_modifications(:visibility)
    mods.length.must_equal 0
  end

  describe "during publish" do
    before do
      @initial_revision = 1
      @final_revision = 2
      Content.delete_revision(@initial_revision) rescue nil
      Content.delete_revision(@final_revision) rescue nil
      ::Content.publish(@initial_revision)
    end

    after do
      Content.delete_revision(@initial_revision) rescue nil
      Content.delete_revision(@final_revision) rescue nil
      Content.delete_revision(@final_revision+1) rescue nil
    end

    it "act on path change modifications" do
      page = Page.first :uid => "1"
      old_slug = page.slug
      page.slug = "changed"
      page.save
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        %w(1 1.1.1).each do |uid|
          published_page = Page.first :uid => uid
          ::Content.with_editable do
            editable_page = Page.first :uid => uid
            published_page.path.must_equal editable_page.path
          end
        end
      end
    end

    it "not publish slug changes on pages other than the one being published" do
      #/bands/beatles -> /bands/beatles-changed
      #/bands -> /bands-changed
      # publish(bands)
      # with_published { beatles.path.must_equal /bands-changed/beatles }
      page = Page.first :uid => "1"
      page.slug = "changed"
      page.save

      child_page = Page.first :uid => "1.0.0"
      old_slug = child_page.slug
      child_page.slug = "changed-too"
      child_page.save

      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        published = Page.first :uid => "1.0.0"
        published.path.must_equal "/changed/#{old_slug}"
      end
    end

    it "publish the correct path for new child pages with an un-published parent slug change" do
      # add /bands/beatles
      # /bands -> /bands-changed
      # publish(beatles)
      # with_published { beatles.path.must_equal /bands/beatles }
      page = Page.first :uid => "1"
      old_slug = page.slug
      page.slug = "changed"
      page.save

      child_page = Page.first :uid => "1.0.0"
      child_page.slug = "changed-too"
      child_page.save

      ::Content.publish(@final_revision, [child_page.id])
      ::Content.with_revision(@final_revision) do
        published = Page.first :uid => "1.0.0"
        published.path.must_equal "/#{old_slug}/changed-too"
      end
    end


    it "act on visibility modifications" do
      page = Page.first :uid => "1"
      page.hide!
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        %w(1 1.1.1).each do |uid|
          published_page = Page.first :uid => uid
          ::Content.with_editable do
            editable_page = Page.first :uid => uid
            published_page.hidden?.must_equal editable_page.hidden?
          end
        end
      end
    end

    it "publish the correct visibility for new child pages with un-published up-tree visibility changes" do
      page = Page.first :uid => "1"
      page.hide!

      child_page = Page.new :uid => "child"
      page.things << child_page
      page.save

      ::Content.publish(@final_revision, [child_page.id])

      ::Content.with_revision(@final_revision) do
        published = Page.first :uid => "1.0.0"
        assert published.visible?
        published = Page.first :uid => "child"
        assert published.visible?
      end
    end

    it "publish the correct visibility for new child pages with published up-tree visibility changes" do
      page = Page.first :uid => "1"
      page.hide!

      child_page = Page.new :uid => "child"
      page.things << child_page
      page.save

      ::Content.publish(@final_revision, [page.id, child_page.id])

      ::Content.with_revision(@final_revision) do
        published = Page.first :uid => "child"
        refute published.visible?
      end
    end

    it "publish the correct visibility for child pages with un-published parent visibility changes" do
      # if we publish changes to a child page whose parent page is hidden but that visibility change
      # hasn't been published then the child page it be visible until the parent is published
      page = Page.first :uid => "1"
      page.hide!

      child_page = Page.first :uid => "1.0.0"
      child_page.slug = "changed-too"
      child_page.save

      ::Content.publish(@final_revision, [child_page.id])

      ::Content.with_revision(@final_revision) do
        published = Page.first :uid => "1.0.0"
        assert published.visible?
      end
    end

    it "publish the correct visibility for immediate child pages with published parent visibility changes" do
      page = Page.first :uid => "1"

      child_page = Page.new :uid => "newpage"
      page.things << child_page
      page.save

      ::Content.publish(@final_revision, [page.id, child_page.id])

      refute child_page.hidden?

      page.hide!

      assert child_page.reload.hidden?

      ::Content.publish(@final_revision + 1, [page.id])

      ::Content.with_revision(@final_revision + 1) do
        published = Page.first :uid => "newpage"
        refute published.visible?
      end
    end

    it "publish the correct visibility for child pages with published parent visibility changes" do
      page = Page.first :uid => "1"
      child_page = Page.first :uid => "1.0.0"
      refute child_page.hidden?

      page.hide!

      assert child_page.reload.hidden?

      ::Content.publish(@final_revision, [page.id])

      ::Content.with_revision(@final_revision) do
        published = Page.first :uid => "1.0.0"
        refute published.visible?
      end
    end

    it "maintain correct published visibility for pieces" do
      page = Page.first :uid => "1"
      piece = page.things.first
      piece.hide!
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        piece = Page.first(:uid => "1").things.first
        refute piece.visible?
      end

      ::Content.publish(@final_revision+1, [page.id])

      ::Content.with_revision(@final_revision+1) do
        piece = Page.first(:uid => "1").things.first
        refute piece.visible?
      end
    end

    it "maintain correct published visibility for pages" do
      page = Page.first :uid => "1.1.1"
      page.hide!
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        page = Page.first(:uid => "1.1.1")
        refute page.visible?
      end

      ::Content.publish(@final_revision+1, [page.id])

      ::Content.with_revision(@final_revision+1) do
        page = Page.first(:uid => "1.1.1")
        refute page.visible?
      end
    end


    it "act on multiple modifications" do
      page = Page.first :uid => "1"
      page.slug = "changed"
      page.slug = "changed-again"
      page.hide!

      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        %w(1 1.1.1).each do |uid|
          published_page = Page.first :uid => uid
          ::Content.with_editable do
            editable_page = Page.first :uid => uid
            published_page.hidden?.must_equal editable_page.hidden?
            published_page.slug.must_equal editable_page.slug
            published_page.path.must_equal editable_page.path
          end
        end
      end
    end

    it "ignore deletion modifications" do
      page = Page.first(:uid => "1")
      page.destroy
      page = Page.first(:uid => "root")
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        %w(1 1.1.1).each do |uid|
          published_page = Page.first :uid => uid
          published_page.must_be_nil
        end
        published_page = Page.first :uid => "0"
        published_page.wont_be_nil
      end
    end

    it "clear modifications after publish" do
      page = Page.first :uid => "1"
      page.slug = "changed"
      page.hide!
      ::Content.publish(@final_revision, [page.id])
      page = Page.first :id => page.id
      page.pending_modifications.length.must_equal 0
    end
  end

  describe "with assigned editor" do
    before do
      Spontaneous::Permissions::User.delete
      @user = Spontaneous::Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root", :password => "rootpass")
    end

    after do
      @user.destroy
    end

    it "add the editor to any modifications" do
      stub_time(@now+3600)
      page = Page.first :uid => "1"
      page.current_editor = @user
      page.slug = "changed"
      page.save
      mod = page.pending_modifications(:slug).first
      mod.user.must_equal @user
    end

    it "persist the user" do
      stub_time(@now+3600)
      page = Page.first :uid => "1"
      page.current_editor = @user
      page.slug = "changed"
      page.save
      page = Page.first :uid => "1"
      mod = page.pending_modifications(:slug).first
      mod.user.must_equal @user
    end
  end
end
