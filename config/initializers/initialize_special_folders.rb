case RAILS_ENV.to_s
  when "development"      then $base_client_medias = "public/images/client_medias"
  when "production" then $base_client_medias = "public/images/client_medias"
  when "test"       then $base_client_medias = "public/images/client_medias"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

case RAILS_ENV.to_s
  when "development"      then $url_client_medias = "images/client_medias"
  when "production" then $url_client_medias = "images/client_medias"
  when "test"       then $url_client_medias = "images/client_medias"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

case RAILS_ENV.to_s
  when "development"      then $domain = "http://localhost:3000"
  when "production" then $domain = "http://81.93.24.42:60100"
  when "test"       then $domain = "http://localhost"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

case RAILS_ENV.to_s
  when "development"      then $tmp_path = "public/tmp"
  when "production" then $tmp_path = "public/tmp"
  when "test"       then $tmp_path = "public/tmp"
end

case RAILS_ENV.to_s
  when "development"      then $base_executions_sources = "public/executions_sources"
  when "production" then $base_executions_sources = "public/executions_sources"
  when "test"       then $base_executions_sources = "public/executions_sources"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

case RAILS_ENV.to_s
  when "development"      then $default_client_folder = "no_client"
  when "production" then $default_client_folder = "no_client"
  when "test"       then $default_client_folder = "no_client"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

case RAILS_ENV.to_s
  when "development"      then $url_executions_sources = "executions_sources"
  when "production" then $url_executions_sources = "executions_sources"
  when "test"       then $url_executions_sources = "executions_sources"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

case RAILS_ENV.to_s
  when "development"      then $base_ftp_repo = "C:/web applications/FTP filezilla/"
  when "production" then $base_ftp_repo = "C:/web applications/FTP filezilla/"
  when "test"       then $base_ftp_repo = "C:/web applications/FTP filezilla/"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

case RAILS_ENV.to_s
  when "development"      then $firmware_folder = "firmwares"
  when "production" then $firmware_folder = "firmwares"
  when "test"       then $firmware_folder = "firmwares"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

case RAILS_ENV.to_s
  when "development"      then $filezilla_server_folder = "C:/Program Files (x86)/FileZilla Server"
  when "production" then $filezilla_server_folder = "C:/Program Files (x86)/FileZilla Server"
  when "test"       then $filezilla_server_folder = "C:/Program Files (x86)/FileZilla Server"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

Dir.mkdir $base_client_medias unless File.exist? $base_client_medias
Dir.mkdir $tmp_path unless File.exist? $tmp_path
Dir.mkdir $base_executions_sources unless File.exist? $base_executions_sources
Dir.mkdir "#{$base_executions_sources}/#{$firmware_folder}" unless File.exist? "#{$base_executions_sources}/#{$firmware_folder}"
Dir.mkdir "#{$base_client_medias}/#{$default_client_folder}" unless File.exist? "#{$base_client_medias}/#{$default_client_folder}"