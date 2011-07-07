class BienPhoto < ActiveRecord::Base

  hobo_model # Don't put anything above this

  require 'mimetype_fu'
  require 'open-uri'
  
  fields do
    ordre     :integer
    titre     :string
	hashsum	  :string
    attributs :text
    timestamps
  end

  has_attached_file :photo,
	:styles => {
		:thumb=> "100x100#",
		:small  => "150x150>",
		:medium => "400x300>",
		:large =>   "800x600>"
	},
	:path  => "#{$base_client_medias}/:client_folder/:id.:style.:extension",
	:url  => "#{$url_client_medias}/:client_folder/:id.:style.:extension",
    :default_url => '/images/blank.gif'
	#:path => "#{$base_path_media}/:login/:style_:basename_:id.:extension",
    #:url  => "#{$base_url_media}/:login/:style_:basename_:id.:extension"
	
	belongs_to :bien
	default_scope :order => :ordre
	#process_in_background :photo
	typed_serialize :attributs, Hash
  
    def self.from_local(local_path, bien, ordre, titre)
      filename = File.basename local_path
      f = File.open(local_path)
      self.from_data(filename,f.read,bien,ordre,titre)
    end
    
    def self.from_url(url, bien, ordre, titre)
      
      Logger.send("warn","Opening URL '#{url}'")
      filename = File.basename url
      fd = open(URI.encode(url))
      image_data = fd.read
      mime = fd.content_type
      Logger.send("warn","Content type is #{mime}")
      fd.close

      self.from_data(filename,image_data,bien,ordre,titre)
    end
    
    def self.from_data(filename,data,bien,ordre,titre)
      require 'image_size'
      require 'pp'
      begin
        hash = Digest::MD5.hexdigest data
      rescue   Exception => e
        Logger.send("warn","Photo could not be saved: #{e.message}")
        return nil
      end

      # Check if the hash is already known
      if bien.nil?
		Logger.send("warn","Photo could not be saved: bien is unknow")
        return nil
      else
        photo = self.find :first, :conditions => {:hashsum => hash, :bien_id => bien.id}
        return photo unless photo.nil?
      end
          
	  # Create the new media using a temporary file
	  tmp = File.new("#{$tmp_path}/tmp.jpg","w+b")
	  tmp.write data
	  
      #tmp = Tempfile.new filename
	  #tmp.set_encoding("ASCII-8BIT")
      #tmp.write data
      # Use mimetype-fu to obtain mime if unknown
      #mime = File.mime_type? tmp
      #mime.gsub!(/\n/,"")
	  
      #if article.nil?
      #  Logger.send("warn","unique label[#{label_name}] MIME (mimetype_fu) is #{mime}")
      #else
      #Logger.send("warn","#{bien.id}[#{filename}] MIME (mimetype_fu) is #{mime}")
      #end

      # Guess media type from MIME
      #case mime
      #  when /image/ then generator = Media::Image
      #  when /video/ then generator = Media::Video
      #else
      #  Logger.send("warn","Could not guess MIME type : [#{mime.to_s}]")
      #  return nil
      #end
	  
	  #unless mime =~ /image/
	#	Logger.send("warn","Could not guess MIME type : [#{mime.to_s}]")
	#	return nil
	#  end
      
      photo = self.new
      photo.hashsum = hash
      photo.bien = bien
	  photo.photo = tmp
      photo.titre = titre
	  photo.ordre = ordre
      
      #if media is image store the size
      #if media.is_a?(Media::Image)
      #  size = ImageSize.new( data ).get_size
      #  media.attrs[:width]  = size[0]
      #  media.attrs[:height] = size[1]
      #end
      
      begin
        photo.save!
      rescue Exception => e  
        Logger.send("warn","Photo could not be saved: \n #{e} :\n#{e.backtrace.join("\n")}")
        return nil
      else
        return photo
      ensure
        tmp.close
		File.delete tmp if File.exist? tmp.path
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
