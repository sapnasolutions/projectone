# Superclass for importers that use (uploaded) files as input.
class Importers::FromDataBase < Importers::FromFiles
  require 'mysql'
  
  # Setup for a +client+ and an +importer+ name (short string).
  # +mime+ is a list of valid file mime types
  def initialize client, importer, db_address, db_name, login, password, query
    @db_address = db_address
    @db_name = db_name
    @login = login
    @password = password
    @query = query
    super client, importer, nil
  end
  
  # scan database and upload result
  def scan_files
    @logger.info "Start query data base"
    if @app.importer != @importer.to_s
      raise "Client #{@client.to_label} doesn't use the #{@importer} importer."
    end
    begin
      db = Mysql.real_connect(@db_address,@db_name,@login,@password)
    rescue Mysql::Error
      @logger.error "Error during loggin database !!"
    end

    query_result = db.query @query
    hash = []
    query_result.each_hash{ |row| 
      encoded_row = {}
      row.each{ |key, value|
        encoded_row[key] = Iconv.conv('utf-8','cp1252',value)
      }
      hash << encoded_row 
    }
    
    xml = hash.to_xml(:root => 'goods')
    m = Media::Data.from_data(xml,@client)
    return if m.nil?
    m.attrs[@importer] = true
    m.refcount = 1
    m.save!
  end

end