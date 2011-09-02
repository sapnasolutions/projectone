# Superclass for importers that use (uploaded) files as input.
class Importers::FromFiles < Importers::BaseImporters
  
  #waiting parameters : dir
  
  def scan_files
    Logger.send("warn","[FILE] Start scan files")
	@result[:description] << "[FILE] Start scan files"
    
	unless File.exists? $base_ftp_repo+@parameters["dir"]
	  Logger.send("warn","[FILE] Directory #{@parameters["dir"]} does not exist.")
	  @result[:description] << "[FILE] Directory #{@parameters["dir"]} does not exist."
      return
    end
	
	# obtain a list of recent zips, sorted by modification time,
    # that can be opened as zipfiles, and save them
    pattern = File.join($base_ftp_repo+@parameters["dir"], '*')
    Dir[pattern].sort { |a,b|
		File.mtime(a) <=> File.mtime(b)
    }.select{ |path|
		tmp_file = File.new(path,"r+b")
        ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest tmp_file.read)).first.nil?
	}.each { |path|
	# self.from_file(filename,file,execution)
		name = path
		tmp_file = File.new(path,"r+b")
		e = Execution.new
		e.passerelle = @passerelle
		e.statut = "nex"
		e.save!
		f = ExecutionSourceFile.from_file(name,tmp_file,e)
		e.execution_source_file = f
		e.save!
    }
	
  end
  
  def dl_and_update_medias_directly_from_root
    # @logger.info "Start Root's medias registeration"
    # @nb_medias = 0
    
    # remote_files = search_file(@ftp_media_repository,/\.(jpg|jpeg|png|bmp)$/)

    # download_file @ftp_media_repository, remote_files, :bin, "download_images"
    # @logger.info "#{@nb_medias} Root's medias registered"
    
  # rescue Exception => e
    # @logger.error "Error during navigation in FTP : #{@ftp_adress}; log|pass : #{@app.parameter}."
    # @logger.error "#{e} :\n#{e.backtrace.join("\n")}"
  end

  ################
  def download_data tmp_dl
	name = File.basename(tmp_dl.path)
    # tmp_data = Paperclip::Tempfile.new "temp_file"
    # tmp_data.write Iconv.conv('utf-8','cp1252',data.to_s)
    # tmp_data.rewind
    # mime = File.mime_type? StringIO.new(tmp_data.read)
    # @logger.info "Download file mime type is : #{mime}"
    # if @mime.include? mime.gsub(/\n/,"")
      # if Importers::Check.check(tmp_data.path)
	  e = Execution.new
	  e.passerelle = @passerelle
	  e.statut = "nex"
	  e.save!
	  f = ExecutionSourceFile.from_file(name,tmp_dl,e)
	  e.execution_source_file = f
      # end
    # end
#    tmp_data.close
  end
  
  def download_images tmp_dl
    # m = Media::Base.from_data tmp_dl.read, @client
    # next if m.nil?
    # m.attrs[@importer] = true
    # name = File.basename tmp_dl.path.to_s.downcase
    # if m.attrs[:source_name].nil? || m.attrs[:source_name] == ""
      # m.attrs[:source_name] = name
    # else
      # (m.attrs[:source_name] += "|"+name) unless (m.attrs[:source_name].split('|').include? name)
    # end
    # m.label = name

    # m.save!
    # @nb_medias += 1
    # @medias[name] = m
  end
  
end