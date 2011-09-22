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
	# :styles => {
		# :thumb=> "100x100#",
		# :small  => "150x150>",
		# :medium => "400x300>",
		# :large =>   "800x600>"
	# },
	:path  => "#{$base_client_medias}/:client_folder/:id.:style.:extension",
	:url  => "#{$url_client_medias}/:client_folder/:id.:style.:extension",
    :default_url => '/images/blank.gif'
	#:path => "#{$base_path_media}/:login/:style_:basename_:id.:extension",
    #:url  => "#{$base_url_media}/:login/:style_:basename_:id.:extension"
	
	belongs_to :bien
	default_scope :order => :ordre
	#process_in_background :photo
	#typed_serialize :attributs, Hash
	
	def absolute_url
		return "#{$domain}/#{self.photo.url}"
	end
  
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
	
	def save
		if self.bien && self.ordre.nil?
			if self.bien.bien_photos.empty?
				self.ordre = 1
			else
				self.ordre = self.bien.bien_photos.map{ |p| p.ordre.to_i}.max+1
			end
		end
		super
	end
	
	def save!
		if self.bien && self.ordre.nil?
			if self.bien.bien_photos.empty?
				self.ordre = 1
			else
				self.ordre = self.bien.bien_photos.map{ |p| p.ordre.to_i}.max+1
			end
		end
		super
	end
	
    def self.from_data(filename,data,bien,ordre,titre)
      begin
        hash = Digest::MD5.hexdigest data
      rescue   Exception => e
        Logger.send("warn","Photo could not be saved: #{e.message}")
        return nil
      end

      # Check if the hash is already known, now don't differenciate with the goods
      # if bien.nil?
		photo = self.where(:hashsum => hash).first
		photo.bien = bien
      # else
		# photo = self.where(:hashsum => hash, :bien_id => bien.id).first
      # end
        
	  if photo.nil?
		  # Create the new media using a temporary file
		  Logger.send("warn","Register a new photo : #{filename}")
		  tmp = File.new("#{$tmp_path}/tmp.jpg","w+b")
		  tmp.write data
		  
		  photo = self.new
		  photo.hashsum = hash
		  photo.bien = bien
		  photo.photo = tmp
		  photo.titre = titre
		  photo.ordre = ordre
	  end
	  if photo.attributs.nil? || photo.attributs.empty?
          photo.attributs = titre
      else
          (photo.attributs += "|"+titre) unless (photo.attributs.split('|').include? titre)
      end
	  
      begin
        photo.save!
      rescue Exception => e  
        Logger.send("warn","Photo could not be saved: \n #{e} :\n#{e.backtrace.join("\n")}")
        return nil
      else
        return photo
      ensure
		if tmp
			tmp.close
			File.delete tmp if File.exist? tmp.path
		end
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
