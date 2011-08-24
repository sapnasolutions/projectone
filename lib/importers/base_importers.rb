# Superclass for importers that use (uploaded) files as input.
class Importers::BaseImporters

  require 'zip/zipfilesystem'
  require 'iconv'
  
  # Setup for a +client+ and an +importer+ name (short string).
  # +mime+ is a list of valid file mime types
  def initialize passerelle, mime = nil
    @passerelle = passerelle
	$passerelle = passerelle
    @mime = mime
	@parameters = {}
	unless @passerelle.parametres.empty? || @passerelle.parametres.nil?
		@passerelle.parametres.split(";").each{ |couple|
			@parameters[couple.split(":").first] = couple.split(":").second
		}
	end
    #@agency = nil
    @medias = {}
  end
  
  # Import the non-imported zipfiles for a given client.
  def import
    scan_files
    # import non-imported files
	Execution.where(:passerelle_id => @passerelle.id, :statut => "nex").order_by(:created_at).each{ |execution|
		result = import_exe execution
		# if result
		execution.statut = "ok"
		# else
			# execution.statut = "err"
		# end
		execution.save!
	}
    @passerelle.updated_at = DateTime.now
    @passerelle.save!
  end
  
  
  # Overload this in inherited classes
  def import_file
    raise "import_file must be redefined in children classes"
  end
  
  
  # Overload method to access distant file (database, url, ftp, other ...)
  def scan_files
    raise "scan_files must be redefined in children classes"
  end
  
  # Overload method to access distant medias (if medias are not with data's file in zip)
  # Register and reference all medias in @medias var
  def dl_and_update_medias_directly_from_root
    raise "dl_and_update_medias_directly_from_root must be redefined in children classes"
  end
  
  # Check zip_file, reference all medias in @medias var
  def dl_and_update_medias zip_file
    nb_medias = 0
    zip_file.each do |entry|
      begin
        next unless entry.name.to_s.downcase =~ /.(jpg|jpeg|png|bmp)$/
      
        data = zip_file.read(entry)
		# find a way to create media without "bien" linked, but only "passerelle" ?
		name = File.basename entry.name.to_s.downcase
		#params for from_data : filename,image_data,bien,ordre,titre
        p = BienPhoto.from_data name, data, nil, nil, name
        next if p.nil?
		#FIXME this part can be in from_datas method
        if p.attributs.nil? || p.attributs.empty?
          p.attributs = name
        else
          (p.attributs += "|"+name) unless (p.attributs.split('|').include? name)
        end
        p.save!
		
        nb_medias += 1
        @medias[name] = p
      rescue
		Logger.send("warn","[Import] Error during reading entry : #{entry.name.to_s}")
      end
    end
	Logger.send("warn","[Import] #{nb_medias.to_s} medias registered")
  end
  
  # If media are not with data's file, and we have to download them we reference all active media of the gateway
######def update_remote_medias <-- FIXME change the name
  def update_medias
	@passerelle.biens.each{ |b|
		b.bien_photos.each{ |p|
			next unless p.attributs
			@medias[p.attributs] = p
		}
	}
	return true
  end
  
  # Find in all existing medias for actual imported gateway, if there is one who have the research name
  def last_chance_find_media research_name
	@passerelle.biens.each{ |b|
		b.bien_photos.each{ |p|
			next unless p.attributs
			p.attributs.split('|').each{ |n|
				return p if research_name.to_s.downcase == n.to_s.downcase
			}
			@medias[p.attributs] = p
		}
	}
	return false
  end
  
  # Import an image from the given url
