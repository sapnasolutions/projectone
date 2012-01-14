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
  
end