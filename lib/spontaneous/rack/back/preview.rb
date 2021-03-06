module Spontaneous::Rack::Back
  class Preview < Base
    include Spontaneous::Rack::Public


    # In preview mode we want to find pages even if they're
    # invisible.
    def find_page_by_path(path)
      Spontaneous::Content.scope do
        Spontaneous::Site.by_path(path)
      end
    end

    # Forward all GETs to the page resolution method
    get '*' do
      render_path(params[:splat][0])
    end

    # Forward all POSTs to the page resolution method
    post '*' do
      render_path(params[:splat][0])
    end

    # Override the S::Rack::Public method to add in some cache-busting headers
    def render_page(page, format = :html, local_params = {})
      now = Time.now.to_formatted_s(:rfc822)
      response.headers[HTTP_EXPIRES] = now
      response.headers[HTTP_LAST_MODIFIED] = now
      response.headers[HTTP_CACHE_CONTROL] = HTTP_NO_CACHE
      super
    end
  end # Preview
end