######def import_remote_media <-- FIXME change the name
  def import_image(url, ordre, img_name = "")
    # Check if the media have been already download in a previous execution
    unless p = @medias[url]
	 #params : from_url(url, bien, ordre, titre)
     p = BienPhoto.from_url(url, nil, nil, nil)
     if p.nil?
		Logger.send("warn","[Import] Media not download correctly. Try to find [#{url}] in all client medias already downloaded")
		p = last_chance_find_media url
		if p.nil?
			Logger.send("warn", "Media will miss : [#{url}]")
			return nil 
		end
     end
    end

    # if allready imported just update order
    p.ordre = ordre
    p.save!

    return p
  rescue Exception => e
	Logger.send("warn", "Misformatted image entry : [#{url}]")
    #ExceptionLogger.log e, :client => @client
    return nil
  end

  # Find an image already imported (via dl_and_update_medias's method) from the given name
######def import_local_media <-- FIXME change the name  
  def import_local_image(file_name, ordre, img_name = "")
    # Test if media is in those who's been downloaded
    research_file_name = file_name.to_s.downcase
    if @medias.has_key? research_file_name
		# Then update order
		p = @medias[research_file_name]
    else
		Logger.send("warn", "Media not found in new downloaded medias. Try to find [#{research_file_name}] in all client medias")
		p = last_chance_find_media research_file_name
		if p.nil?
			Logger.send("warn", "Don't find file_name : ["+research_file_name+"]")
			return nil
		end
    end
	p.ordre = ordre
	p.save!
	return p
  end
  
	# Update the status of the "bien" (the one who had been updated will become "current" bien, the others will become "old")
######def maj_bien <-- FIXME change the name
  def update_goods
    
    # Commit: age old goods, activate newly imported goods
    to_age = @passerelle.biens.where(:statut => "cur")
	to_activate = @passerelle.biens.where(:statut => "new")
    
    Bien.transaction do
      to_age.each do |b|
        b.statut = 'old'
        b.bien_photos.clear
        b.save!
      end
      to_activate.each do |b|
        b.statut = 'cur'
        b.save!
      end
	  
	  Logger.send("warn", "[Import] Marked #{to_age.size} good entries as old.")
	  Logger.send("warn", "[Import] Activated #{to_activate.size} new good entries.")
    end
  end
  
  # With a given name, we will find the associated good.
  # This method depend on an other who have to be declare in the importer file
  # The other method ("match_agency_ref_by_name" will use the name to match the good's reference)
  def get_good_by_media_name name
    
    bien_ref = match_agency_ref_by_name(name)    
    if bien_ref.nil?
	  Logger.send("warn", "No corresponding ref to this media name : #{name}")
      return nil
    end
	b = Bien.where(:statut => "new", :reference => bien_ref).first
    if b.nil?
	  Logger.send("warn", "No corresponding 'bien' to this media name : #{name} - 'bien' ref : #{bien_ref}")
      return nil
    end
    return b
  end
  
  # The method who will find a good with the name of a media
  def match_agency_ref_by_name name
    raise "match_agency_ref_by_name must be redefined in children classes"
  end
  
  # Special Import Method for importer who we don't know the list of the media for a given goods.
  # So we have to find the corresponding good thanks to the name of the media (with matching methods)
######def match_import_bien <-- FIXME change the name  
######def import_bien_par_correspondance <-- FIXME change the name
  def matching_import_image
    goods_img_clear = Hash.new
    good_medias = []
	matcher_good_and_medias = Hash.new

	# Reference all 'bien' who matched with media's name
    @medias.sort.map{ |a| a[0]}.each do |name|
      next unless (good = get_good_by_media_name(name))
      goods_img_clear[good.id] = good
      good_medias.push @medias[name]
	  matcher_good_and_medias[@medias[name].id] = good
    end
    
    # Before import media, clear media for new good who's medias is update
    goods_img_clear.each do |id, good|
     good.bien_photos.clear
     good.save!
    end
	
	matcher_good_and_medias.each{ |media_id,good|
		begin
			m = BienPhoto.find media_id
		rescue
			Logger.send("warn", "No corresponding bien_photo to this id : #{media_id}")
			next
		end
		next if m.nil?
		next if good.bien_photos.include? m
		m.bien = good
		m.save!
	}
	
    return goods_img_clear.size    
  end

end