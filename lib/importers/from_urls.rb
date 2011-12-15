# Superclass for importers that use (uploaded) files as input.
class Importers::FromUrls < Importers::BaseImporters
  require 'open-uri'
  require 'iconv'
  # no waiting parameters
  
  def create_uri
	raise "create_uri must be redefined in children classes"
  end
  
  # Scan the web service for check if the file was updated
  def scan_files
	Logger.send("warn","[FILE] Start scan files")
	@result[:description] << "[FILE] Start scan files"
    
	uri = create_uri
	Logger.send("warn","Loading from URI #{uri}")
	@result[:description] << "Loading from URI #{uri}"
	data = ""
    begin
   	  # i = Iconv.new('ASCII-8BIT','UTF-8')
      uriOpener = open(URI.encode(uri))
      data =  Iconv.conv("utf-8//ignore","gb2312//ignore",uriOpener.read)
      data.gsub!(/&([^ ;]{0,20}) /,"&amp;#{'\1'} ") #remplace le signe & par son equivalent HTML : &amp;
	  ### check if the file is a well formated xml ###
    rescue
	  Logger.send("warn","Failure: (#{$!})")
	  @result[:description] << "Failure: (#{$!})"
      return false
    end
    # check if the xlm returned by the uri have been already downloaded
	return unless ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest data)).first.nil?
    e = Execution.new
	e.passerelle = @passerelle
	e.statut = "nex"
	e.save!
	
	f = ExecutionSourceFile.from_data("data_file", data, e)
	
	e.execution_source_file = f
	e.save!
  end

end