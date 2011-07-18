# Superclass for importers that use (uploaded) files as input.
class Importers::FromFtp < Importers::BaseImporters
  require 'net/ftp'
  
  FTP_TEMP_REPOSITORY = "#{$tmp_path}"
  
  #waiting parameters : login, password, address (not required)
  
  # +mime+ is a list of valid file mime types
  def initialize passerelle, mime, ext, ftp_adress, ftp_file_repository = "/", ftp_media_repository = "/"
    super passerelle, mime
	@ftp_adress = @parameters["address"]||ftp_adress
    @ftp_type_filter = ext
    @ftp_file_repository = ftp_file_repository
    @ftp_media_repository = ftp_media_repository
  end
  
  def scan_files
    Logger.send("warn","[FTP] Start scan FTP files")
    
    remote_files = search_file(@ftp_file_repository,/\.#{@ftp_type_filter}/)
    
    download_file @ftp_file_repository, remote_files, :bin, "download_data"
  # rescue Exception => e
		# Logger.send("warn","[FTP] Error during navigation in FTP : #{@ftp_adress}; log|pass : #{@parameters.to_s}.")
		# Logger.send("warn","[FTP] #{e} :\n#{e.backtrace.join("\n")}")
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

  def search_file repository, filter = nil
    # connect to FTP
    login = @parameters["login"]
    password = @parameters["password"]
    remote_files = []
    ftp = Net::FTP.new(@ftp_adress)
    
    ftp.passive = true
    ftp.login(login,password)
    ftp.chdir(repository)
    i = 1
    # List remote file
    max = ftp.list("*.*").size
    ftp.list("*.*") do |file|
      i += 1
      case file.to_s.downcase 
      when /:\d\d\s(.*)$/ then
        remote_file_path = $1
      when /\s\d\d\d\d\s(.*)$/ then
        remote_file_path = $1
      else
        next
      end
      
      if filter.nil? or remote_file_path =~ filter
        remote_files << remote_file_path
      end
      # Hack for bug with ftp list (ls, nlst)
      # if we don't break manually, it never go out of the loop
      break if i > max
    end
    ftp.close
    return remote_files
  end
  
  def download_file repository, remote_files, file_type, action_on_downloaded_file
    login = @parameters["login"]
    password = @parameters["password"]
    ftp = Net::FTP.new(@ftp_adress)

    ftp.passive = true
    ftp.login(login,password)
    ftp.chdir(repository)
    
    remote_files.each{ |remotepath|
		# begin
			if file_type == :text
				tmp_dl = File.new("#{$tmp_path}/#{remotepath}","w+")
			else
				tmp_dl = File.new("#{$tmp_path}/#{remotepath}","w+b")
			end
			# tmp_dl = File.new remotepath
			# tmp_dl.write ""
			# tmp_dl.rewind
			localpath = tmp_dl.path
			Logger.send("warn","[FTP] Start download : #{remotepath}")
			if file_type == :text
			  ftp.gettextfile(remotepath,localpath)
			else
			  ftp.getbinaryfile(remotepath,localpath)
			end
			eval "#{action_on_downloaded_file} tmp_dl"
			
			Logger.send("warn","[FTP] End download correctly (size : #{File.size tmp_dl.path} )")
		# rescue
			# Logger.send("warn","[FTP] End download with errors")
		# ensure
			tmp_dl.close
			File.delete tmp_dl if File.exist? tmp_dl.path
		# end
    }
    ftp.close
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