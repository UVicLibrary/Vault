module Hyrax

  class ContentBlocksController < ApplicationController
    load_and_authorize_resource
    with_themed_layout 'dashboard'

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
      add_breadcrumb t(:'hyrax.admin.sidebar.content_blocks'), hyrax.edit_content_blocks_path
    end

    def update
      respond_to do |format|
        if @content_block.update(value: update_value_from_params, researcher_name: params[:content_block][:researcher_name],
          researcher_title: params[:content_block][:researcher_title])
          format.html {
            if params[:content_block][:researcher_thumbnail]
              # Save file name of the file in researcher_thumbnail
              @content_block.update(researcher_thumbnail: params[:content_block][:researcher_thumbnail].original_filename)
              dir = Rails.root.join('public', 'uploads', 'researchers')
              Dir.mkdir(dir) unless Dir.exist?(dir)
              File.open(dir.join(params[:content_block][:researcher_thumbnail].original_filename), 'wb') do |file|
                file.write(params[:content_block][:researcher_thumbnail].read)
              end
            end
            redirect_to hyrax.edit_content_blocks_path, notice: t(:'hyrax.content_blocks.updated')
          }
        else
          format.html { render :edit }
        end
      end
    end

    private

      def permitted_params
        params.require(:content_block).permit(:marketing,
                                              :announcement,
                                              :researcher,
                                              :researcher_name,
                                              :researcher_title,
                                              :researcher_thumbnail,
                                              :researcher_thumbnail_cache)
      end

      # When a request comes to the controller, it will be for one and
      # only one of the content blocks. Params always looks like:
      #   {'about_page' => 'Here is an awesome about page!'}
      # So reach into permitted params and pull out the first value.
      def update_value_from_params
        permitted_params.values.first
      end
  end
end
