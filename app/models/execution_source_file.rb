class ExecutionSourceFile < ActiveRecord::Base

  hobo_model # Don't put anything above this

  require 'mimetype_fu'
  require 'open-uri'
  
  fields do
    hashsum :string
    attributs   :text
    timestamps
  end

  belongs_to :execution
  has_many :installations, :dependent => :nullify
  #typed_serialize :attributs, Hash
  
  has_attached_file :file,
	:path  => "#{$base_executions_sources}/:execution_client_folder/:id.:style.:extension",
	:url  => "#{$url_executions_sources}/:execution_client_folder/:id.:style.:extension"
  def self.from_file(filename,file,execution)
	data = file.read
	begin
        hash = Digest::MD5.hexdigest data
    rescue   Exception => e
        Logger.send("warn","File could not be saved: #{e.message}")
        return nil
    end
	
	exe_file = self.new
    exe_file.hashsum = hash
    exe_file.execution = execution
	exe_file.file = file
	
	execution.execution_source_file.destroy unless execution.execution_source_file.nil?
	execution.save!
    exe_file.save!
	return exe_file
  end
  
  def absolute_url
		return "#{$domain}/#{self.file.url}"
  end
  
  def self.from_data(filename,data,execution)
      begin
        hash = Digest::MD5.hexdigest data
      rescue   Exception => e
        Logger.send("warn","File could not be saved: #{e.message}")
        return nil
      end
          
	  # Create the new media using a temporary file
	  
      tmp = Tempfile.new filename
      tmp.write data
	  #tmp.rewind
      # Use mimetype-fu to obtain mime if unknown
      #mime = File.mime_type? tmp
      #mime.gsub!(/\n/,"")
	  #Logger.send("warn","MIME (mimetype_fu) is #{mime}")
      file = self.new
      file.hashsum = hash
      file.execution = execution
	  file.file = tmp
      
      begin
		# delete the old execution source file if exist (FIXME : bad, very bad way to do)
		Logger.send("warn","New execution source file registered : #{filename}")
		execution.execution_source_file.destroy unless execution.execution_source_file.nil?
		execution.save!
        file.save!
      rescue Exception => e  
        Logger.send("warn","File could not be saved: \n #{e} :\n#{e.backtrace.join("\n")}")
        return nil
      else
        return file
      ensure
        tmp.close
      end
    end
  
  def self.download_new_firmware(firmware_name,url)
	  Logger.send("warn","Opening URL '#{url}'")
      filename = File.basename url
	  data = ""
	  open('File.basename', 'wb') do |file|
		data << open(URI.encode(url)).read
	  end
      # fd = open(URI.encode(url),"wb")
      # data = fd.read
      # mime = fd.content_type
      # Logger.send("warn","Content type is #{mime}")
      # fd.close
  
      begin
        hash = Digest::MD5.hexdigest data
      rescue   Exception => e
        Logger.send("warn","File could not be saved: #{e.message}")
        return nil
      end
          
	  # Create the new firmware file using a temporary file
      tmp = File.new("#{$tmp_path}/tmp.zip","w+b")
	  tmp.write data
      file = self.new
      file.hashsum = hash
      file.execution = nil
	  file.file = tmp
	  file.attributs = "type:firmware"
      
      begin
		# delete the old execution source file if exist (FIXME : bad, very bad way to do)
		Logger.send("warn","New execution source file registered : #{filename}")
        file.save!
      rescue Exception => e  
        Logger.send("warn","File could not be saved: \n #{e} :\n#{e.backtrace.join("\n")}")
        return nil
      else
        return file
      ensure
        tmp.close
      end
    end
  
  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end

end
