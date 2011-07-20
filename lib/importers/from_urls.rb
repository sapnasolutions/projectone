# Superclass for importers that use (uploaded) files as input.
class Importers::FromUrls
  require 'open-uri'
  
  # Setup for a +client+ and an +importer+ name (short string).
  # +mime+ is a list of valid file mime types
  def initialize client, importer, mime, uri
    @client = client
    @app = @client.application
    @logger = PrefixedLogger.new self.class
    @importer = importer
    @mime = mime
    @agency = nil
    @medias = {}
    @uri = uri
  end
  
  
  # Completely reset the imports for the client:
  # don't destroy any data, but mark all already-imported files as not imported.
  # Parameter : 
  # => nb_last_file : if nil : reset all
  #                   if <= max datas for client reset as much as value passed
  #                   if > max datas for client reset all
  def reset nb_last_file = nil
    @logger.info "Start reset #{@client.to_label}"
    scan_files
    
    datas = Media::Data.find(:all, :conditions => {:client_id => @client.id}, :order => :created_at).select { |z|
      z.attrs[@importer]      
    }
    total_imported_file = datas.size
    datas.slice!(-nb_last_file..-1) if nb_last_file && nb_last_file <= datas.size
    
    datas.each { |z|
      z.attrs[:imported] = false
      z.save!
    }
    @logger.info "End reset #{@client.to_label} => #{datas.size.to_s} last file reseted (total : #{total_imported_file.to_s})"
  end
  
  # List all medias for actual Client
  def update_medias
    Media::Image.find(:all, :conditions => {:client_id => @client.id}).each do |m|
      url = m.attrs[:url]
      next unless url
      next unless m.attrs[@importer]
      @medias[url] = m
    end
    return
  end
  
  # Import the non-imported zipfiles for a given client.
  def import
    scan_files
    
    # import non-imported zipfiles
    Media::Data.find(:all, :conditions => {:client_id => @client.id}, :order => :created_at).select { |z|
      z.attrs[@importer] and not z.attrs[:imported]      
    }.each { |xml|
      update_medias
      
      import_file xml.data.path if File.exist? z.data.path
      xml.attrs[:imported] = true
      xml.save!
    }
    
    @app.last_import = DateTime.now
    @app.save!
  end
  
  
  # Overload this in inherited classes
  def import_file
    raise "import_file must be redefined in children classes"
  end
  
  
  # Scan for zipfiles in the client's directory, and copy them to Media::Data
  def scan_files
    if @app.importer != @importer.to_s
      raise "Client #{@client.to_label} doesn't use the #{@importer} importer."
    end
        
    @logger.info "Loading from URI #{@uri}"
    begin
      uriOpener = open(URI.encode(@uri))
      xml = uriOpener.read
      xml.gsub!(/&([^ ;]{0,20}) /,"&amp;#{'\1'} ")
      tmp = Paperclip::Tempfile.new "tempxml"
      tmp.write xml
      tmp.rewind
      raise "Fail Read" unless Importers::Check.check(tmp.path, @mime)
    rescue
      @logger.error "Failure: (#{$!})"
      return false
    end
    
    
    # check if the xlm returned by the uri have been already downloaded
    m = Media::Data.from_data(xml, @client)
    return false if m.nil?
    m.attrs[@importer] = true
    m.refcount = 1
    m.save!
    
  end

end