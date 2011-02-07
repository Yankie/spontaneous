# encoding: UTF-8


module Spontaneous::Plugins::Application
  module Paths

    def self.configure(base)
    end

    module ClassMethods
      def log_dir(*path)
        relative_dir(root / "log", *path)
      end

      def config_dir(*path)
        relative_dir(root / "config", *path)
      end

      def template_root=(template_root)
        Spot::Render.template_root = template_root.nil? ? nil : File.expand_path(template_root)
      end

      def template_root(*path)
        relative_dir(Spot::Render.template_root, *path)
      end

      def template_path(*args)
        File.join(template_root, *args)
      end

      def schema_root=(schema_root)
        @schema_root = schema_root
      end

      def schema_root(*path)
        @schema_root ||= root / "schema"
        relative_dir(@schema_root, *path)
      end


      def media_dir=(dir)
        @media_dir = File.expand_path(dir)
      end

      def media_dir(*path)
        @media_dir ||= File.expand_path(root / "../media")
        relative_dir(@media_dir, *path)
      end

      def media_path(*args)
        Spontaneous::Media.media_path(*args)
      end

      def root(*path)
        @root ||= File.expand_path(ENV[Spontaneous::SPOT_ROOT] || Dir.pwd)
        relative_dir(@root, *path)
      end

      def root=(root)
        @root = File.expand_path(root)
      end

      def revision_root(*path)
        @revision_dir ||= File.expand_path(root / '../revisions')
        relative_dir(@revision_dir, *path)
      end

      def revision_root=(revision_dir)
        @revision_dir = File.expand_path(revision_dir)
      end

      def gem_dir(*path)
        relative_dir(Spontaneous.gem_root, *path)
      end

      def application_dir(*path)
        @application_dir ||= File.expand_path("application", Spontaneous.gem_root)
        relative_dir(@application_dir, *path)
      end

      def static_dir(*path)
        application_dir / "static"
        relative_dir(application_dir / "static", *path)
      end

      def js_dir(*path)
        relative_dir(application_dir / "js", *path)
      end

      def css_dir(*path)
        relative_dir(application_dir / "css", *path)
      end

      private

      def relative_dir(root, *path)
        File.join(root, *path)
      end
    end # ClassMethods
  end # Paths
end
