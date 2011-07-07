case RAILS_ENV.to_s
  when "development"      then $base_client_medias = "public/images/client_medias"
  when "production" then $base_client_medias = "public/images/client_medias"
  when "staging"       then $base_client_medias = "public/images/client_medias"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

case RAILS_ENV.to_s
  when "development"      then $url_client_medias = "images/client_medias"
  when "production" then $url_client_medias = "images/client_medias"
  when "staging"       then $url_client_medias = "images/client_medias"
else
  raise "Unknown environnement : #{RAILS_ENV}"
end

case RAILS_ENV.to_s
  when "development"      then $tmp_path = "public/images/tmp"
  when "production" then $tmp_path = "public/images/tmp"
  when "staging"       then $tmp_path = "public/images/tmp"
end

Dir.mkdir $base_client_medias unless File.exist? $base_client_medias
Dir.mkdir $tmp_path unless File.exist? "public/images/tmp"