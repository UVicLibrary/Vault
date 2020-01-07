class FilePathCheckerController < ApplicationController

  require 'csv'
  layout 'hyrax/dashboard'

    def upload

     if params[:file]
      @csv_file = params[:file].path
      row_number = 1 # +1 offset to account for csv headers
      @path_list = {}

      CSV.foreach(@csv_file, headers: true, header_converters: :symbol) do |row|
        row_number +=1
        next if row[:url].nil?
        file_path = row[:url]
        if !File.file?(file_path.gsub("file:///usr/local/rails/vault/tmp/uploads/local_files", "/mnt/qdrive"))
          @path_list[row_number] = file_path
        end
      end

       if @path_list.blank?
         flash[:notice] = "All file paths are valid."
       else
         flash[:error] = "Vault couldn't find files at the following urls. Please correct the paths and try again."
       end
     end


    end

end
