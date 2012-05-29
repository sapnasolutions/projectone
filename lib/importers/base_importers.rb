# encoding: utf-8
# Superclass for importers that use (uploaded) files as input.
class Importers::BaseImporters

  require 'zip/zipfilesystem'
  require 'iconv'
  
  # Setup for a +client+ and an +importer+ name (short string).
  # +mime+ is a list of valid file mime types
  def initialize passerelle, mime = nil
    @passerelle = passerelle
    @mime = mime
	@parameters = {}
	unless @passerelle.parametres.empty? || @passerelle.parametres.nil?
		@parameters = @passerelle.parametres.to_hashtribute
	end
    #@agency = nil
	@result = Hash.new
	@result[:ok] = true
	@result[:description] = ""
    @medias = {}
  end
  
  # Import the non-imported zipfiles for a given client.
  def import
    scan_files
    # import non-imported files
	to_be_executed = Execution.where(:passerelle_id => @passerelle.id, :statut => "nex").order('created_at')
	to_be_executed.each{ |execution|
		execution.statut = "ece" #note : En Cours d'Execution
		execution.save!
	}
	to_be_executed.each{ |execution|
	
	
	begin
	  import_exe execution
	  statut = "ok"
	rescue Exception => e
		    @rapport_import << "Fail<\br>"
		    @rapport_import << "Error message => : #{e.message}<\br>"
		    @rapport_import << "Error backtrace => #{e.backtrace}<\br>"
		    Logger.send("warn","[Passerelle] Import FAIL !")
		    Logger.send("warn","[Passerelle] Rapport : #{@rapport_import}")
		    statut = "err"
	end
		
		exe_to_save = Execution.find execution.id
		exe_to_save.statut = statut
		exe_to_save.description = @result[:description]
		exe_to_save.save!
	}
    @passerelle.updated_at = DateTime.now
    @passerelle.save!
	
	res = Hash.new
	res["updated"] = true
	# res["message"] = "desc"
	
	return res
  end
  
  
  # Overload this in inherited classes
  def import_exe execution
    raise "import_exe must be redefined in children classes"
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
      # begin
        next unless entry.name.to_s.downcase =~ /.(jpg|jpeg|png|bmp)$/
      
        data = zip_file.read(entry)
		# find a way to create media without "bien" linked, but only "passerelle" ?
		name = File.basename entry.name.to_s.downcase
		#params for from_data : filename,image_data,bien,ordre,titre
        p = BienPhoto.from_data name, data, nil, nil, name, @passerelle
        next if p.nil?
		
        nb_medias += 1
        @medias[name] = p
      # rescue
		# Logger.send("warn","[Import] Error during reading entry : #{entry.name.to_s}")
		# @result[:description] << "[Import] Error during reading entry : #{entry.name.to_s}"
      # end
    end
	Logger.send("warn","[Import] #{nb_medias.to_s} medias registered")
	@result[:description] << "[Import] #{nb_medias.to_s} medias registered"
  end
  
  # If media are not with data's file, and we have to download them we reference all active media of the gateway
  def update_remote_medias
	@passerelle.biens.each{ |b|
		b.bien_photos.each{ |p|
			next unless p.attributs
			@medias[p.attributs] = p
		}
	}
	return true
  end
  
  # Import an image from the given url
  def import_remote_media(url, ordre, bien = nil, img_name = nil)
    # Check if the media have been already download in a previous execution
    unless p = @medias[url]
	 img_name = File.basename url unless img_name
     p = BienPhoto.from_url(url, bien, ordre, img_name, @passerelle)
     if p.nil?
		Logger.send("warn","[Import] Media not download correctly. Try to find [#{url}] in all client medias already downloaded")
		@result[:description] << "[Import] Media not download correctly. Try to find [#{url}] in all client medias already downloaded"
		p = last_chance_find_media url
		p_safe = BienPhoto.find(p.id)
		p_safe.bien = bien
		p_safe.save!
		if p_safe.nil?
			Logger.send("warn", "Media will miss : [#{url}]")
			@result[:description] << "Media will miss : [#{url}]"
			return nil 
		end
     end
    end
    p_safe = BienPhoto.find(p.id)
    # if allready imported just update order
    p_safe.ordre = ordre
    p_safe.save!

    return p
  rescue Exception => e
	Logger.send("warn", "Misformatted image entry : [#{url}]")
	@result[:description] << "Misformatted image entry : [#{url}]"
    #ExceptionLogger.log e, :client => @client
    return nil
  end

  # Find an image already imported (via dl_and_update_medias's method) from the given name
  def import_local_media(file_name, ordre, bien = nil, img_name = "")
    # Test if media is in those who's been downloaded
    research_file_name = file_name.to_s.downcase
    if @medias.has_key? research_file_name
		# Then update order
		p = BienPhoto.find(@medias[research_file_name].id)
    else
		Logger.send("warn", "Media not found in new downloaded medias. Try to find [#{research_file_name}] in all client medias")
		@result[:description] << "Media not found in new downloaded medias. Try to find [#{research_file_name}] in all client medias"
		p = last_chance_find_media research_file_name
		if p.nil?
			Logger.send("warn", "Don't find file_name : ["+research_file_name+"]")
			@result[:description] << "Don't find file_name : ["+research_file_name+"]"
			return nil
		end
    end
	p.ordre = ordre
	p.bien = bien
	p.save!
	return p
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
	return nil
  end
  
	# Update the status of the "bien" (the one who had been updated will become "current" bien, the others will become "old")
  def maj_biens(transaction_type = nil)
    
    # Commit: age old goods, activate newly imported goods
	if transaction_type
		to_age = @passerelle.biens.where(:statut => "cur", :bien_transaction_id => transaction_type.id)
		nom = transaction_type.nom
	else
		to_age = @passerelle.biens.where(:statut => "cur")
		nom = "Tous type"
	end
	to_activate = @passerelle.biens.where(:statut => "new")
    
    Bien.transaction do
	  destroyedsize = to_age.size
      to_age.each do |b|
        b.destroy
      end
      to_activate.each do |b|
        b.statut = 'cur'
        b.save!
      end
	  
	  Logger.send("warn", "[Import : #{nom}] Destroy #{destroyedsize} old good entries.")
	  @result[:description] << "[Import : #{nom}] Destroy #{destroyedsize} old good entries."
	  Logger.send("warn", "[Import : #{nom}] Activated #{to_activate.size} new good entries.")
	  @result[:description] << "[Import : #{nom}] Activated #{to_activate.size} new good entries."
    end
  end
  
  # With a given name, we will find the associated good.
  # This method depend on an other who have to be declare in the importer file
  # The other method ("match_agency_ref_by_name" will use the name to match the good's reference)
  def get_good_by_media_name name
    
    bien_ref = match_agency_ref_by_name(name)    
    if bien_ref.nil?
	  Logger.send("warn", "No corresponding ref to this media name : #{name}")
	  @result[:description] << "No corresponding ref to this media name : #{name}"
      return nil
    end
	b = Bien.where(:statut => "new", :reference => bien_ref, :passerelle_id => @passerelle.id).first
    if b.nil?
	  Logger.send("warn", "No corresponding 'bien' to this media name : #{name} - 'bien' ref : #{bien_ref}")
	  @result[:description] << "No corresponding 'bien' to this media name : #{name} - 'bien' ref : #{bien_ref}"
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
  def import_bien_par_correspondance
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
	# un-associate the photos to the goods (equivalent to clear, but not destroy the photos.
     good.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
    end
	
	matcher_good_and_medias.each{ |media_id,good|
		begin
			m = BienPhoto.find media_id
		rescue
			Logger.send("warn", "No corresponding bien_photo to this id : #{media_id}")
			@result[:description] << "No corresponding bien_photo to this id : #{media_id}"
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